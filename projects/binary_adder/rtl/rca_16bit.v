module rca_16bit (
    input [15:0] a,
    b,
    input c_in,
    output c_out,
    output [15:0] sum

);
    wire c8;
    rca_8bit M0 (
        .a(a[7:0]),
        .b(b[7:0]),
        .c_in(c_in),
        .c_out(c8),
        .sum(sum[7:0])
    );
    rca_8bit M1 (
        .a(a[15:8]),
        .b(b[15:8]),
        .c_in(c8),
        .c_out(c_out),
        .sum(sum[15:8])
    );
endmodule
