`timescale 1ns / 1ps

module test_rca_4bit ();
  reg [3:0] t_a, t_b;
  reg t_c_in;
  wire t_c_out;
  wire [3:0] t_sum;

  integer ai;
  integer bi;
  integer ci;
  reg [4:0] exp;
  integer err_cnt;

  rca_4bit uut (
      .a(t_a),
      .b(t_b),
      .c_in(t_c_in),
      .c_out(t_c_out),
      .sum(t_sum)
  );

  initial begin
    err_cnt = 0;
    for (ai = 0; ai < 16; ai++) begin
      for (bi = 0; bi < 16; bi++) begin
        for (ci = 0; ci < 2; ci++) begin
          t_a = ai;
          t_b = bi;
          t_c_in = ci;
          #1;
          exp = ai + bi + ci;
          if ({t_c_out, t_sum} !== exp) begin
            $display("Error: a=%b b=%b c_in=%b | Expected c_out=%b sum=%b, got c_out=%b sum=%b",
                     t_a, t_b, t_c_in, exp[4], exp[3:0], t_c_out, t_sum);
            err_cnt++;
          end
        end
      end
    end

    if (err_cnt == 0) $display("PASS");
    else $fatal(1, "FAIL: err_cnt=%0d", err_cnt);
  end
  initial #1000 $finish;
endmodule
