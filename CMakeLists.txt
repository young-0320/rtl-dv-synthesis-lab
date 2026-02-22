# Root CMakeLists.txt
cmake_minimum_required(VERSION 3.10)
project(DIGITAL-PROJECTS VERSION 1.0 LANGUAGES C CXX)

# 옵션: 테스트(sim/test) 빌드 여부
# option(BUILD_FIR_TESTS "Build FIR simulation tests" ON)

# 하위 디렉토리 추가 (컴파일 순서 제어)
# add_subdirectory(lib)

add_subdirectory(projects/model/)

