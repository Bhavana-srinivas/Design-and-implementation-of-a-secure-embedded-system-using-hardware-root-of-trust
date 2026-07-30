// =====================================================
// FILE: top_module.v
// Main Top Module
// =====================================================

module top_module(
    input [7:0] sw,
    output boot_led,
    output block_led,
    output [7:0] led
);

wire [7:0] puf_response;
wire [7:0] firmware_data;
wire [7:0] hash_value;
wire match;

// PUF Module
ro_puf p1(
    .challenge(sw),
    .response(puf_response)
);

// Firmware Module
firmware_module f1(
    .firmware_data(firmware_data)
);

// Hash Module
hash_module h1(
    .puf_response(puf_response),
    .firmware_data(firmware_data),
    .hash_value(hash_value)
);

// Comparator
comparator c1(
    .hash_value(hash_value),
    .match(match)
);

// Decision Module
decision_module d1(
    .match(match),
    .boot_led(boot_led),
    .block_led(block_led)
);

// Output LEDs
assign led = hash_value;

endmodule