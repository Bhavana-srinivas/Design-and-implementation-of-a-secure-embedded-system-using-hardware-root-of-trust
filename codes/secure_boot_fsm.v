// secure_boot_fsm.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// Top-level control sequencing. This is the single place that decides
// "has the device proven both its physical identity AND its firmware
// integrity" -- deliberately centralized so the trust decision isn't
// scattered across multiple modules where a bug could create a bypass
// path. AUTH_FAIL is a trap state: it does NOT auto-retry or timeout
// back to IDLE on its own within a power cycle, so a failed device
// cannot be brute-forced into passing by simply waiting/retrying
// indefinitely without an explicit external reset.
// -----------------------------------------------------------------------
module secure_boot_fsm (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       mode_enroll,        // 1 = ENROLL, 0 = AUTHENTICATE
    input  wire       start,              // external "begin boot sequence" trigger

    // RO-PUF controller interface
    output reg        puf_start,
    input  wire        puf_response_valid,
    input  wire [7:0]  puf_response,

    // enrollment storage interface
    output reg         enroll_capture_en,
    input  wire [7:0]  reference_response,
    input  wire        reference_valid,

    // authentication controller interface (PUF Hamming-distance check)
    output reg         puf_compare_en,
    input  wire        puf_decision_valid,
    input  wire        puf_pass,

    // hash path interface
    input  wire        current_hash_valid, // pulses when ESP32 has sent this boot's hash
    input  wire        ref_hash_valid,     // reference hash has been provisioned
    output reg         hash_compare_en,
    input  wire        hash_decision_valid,
    input  wire        hash_pass,

    // reset control
    output reg         release_reset,

    // status (e.g. for LCD)
    output reg  [3:0]  status_code
);

    localparam S_IDLE          = 4'd0,
               S_PUF_START     = 4'd1,
               S_PUF_MEASURE   = 4'd2,
               S_PUF_COMPARE   = 4'd3,
               S_ENROLL_STORE  = 4'd4,
               S_WAIT_HASH     = 4'd5,
               S_HASH_COMPARE  = 4'd6,
               S_AUTH_PASS     = 4'd7,
               S_AUTH_FAIL     = 4'd8,
               S_RELEASE_RESET = 4'd9;

    // status codes for external display
    localparam ST_IDLE      = 4'd0,
               ST_PUF_BUSY  = 4'd1,
               ST_HASH_WAIT = 4'd2,
               ST_PASS      = 4'd3,
               ST_FAIL      = 4'd4,
               ST_ENROLLED  = 4'd5;

    reg [3:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state             <= S_IDLE;
            puf_start         <= 1'b0;
            enroll_capture_en <= 1'b0;
            puf_compare_en    <= 1'b0;
            hash_compare_en   <= 1'b0;
            release_reset     <= 1'b0;
            status_code       <= ST_IDLE;
        end else begin
            // default: pulses low unless explicitly asserted below
            puf_start         <= 1'b0;
            enroll_capture_en <= 1'b0;
            puf_compare_en    <= 1'b0;
            hash_compare_en   <= 1'b0;

            case (state)
                S_IDLE: begin
                    status_code <= ST_IDLE;
                    if (start) begin
                        puf_start <= 1'b1;
                        state     <= S_PUF_START;
                    end
                end

                S_PUF_START: begin
                    status_code <= ST_PUF_BUSY;
                    state       <= S_PUF_MEASURE;
                end

                S_PUF_MEASURE: begin
                    status_code <= ST_PUF_BUSY;
                    if (puf_response_valid) begin
                        state <= mode_enroll ? S_ENROLL_STORE : S_PUF_COMPARE;
                    end
                end

                S_ENROLL_STORE: begin
                    enroll_capture_en <= 1'b1;
                    status_code       <= ST_ENROLLED;
                    release_reset     <= 1'b0; // enrollment does not itself boot the ESP32
                    state             <= S_IDLE;
                end

                S_PUF_COMPARE: begin
                    if (reference_valid) begin
                        puf_compare_en <= 1'b1;
                        if (puf_decision_valid) begin
                            state <= puf_pass ? S_WAIT_HASH : S_AUTH_FAIL;
                        end
                    end else begin
                        // no reference enrolled yet -- cannot authenticate
                        state <= S_AUTH_FAIL;
                    end
                end

                S_WAIT_HASH: begin
                    status_code <= ST_HASH_WAIT;
                    if (current_hash_valid && ref_hash_valid) begin
                        hash_compare_en <= 1'b1;
                        state           <= S_HASH_COMPARE;
                    end
                end

                S_HASH_COMPARE: begin
                    if (hash_decision_valid) begin
                        state <= hash_pass ? S_AUTH_PASS : S_AUTH_FAIL;
                    end
                end

                S_AUTH_PASS: begin
                    status_code <= ST_PASS;
                    state       <= S_RELEASE_RESET;
                end

                S_AUTH_FAIL: begin
                    status_code   <= ST_FAIL;
                    release_reset <= 1'b0;
                    // trap state -- stays here until external rst_n, by design
                end

                S_RELEASE_RESET: begin
                    release_reset <= 1'b1;
                    status_code   <= ST_PASS;
                    // remains here for the rest of the power cycle
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
