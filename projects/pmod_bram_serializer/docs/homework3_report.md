# BRAM 기반 Serializer 하드웨어 보고서

## 1. 개요

본 설계는 Zybo Z7-20 보드에서 동작하는 BRAM 기반 Serializer 시스템으로, PMOD JE 포트를 통해 입력되는 `8비트` 병렬 데이터 `X[7:0]`를 한 번에 하나씩 받아 총 `5개`를 BRAM에 저장한 뒤, 저장된 데이터를 순차적으로 읽어 `1비트` 직렬 신호로 출력한다. 저장된 5개의 값은 ILA에서 `40비트` 버스 `ila_data[39:0] = {x4, x3, x2, x1, x0}` 형태로 관측한다.

시연 영상 링크: https://youtu.be/vsxncSsmpLg

## 2. 설계 사양

과제의 핵심 요구사항은 다음과 같다.

1. PMOD를 사용하여 `8비트` 병렬 입력 `X[7:0]`를 받는다.
2. 입력되는 `X` 값을 총 `5개` BRAM에 저장한다.
3. 저장된 5개의 `8비트` 값을 순차적으로 ParToSer에 공급하여 직렬 출력한다.
4. 저장된 5개 값은 ILA에서 `40비트` 버스로 검증할 수 있어야 한다.
5. 버튼 및 스위치 구성은 자유롭게 설계하되, 입력 `X`는 반드시 PMOD를 통해 받아야 한다.

## 3. 시스템 동작 요약

시스템은 입력 저장 단계와 직렬 출력 단계로 나뉜다.

1. 브레드보드와 PMOD의 동일한 8개 입력선을 이용해 한 번에 1개의 `8비트` 병렬 입력 `X[7:0]`를 구성한다.
2. 디바운싱된 `save` 버튼의 상승 에지가 감지되면 해당 시점의 `X[7:0]` 값을 BRAM의 현재 주소에 저장한다.
3. 사용자는 배선을 다시 바꿔 다음 `8비트` 값을 만들고, 다시 `save`를 눌러 다음 주소에 저장한다.
4. 이 과정을 `5회` 반복하여 BRAM 주소 `0, 1, 2, 3, 4`에 총 `5개`의 `8비트` 데이터를 저장한다.
5. 저장이 완료되면 시스템은 전송 대기 상태로 진입하고 `ready_led`를 통해 준비 상태를 표시한다.
6. 디바운싱된 `start` 버튼의 상승 에지가 감지되면 BRAM 주소 `0~4`를 순차적으로 읽는다.
7. BRAM read data는 주소 인가 후 `1클럭` 뒤 유효하므로, FSM에 `read wait` 상태를 포함한다.
8. 유효해진 `bram_dout[7:0]`를 `serializer_ld` 펄스로 ParToSer에 적재한다.
9. ParToSer는 각 바이트를 `8클럭` 동안 `LSB-first` 방식으로 직렬 출력한다.
10. 5개 바이트 전송이 끝나면 주소와 카운터를 초기화하고 초기 상태로 복귀한다.

## 4. 주요 입출력 및 내부 신호

### 외부 입력

- `clk`: 시스템 클럭 `125 MHz`
- `reset`: 시스템 초기화 버튼
- `save`: 현재 `X[7:0]` 값을 BRAM에 저장하는 버튼
- `start`: 저장된 5개 데이터를 직렬 출력 시작하는 버튼
- `X[7:0]`: PMOD를 통한 `8비트` 병렬 입력

### 외부 출력

- `serial_out`: 1비트 직렬 출력
- `stored_cnt_led[2:0]`: 저장된 데이터 개수 표시
- `ready_led`: 5개 저장 완료 후 전송 대기 상태 표시
- `error_led`: 잘못된 입력 또는 예외 상황 표시

### 내부 신호

- `clk_7M`: `clk_wiz_0`가 `clk(125MHz)`에서 생성한 내부 동작 클럭
- `safe_reset`: 외부 `reset` 또는 `pll_locked` 미완료 시 활성화되는 내부 reset
- `serializer_ld`: `bram_dout[7:0]`을 ParToSer에 적재하는 1클럭 펄스
- `serializer_shift_en`: ParToSer 시프트 허가 신호
- `Q[7:0]`: ParToSer 내부 시프트 레지스터
- `ila_data[39:0]`: 저장된 5개 값을 묶은 ILA 관측용 40비트 데이터
- `bram_addr[2:0]`: BRAM 주소
- `bram_din[7:0]`: BRAM 입력 데이터
- `bram_dout[7:0]`: BRAM 출력 데이터
- `bram_wea[0:0]`: BRAM write enable

## 5. FSM 기반 제어 구조

상위 모듈 `ParToSer_ctrl`는 다음 상태를 이용해 전체 제어를 수행한다.

