`timescale 1ns/1ps
module tb_top_integration_fail;

    localparam CLK_FREQ_HZ = 50_000_000;
    localparam BAUD_RATE   = 115200;
    localparam BIT_PERIOD_NS = 1_000_000_000 / BAUD_RATE;

    reg clk, rst_n, mode_enroll, start, uart_rx;
    wire esp32_reset_n;
    wire [3:0] status_code;

    top_module #(
        .NUM_PAIRS     (8),
        .NUM_INVERTERS (5),
        .COUNT_WIDTH   (16),
        .WINDOW_CYCLES (500),
        .CLK_FREQ_HZ   (CLK_FREQ_HZ),
        .BAUD_RATE     (BAUD_RATE)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .mode_enroll    (mode_enroll),
        .start          (start),
        .uart_rx        (uart_rx),
        .esp32_reset_n  (esp32_reset_n),
        .status_code    (status_code)
    );

    always #10 clk = ~clk;

    task send_byte(input [7:0] data);
        integer i;
        begin
            uart_rx = 1'b0;
            #(BIT_PERIOD_NS);
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #(BIT_PERIOD_NS);
            end
            uart_rx = 1'b1;
            #(BIT_PERIOD_NS);
        end
    endtask

    reg [255:0] real_hash, tampered_hash;
    integer i;

    initial begin
        $display("---- tb_top_integration_fail (modified firmware) ----");
        clk = 0; rst_n = 0; mode_enroll = 0; start = 0; uart_rx = 1'b1;
        #100 rst_n = 1;
        #100;

        // enroll
        mode_enroll = 1;
        @(posedge clk); start = 1; @(posedge clk); start = 0;
        #30000;

        // provision reference hash
        real_hash = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEE;
        tampered_hash = real_hash ^ 256'h1; // one bit flipped: "modified firmware"
        send_byte(8'h01);
        for (i = 0; i < 32; i = i + 1)
            send_byte(real_hash[255 - i*8 -: 8]);
        #200;

        // authenticate: PUF will match (same die, same sim), but send TAMPERED hash
        mode_enroll = 0;
        @(posedge clk); start = 1; @(posedge clk); start = 0;
        #30000;

        send_byte(8'h02);
        for (i = 0; i < 32; i = i + 1)
            send_byte(tampered_hash[255 - i*8 -: 8]);

        #5000;
        $display("Final: status_code=%0d esp32_reset_n=%b", status_code, esp32_reset_n);
        if (esp32_reset_n == 1'b0 && status_code == 4'd4)
            $display("PASS: reset correctly held for modified firmware (status=FAIL)");
        else
            $display("FAIL: expected reset held + status=FAIL, got reset_n=%b status=%0d", esp32_reset_n, status_code);

        $display("---- done ----");
        $finish;
    end

endmodule
