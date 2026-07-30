// =====================================================
// FILE: decision_module.v
// Boot / Block Decision
// =====================================================

module decision_module(
    input match,
    output boot_led,
    output block_led
);

assign boot_led = match;
assign block_led = ~match;

endmodule