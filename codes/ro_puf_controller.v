// ro_puf_controller.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// Orchestrates all 8 RO pairs and assembles the final 8-bit PUF
// response. Pairs are measured simultaneously (not multiplexed one at a
// time onto shared oscillators) so that every bit sees the same
// temperature/voltage snapshot -- reduces cross-bit environmental skew.
// -----------------------------------------------------------------------
module ro_puf_controller #(
    parameter NUM_PAIRS      = 8,
    parameter NUM_INVERTERS  = 5,
    parameter COUNT_WIDTH    = 16,
    parameter WINDOW_CYCLES  = 16'd10000   // measurement window length, in clk cycles
) (
    input  wire        clk,
    input  wire         rst_n,
    input  wire         start,          // pulse to begin one full 8-bit measurement
    output reg  [NUM_PAIRS-1:0] puf_response,
    output reg           response_valid
);

    localparam S_IDLE    = 2'd0,
               S_ENABLE  = 2'd1,   // let ROs settle before counting
               S_MEASURE = 2'd2,
               S_DONE    = 2'd3;

    reg [1:0]  state;
    reg        ro_enable;
    reg        window_en;
    reg [15:0] window_cnt;
    reg [15:0] settle_cnt;

    wire [NUM_PAIRS-1:0] bit_valid_v;
    wire [NUM_PAIRS-1:0] response_bit_v;

    genvar g;
    generate
        for (g = 0; g < NUM_PAIRS; g = g + 1) begin : pairs
            // GATE_DELAY_B_NS varies per pair index purely so behavioral
            // simulation produces a non-trivial (non-all-zero) response;
            // on real hardware this has no effect -- the mismatch comes
            // from physical placement, not this parameter.
            ro_pair #(
                .NUM_INVERTERS   (NUM_INVERTERS),
                .COUNT_WIDTH     (COUNT_WIDTH),
                .GATE_DELAY_A_NS (1),
                .GATE_DELAY_B_NS (1 + (g % 3))
            ) u_pair (
                .clk          (clk),
                .rst_n        (rst_n),
                .enable       (ro_enable),
                .window_en    (window_en),
                .bit_valid    (bit_valid_v[g]),
                .response_bit (response_bit_v[g])
            );
        end
    endgenerate

    localparam SETTLE_CYCLES = 16'd200; // let oscillation stabilize before counting

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_IDLE;
            ro_enable      <= 1'b0;
            window_en      <= 1'b0;
            window_cnt     <= 16'd0;
            settle_cnt     <= 16'd0;
            puf_response   <= {NUM_PAIRS{1'b0}};
            response_valid <= 1'b0;
        end else begin
            response_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    ro_enable  <= 1'b0;
                    window_en  <= 1'b0;
                    settle_cnt <= 16'd0;
                    window_cnt <= 16'd0;
                    if (start) begin
                        ro_enable <= 1'b1;
                        state     <= S_ENABLE;
                    end
                end

                S_ENABLE: begin
                    if (settle_cnt >= SETTLE_CYCLES) begin
                        window_en <= 1'b1;
                        state     <= S_MEASURE;
                    end else begin
                        settle_cnt <= settle_cnt + 1'b1;
                    end
                end

                S_MEASURE: begin
                    if (window_cnt >= WINDOW_CYCLES) begin
                        window_en <= 1'b0;
                        state     <= S_DONE;
                    end else begin
                        window_cnt <= window_cnt + 1'b1;
                    end
                end

                S_DONE: begin
                    // all bit_valid_v bits pulse once the counters close out
                    if (&bit_valid_v) begin
                        puf_response   <= response_bit_v;
                        response_valid <= 1'b1;
                        ro_enable      <= 1'b0;
                        state          <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
