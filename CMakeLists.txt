cmake_minimum_required(VERSION 3.18)

include(cmake/CPM.cmake)
include(cmake/helpers.cmake)
LoadDotenv()
message("Project namefrom dotenv: $ENV{APPNAME}")
set(APP $ENV{APPNAME})

project(${APP})


# Enable profiling in google benchmark, lunix only.
if (NOT WIN32)
    set(BENCHMARK_ENABLE_LIBPFM ON)
endif()

CPMAddPackage(URI "gh:google/benchmark@1.9.4" OPTIONS "BENCHMARK_ENABLE_TESTING Off")

add_executable(${APP} src/main.cpp src/template.cpp)
target_compile_features(${APP} PRIVATE cxx_std_23)
target_link_libraries(${APP} PRIVATE benchmark::benchmark)
FullCompilerWarnings(${APP} PRIVATE)

# Static benchmark and libaries for mingw, both of some for fairness of benchmarks.
if(MINGW)
    target_link_options(benchmark PUBLIC -static -static-libgcc -static-libstdc++ -fstack-protector-all) 
endif()
target_link_options(${APP} PUBLIC -static-libgcc -static-libstdc++ -fstack-protector-all) 

