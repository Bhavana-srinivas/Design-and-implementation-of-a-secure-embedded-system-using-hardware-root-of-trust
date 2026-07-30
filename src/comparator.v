// =====================================================
// FILE: comparator.v
// Compare Hash Result
// =====================================================

module comparator(
    input [7:0] hash_value,
    output match
);

assign match = (hash_value == 8'b01100110);

endmodule