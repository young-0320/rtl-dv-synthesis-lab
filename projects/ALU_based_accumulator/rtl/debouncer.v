module debouncer #(
    parameter integer COUNT_MAX = 1000_000  // 시스템 클록 기준 디바운스 시간
) (
    input clk,
    input reset,
    input btn_in,
    output reg btn_level,
    output reg btn_pulse
);

  reg sync_0, sync_1;
  reg [31:0] cnt;
  reg btn_stable;
  reg btn_stable_d;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      sync_0       <= 1'b0;
      sync_1       <= 1'b0;
      cnt          <= 32'd0;
      btn_stable   <= 1'b0;
      btn_stable_d <= 1'b0;
      btn_level    <= 1'b0;
      btn_pulse    <= 1'b0;
    end else begin
      // 1) 2-FF synchronizer 
      sync_0 <= btn_in;
      sync_1 <= sync_0;

      // 2) 디바운싱
      if (sync_1 == btn_stable) begin
        cnt <= 32'd0;  // 현재 상태와 버튼 입력이 같으면 카운터 리셋
      end else begin
        if (cnt == COUNT_MAX - 1) begin
          // 일정 시간(COUNT_MAX) 동안 변한 상태가 유지되면 인정
          btn_stable <= sync_1;
          cnt <= 32'd0;
        end else begin
          // 상태가 다르면(변했으면) 카운트 시작
          cnt <= cnt + 1'b1;
        end
      end

      // 3) 깨끗한 one-pulse 생성
      btn_stable_d <= btn_stable;
      btn_level    <= btn_stable;
      btn_pulse    <= btn_stable & ~btn_stable_d;
    end
  end

endmodule
