`timescale 1ns/1ps
module tb_uart_receiver;

    localparam CLK_FREQ_HZ = 50_000_000;
    localparam BAUD_RATE   = 115200;
    localparam BIT_PERIOD_NS = 1_000_000_000 / BAUD_RATE; // ~8680ns

    reg clk, rst_n, rx;
    wire [7:0] rx_byte;
    wire rx_valid;

    uart_receiver #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD_RATE   (BAUD_RATE)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .rx       (rx),
        .rx_byte  (rx_byte),
        .rx_valid (rx_valid)
    );

    always #10 clk = ~clk; // 50MHz -> 20ns period

    task send_byte(input [7:0] data);
        integer i;
        begin
            rx = 1'b0; // start bit
            #(BIT_PERIOD_NS);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD_NS);
            end
            rx = 1'b1; // stop bit
            #(BIT_PERIOD_NS);
        end
    endtask

    reg [7:0] expected;
    integer errors;

    initial begin
        $display("---- tb_uart_receiver ----");
        clk = 0; rst_n = 0; rx = 1'b1;
        errors = 0;
        #100 rst_n = 1;
        #100;

        expected = 8'hA5;
        send_byte(expected);
        #100;
        if (rx_byte === expected)
            $display("PASS: received 0x%02h", rx_byte);
        else begin
            $display("FAIL: expected 0x%02h got 0x%02h", expected, rx_byte);
            errors = errors + 1;
        end

        expected = 8'h01;
        send_byte(expected);
        #100;
        if (rx_byte === expected)
            $display("PASS: received 0x%02h", rx_byte);
        else begin
            $display("FAIL: expected 0x%02h got 0x%02h", expected, rx_byte);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("---- all PASS ----");
        else
            $display("---- FAILURES SEEN ----");
        $finish;
    end

    // catch rx_valid pulses async
    always @(posedge rx_valid) begin
        $display("  rx_valid pulse: byte=0x%02h at t=%0t", rx_byte, $time);
    end

endmodule
