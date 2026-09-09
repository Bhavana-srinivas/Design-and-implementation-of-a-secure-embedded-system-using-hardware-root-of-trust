// uart_receiver.v
// -----------------------------------------------------------------------
// SECURITY RELEVANCE:
// Physical channel over which the ESP32 delivers its firmware hash (and
// provisioning commands) to the FPGA. Standard 8N1 UART RX. This module
// only recovers raw bytes -- framing them into the command protocol
// (hash load, reference load, threshold set) is sha256_interface.v's job,
// keeping the bit-recovery layer and the protocol layer separate.
// -----------------------------------------------------------------------
module uart_receiver #(
    parameter CLK_FREQ_HZ  = 50_000_000,
    parameter BAUD_RATE    = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,          // UART RX line from ESP32

    output reg  [7:0] rx_byte,
    output reg        rx_valid     // pulses one clk when rx_byte is fresh
);

    localparam integer BIT_PERIOD = CLK_FREQ_HZ / BAUD_RATE;
    localparam integer HALF_BIT   = BIT_PERIOD / 2;

    // double-flop synchronizer for the async rx line
    reg rx_sync0, rx_sync1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= rx;
            rx_sync1 <= rx_sync0;
        end
    end

    localparam S_IDLE  = 2'd0,
               S_START = 2'd1,
               S_DATA  = 2'd2,
               S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_IDLE;
            clk_cnt  <= 16'd0;
            bit_idx  <= 3'd0;
            rx_byte  <= 8'd0;
            rx_valid <= 1'b0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    clk_cnt <= 16'd0;
                    if (rx_sync1 == 1'b0) begin // start bit detected
                        state <= S_START;
                    end
                end

                S_START: begin
                    if (clk_cnt == HALF_BIT - 1) begin
                        if (rx_sync1 == 1'b0) begin // confirm still low at mid-bit
                            clk_cnt <= 16'd0;
                            bit_idx <= 3'd0;
                            state   <= S_DATA;
                        end else begin
                            state <= S_IDLE; // false start (glitch)
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                S_DATA: begin
                    if (clk_cnt == BIT_PERIOD - 1) begin
                        clk_cnt <= 16'd0;
                        shift_reg[bit_idx] <= rx_sync1;
                        if (bit_idx == 3'd7)
                            state <= S_STOP;
                        else
                            bit_idx <= bit_idx + 1'b1;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                S_STOP: begin
                    if (clk_cnt == BIT_PERIOD - 1) begin
                        rx_byte  <= shift_reg;
                        rx_valid <= 1'b1;
                        state    <= S_IDLE;
                    end else begin
                        clk_cnt <= clk_cnt + 1'b1;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
