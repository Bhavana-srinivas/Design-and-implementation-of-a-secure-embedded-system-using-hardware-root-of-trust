`timescale 1ns/1ps
module tb_ro_pair;

    reg clk, rst_n, enable, window_en;
    wire bit_valid, response_bit;

    // RO_B given a larger simulated gate delay -> RO_B oscillates SLOWER
    // -> fewer edges counted -> RO_A > RO_B -> expect response_bit = 1
    ro_pair #(
        .NUM_INVERTERS   (5),
        .COUNT_WIDTH     (16),
        .GATE_DELAY_A_NS (1),
        .GATE_DELAY_B_NS (2)
    ) dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .enable       (enable),
        .window_en    (window_en),
        .bit_valid    (bit_valid),
        .response_bit (response_bit)
    );

    always #5 clk = ~clk; // 100MHz system clock

    initial begin
        $display("---- tb_ro_pair (RO_A faster than RO_B) ----");
        clk = 0; rst_n = 0; enable = 0; window_en = 0;
        #20 rst_n = 1;

        enable = 1;
        #100;              // let ROs settle
        window_en = 1;
        #2000;              // measurement window
        window_en = 0;

        wait (bit_valid == 1'b1);
        #1;
        $display("count_a_reg=%0d count_b_reg=%0d", dut.count_a_reg, dut.count_b_reg);
        if (response_bit == 1'b1)
            $display("PASS: response_bit=1 as expected (faster RO_A)");
        else
            $display("FAIL: response_bit=%b, expected 1", response_bit);

        $finish;
    end

endmodule
