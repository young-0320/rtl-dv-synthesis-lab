// Parallel-to-Serial(8비트 병렬 입력을 직렬 입력으로 전환하는 모듈)
// PMOD와 PLL, ILA 사용법 숙지

// ip를 사용해서  BRAM을 생성한 후, ParToSer_ctrl 모듈에서 instantiation하여 사용
module ParToSer (
    input [7:0] X,
    input clk,
    input reset,
    input ld,
    output out,
    output reg [7:0] Q
);

  assign out = Q[0];
  always @(posedge clk) begin
    if (reset) begin
      Q <= 8'b00000000;
    end else if (ld) begin
      Q <= X;
    end else begin
      Q <= {Q[0], Q[7:1]};
    end
  end
endmodule
