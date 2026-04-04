module ParToSer_ctrl (
    input  [7:0] X,
    input        clk,    // 메인 클럭 (125MHz)
    input        reset,
    input        save,
    input        start,
    output       serial_out,
    output [2:0] stored_cnt_led,
    output       ready_led,
    output       error_led
);

  localparam integer DEBOUNCE_COUNT_MAX = 70_000;

  wire [7:0] Q;
  wire clk_7M;
  wire pll_locked;
  wire safe_reset;
  wire save_level;
  wire save_pulse;
  wire start_level;
  wire start_pulse;

  // PLL이 안정화되지 않았거나(~pll_locked), 외부 리셋이 들어왔을 때 리셋 인가
  assign safe_reset = reset | ~pll_locked;

  // TODO: BRAM/FSM 통합 전까지는 문서 기준 외부 포트만 정렬해 둔다.
  // save는 디바운싱 후 serializer load에 연결하고,
  // start와 상태 LED는 추후 BRAM/FSM 제어부 구현 시 사용한다.
  assign stored_cnt_led = 3'b000;
  assign ready_led      = 1'b0;
  assign error_led      = 1'b0;

  debouncer #(
      .COUNT_MAX(DEBOUNCE_COUNT_MAX)
  ) i_save_debouncer (
      .clk      (clk_7M),
      .reset    (safe_reset),
      .btn_in   (save),
      .btn_level(save_level),
      .btn_pulse(save_pulse)
  );

  debouncer #(
      .COUNT_MAX(DEBOUNCE_COUNT_MAX)
  ) i_start_debouncer (
      .clk      (clk_7M),
      .reset    (safe_reset),
      .btn_in   (start),
      .btn_level(start_level),
      .btn_pulse(start_pulse)
  );

  ParToSer i0 (
      .X(X),
      .clk(clk_7M),
      .reset(safe_reset),
      .ld(save_pulse),
      .serial_out(serial_out),
      .Q(Q)
  );

  clk_wiz_0 i1 (
      .clk_in1 (clk),
      .clk_out1(clk_7M),
      .locked  (pll_locked)  // IP에서 locked 신호 포트를 빼와야 함
  );
endmodule
