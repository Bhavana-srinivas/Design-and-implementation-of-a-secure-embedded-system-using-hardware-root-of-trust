// ring_oscillator.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// This is the physical entropy source for the PUF. An odd number of
// inverters chained combinationally and fed back on itself will free-run
// oscillate. Its exact frequency depends on the physical propagation
// delay of each gate/wire on THIS particular silicon die -- delay that
// is set by uncontrollable sub-nm manufacturing variation. No two dies
// (even from the same wafer, same mask set) will produce identical
// frequencies. This is the unclonability property the whole PUF depends
// on. Do NOT replace this with a counter or LFSR -- those are
// deterministic and give zero physical unclonability.
//
// Implementation note: for Spartan-6, place constraints (LOC/RLOC in the
// UCF) are required so the place-and-route tool does not "optimize" the
// feedback loop away or balance it with the sibling RO in the pair --
// that would destroy the very mismatch you're trying to measure.
//
// SIMULATION vs HARDWARE:
// On real Spartan-6 silicon, oscillation comes from actual gate/wire
// propagation delay -- no explicit delay needed in the RTL, and none is
// synthesizable (Xilinx XST will ignore #delay in synthesizable code).
// In pure zero-delay Verilog simulation, however, a purely combinational
// feedback loop is an infinite delta-cycle loop with no time advancing,
// which hangs the simulator. GATE_DELAY_NS below models per-inverter
// delay ONLY for simulation (default 1ns, tweak per-instance in the
// testbench to create the frequency mismatch between RO_A and RO_B that
// a real die's process variation would produce). Synthesis tools ignore
// these delays; the real oscillation frequency on hardware is whatever
// physical place-and-route makes it, which is the whole point.
// -----------------------------------------------------------------------
`timescale 1ns/1ps
module ring_oscillator #(
    parameter NUM_INVERTERS = 5,     // must be ODD for oscillation
    parameter GATE_DELAY_NS = 1      // simulation-only; ignored by synthesis
) (
    input  wire enable,   // gate the oscillator on/off to save power / avoid interference
    output wire osc_out
);

    wire [NUM_INVERTERS-1:0] chain;

    // First stage is NAND'd with enable so the ring is fully stopped
    // (not just gated at the output) when disabled -- this avoids
    // leaving a free-running unstoppable oscillator that would couple
    // noise into neighboring ROs during the OTHER RO's measurement.
    assign #GATE_DELAY_NS chain[0] = ~(chain[NUM_INVERTERS-1] & enable);

    genvar i;
    generate
        for (i = 1; i < NUM_INVERTERS; i = i + 1) begin : inv_chain
            assign #GATE_DELAY_NS chain[i] = ~chain[i-1];
        end
    endgenerate

    assign osc_out = chain[NUM_INVERTERS-1];

endmodule