- `S_STORE`: 입력 저장 대기 상태
- `S_WRITE`: BRAM 쓰기 및 shadow register(`x0~x4`) 갱신 상태
- `S_WAIT_START`: 5개 저장 완료 후 전송 시작 대기 상태
- `S_READ_ADDR`: BRAM 읽기 주소 인가 상태
- `S_READ_WAIT`: BRAM read latency 대기 상태
- `S_LOAD`: `bram_dout`을 ParToSer에 로드하는 상태
- `S_SHIFT`: 직렬 시프트 수행 상태
- `S_DONE`: 전송 완료 후 초기 상태 복귀 상태

## 6. 하드웨어 매핑

Zybo Z7-20 보드를 기준으로 핀을 다음과 같이 할당하였다.

| 분류 | 신호명              | 하드웨어 핀 (Zybo) | 비고               |
| ---- | ------------------- | ------------------ | ------------------ |
| 입력 | `clk`               | `K17`              | 시스템 클럭 125MHz |
| 입력 | `reset`             | `K18`              | BTN0               |
| 입력 | `save`              | `P16`              | BTN1               |
| 입력 | `start`             | `K19`              | BTN2               |
| 입력 | `X[0]`              | `V12`              | JE1                |
| 입력 | `X[1]`              | `W16`              | JE2                |
| 입력 | `X[2]`              | `J15`              | JE3                |
| 입력 | `X[3]`              | `H15`              | JE4                |
| 입력 | `X[4]`              | `V13`              | JE7                |
| 입력 | `X[5]`              | `U17`              | JE8                |
| 입력 | `X[6]`              | `T17`              | JE9                |
| 입력 | `X[7]`              | `Y17`              | JE10               |
| 출력 | `serial_out`        | `M14`              | LD0                |
| 출력 | `stored_cnt_led[0]` | `M15`              | LD1                |
| 출력 | `stored_cnt_led[1]` | `G14`              | LD2                |
| 출력 | `stored_cnt_led[2]` | `D18`              | LD3                |
| 출력 | `ready_led`         | `T5`               | RGB LED5 Green     |
| 출력 | `error_led`         | `Y11`              | RGB LED5 Red       |

## 7. ILA 및 JTAG 디버깅 메모

`JTAG`는 FPGA와 PC 사이를 연결하는 디버깅 및 프로그램용 직렬 인터페이스이다. Vivado는 JTAG를 통해 bitstream을 다운로드하고, ILA/debug hub와 통신하여 내부 신호를 읽거나 trigger를 제어한다.

이번 설계에서 ILA와 debug hub는 내부 동작 클럭 `clk_7M`에 연결되어 있다. Vivado의 기본 JTAG 주파수는 보통 `15 MHz`로 동작하는데, 이는 약 `7 MHz`의 debug hub clock에 비해 너무 빠를 수 있다. 이 경우 다음 문제가 나타날 수 있다.

- `.ltx` mismatch 또는 ILA probe 관련 오류
- ILA 파형 창은 열리지만 trigger가 제대로 걸리지 않는 현상
- 동일 설계가 어떤 날은 capture되고 어떤 날은 실패하는 불안정한 동작

AMD Vivado 가이드에서는 JTAG clock이 debug hub clock보다 최소 `2.5배` 이상 느려야 안정적이라고 안내한다. 본 설계의 내부 clock이 약 `7 MHz`이므로, 안전한 JTAG 상한은 대략 `2.8 MHz` 이하이고 `1 MHz` 설정 시 충분한 안정 여유를 확보할 수 있다.

하드웨어 연결 후 Tcl Console에서 JTAG를 `1 MHz`로 설정하는 명령은 다음과 같다.

```tcl
open_hw_manager
connect_hw_server
current_hw_target [lindex [get_hw_targets] 0]
close_hw_target
set_property PARAM.FREQUENCY 1000000 [current_hw_target]
open_hw_target
get_property PARAM.FREQUENCY [current_hw_target]
```

마지막 명령의 출력이 `1000000`이면 정상 적용된 것이다.

## 8. 구현 파일 구성

수동 작성 소스는 다음과 같다.

- `rtl/ParToSer_ctrl.v`: 상위 FSM 제어 모듈
- `rtl/ParToSer.v`: 8비트 parallel-to-serial 변환 모듈
- `rtl/debouncer.v`: 버튼 디바운서
- `rtl/constrs/pmod_bram_serializer.xdc`: 핀 및 클럭 제약 파일

Vivado IP로 생성하여 사용하는 모듈은 다음과 같다.

- `blk_mem_gen_0`: BRAM IP
- `clk_wiz_0`: 내부 `clk_7M` 생성용 clock wizard IP
- `ila_0`: 내부 신호 관측용 ILA IP

## 9. RTL 코드 전문

### 9.1 `rtl/ParToSer_ctrl.v`

