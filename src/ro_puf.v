// =====================================================
// FILE: ro_puf.v
// Simple RO-PUF Prototype
// =====================================================

module ro_puf(
    input [7:0] challenge,
    output [7:0] response
);

assign response = challenge ^ 8'b10101100;

endmodule