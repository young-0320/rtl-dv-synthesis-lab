// self-checking testbench for full_adder

`timescale 1ns / 1ps


module test_full_adder;
  reg t_a, t_b;
  wire t_c_out, t_sum;

  integer i;
  integer err_cnt;
  // DUT 인스턴스화
  half_adder u_dut (
      .a(t_a),
      .b(t_b),
      .c_out(t_c_out),
      .sum(t_sum)
  );

  // reference 모델
  function automatic logic [1:0] ref_full_adder(input logic a_i, input logic b_i);
    ref_full_adder = {(a_i & b_i), (a_i ^ b_i)};  // {c_out, sum}
  endfunction

  task automatic apply_and_check(input logic a_i, input logic b_i);
    logic [1:0] exp;
    begin
      t_a = a_i;
      t_b = b_i;
      #1;
      exp = ref_full_adder(a_i, b_i);

      if (t_sum !== exp[0]) begin
        $display("Error: sum mismatch. Expected %b, got %b", exp[0], t_sum);
        err_cnt++;
      end
      if (t_c_out !== exp[1]) begin
        $display("Error: carry mismatch. Expected %b, got %b", exp[1], t_c_out);
        err_cnt++;
      end
    end
  endtask

  initial begin
    err_cnt = 0;

    // directed or random stimulus
    apply_and_check(0, 0);
    apply_and_check(0, 1);
    apply_and_check(1, 0);
    apply_and_check(1, 1);

    if (err_cnt == 0) $display("PASS");
    else $fatal(1, "FAIL: err_cnt=%0d", err_cnt);

    $finish;
  end

  // 6) 타임아웃 가드
  initial begin
    #1000;
    $fatal(1, "TIMEOUT");
  end
endmodule
