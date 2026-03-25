`timescale 1ns / 1ps
module full_adder (
    input  a,
    b,
    c_in,
    output c_out,
    sum
);
  assign sum   = a ^ b ^ c_in;
  assign c_out = (a & b) | (b & c_in) | (a & c_in);
endmodule
