`timescale 1ns / 1ps

module test_top;

  parameter integer COUNT_MAX = 4;

  reg clk;
  reg [2:0] a;
  reg       b;
  reg [1:0] f;
  reg       go_btn;
  reg       reset;
  wire signed [4:0] r;
  wire              over;

  integer curr_over;
  integer curr_r;
  integer in_a;
  integer sel_b;
  integer func_sel;
  integer operand_b;
  integer full_result;
  integer expected_r;
  integer expected_over;
  integer actual_r;
  integer error_count;
  integer case_count;
  reg [8*28-1:0] note;

  top #(
      .DebounceCountMax(COUNT_MAX)
  ) uut (
      .clk(clk),
      .a(a),
      .b(b),
      .f(f),
      .go_btn(go_btn),
      .reset(reset),
      .r(r),
      .over(over)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;

  task automatic wait_clocks;
    input integer count;
    integer idx;
    begin
      for (idx = 0; idx < count; idx = idx + 1) begin
        @(posedge clk);
        #1;
      end
    end
  endtask

  task automatic seed_state;
    input integer seed_r;
    input integer seed_over;
    begin
      uut.u_acc.r = seed_r;
      uut.u_acc.over = seed_over[0];
      uut.u_go_btn.sync_0 = 1'b0;
      uut.u_go_btn.sync_1 = 1'b0;
      uut.u_go_btn.cnt = 32'd0;
      uut.u_go_btn.btn_stable = 1'b0;
      uut.u_go_btn.btn_stable_d = 1'b0;
      uut.u_go_btn.btn_level = 1'b0;
      uut.u_go_btn.btn_pulse = 1'b0;
      go_btn = 1'b0;
    end
  endtask

  task automatic clean_press;
    begin
      go_btn = 1'b1;
      wait_clocks(COUNT_MAX + 4);
      go_btn = 1'b0;
      wait_clocks(COUNT_MAX + 4);
    end
  endtask

  initial begin
    $dumpfile("sim/output/test_top.vcd");
    $dumpvars(0, test_top);
  end

  initial begin
    error_count = 0;
    case_count = 0;
    a = 3'd0;
    b = 1'b0;
    f = 2'b00;
    go_btn = 1'b0;
    reset = 1'b1;

    wait_clocks(2);
    reset = 1'b0;
    wait_clocks(2);

    $display({"========================================================",
              "======================================================="});
    $display({"Case | R_in | O_in |  A  | Bsel |  F  | R_out | O_out ",
              "| Exp_R | Exp_O | Note"});
    $display({"========================================================",
              "======================================================="});

    for (curr_over = 0; curr_over < 2; curr_over = curr_over + 1) begin
      for (curr_r = -16; curr_r < 16; curr_r = curr_r + 1) begin
        for (sel_b = 0; sel_b < 2; sel_b = sel_b + 1) begin
          for (func_sel = 0; func_sel < 4; func_sel = func_sel + 1) begin
            for (in_a = 0; in_a < 8; in_a = in_a + 1) begin
              @(negedge clk);
              seed_state(curr_r, curr_over);
              a = in_a[2:0];
              b = sel_b[0];
              f = func_sel[1:0];
              clean_press;

              operand_b = (sel_b == 0) ? 0 : curr_r;
              case (func_sel)
                0: begin
                  full_result = in_a + operand_b;
                  expected_r = $signed(full_result[4:0]);
                  expected_over = (full_result > 15) || (full_result < -16);
                end
                1: begin
                  full_result = in_a - operand_b;
                  expected_r = $signed(full_result[4:0]);
                  expected_over = (full_result > 15) || (full_result < -16);
                end
                2: begin
                  full_result = in_a * operand_b;
                  expected_r = $signed(full_result[4:0]);
                  expected_over = (full_result > 15) || (full_result < -16);
                end
                default: begin
                  full_result = curr_r;
                  expected_r = curr_r;
                  expected_over = curr_over;
                end
              endcase

              actual_r = $signed(r);
              note = "";
              if (func_sel == 0 && sel_b == 1 && curr_r == 15 && in_a == 7)
                note = "<< POS ADD OVF";
              else if (func_sel == 2 && sel_b == 1 && curr_r == -16 &&
                       in_a == 7)
                note = "<< NEG MUL OVF";
              else if (func_sel == 3) note = "<< HOLD CASE";

              case_count = case_count + 1;
              $display("%4d | %4d |  %b   | %2d |  %b   | %02b | %5d |   %b   | %5d |   %b   | %s",
                       case_count, curr_r, curr_over[0], in_a, sel_b[0],
                       func_sel[1:0], actual_r, over,
                       expected_r, expected_over[0], note);

              if ((actual_r !== expected_r) || (over !== expected_over[0])) begin
                error_count = error_count + 1;
                $display("ERROR: expected r=%0d over=%0b, got r=%0d over=%0b",
                         expected_r, expected_over[0], actual_r, over);
              end
            end
          end
        end
      end
    end

    @(negedge clk);
    seed_state(5, 0);
    a = 3'd7;
    b = 1'b1;
    f = 2'b00;
    note = "bounce filter";
    go_btn = 1'b1;
    wait_clocks(1);
    go_btn = 1'b0;
    wait_clocks(1);
    go_btn = 1'b1;
    wait_clocks(1);
    go_btn = 1'b0;
    wait_clocks(4);
    actual_r = $signed(r);
    $display("BNC1 | %4d |  %b   | %2d |  %b   | %02b | %5d |   %b   | %5d |   %b   | %s",
             5, 0, 7, 1'b1, 2'b00, actual_r, over, 5, 1'b0, note);
    if ((actual_r !== 5) || (over !== 1'b0)) begin
      error_count = error_count + 1;
      $display("ERROR: bounce should not trigger top-level update");
    end

    $display({"--------------------------------------------------------",
              "------------------------------------------------------"});
    if (error_count == 0) $display("Verification Task Completed Successfully.");
    else $display("Verification failed: %0d mismatches found.", error_count);
    $display("TEST_RESULT: %s", (error_count == 0) ? "PASS" : "FAIL");
    $finish;
  end

endmodule
