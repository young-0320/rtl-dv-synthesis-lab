# 과제 2: ALU 기반 누산기

시연 영상 링크: https://youtu.be/4IZhxGSASdg

## 1. 입력

* `a[2:0]`: 외부 스위치 값
* `b`: 0 -> 0, 1 ->현재 `r`
* `f`: ALU 기능 선택(+, -, *)
* `go`: 진행 버튼
* `reset`: 초기화 버튼

출력

`r`: signed int 5bit	

## 내부 상태

* `r`: 현재까지 저장된 결과

## 동작

버튼 `go`를 한 번 누를 때마다:

1. `a`를 읽음
2. `b`에 따라 두 번째 입력을 결정(두 번째 입력을 R이라고 설정)

* `0`
* 또는 `r`

1. `f`에 따라 연산 수행
   1. `f` : 00 -> a + R
   2. `f` : 01 -> a - R
   3. `f` : 10 -> a * R
   4. `f`: 이외의 입력(default) ->don't care 출력(해당 설계에선 안전하게 연산을 하지 않는 것으로 구현)
2. 연산 결과를 `r`에 저장
3. 5개의 LED에 `r` 표시
   1. 만약 오버플로가 발생할 시 LD5에 빨란불 들어옴
   2. overflow 발생 시 아래의 정책에 따라 행동

## 2 . overflow 정책

Wrap-around: 하위 5비트만 출력됨

`over`는 가장 최근의 유효한 `go` 연산의 결과가 signed 5-bit 표현 범위를 벗어났을 때 1로 저장되며, 새 연산 결과로 덮어쓴다.

reset 입력 인가 시 0으로 초기화

---

## 3. 하드웨어 매핑

Zybo Z7-20 보드 사용

| **분류** | **신호명** | **하드웨어 핀 (Zybo)**          | **비고**                  |
| -------------- | ---------------- | ------------------------------------- | ------------------------------- |
| **입력** | `a[2:0]`       | **SW3, SW2, SW1**               | unsigned                        |
| **입력** | `b`            | **SW0**                         | 0또는 1, mux 제어신호           |
| **입력** | `f[1:0]`       | **BTN1, BTN0**                  | 덧셈/뺄셈/곱셈                  |
| **입력** | `reset`        | **BTN2**                        | `r`과 `over`을 0으로 초기화 |
| **입력** | `go`           | **BTN3**                        | 클럭/진행 버튼                  |
| **출력** | `r[4:0]`       | **LD3, LD2, LD1, LD0, LD6(G))** | 연산 결과 (5비트 표시)          |
| **출력** | `over`         | **RGB LD5 (R)**                 | 오버플로 발생시  점등           |

---

## RTL Source Code

### `rtl/top.v`

```verilog
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
```

### `rtl/alu_based_accumulator.v`

```verilog
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
```

### `rtl/debouncer.v`

```verilog
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
      // 1) 동기화
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
```

### `rtl/constrs/ALU_based_accumulator.xdc`

```xdc
# ALU_based_accumulator.xdc

##Clock signal
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sysclk }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
#create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { sysclk }];

## 1. 클록 입력 (sysclk)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## 2. 입력 a 스위치 (SW1, SW2, SW3)
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { a[0] }];
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { a[1] }];
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { a[2] }];

## 3. 입력 b 스위치 (SW0)
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { b }];

## 4. 연산 선택 버튼 f (BTN0, BTN1)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { f[0] }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { f[1] }];

## 5. 제어 버튼 (BTN2, BTN3)
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { reset }];
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { go_btn }];

## 6. 결과 출력 r (LD6(G), LD0, LD1, LD2, LD3)
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { r[0] }];
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { r[1] }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { r[2] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { r[3] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { r[4] }];

## 7. overflow 표시 (RGB LED 5 - Red)
set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { over }];
```
