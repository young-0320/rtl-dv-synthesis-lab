module ParToSer_ctrl (
    input  [7:0] X,
    input        clk,    // 메인 클럭 (125MHz)
    input        reset,
    input        ld,
    output       out
);

  wire [7:0] Q;
  wire clk_7M;
  wire pll_locked;
  wire safe_reset;

  // PLL이 안정화되지 않았거나(~pll_locked), 외부 리셋이 들어왔을 때 리셋 인가
  assign safe_reset = reset | ~pll_locked;

  ParToSer i0 (
      .X(X),
      .clk(clk_7M),
      .reset(safe_reset),
      .ld(ld),
      .out(out)
  );

  clk_wiz_0 i1 (
      .clk_in1 (clk),
      .clk_out1(clk_7M),
      .locked  (pll_locked)  // IP에서 locked 신호 포트를 빼와야 함
  );
endmodule
