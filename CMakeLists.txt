cmake_minimum_required(VERSION 3.10)

project(snek ASM_NASM CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(headers2Asm ${PROJECT_SOURCE_DIR}/headers2Asm.cpp)

add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/headers.asm
    COMMAND headers2Asm > ${CMAKE_BINARY_DIR}/headers.asm
    DEPENDS headers2Asm
    COMMENT "Generating headers.asm"
)

add_executable(snek snek.asm ${CMAKE_BINARY_DIR}/headers.asm)
# set_target_properties(snek PROPERTIES
#     COMPILE_OPTIONS "-I${CMAKE_BINARY_DIR}"
# )

add_dependencies(snek headers2Asm)
