// hash_comparator.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// SHA-256 is a cryptographic hash: a single flipped bit in the firmware
// image changes roughly half the hash bits (avalanche effect), so unlike
// the PUF response, hash comparison is EXACT-match, not fuzzy. Any
// mismatch, however small, means the firmware image has been altered
// (or corrupted) and must fail closed.
// -----------------------------------------------------------------------
module hash_comparator #(
    parameter HASH_WIDTH = 256
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  compare_en,
    input  wire [HASH_WIDTH-1:0] reference_hash,
    input  wire [HASH_WIDTH-1:0] current_hash,
    output reg                   hash_pass,
    output reg                   decision_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_pass      <= 1'b0;
            decision_valid <= 1'b0;
        end else begin
            decision_valid <= 1'b0;
            if (compare_en) begin
                hash_pass      <= (reference_hash == current_hash);
                decision_valid <= 1'b1;
            end
        end
    end

endmodule
