// authentication_controller.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// Turns the raw Hamming distance into a binary trust decision. The
// threshold is deliberately NOT a hard-coded constant: it is a register
// that resets to a synthesis-time DEFAULT_THRESHOLD parameter but can be
// overwritten at runtime via a UART command (see uart_receiver.v /
// top_module.v command decode). This satisfies "configurable, not
// hard-coded" while still giving a safe out-of-box value. Keep the
// default conservative -- too loose weakens unclonability guarantees,
// too tight causes false rejections of the genuine device.
// -----------------------------------------------------------------------
module authentication_controller #(
    parameter RESP_WIDTH        = 8,
    parameter HD_WIDTH          = 4,
    parameter DEFAULT_THRESHOLD = 2   // typical starting point for an 8-bit response
) (
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire                   compare_en,       // pulse to trigger a decision
    input  wire [RESP_WIDTH-1:0]  reference_response,
    input  wire [RESP_WIDTH-1:0]  current_response,

    // runtime threshold programming
    input  wire                   threshold_wr_en,
    input  wire [HD_WIDTH-1:0]    threshold_wr_data,

    output wire [HD_WIDTH-1:0]    hamming_dist,
    output reg                    puf_pass,
    output reg                    decision_valid
);

    reg [HD_WIDTH-1:0] threshold_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            threshold_reg <= DEFAULT_THRESHOLD[HD_WIDTH-1:0];
        else if (threshold_wr_en)
            threshold_reg <= threshold_wr_data;
    end

    hamming_distance #(
        .RESP_WIDTH (RESP_WIDTH),
        .HD_WIDTH   (HD_WIDTH)
    ) u_hd (
        .reference_response (reference_response),
        .current_response   (current_response),
        .hamming_dist        (hamming_dist)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            puf_pass       <= 1'b0;
            decision_valid <= 1'b0;
        end else begin
            decision_valid <= 1'b0;
            if (compare_en) begin
                puf_pass       <= (hamming_dist <= threshold_reg);
                decision_valid <= 1'b1;
            end
        end
    end

endmodule
