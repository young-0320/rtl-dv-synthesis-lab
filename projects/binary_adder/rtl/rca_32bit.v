`timescale 1ns / 1ps


module rca_32bit (
    input [31:0] a,
    b,
    input c_in,
    output c_out,
    output [31:0] sum
);
  wire c16;
  rca_16bit M0 (
      .a(a[15:0]),
      .b(b[15:0]),
      .c_in(c_in),
      .c_out(c16),
      .sum(sum[15:0])
  );
  rca_16bit M1 (
      .a(a[31:16]),
      .b(b[31:16]),
      .c_in(c16),
      .c_out(c_out),
      .sum(sum[31:16])
  );
endmodule
