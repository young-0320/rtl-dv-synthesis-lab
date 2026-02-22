module rca_64bit (
    input [63:0] a,
    b,
    output c_out,
    output [63:0] sum
);
  wire c32;
  rca_32bit M0 (
      .a(a[31:0]),
      .b(b[31:0]),
      .c_in(1'b0),  // 스펙: a+b 이므로 초기 carry는 0
      .c_out(c32),
      .sum(sum[31:0])
  );
  rca_32bit M1 (
      .a(a[63:32]),
      .b(b[63:32]),
      .c_in(c32),
      .c_out(c_out),
      .sum(sum[63:32])
  );
endmodule
