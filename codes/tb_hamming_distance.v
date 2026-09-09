`timescale 1ns/1ps
module tb_hamming_distance;

    reg  [7:0] ref_resp, cur_resp;
    wire [3:0] hd;

    hamming_distance #(.RESP_WIDTH(8), .HD_WIDTH(4)) dut (
        .reference_response (ref_resp),
        .current_response   (cur_resp),
        .hamming_dist        (hd)
    );

    task check(input [7:0] r, input [7:0] c, input [3:0] expected);
        begin
            ref_resp = r;
            cur_resp = c;
            #1;
            if (hd !== expected)
                $display("FAIL: ref=%b cur=%b expected HD=%0d got HD=%0d", r, c, expected, hd);
            else
                $display("PASS: ref=%b cur=%b HD=%0d", r, c, hd);
        end
    endtask

    initial begin
        $display("---- tb_hamming_distance ----");
        check(8'b10110110, 8'b10110110, 0); // identical
        check(8'b10110110, 8'b10110010, 1); // 1 bit differs (per spec example)
        check(8'b10110110, 8'b01001001, 8); // fully inverted
        check(8'b00000000, 8'b00000011, 2); // 2 bits differ
        $display("---- done ----");
        $finish;
    end

endmodule
