// ro_pair.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// One "cell" of the PUF. Two nominally-identical ROs are compared
// against each other rather than against an absolute frequency target.
// This differential comparison cancels out global effects (temperature,
// supply voltage, process corner) that affect both ROs roughly equally,
// leaving mostly the LOCAL, chip-specific mismatch as the signal. This
// is why RO-PUFs are far more repeatable across environmental
// conditions than a single absolute frequency measurement would be.
// -----------------------------------------------------------------------
module ro_pair #(
    parameter NUM_INVERTERS   = 5,
    parameter COUNT_WIDTH     = 16,
    parameter GATE_DELAY_A_NS = 1,  // simulation-only mismatch knob; ignored by synthesis
    parameter GATE_DELAY_B_NS = 1
) (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   enable,
    input  wire                   window_en,
    output reg                    bit_valid,
    output reg                    response_bit
);

    wire osc_a, osc_b;
    wire [COUNT_WIDTH-1:0] count_a, count_b;
    wire valid_a, valid_b;

    // NUM_INVERTERS is deliberately allowed to differ by construction
    // routing (not by parameter) between A and B -- identical RTL,
    // physically distinct placement is what creates the mismatch.
    ring_oscillator #(.NUM_INVERTERS(NUM_INVERTERS), .GATE_DELAY_NS(GATE_DELAY_A_NS)) ro_a (
        .enable  (enable),
        .osc_out (osc_a)
    );

    ring_oscillator #(.NUM_INVERTERS(NUM_INVERTERS), .GATE_DELAY_NS(GATE_DELAY_B_NS)) ro_b (
        .enable  (enable),
        .osc_out (osc_b)
    );

    frequency_counter #(.COUNT_WIDTH(COUNT_WIDTH)) fc_a (
        .clk         (clk),
        .rst_n       (rst_n),
        .osc_in      (osc_a),
        .window_en   (window_en),
        .freq_count  (count_a),
        .count_valid (valid_a)
    );

    frequency_counter #(.COUNT_WIDTH(COUNT_WIDTH)) fc_b (
        .clk         (clk),
        .rst_n       (rst_n),
        .osc_in      (osc_b),
        .window_en   (window_en),
        .freq_count  (count_b),
        .count_valid (valid_b)
    );

    // valid_a / valid_b are single-clk-cycle pulses out of each
    // frequency_counter's own CDC synchronizer. Because RO_A and RO_B run
    // at different (mismatched, by design) frequencies, their pulses are
    // NOT guaranteed to land on the same clk edge -- a plain AND of the
    // two would only catch bit_valid on the rare cycle they coincide.
    // Latch each into a sticky bit and only clear both once a NEW
    // measurement window opens, so bit_valid asserts reliably once BOTH
    // counters have reported, however far apart in time that happens.
    reg count_a_latched, count_b_latched;
    reg [COUNT_WIDTH-1:0] count_a_reg, count_b_reg;
    reg window_en_d;
    reg valid_a_seen, valid_b_seen;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_a_seen <= 1'b0;
            valid_b_seen <= 1'b0;
            count_a_reg  <= {COUNT_WIDTH{1'b0}};
            count_b_reg  <= {COUNT_WIDTH{1'b0}};
            window_en_d  <= 1'b0;
        end else begin
            window_en_d <= window_en;
            if (window_en && !window_en_d) begin
                // new window just opened -- clear stickies for this round
                valid_a_seen <= 1'b0;
                valid_b_seen <= 1'b0;
            end else begin
                if (valid_a) begin
                    valid_a_seen <= 1'b1;
                    count_a_reg  <= count_a;
                end
                if (valid_b) begin
                    valid_b_seen <= 1'b1;
                    count_b_reg  <= count_b;
                end
            end
        end
    end

    // Register bit_valid (rather than a continuous assign off valid_a_seen
    // /valid_b_seen) so it lands on the SAME clock edge as response_bit
    // below, instead of one cycle earlier -- both are derived from the
    // same pre-edge snapshot of valid_a_seen/valid_b_seen, avoiding a
    // same-cycle race between "result ready" and "result correct".
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_valid    <= 1'b0;
            response_bit <= 1'b0;
        end else if (valid_a_seen && valid_b_seen) begin
            bit_valid    <= 1'b1;
            response_bit <= (count_a_reg > count_b_reg) ? 1'b1 : 1'b0;
        end else begin
            bit_valid <= 1'b0;
        end
    end

endmodule
