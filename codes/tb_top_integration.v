`timescale 1ns/1ps
// -----------------------------------------------------------------------
// End-to-end test of top_module: real (behaviorally-delayed) RO-PUF,
// real UART bit timing, real FSM sequencing. Runs:
//   1. ENROLL mode -> capture reference PUF response
//   2. AUTHENTICATE: provision reference hash + matching current hash
//      -> expect esp32_reset_n to go HIGH (released)
// -----------------------------------------------------------------------
module tb_top_integration;

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
        .WINDOW_CYCLES (500),     // shortened for sim time
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

    always #10 clk = ~clk; // 50MHz

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

    reg [255:0] test_hash;
    integer i;

    initial begin
        $display("---- tb_top_integration ----");
        clk = 0; rst_n = 0; mode_enroll = 0; start = 0; uart_rx = 1'b1;
        #100 rst_n = 1;
        #100;

        // ---- Step 1: ENROLL mode -- capture the device's PUF response ----
        mode_enroll = 1;
        @(posedge clk); start = 1; @(posedge clk); start = 0;
        // wait long enough for PUF measurement + settle
        #30000;
        $display("After enroll: status_code=%0d reference_response=%b reference_valid=%b",
                  status_code, dut.u_enroll_store.reference_response, dut.u_enroll_store.reference_valid);

        // ---- Step 2: provision reference hash over UART (CMD 0x01 + 32 bytes) ----
        test_hash = 256'h00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEE;
        send_byte(8'h01);
        for (i = 0; i < 32; i = i + 1)
            send_byte(test_hash[255 - i*8 -: 8]);
        #200;
        $display("ref_hash_valid=%b", dut.ref_hash_valid);

        // ---- Step 3: switch to AUTHENTICATE mode, start boot sequence ----
        mode_enroll = 0;
        @(posedge clk); start = 1; @(posedge clk); start = 0;
        #30000; // let PUF re-measure and compare against reference

        // ---- Step 4: send the CURRENT firmware hash (matches reference) ----
        send_byte(8'h02);
        for (i = 0; i < 32; i = i + 1)
            send_byte(test_hash[255 - i*8 -: 8]);

        #5000;
        $display("Final: status_code=%0d esp32_reset_n=%b", status_code, esp32_reset_n);
        if (esp32_reset_n == 1'b1)
            $display("PASS: ESP32 reset released after matching PUF + matching hash");
        else
            $display("FAIL: ESP32 reset still asserted, status_code=%0d", status_code);

        $display("---- done ----");
        $finish;
    end

endmodule
