
module alu_based_accumulator (
    input clk,
    input [2:0] a,
    input b,
    input [1:0] f,
    input go_pulse,
    input reset,
    output reg signed [4:0] r,
    output reg over
);
  wire signed [4:0] a_ext;
  wire signed [4:0] op_b;
  wire signed [5:0] add_full, sub_full;
  wire signed [9:0] mul_full;

  assign a_ext = {2'b00, a};  //양수 확장
  assign op_b = b ? r : 5'sb0;
  // 오버플로 감지
  assign add_full = a_ext + op_b;
  assign sub_full = a_ext - op_b;
  assign mul_full = a_ext * op_b;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      r <= 5'sb00000;
      over <= 1'b0;
    end else if (go_pulse) begin
      case (f)
        2'b00: begin
          r <= add_full[4:0];
          over <= (add_full > 6'sd15) || (add_full < -6'sd16);
        end
        2'b01: begin
          r <= sub_full[4:0];
          over <= (sub_full > 6'sd15) || (sub_full < -6'sd16);
        end
        2'b10: begin
          r <= mul_full[4:0];
          // r이 5비트이므로 5비트 범위를 벗어나면 오버플로
          over <= (mul_full > 10'sd15) || (mul_full < -10'sd16);
        end
        default: begin
          r <= r;
          over <= over;
        end
      endcase
    end
  end
endmodule
