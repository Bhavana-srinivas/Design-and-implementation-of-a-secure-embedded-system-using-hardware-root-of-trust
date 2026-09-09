// hamming_distance.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// PUF responses are noisy (temperature, voltage, aging cause a handful
// of bits to flip run-to-run) so exact-match comparison would lock out
// the genuine device. Hamming distance -- the popcount of the XOR
// between reference and current response -- gives a fuzzy-match score
// that a downstream threshold check can tolerate small, expected noise
// while still rejecting a genuinely different (cloned/counterfeit) die,
// whose HD against the reference will be large (statistically ~N/2 for
// an unrelated PUF instance).
// -----------------------------------------------------------------------
module hamming_distance #(
    parameter RESP_WIDTH = 8,
    parameter HD_WIDTH   = 4   // ceil(log2(RESP_WIDTH+1))
) (
    input  wire [RESP_WIDTH-1:0] reference_response,
    input  wire [RESP_WIDTH-1:0] current_response,
    output wire [HD_WIDTH-1:0]   hamming_dist
);

    wire [RESP_WIDTH-1:0] diff;
    assign diff = reference_response ^ current_response;

    // Simple popcount via generate/adder tree -- fine for RESP_WIDTH=8.
    function [HD_WIDTH-1:0] popcount;
        input [RESP_WIDTH-1:0] vec;
        integer i;
        begin
            popcount = {HD_WIDTH{1'b0}};
            for (i = 0; i < RESP_WIDTH; i = i + 1)
                popcount = popcount + vec[i];
        end
    endfunction

    assign hamming_dist = popcount(diff);

endmodule
