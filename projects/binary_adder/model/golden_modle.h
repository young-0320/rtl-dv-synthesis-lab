// golden_modle.h
#pragma once
#include <cstdint>

struct BinaryAdder64Result {
  uint64_t sum;
  uint8_t c_out;
};

// 64-bit unsigned adder golden model
inline BinaryAdder64Result run_64bit_unsigned_adder(uint64_t a, uint64_t b) {
  uint64_t sum = a + b;
  // 오버플로 검출식
  uint8_t c_out = static_cast<uint8_t>(sum < a);
  return {sum, c_out};
}
