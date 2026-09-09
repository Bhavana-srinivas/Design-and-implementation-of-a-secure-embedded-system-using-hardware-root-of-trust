`timescale 1ns/1ps
module tb_sha256_interface;

    reg clk, rst_n;
    reg [7:0] rx_byte;
    reg rx_valid;

    wire [255:0] ref_hash, current_hash;
    wire ref_hash_wr_en, current_hash_valid;
    wire [7:0] ref_puf_wr_data;
    wire ref_puf_wr_en;
    wire [3:0] threshold_wr_data;
    wire threshold_wr_en;

    sha256_interface #(
        .HASH_WIDTH (256),
        .RESP_WIDTH (8),
        .HD_WIDTH   (4)
    ) dut (
        .clk                (clk),
        .rst_n              (rst_n),
        .rx_byte            (rx_byte),
        .rx_valid           (rx_valid),
        .ref_hash           (ref_hash),
        .ref_hash_wr_en     (ref_hash_wr_en),
        .current_hash       (current_hash),
        .current_hash_valid (current_hash_valid),
        .ref_puf_wr_data    (ref_puf_wr_data),
        .ref_puf_wr_en      (ref_puf_wr_en),
        .threshold_wr_data  (threshold_wr_data),
        .threshold_wr_en    (threshold_wr_en)
    );

    always #5 clk = ~clk;

    task send_byte(input [7:0] b);
        begin
            @(posedge clk);
            rx_byte = b;
            rx_valid = 1'b1;
            @(posedge clk);
            rx_valid = 1'b0;
            @(posedge clk); // idle gap between bytes
        end
    endtask

    // a recognizable 32-byte test hash: 0x00,0x01,0x02,...,0x1F
    integer i;
    reg [255:0] expected_hash;

    initial begin
        $display("---- tb_sha256_interface ----");
        clk = 0; rst_n = 0; rx_byte = 0; rx_valid = 0;
        #20 rst_n = 1;
        #20;

        // build expected hash value MSB-first as the DUT assembles it
        expected_hash = 256'd0;
        for (i = 0; i < 32; i = i + 1)
            expected_hash = {expected_hash[247:0], i[7:0]};

        // ---- CMD_REF_HASH (0x01) + 32 bytes ----
        send_byte(8'h01);
        for (i = 0; i < 32; i = i + 1)
            send_byte(i[7:0]);
        #20;
        if (ref_hash === expected_hash)
            $display("PASS: reference hash loaded correctly");
        else
            $display("FAIL: ref_hash=%h expected=%h", ref_hash, expected_hash);

        // ---- CMD_CUR_HASH (0x02) + same 32 bytes (simulate matching firmware) ----
        send_byte(8'h02);
        for (i = 0; i < 32; i = i + 1)
            send_byte(i[7:0]);
        #20;
        if (current_hash === expected_hash)
            $display("PASS: current hash loaded correctly");
        else
            $display("FAIL: current_hash=%h expected=%h", current_hash, expected_hash);

        // ---- CMD_REF_PUF (0x03) + 1 byte ----
        send_byte(8'h03);
        send_byte(8'b10110110);
        #20;
        if (ref_puf_wr_data === 8'b10110110)
            $display("PASS: reference PUF response loaded correctly");
        else
            $display("FAIL: ref_puf_wr_data=%b", ref_puf_wr_data);

        // ---- CMD_THRESHOLD (0x04) + 1 byte ----
        send_byte(8'h04);
        send_byte(8'd3);
        #20;
        if (threshold_wr_data === 4'd3)
            $display("PASS: threshold loaded correctly");
        else
            $display("FAIL: threshold_wr_data=%0d", threshold_wr_data);

        $display("---- done ----");
        $finish;
    end

    always @(posedge ref_hash_wr_en)     $display("  ref_hash_wr_en pulsed at t=%0t", $time);
    always @(posedge current_hash_valid) $display("  current_hash_valid pulsed at t=%0t", $time);
    always @(posedge ref_puf_wr_en)      $display("  ref_puf_wr_en pulsed at t=%0t", $time);
    always @(posedge threshold_wr_en)    $display("  threshold_wr_en pulsed at t=%0t", $time);

endmodule
