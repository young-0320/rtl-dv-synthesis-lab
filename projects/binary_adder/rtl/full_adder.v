module full_adder (
    input  a,
    b,
    c_in,
    output c_out,
    sum
);
  wire w1, w2, w3;
  half_adder M1 (
      .a(a),
      .b(b),
      .c_out(w1),
      .sum(w2)
  );
  half_adder M0 (
      .a(w2),
      .b(c_in),
      .c_out(w3),
      .sum(sum)
  );
  or g1 (c_out, w1, w3);
endmodule



