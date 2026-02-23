// directed testbench for half adder
`timescale 1ns / 1ps

module test_half_adder ();
  reg t_a, t_b;
  wire t_c_out, t_sum;
  half_adder uut (
      .a(t_a),
      .b(t_b),
      .c_out(t_c_out),
      .sum(t_sum)
  );

  initial #100 $finish;
  initial begin
    $dumpfile("sim/build/output/iverilog/test_half_adder.vcd");
    $dumpvars(0, test_half_adder);
    $display("a b | c_out sum");
    $display("-------------");
    t_a = 0;
    t_b = 0;
    #10;
    $display("%b %b | %b     %b", t_a, t_b, t_c_out, t_sum);
    t_a = 0;
    t_b = 1;
    #10;
    $display("%b %b | %b     %b", t_a, t_b, t_c_out, t_sum);
    t_a = 1;
    t_b = 0;
    #10;
    $display("%b %b | %b     %b", t_a, t_b, t_c_out, t_sum);
    t_a = 1;
    t_b = 1;
    #10;
    $display("%b %b | %b     %b", t_a, t_b, t_c_out, t_sum);

  end
endmodule
