cmake_minimum_required(VERSION 3.16)
project(binary_adder_vector_gen LANGUAGES CXX)

# add_executable([실행 파일 이름] [소스 코드들(.cpp)])
add_executable(gen_golden_vectors gen_golden_vectors.cpp)
target_include_directories(gen_golden_vectors PRIVATE ${CMAKE_CURRENT_LIST_DIR}/../../model)
target_compile_definitions(
    gen_golden_vectors
    PRIVATE DEFAULT_GOLDEN_VECTOR_PATH="${CMAKE_CURRENT_LIST_DIR}/golden_vectors.hex"
)
target_compile_features(gen_golden_vectors PRIVATE cxx_std_20)
