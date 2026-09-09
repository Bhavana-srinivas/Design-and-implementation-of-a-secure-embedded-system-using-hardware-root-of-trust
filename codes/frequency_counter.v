// frequency_counter.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// Converts "how fast is this RO" into a digital count for comparison.
//
// DESIGN NOTE (important): this counter is clocked DIRECTLY by osc_in,
// not by the system clock. Sampling a free-running RO's edges into the
// system clock domain (a synchronizer + edge-detect scheme) only works
// reliably if the system clock is comfortably above the Nyquist rate of
// the RO -- otherwise you alias and miscount, which is exactly the
// failure mode you'd hit here since ROs on a Spartan-6 commonly run in
// the hundreds of MHz, similar to or faster than the system clock. A
// ripple counter clocked directly by osc_in has no such limit -- it
// counts every edge by construction, at the cost of needing a proper
// clock-domain-crossing (CDC) synchronizer to safely read the count out
// into the system clock domain, which is what the second stage below
// does.
// -----------------------------------------------------------------------
module frequency_counter #(
    parameter COUNT_WIDTH = 16
) (
    input  wire                    clk,          // system clock domain (for control/readout)
    input  wire                    rst_n,
    input  wire                    osc_in,       // RO output being measured -- used AS A CLOCK here
    input  wire                    window_en,    // high (in clk domain) for the measurement window
    output reg  [COUNT_WIDTH-1:0]  freq_count,   // valid in clk domain once count_valid pulses
    output reg                     count_valid
);

    // --- synchronize window_en into the osc_in clock domain ---
    reg [1:0] window_en_osc_sync;
    always @(posedge osc_in or negedge rst_n) begin
        if (!rst_n)
            window_en_osc_sync <= 2'b00;
        else
            window_en_osc_sync <= {window_en_osc_sync[0], window_en};
    end
    wire window_en_osc = window_en_osc_sync[1];

    // --- free-running ripple counter, clocked by the RO, gated by the
    //     synchronized window enable; clears when the window is not active ---
    reg [COUNT_WIDTH-1:0] osc_count;
    always @(posedge osc_in or negedge rst_n) begin
        if (!rst_n)
            osc_count <= {COUNT_WIDTH{1'b0}};
        else if (window_en_osc)
            osc_count <= osc_count + 1'b1;
        else
            osc_count <= {COUNT_WIDTH{1'b0}};
    end

    // --- snapshot the count on the osc clock the moment the (synchronized)
    //     window enable falls, then double-flop that snapshot into the
    //     system clock domain -- standard 2-flop CDC synchronizer.
    //     snapshot_taken is held HIGH (a level, not a single-cycle pulse)
    //     until the next window opens, so the slower/independent clk
    //     domain synchronizer below is guaranteed to catch it regardless
    //     of the osc/clk frequency ratio. ---
    reg [COUNT_WIDTH-1:0] count_snapshot;
    reg                   snapshot_taken;
    always @(posedge osc_in or negedge rst_n) begin
        if (!rst_n) begin
            count_snapshot <= {COUNT_WIDTH{1'b0}};
            snapshot_taken <= 1'b0;
        end else if (window_en_osc_sync == 2'b10) begin
            // falling edge of the synchronized window enable, seen on osc clock
            count_snapshot <= osc_count;
            snapshot_taken <= 1'b1;
        end else if (window_en_osc_sync == 2'b01) begin
            snapshot_taken <= 1'b0; // re-arm only when next window opens
        end
    end

    reg [1:0] snap_taken_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            snap_taken_sync <= 2'b00;
            freq_count      <= {COUNT_WIDTH{1'b0}};
            count_valid     <= 1'b0;
        end else begin
            snap_taken_sync <= {snap_taken_sync[0], snapshot_taken};
            count_valid     <= 1'b0;
            if (snap_taken_sync == 2'b01) begin // rising edge detected in clk domain
                freq_count  <= count_snapshot;
                count_valid <= 1'b1;
            end
        end
    end

endmodule
