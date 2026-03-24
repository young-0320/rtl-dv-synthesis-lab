# adder_subtractor.xdc

## 1. Mode 결정 스위치 (SW3)
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { mode }]; 

## 2. 입력 a 스위치 (SW0, SW1, SW2)
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { a[0] }]; 
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { a[1] }]; 
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { a[2] }]; 

## 3. 입력 b 버튼 (BTN0, BTN1, BTN2)
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { b[0] }]; 
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { b[1] }]; 
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { b[2] }]; 

## 4. 결과 출력 (LED 0, 1, 2, 3)
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { sum[0] }]; 
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { sum[1] }]; 
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { sum[2] }]; 
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { sum[3] }]; 

## 5. 추가 캐리 출력 (RGB LED 5 - Red)
set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { c_out }];