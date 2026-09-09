`timescale 1ns/1ps
// -----------------------------------------------------------------------
// Drives secure_boot_fsm's interface directly (bypassing the analog RO
// timing and UART bit-timing, which are covered in tb_ro_pair.v and
// would need real-time baud simulation respectively) to verify the
// control-flow logic itself against the four required scenarios:
//   1. correct PUF + correct firmware  -> PASS, reset released
//   2. correct PUF + modified firmware -> FAIL, reset held
//   3. incorrect PUF + correct firmware -> FAIL, reset held
//   4. incorrect PUF + modified firmware -> FAIL, reset held
// -----------------------------------------------------------------------
module tb_secure_boot_fsm;

    reg clk, rst_n;
    reg mode_enroll, start;
    reg puf_response_valid;
    reg [7:0] puf_response;
    reg [7:0] reference_response;
    reg reference_valid;
    reg puf_decision_valid, puf_pass;
    reg current_hash_valid, ref_hash_valid;
    reg hash_decision_valid, hash_pass;

    wire puf_start, enroll_capture_en, puf_compare_en, hash_compare_en;
    wire release_reset;
    wire [3:0] status_code;

    secure_boot_fsm dut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .mode_enroll         (mode_enroll),
        .start               (start),
        .puf_start           (puf_start),
        .puf_response_valid  (puf_response_valid),
        .puf_response        (puf_response),
        .enroll_capture_en   (enroll_capture_en),
        .reference_response  (reference_response),
        .reference_valid     (reference_valid),
        .puf_compare_en      (puf_compare_en),
        .puf_decision_valid  (puf_decision_valid),
        .puf_pass            (puf_pass),
        .current_hash_valid  (current_hash_valid),
        .ref_hash_valid      (ref_hash_valid),
        .hash_compare_en     (hash_compare_en),
        .hash_decision_valid (hash_decision_valid),
        .hash_pass           (hash_pass),
        .release_reset       (release_reset),
        .status_code         (status_code)
    );

    always #5 clk = ~clk;

    // Runs one full AUTHENTICATE-mode boot attempt and reports PASS/FAIL
    task run_boot(input puf_ok, input hash_ok, input [127:0] label);
        begin
            // power-on reset
            rst_n = 0; mode_enroll = 0; start = 0;
            puf_response_valid = 0; reference_valid = 1;
            puf_decision_valid = 0; current_hash_valid = 0;
            ref_hash_valid = 1; hash_decision_valid = 0;
            @(posedge clk); @(posedge clk);
            rst_n = 1;
            @(posedge clk);

            start = 1;
            @(posedge clk);
            start = 0;

            // wait for FSM to request PUF measurement
            @(posedge clk); // S_PUF_START -> S_PUF_MEASURE

            // simulate PUF controller returning a response
            @(posedge clk);
            puf_response_valid = 1;
            @(posedge clk);
            puf_response_valid = 0;

            // FSM now in S_PUF_COMPARE, asserts puf_compare_en
            @(posedge clk);
            if (puf_compare_en) begin
                puf_pass = puf_ok;
                puf_decision_valid = 1;
                @(posedge clk);
                puf_decision_valid = 0;
            end

            if (puf_ok) begin
                // FSM now in S_WAIT_HASH
                @(posedge clk);
                current_hash_valid = 1;
                @(posedge clk);
                if (hash_compare_en) begin
                    hash_pass = hash_ok;
                    hash_decision_valid = 1;
                    @(posedge clk);
                    hash_decision_valid = 0;
                end
                current_hash_valid = 0;
            end

            // let FSM settle into its final state
            repeat (3) @(posedge clk);

            $display("[%0s] status_code=%0d release_reset=%b (puf_ok=%b hash_ok=%b)",
                       label, status_code, release_reset, puf_ok, hash_ok);
            if (puf_ok && hash_ok) begin
                if (release_reset && status_code == 4'd3)
                    $display("  PASS (reset released as expected)");
                else
                    $display("  FAIL (expected reset release, got status=%0d release=%b)", status_code, release_reset);
            end else begin
                if (!release_reset && status_code == 4'd4)
                    $display("  PASS (reset held as expected)");
                else
                    $display("  FAIL (expected reset held, got status=%0d release=%b)", status_code, release_reset);
            end
        end
    endtask

    initial begin
        clk = 0;
        $display("---- tb_secure_boot_fsm ----");
        run_boot(1'b1, 1'b1, "TC1 correct PUF + correct FW  ");
        run_boot(1'b1, 1'b0, "TC2 correct PUF + modified FW ");
        run_boot(1'b0, 1'b1, "TC3 incorrect PUF + correct FW");
        run_boot(1'b0, 1'b0, "TC4 incorrect PUF + modified FW");
        $display("---- done ----");
        $finish;
    end

endmodule
