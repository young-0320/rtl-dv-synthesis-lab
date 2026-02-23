`timescale 1ns / 1ps

module half_adder (
    input  a,
    b,
    output c_out,
    sum
);
  xor g1 (sum, a, b);
  and g2 (c_out, a, b);
endmodule
