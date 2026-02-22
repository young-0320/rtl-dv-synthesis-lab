module rca_8bit (
    input [7:0] a,
    b,
    input c_in,
    output c_out,
    output [7:0] sum
);
  wire c4;
  rca_4bit M0 (
      .a(a[3:0]),
      .b(b[3:0]),
      .c_in(c_in),
      .c_out(c4),
      .sum(sum[3:0])
  );
  rca_4bit M1 (
      .a(a[7:4]),
      .b(b[7:4]),
      .c_in(c4),
      .c_out(c_out),
      .sum(sum[7:4])
  );
endmodule
