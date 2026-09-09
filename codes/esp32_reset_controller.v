// esp32_reset_controller.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// This is the actual enforcement point of the root of trust: physically
// holding the ESP32 in reset means it cannot fetch or execute a single
// instruction until the FPGA has explicitly decided to release it.
// Fail-safe default: reset is ASSERTED (active) out of power-on-reset
// and stays asserted unless the FSM affirmatively releases it -- so any
// undefined/glitched state defaults to "no boot", never "boot anyway".
// -----------------------------------------------------------------------
module esp32_reset_controller (
    input  wire clk,
    input  wire rst_n,          // FPGA's own power-on reset
    input  wire release_reset,  // asserted by secure_boot_fsm on AUTH_PASS + HASH_PASS
    output reg  esp32_reset_n   // active-low reset to the ESP32 EN/RESET pin
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            esp32_reset_n <= 1'b0;        // held in reset (fail-safe default)
        else if (release_reset)
            esp32_reset_n <= 1'b1;        // release only on explicit PASS
        else
            esp32_reset_n <= 1'b0;
    end

endmodule
