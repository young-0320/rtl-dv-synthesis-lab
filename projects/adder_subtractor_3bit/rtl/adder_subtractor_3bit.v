`timescale 1ns / 1ps

module adder_subtractor_3bit #(
    parameter N = 3
)(
    input  [N-1:0] a,
    input  [N-1:0] b,
    input          mode,
    output         c_out,
    output [N:0]   sum    // 최종 4비트 결과
);

    wire [N:0] carry;
    assign carry[0] = mode; // 뺄셈 시 +1 역할(1의 보수 -> 2의 보수)

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

    assign c_out = carry[N];
    assign sum[N] = carry[N]; // 4번째 LED를 위한 캐리 연결

endmodule