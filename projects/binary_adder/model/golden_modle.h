// binary_adder.h
#pragma once
#include <cstdint>

// 1비트 Half Adder 기능을 수학적으로 기술
inline uint8_t run_half_adder(uint8_t a, uint8_t b) {
  return (a + b);
  // 결과값은 0(00), 1(01), 2(10) 중 하나 (LSB가 sum, MSB가 carry)
}

// 1비트 Full Adder 기능을 수학적으로 기술
inline uint8_t run_full_adder(uint8_t a, uint8_t b, uint8_t c_in) {
  return (a + b + c_in);
  // 결과값은 0(00), 1(01), 2(10), 3(11) 중 하나 (LSB가 sum, MSB가 carry)
}