// generate golden vectors
#include <cstdint>    // 고정폭 정수 타입 라이브러리: uint64_t, uint8_t 사용
#include <fstream>    // 파일 입출력 스트림 라이브러리: golden_vectors.hex 파일 쓰기
#include <iomanip>    // 출력 포맷 제어 라이브러리: hex, setw, setfill 설정
#include <iostream>   // 표준 입출력 스트림 라이브러리: 로그/에러 메시지 출력
#include <random>     // 난수 생성 라이브러리: mt19937_64로 랜덤 벡터 생성
#include <stdexcept>  // 예외 타입 라이브러리: stoull 변환 예외 처리
#include <string>     // 문자열 라이브러리: 출력 경로/인자 문자열 처리
#include <utility>    // 유틸리티 라이브러리: std::pair 사용
#include <vector>     // 동적 배열 컨테이너 라이브러리: 입력 벡터 목록 보관

#include "golden_modle.h"

#ifndef DEFAULT_GOLDEN_VECTOR_PATH
#define DEFAULT_GOLDEN_VECTOR_PATH "golden_vectors.hex"
#endif

static std::vector<std::pair<uint64_t, uint64_t>> build_input_vectors(std::size_t random_count) {
    // 코너 케이스 생성 
    std::vector<std::pair<uint64_t, uint64_t>> inputs = {
        {0x0000000000000000ULL, 0x0000000000000000ULL},
        {0x0000000000000000ULL, 0x0000000000000001ULL},
        {0x0000000000000001ULL, 0x0000000000000000ULL},
        {0x0000000000000001ULL, 0x0000000000000001ULL},
        {0xFFFFFFFFFFFFFFFFULL, 0x0000000000000001ULL},
        {0xFFFFFFFFFFFFFFFFULL, 0xFFFFFFFFFFFFFFFFULL},
        {0x7FFFFFFFFFFFFFFFULL, 0x0000000000000001ULL},
        {0x8000000000000000ULL, 0x8000000000000000ULL},
        {0xAAAAAAAAAAAAAAAAULL, 0x5555555555555555ULL},
        {0x5555555555555555ULL, 0xAAAAAAAAAAAAAAAAULL},
    };
    // 고정 시드 랜덤 입력(a,b) 목록 생성
    std::mt19937_64 rng(0xB1ADDE20260222ULL);
    for (std::size_t i = 0; i < random_count; ++i) {
        inputs.emplace_back(rng(), rng());
    }

    return inputs;
}

// main 함수 인자 정리
// 예시 : gen_golden_vectors out.hex 512

//   - argv[0]=gen_golden_vectors
//   - argv[1]=out.hex
//   - argv[2]=512
int main(int argc, char** argv) {
    // 기본 출력은 소스 트리의 sim/vector/golden_vectors.hex
    std::string output_path = DEFAULT_GOLDEN_VECTOR_PATH;
    std::size_t random_count = 256;

    if (argc >= 2) {
        output_path = argv[1];
    }
    if (argc >= 3) {
        try {
            random_count = static_cast<std::size_t>(std::stoull(argv[2]));
        } catch (const std::exception&) {
            std::cerr << "Invalid random_count: " << argv[2] << "\n";
            return 1 ;
        }
    }

    auto inputs = build_input_vectors(random_count);

    std::ofstream ofs(output_path);
    if (!ofs) {
        std::cerr << "Failed to open output file: " << output_path << "\n";
        return 1;
    }

    ofs << std::hex << std::nouppercase << std::setfill('0');

    for (const auto& input : inputs) {
        uint64_t a = input.first;
        uint64_t b = input.second;
        BinaryAdder64Result result = run_64bit_unsigned_adder(a, b);

        ofs << std::setw(16) << a << " "
            << std::setw(16) << b << " "
            << std::setw(16) << result.sum << " "
            << std::setw(1) << static_cast<unsigned>(result.c_out) << "\n";
    }

    std::cout << "Generated " << inputs.size() << " vectors to " << output_path << "\n";
    return 0;
}
