// enrollment_storage.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// Holds the enrolled reference PUF response -- the device's "template".
// This is scope-limited to register storage (not non-volatile memory):
// on a Spartan-6 with no external NVM in this design, the reference is
// re-loaded each power cycle, either by running ENROLL mode again or by
// a UART "load reference" command. In a production HRoT this register
// would be backed by protected non-volatile storage (e.g. eFuse/OTP or
// an authenticated external flash region) so enrollment happens exactly
// once at manufacture time. That hardening step is out of scope here
// but is called out explicitly so it isn't mistaken for an oversight.
// -----------------------------------------------------------------------
module enrollment_storage #(
    parameter RESP_WIDTH = 8
) (
    input  wire                    clk,
    input  wire                    rst_n,

    // capture path: from ro_puf_controller during ENROLL mode
    input  wire                    enroll_capture_en,
    input  wire [RESP_WIDTH-1:0]   enroll_capture_data,

    // load path: from UART command (re-provision reference without re-running PUF)
    input  wire                    uart_load_en,
    input  wire [RESP_WIDTH-1:0]   uart_load_data,

    output reg  [RESP_WIDTH-1:0]   reference_response,
    output reg                     reference_valid
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reference_response <= {RESP_WIDTH{1'b0}};
            reference_valid    <= 1'b0;
        end else if (enroll_capture_en) begin
            reference_response <= enroll_capture_data;
            reference_valid    <= 1'b1;
        end else if (uart_load_en) begin
            reference_response <= uart_load_data;
            reference_valid    <= 1'b1;
        end
    end

endmodule
