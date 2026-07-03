# Binary Adder (64-bit Ripple-Carry Adder)

Half/Full Adder로부터 계층적으로 합성한 64비트 unsigned Ripple-Carry Adder(RCA)와,
C++ 골든 모델로 생성한 테스트 벡터를 이용해 iverilog로 검증하는 프로젝트.

상세 인터페이스와 벡터 파일 포맷은 [`docs/binary_adder_spec.md`](docs/binary_adder_spec.md) 참고.

## 1. 모듈 계층 구조

```text
half_adder ──2개──> full_adder ──4개──> rca_4bit
rca_4bit  ──2개──> rca_8bit
rca_8bit  ──2개──> rca_16bit
rca_16bit ──2개──> rca_32bit
rca_32bit ──2개──> rca_64bit   (최상위, {c_out, sum} = a + b)
```

- 조합 논리(0-cycle latency), unsigned 전용, 뺄셈/부호 오버플로 플래그 없음.
- `rca_64bit`은 하위 32비트의 carry-out을 상위 32비트의 carry-in으로 전달.

## 2. 디렉터리 구성

| 경로 | 내용 |
| ---- | ---- |
| `rtl/` | `half_adder`, `full_adder`, `rca_4/8/16/32/64bit` RTL |
| `model/golden_modle.h` | 64비트 unsigned 덧셈 C++ 골든 모델 |
| `sim/vector/gen_golden_vectors.cpp` | 골든 벡터 생성기 (코너 케이스 10개 + 고정 시드 랜덤) |
| `sim/vector/golden_vectors.hex` | 생성된 골든 벡터 (기본 266줄) |
| `sim/test/test_*.v` | half/full adder, rca_4bit, rca_64bit 테스트벤치 |
| `docs/binary_adder_spec.md` | 모듈 스펙 및 벡터 포맷 정의 |

## 3. 검증 흐름

1. **골든 벡터 생성** — CMake로 `gen_golden_vectors`를 빌드해 실행하면
   `sim/vector/golden_vectors.hex`가 생성된다. (루트 `CMakeLists.txt`가
   `model`, `sim/vector`를 등록)

   ```bash
   cmake -S . -B build && cmake --build build
   ./build/projects/binary_adder/sim/vector/gen_golden_vectors   # [out.hex] [random_count]
   ```

2. **RTL 시뮬레이션** — iverilog로 RTL과 테스트벤치를 컴파일해 vvp로 실행.
   테스트벤치는 저장소 루트 기준 상대경로로 `golden_vectors.hex`를 읽어
   RTL 출력과 비교한다. (아래 명령은 저장소 루트에서 실행)

   ```bash
   iverilog -g2012 -Wall -s test_rca_64bit -o test_rca_64bit.vvp \
       projects/binary_adder/rtl/*.v projects/binary_adder/sim/test/test_rca_64bit.v
   vvp test_rca_64bit.vvp
   ```

> 참고: `golden_vectors.hex`는 고정 시드로 재생성 가능하지만, 기준 벡터로서
> 저장소에 커밋되어 있다. 컴파일 산출물(`.vvp`, 빌드 디렉터리)은 커밋하지 않는다.
