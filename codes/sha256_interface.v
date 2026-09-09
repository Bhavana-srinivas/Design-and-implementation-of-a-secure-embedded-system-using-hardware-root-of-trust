// sha256_interface.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// The ESP32 computes the real SHA-256 of its own flashed firmware image
// (this module does NOT compute SHA-256 in hardware -- the FPGA only
// needs to COMPARE hashes, not hash arbitrary data, so keeping the SHA
// engine off-FPGA reduces attack surface and gate count). This module
// frames incoming UART bytes into a simple command protocol so the FPGA
// knows whether an incoming 32-byte block is:
//   - the CURRENT firmware hash to check this boot, or
//   - a new REFERENCE hash being (re-)provisioned, or
//   - a REFERENCE PUF response being (re-)provisioned, or
//   - a new HD threshold value.
// This a minimal framing layer, not a cryptographically authenticated
// channel -- in a hardened design the provisioning commands (REF_HASH,
// REF_PUF, THRESHOLD) would themselves need to be signed/authenticated
// so an attacker on the UART line can't simply reprogram the reference
// values to match malicious firmware. Flagged here as a known
// simplification appropriate for an academic prototype.
//
// Protocol (all single UART bytes unless noted):
//   0x01 <32 bytes>  -> load REFERENCE hash
//   0x02 <32 bytes>  -> load CURRENT firmware hash (normal boot path)
//   0x03 <1 byte>    -> load REFERENCE PUF response (8-bit)
//   0x04 <1 byte>    -> set HD threshold
// -----------------------------------------------------------------------
module sha256_interface #(
    parameter HASH_WIDTH = 256,
    parameter RESP_WIDTH = 8,
    parameter HD_WIDTH   = 4
) (
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire [7:0]              rx_byte,
    input  wire                    rx_valid,

    output reg  [HASH_WIDTH-1:0]   ref_hash,
    output reg                     ref_hash_wr_en,

    output reg  [HASH_WIDTH-1:0]   current_hash,
    output reg                     current_hash_valid,

    output reg  [RESP_WIDTH-1:0]   ref_puf_wr_data,
    output reg                     ref_puf_wr_en,

    output reg  [HD_WIDTH-1:0]     threshold_wr_data,
    output reg                     threshold_wr_en
);

    localparam CMD_REF_HASH  = 8'h01,
               CMD_CUR_HASH  = 8'h02,
               CMD_REF_PUF   = 8'h03,
               CMD_THRESHOLD = 8'h04;

    localparam S_WAIT_CMD = 2'd0,
               S_PAYLOAD  = 2'd1;

    reg [1:0]  state;
    reg [7:0]  cmd;
    reg [5:0]  byte_cnt;      // up to 32 bytes for hash payload
    reg [255:0] shift_buf;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state               <= S_WAIT_CMD;
            cmd                 <= 8'd0;
            byte_cnt            <= 6'd0;
            shift_buf           <= {HASH_WIDTH{1'b0}};
            ref_hash            <= {HASH_WIDTH{1'b0}};
            ref_hash_wr_en      <= 1'b0;
            current_hash        <= {HASH_WIDTH{1'b0}};
            current_hash_valid  <= 1'b0;
            ref_puf_wr_data     <= {RESP_WIDTH{1'b0}};
            ref_puf_wr_en       <= 1'b0;
            threshold_wr_data   <= {HD_WIDTH{1'b0}};
            threshold_wr_en     <= 1'b0;
        end else begin
            // default: all "write enable" / "valid" pulses last one cycle
            ref_hash_wr_en     <= 1'b0;
            current_hash_valid <= 1'b0;
            ref_puf_wr_en      <= 1'b0;
            threshold_wr_en    <= 1'b0;

            if (rx_valid) begin
                case (state)
                    S_WAIT_CMD: begin
                        cmd       <= rx_byte;
                        byte_cnt  <= 6'd0;
                        shift_buf <= {HASH_WIDTH{1'b0}};
                        state     <= S_PAYLOAD;
                    end

                    S_PAYLOAD: begin
                        case (cmd)
                            CMD_REF_HASH, CMD_CUR_HASH: begin
                                // MSB-first byte stream into a 256-bit shift buffer
                                shift_buf <= {shift_buf[247:0], rx_byte};
                                if (byte_cnt == 6'd31) begin
                                    if (cmd == CMD_REF_HASH) begin
                                        ref_hash       <= {shift_buf[247:0], rx_byte};
                                        ref_hash_wr_en <= 1'b1;
                                    end else begin
                                        current_hash       <= {shift_buf[247:0], rx_byte};
                                        current_hash_valid <= 1'b1;
                                    end
                                    state <= S_WAIT_CMD;
                                end else begin
                                    byte_cnt <= byte_cnt + 1'b1;
                                end
                            end

                            CMD_REF_PUF: begin
                                ref_puf_wr_data <= rx_byte[RESP_WIDTH-1:0];
                                ref_puf_wr_en   <= 1'b1;
                                state           <= S_WAIT_CMD;
                            end

                            CMD_THRESHOLD: begin
                                threshold_wr_data <= rx_byte[HD_WIDTH-1:0];
                                threshold_wr_en   <= 1'b1;
                                state             <= S_WAIT_CMD;
                            end

                            default: state <= S_WAIT_CMD; // unknown cmd, resync
                        endcase
                    end

                    default: state <= S_WAIT_CMD;
                endcase
            end
        end
    end

endmodule