```verilog
module ParToSer_ctrl (
    input  [7:0] X,
    input        clk,             // 메인 클럭 (125MHz)
    input        reset,
    input        save,
    input        start,
    output       serial_out,
    output [2:0] stored_cnt_led,
    output       ready_led,
    output       error_led
);

  localparam integer DEBOUNCE_COUNT_MAX = 70_000;
  localparam integer STORED_TARGET = 5;

  // FSM 상태 정의 
  localparam [2:0] S_STORE = 3'd0;
  localparam [2:0] S_WRITE = 3'd1;
  localparam [2:0] S_WAIT_START = 3'd2;
  localparam [2:0] S_READ_ADDR = 3'd3;
  localparam [2:0] S_READ_WAIT = 3'd4;
  localparam [2:0] S_LOAD = 3'd5;
  localparam [2:0] S_SHIFT = 3'd6;
  localparam [2:0] S_DONE = 3'd7;

  reg  [ 2:0] state;
  reg  [ 2:0] write_count;
  reg  [ 2:0] read_count;
  reg  [ 2:0] shift_count;
  reg  [ 2:0] bram_addr;
  reg  [ 7:0] bram_din;
  reg         error_latched;
  reg  [ 7:0] x0;
  reg  [ 7:0] x1;
  reg  [ 7:0] x2;
  reg  [ 7:0] x3;
  reg  [ 7:0] x4;

  wire [ 7:0] serializer_q;
  wire [ 7:0] bram_dout;
  wire [39:0] ila_data;
  wire [ 0:0] bram_wea;
  wire        clk_7M;
  wire        pll_locked;
  wire        safe_reset;
  wire        save_pulse;
  wire        start_pulse;
  wire        serializer_ld;
  wire        serializer_shift_en;

  assign safe_reset          = reset | ~pll_locked;
  assign stored_cnt_led      = write_count;
  assign ready_led           = (state == S_WAIT_START);
  assign error_led           = error_latched;
  assign ila_data            = {x4, x3, x2, x1, x0};
  assign bram_wea            = (state == S_WRITE) ? 1'b1 : 1'b0;
  assign serializer_ld       = (state == S_LOAD);
  assign serializer_shift_en = (state == S_SHIFT);

  debouncer #(
      .COUNT_MAX(DEBOUNCE_COUNT_MAX)
  ) i_save_debouncer (
      .clk      (clk_7M),
      .reset    (safe_reset),
      .btn_in   (save),
      .btn_level(),
      .btn_pulse(save_pulse)
  );

  debouncer #(
      .COUNT_MAX(DEBOUNCE_COUNT_MAX)
  ) i_start_debouncer (
      .clk      (clk_7M),
      .reset    (safe_reset),
      .btn_in   (start),
      .btn_level(),
      .btn_pulse(start_pulse)
  );

  ParToSer i_serializer (
      .X         (bram_dout),
      .clk       (clk_7M),
      .reset     (safe_reset),
      .ld        (serializer_ld),
      .shift_en  (serializer_shift_en),
      .serial_out(serial_out),
      .Q         (serializer_q)
  );

  blk_mem_gen_0 i_bram (
      .clka (clk_7M),
      .wea  (bram_wea),
      .addra(bram_addr),
      .dina (bram_din),
      .douta(bram_dout)
  );

  ila_0 i_ila (
      .clk   (clk_7M),
      .probe0(ila_data),
      .probe1(serial_out)
  );

  clk_wiz_0 i_clk_wiz (
      .reset   (reset),
      .clk_in1 (clk),
      .clk_out1(clk_7M),
      .locked  (pll_locked)
  );
  // FSM 구현
  // 리셋 -> 저장 대기 -> BRAM 쓰기 -> start 대기 -> BRAM 읽기 -> serializer load -> shift -> 완료

  always @(posedge clk_7M or posedge safe_reset) begin
    if (safe_reset) begin
      state         <= S_STORE;
      write_count   <= 3'd0;
      read_count    <= 3'd0;
      shift_count   <= 3'd0;
      bram_addr     <= 3'd0;
      bram_din      <= 8'd0;
      error_latched <= 1'b0;
      x0            <= 8'd0;
      x1            <= 8'd0;
      x2            <= 8'd0;
      x3            <= 8'd0;
      x4            <= 8'd0;
    end else begin
      case (state)
        S_STORE: begin
          bram_addr <= write_count;
          if (save_pulse) begin
            if (write_count < STORED_TARGET) begin
              bram_addr <= write_count;
              bram_din  <= X;
              state     <= S_WRITE;
            end else begin
              error_latched <= 1'b1;
            end
          end
          if (start_pulse) begin
            error_latched <= 1'b1;
          end
        end

        S_WRITE: begin
          case (write_count)
            3'd0: x0 <= bram_din;
            3'd1: x1 <= bram_din;
            3'd2: x2 <= bram_din;
            3'd3: x3 <= bram_din;
            3'd4: x4 <= bram_din;
            default: begin
            end
          endcase

          if (write_count == STORED_TARGET - 1) begin
            write_count <= STORED_TARGET[2:0];
            state       <= S_WAIT_START;
          end else begin
            write_count <= write_count + 1'b1;
            state       <= S_STORE;
          end
        end

        S_WAIT_START: begin
          if (save_pulse) begin
            error_latched <= 1'b1;
          end
          if (start_pulse) begin
            read_count <= 3'd0;
            bram_addr  <= 3'd0;
            state      <= S_READ_ADDR;
          end
        end

        S_READ_ADDR: begin
          bram_addr <= read_count;
          state     <= S_READ_WAIT;
        end

        S_READ_WAIT: begin
          state <= S_LOAD;
        end

        S_LOAD: begin
          shift_count <= 3'd7;
          state       <= S_SHIFT;
        end

        S_SHIFT: begin
          if (shift_count == 3'd1) begin
            if (read_count == STORED_TARGET - 1) begin
              state <= S_DONE;
            end else begin
              read_count <= read_count + 1'b1;
              state      <= S_READ_ADDR;
            end
          end
          shift_count <= shift_count - 1'b1;
        end

        S_DONE: begin
          state         <= S_STORE;
          write_count   <= 3'd0;
          read_count    <= 3'd0;
          shift_count   <= 3'd0;
          bram_addr     <= 3'd0;
          bram_din      <= 8'd0;
          error_latched <= 1'b0;
          x0            <= 8'd0;
          x1            <= 8'd0;
          x2            <= 8'd0;
          x3            <= 8'd0;
          x4            <= 8'd0;
        end

        default: begin
          state         <= S_STORE;
          write_count   <= 3'd0;
          read_count    <= 3'd0;
          shift_count   <= 3'd0;
          bram_addr     <= 3'd0;
          bram_din      <= 8'd0;
          error_latched <= 1'b1;
          x0            <= 8'd0;
          x1            <= 8'd0;
          x2            <= 8'd0;
          x3            <= 8'd0;
          x4            <= 8'd0;
        end
      endcase
    end
  end

endmodule
```

