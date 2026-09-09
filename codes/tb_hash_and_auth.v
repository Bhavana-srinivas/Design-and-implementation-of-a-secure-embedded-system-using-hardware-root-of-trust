`timescale 1ns/1ps
module tb_hash_and_auth;

    reg clk, rst_n;

    // hash_comparator
    reg hc_en;
    reg [255:0] ref_h, cur_h;
    wire hc_pass, hc_valid;

    hash_comparator #(.HASH_WIDTH(256)) u_hc (
        .clk(clk), .rst_n(rst_n), .compare_en(hc_en),
        .reference_hash(ref_h), .current_hash(cur_h),
        .hash_pass(hc_pass), .decision_valid(hc_valid)
    );

    // authentication_controller
    reg ac_en;
    reg [7:0] ac_ref, ac_cur;
    reg ac_thr_wr_en;
    reg [3:0] ac_thr_wr_data;
    wire [3:0] ac_hd;
    wire ac_pass, ac_valid;

    authentication_controller #(
        .RESP_WIDTH(8), .HD_WIDTH(4), .DEFAULT_THRESHOLD(2)
    ) u_ac (
        .clk(clk), .rst_n(rst_n), .compare_en(ac_en),
        .reference_response(ac_ref), .current_response(ac_cur),
        .threshold_wr_en(ac_thr_wr_en), .threshold_wr_data(ac_thr_wr_data),
        .hamming_dist(ac_hd), .puf_pass(ac_pass), .decision_valid(ac_valid)
    );

    always #5 clk = ~clk;

    initial begin
        $display("---- tb_hash_and_auth ----");
        clk=0; rst_n=0; hc_en=0; ref_h=0; cur_h=0;
        ac_en=0; ac_ref=0; ac_cur=0; ac_thr_wr_en=0; ac_thr_wr_data=0;
        #20 rst_n=1;
        #20;

        // ---- hash_comparator: matching hashes -> PASS ----
        ref_h = 256'hDEADBEEF00112233445566778899AABBCCDDEEFF0123456789ABCDEF001122;
        cur_h = ref_h;
        @(posedge clk); hc_en = 1; @(posedge clk); hc_en = 0;
        wait(hc_valid); #1;
        if (hc_pass) $display("PASS: identical hashes -> hash_pass=1");
        else $display("FAIL: identical hashes -> hash_pass=0");

        // ---- hash_comparator: one bit different -> FAIL ----
        cur_h = ref_h ^ 256'h1;
        @(posedge clk); hc_en = 1; @(posedge clk); hc_en = 0;
        wait(hc_valid); #1;
        if (!hc_pass) $display("PASS: modified hash -> hash_pass=0");
        else $display("FAIL: modified hash -> hash_pass=1 (should reject)");

        // ---- authentication_controller: default threshold=2, HD=1 -> PASS ----
        ac_ref = 8'b10110110;
        ac_cur = 8'b10110010; // HD=1 (spec's own example)
        @(posedge clk); ac_en = 1; @(posedge clk); ac_en = 0;
        wait(ac_valid); #1;
        $display("HD=%0d puf_pass=%b (expect HD=1, pass=1)", ac_hd, ac_pass);
        if (ac_hd == 1 && ac_pass) $display("PASS: within default threshold");
        else $display("FAIL: threshold check wrong");

        // ---- runtime threshold reprogramming: set threshold=0, same vectors -> FAIL ----
        @(posedge clk); ac_thr_wr_en = 1; ac_thr_wr_data = 0; @(posedge clk); ac_thr_wr_en = 0;
        @(posedge clk); ac_en = 1; @(posedge clk); ac_en = 0;
        wait(ac_valid); #1;
        $display("After threshold=0: HD=%0d puf_pass=%b (expect pass=0)", ac_hd, ac_pass);
        if (!ac_pass) $display("PASS: tightened threshold correctly rejects HD=1");
        else $display("FAIL: should have rejected");

        $display("---- done ----");
        $finish;
    end
endmodule
