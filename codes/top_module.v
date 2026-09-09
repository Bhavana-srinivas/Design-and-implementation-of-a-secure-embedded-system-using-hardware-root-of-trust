// top_module.v
// -----------------------------------------------------------------------
// Top-level integration: RO-PUF path, enrollment storage, Hamming-distance
// authentication, UART-fed SHA-256 hash path, secure boot FSM, and ESP32
// reset gating.
// -----------------------------------------------------------------------
module top_module #(
    parameter NUM_PAIRS         = 8,
    parameter NUM_INVERTERS     = 5,
    parameter COUNT_WIDTH       = 16,
    parameter WINDOW_CYCLES     = 16'd10000,
    parameter HD_WIDTH          = 4,
    parameter DEFAULT_THRESHOLD = 2,
    parameter HASH_WIDTH        = 256,
    parameter CLK_FREQ_HZ       = 50_000_000,
    parameter BAUD_RATE         = 115200
) (
    input  wire clk,
    input  wire rst_n,          // board power-on reset (active low)

    input  wire mode_enroll,    // switch/jumper: 1 = ENROLL, 0 = AUTHENTICATE
    input  wire start,          // push-button: begin boot/enroll sequence

    input  wire uart_rx,        // from ESP32 TX

    output wire esp32_reset_n,  // to ESP32 EN/RESET pin
    output wire [3:0] status_code // to LCD/LEDs
);

    // ---------------- RO-PUF ----------------
    wire [NUM_PAIRS-1:0] puf_response;
    wire                 puf_response_valid;
    wire                 puf_start;

    ro_puf_controller #(
        .NUM_PAIRS     (NUM_PAIRS),
        .NUM_INVERTERS (NUM_INVERTERS),
        .COUNT_WIDTH   (COUNT_WIDTH),
        .WINDOW_CYCLES (WINDOW_CYCLES)
    ) u_puf_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (puf_start),
        .puf_response   (puf_response),
        .response_valid (puf_response_valid)
    );

    // ---------------- UART + command framing ----------------
    wire [7:0] rx_byte;
    wire       rx_valid;

    uart_receiver #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) u_uart (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx       (uart_rx),
        .rx_byte  (rx_byte),
        .rx_valid (rx_valid)
    );

    wire [HASH_WIDTH-1:0] ref_hash;
    wire                  ref_hash_wr_en;
    wire [HASH_WIDTH-1:0] current_hash;
    wire                  current_hash_valid_pulse;
    wire [NUM_PAIRS-1:0]  ref_puf_wr_data;
    wire                  ref_puf_wr_en;
    wire [HD_WIDTH-1:0]   threshold_wr_data;
    wire                  threshold_wr_en;

    sha256_interface #(
        .HASH_WIDTH (HASH_WIDTH),
        .RESP_WIDTH (NUM_PAIRS),
        .HD_WIDTH   (HD_WIDTH)
    ) u_sha_if (
        .clk                 (clk),
        .rst_n               (rst_n),
        .rx_byte             (rx_byte),
        .rx_valid            (rx_valid),
        .ref_hash            (ref_hash),
        .ref_hash_wr_en      (ref_hash_wr_en),
        .current_hash        (current_hash),
        .current_hash_valid  (current_hash_valid_pulse),
        .ref_puf_wr_data     (ref_puf_wr_data),
        .ref_puf_wr_en       (ref_puf_wr_en),
        .threshold_wr_data   (threshold_wr_data),
        .threshold_wr_en     (threshold_wr_en)
    );

    // latch "reference hash has been provisioned at least once"
    reg ref_hash_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ref_hash_valid <= 1'b0;
        else if (ref_hash_wr_en) ref_hash_valid <= 1'b1;
    end

    // latch current_hash_valid until FSM consumes it, then it's re-armed
    // implicitly because current_hash_valid_pulse re-pulses on next UART send
    reg current_hash_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_hash_valid <= 1'b0;
        else if (current_hash_valid_pulse) current_hash_valid <= 1'b1;
        else if (release_reset_w || auth_fail_w) current_hash_valid <= 1'b0;
    end

    // ---------------- Enrollment storage ----------------
    wire [NUM_PAIRS-1:0] reference_response;
    wire                 reference_valid;
    wire                 enroll_capture_en;

    enrollment_storage #(
        .RESP_WIDTH (NUM_PAIRS)
    ) u_enroll_store (
        .clk                  (clk),
        .rst_n                (rst_n),
        .enroll_capture_en    (enroll_capture_en),
        .enroll_capture_data  (puf_response),
        .uart_load_en         (ref_puf_wr_en),
        .uart_load_data       (ref_puf_wr_data),
        .reference_response   (reference_response),
        .reference_valid      (reference_valid)
    );

    // ---------------- PUF authentication (Hamming distance) ----------------
    wire [HD_WIDTH-1:0] hamming_dist;
    wire                puf_pass;
    wire                puf_decision_valid;
    wire                puf_compare_en;

    authentication_controller #(
        .RESP_WIDTH        (NUM_PAIRS),
        .HD_WIDTH          (HD_WIDTH),
        .DEFAULT_THRESHOLD (DEFAULT_THRESHOLD)
    ) u_auth_ctrl (
        .clk                 (clk),
        .rst_n               (rst_n),
        .compare_en          (puf_compare_en),
        .reference_response  (reference_response),
        .current_response    (puf_response),
        .threshold_wr_en     (threshold_wr_en),
        .threshold_wr_data   (threshold_wr_data),
        .hamming_dist        (hamming_dist),
        .puf_pass            (puf_pass),
        .decision_valid      (puf_decision_valid)
    );

    // ---------------- Hash comparison ----------------
    wire hash_pass;
    wire hash_decision_valid;
    wire hash_compare_en;

    hash_comparator #(
        .HASH_WIDTH (HASH_WIDTH)
    ) u_hash_cmp (
        .clk             (clk),
        .rst_n           (rst_n),
        .compare_en      (hash_compare_en),
        .reference_hash  (ref_hash),
        .current_hash    (current_hash),
        .hash_pass       (hash_pass),
        .decision_valid  (hash_decision_valid)
    );

    // ---------------- Secure boot FSM ----------------
    wire release_reset_w;
    wire auth_fail_w; // convenience net for the current_hash_valid clear above

    secure_boot_fsm u_fsm (
        .clk                  (clk),
        .rst_n                (rst_n),
        .mode_enroll          (mode_enroll),
        .start                (start),
        .puf_start            (puf_start),
        .puf_response_valid   (puf_response_valid),
        .puf_response         (puf_response),
        .enroll_capture_en    (enroll_capture_en),
        .reference_response   (reference_response),
        .reference_valid      (reference_valid),
        .puf_compare_en       (puf_compare_en),
        .puf_decision_valid   (puf_decision_valid),
        .puf_pass             (puf_pass),
        .current_hash_valid   (current_hash_valid),
        .ref_hash_valid       (ref_hash_valid),
        .hash_compare_en      (hash_compare_en),
        .hash_decision_valid  (hash_decision_valid),
        .hash_pass            (hash_pass),
        .release_reset        (release_reset_w),
        .status_code          (status_code)
    );

    assign auth_fail_w = (status_code == 4'd4); // ST_FAIL, see secure_boot_fsm

    // ---------------- ESP32 reset gate ----------------
    esp32_reset_controller u_reset_ctrl (
        .clk            (clk),
        .rst_n          (rst_n),
        .release_reset  (release_reset_w),
        .esp32_reset_n  (esp32_reset_n)
    );

endmodule
