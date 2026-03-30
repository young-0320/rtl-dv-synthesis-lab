
module top #(
    parameter integer DebounceCountMax = 1000000
) (
    input clk,
    input [2:0] a,
    input b,
    input [1:0] f,
    input go_btn,
    input reset,
    output signed [4:0] r,
    output over
);

wire go_level;
wire go_pulse;

debouncer #(
    .COUNT_MAX(DebounceCountMax)
) u_go_btn (
    .clk(clk),
    .reset(reset),
    .btn_in(go_btn),
    .btn_level(go_level),
    .btn_pulse(go_pulse)
);

alu_based_accumulator u_acc (
    .clk(clk),
    .a(a),
    .b(b),
    .f(f),
    .go_pulse(go_pulse),
    .reset(reset),
    .r(r),
    .over(over)
);

endmodule