### 9.2 `rtl/ParToSer.v`

```verilog
// Parallel-to-Serial(8비트 병렬 입력을 직렬 입력으로 전환하는 모듈)
// PMOD와 PLL, ILA 사용법 숙지

// ip를 사용해서  BRAM을 생성한 후, ParToSer_ctrl 모듈에서 instantiation하여 사용
module ParToSer (
    input [7:0] X,
    input clk,
    input reset,
    input ld,
    input shift_en,
    output serial_out,
    output reg [7:0] Q
);

  assign serial_out = Q[0];
  always @(posedge clk) begin
    if (reset) begin
      Q <= 8'b00000000;
    end else if (ld) begin
      Q <= X;
    end else if (shift_en) begin
      Q <= {Q[0], Q[7:1]};
    end else begin
      Q <= Q;
    end
  end
endmodule
```

### 9.3 `rtl/debouncer.v`

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

## 10. 제약 파일 전문

### 10.1 `rtl/constrs/pmod_bram_serializer.xdc`

```tcl
# pmod_bram_serializer.xdc

## 1. 시스템 클럭 입력
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

## 2. 제어 버튼 입력
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { reset }];
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { save }];
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { start }];

## 3. 직렬 출력 및 저장 개수 표시 LED
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { serial_out }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { stored_cnt_led[0] }];
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { stored_cnt_led[1] }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { stored_cnt_led[2] }];

## 4. 상태 표시 RGB LED
set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { ready_led }];
set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { error_led }];

## 5. PMOD JE 병렬 입력 X[7:0]
## JE의 데이터 핀은 1, 2, 3, 4, 7, 8, 9, 10만 사용한다.
## JE5/JE11 = GND, JE6/JE12 = 3.3V 전원 핀이다.
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { X[0] }];   # JE1
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { X[1] }];   # JE2
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { X[2] }];   # JE3
set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { X[3] }];   # JE4
set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { X[4] }];   # JE7
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { X[5] }];   # JE8
set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { X[6] }];   # JE9
set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { X[7] }];   # JE10
```

## 11. 결론

본 설계는 PMOD 기반 `8비트` 병렬 입력을 `5회`에 걸쳐 BRAM에 저장한 뒤, BRAM read latency를 고려하여 ParToSer에 순차 공급하고 `LSB-first` 방식으로 직렬 출력하는 구조를 구현하였다. 또한 ILA를 이용해 저장된 5개 입력을 `40비트` 버스로 검증할 수 있도록 하였으며, 디버깅 안정화를 위해 JTAG 주파수를 `1 MHz`로 낮추는 운용 절차를 함께 정리하였다.
