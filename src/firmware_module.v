// =====================================================
// FILE: firmware_module.v
// Firmware Data Module
// =====================================================

module firmware_module(
    output [7:0] firmware_data
);

assign firmware_data = 8'b11001100;

endmodule