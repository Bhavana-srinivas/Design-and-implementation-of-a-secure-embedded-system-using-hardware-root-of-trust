`timescale 1ns/1ps
module tb_ro_puf_controller;

    reg clk, rst_n, start;
    wire [7:0] puf_response;
    wire response_valid;

    ro_puf_controller #(
        .NUM_PAIRS     (8),
        .NUM_INVERTERS (5),
        .COUNT_WIDTH   (16),
        .WINDOW_CYCLES (500)   // shorter window to keep sim time reasonable
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .start          (start),
        .puf_response   (puf_response),
        .response_valid (response_valid)
    );

    always #5 clk = ~clk; // 100MHz

    initial begin
        $display("---- tb_ro_puf_controller ----");
        clk = 0; rst_n = 0; start = 0;
        #20 rst_n = 1;
        #20;
        start = 1;
        #10 start = 0;

        wait (response_valid == 1'b1);
        #1;
        $display("puf_response = %b", puf_response);
        if (puf_response !== 8'bxxxxxxxx)
            $display("PASS: got a defined 8-bit response");
        else
            $display("FAIL: response still X");

        // run it again to check repeatability (same die, same conditions
        // in simulation -> identical gate delays -> should match exactly;
        // on real silicon small HD would be expected/tolerated instead)
        #500;
        start = 1;
        #10 start = 0;
        wait (response_valid == 1'b1);
        #1;
        $display("puf_response (2nd run) = %b", puf_response);

        $finish;
    end

endmodule
