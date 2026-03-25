`timescale 1ns / 1ps

module adder_subtractor_3bit #(
    parameter integer N = 3
) (
    input  [N-1:0] a,
    input  [N-1:0] b,
    input          mode,
    output         c_out,
    output [  N:0] sum     // 최종 4비트 결과
);

  wire [N:0] carry;
  assign carry[0] = mode;  // 뺄셈 시 +1 역할(1의 보수 -> 2의 보수)

  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : gen_adder
      wire b_in_wire = b[i] ^ mode;

      full_adder fa (
          .a(a[i]),
          .b(b_in_wire),
          .c_in(carry[i]),
          .c_out(carry[i+1]),
          .sum(sum[i])
      );
    end
  endgenerate

  // LD5는 SUB 결과가 음수일 때만 켜지도록 사용한다.
  // unsigned A-B에서 음수 여부는 borrow 발생 여부와 같다.
  assign c_out  = mode ? ~carry[N] : 1'b0;
  // ADD에서는 확장 캐리 비트, SUB에서는 4비트 2의 보수 결과의 부호 비트가 된다.
  assign sum[N] = mode ? ~carry[N] : carry[N];

endmodule
