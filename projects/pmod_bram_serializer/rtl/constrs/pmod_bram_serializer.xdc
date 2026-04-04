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
