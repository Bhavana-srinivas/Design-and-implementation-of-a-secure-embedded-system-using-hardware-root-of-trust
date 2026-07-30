// =====================================================
// FILE: hash_module.v
// Simple XOR Hash Prototype
// =====================================================

module hash_module(
    input [7:0] puf_response,
    input [7:0] firmware_data,
    output [7:0] hash_value
);

assign hash_value = puf_response ^ firmware_data;

endmodule