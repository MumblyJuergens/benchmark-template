set unstable

set dotenv-load
APP := env('APPNAME')

# List all recipes.
default:
    @echo "Recipes for project {{APP}}"
    @just --list

# Put the CPU into power saving mode.
[unix]
mode-powersave:
    sudo cpupower frequency-set --governor powersave

# Put the CPU into performance mode.
[unix]
mode-performance:
    sudo cpupower frequency-set --governor performance

# Prints the current power mode for the CPU cores.
[unix]
mode-verify:
    cpupower frequency-info -o proc

# CMake configure step.
[unix]
configure TYPE='Release' CXX='g++' CC='gcc':
    cmake . -B build/{{CC}}/{{TYPE}} -DCMAKE_BUILD_TYPE={{TYPE}} -DCMAKE_CXX_COMPILER={{CXX}} -DCMAKE_C_COMPILER={{CC}}
    cmake . -B build/{{CC}}/{{TYPE}} -DCMAKE_BUILD_TYPE={{TYPE}} -DCMAKE_CXX_COMPILER={{CXX}} -DCMAKE_C_COMPILER={{CC}}

# CMake build step. May configure fist.
[unix]
build TYPE='Release' CXX='g++' CC='gcc': (configure TYPE CXX CC)
    cmake --build build/{{CC}}/{{TYPE}} --config {{TYPE}}

# Runs the program. May build or configure and build first.
[unix]
run TYPE='Release' CXX='g++' CC='gcc' FILTER='.': (build TYPE CXX CC)
    build/{{CC}}/{{TYPE}}/{{APP}} --benchmark_filter={{FILTER}}

# Runs Relase app for an aggregate report, does not build for you.
[unix]
json REPS='15' FILTER='.' CC='gcc':
    build/{{CC}}/Release/{{APP}} --benchmark_format=json --benchmark_repetitions={{REPS}} --benchmark_report_aggregates_only=true --benchmark_filter={{FILTER}} --benchmark_perf_counters=CACHE-MISSES,CACHE-REFERENCES,CYCLES,INSTRUCTIONS,BRANCHES

# Configures and builds for MinGW.
[unix, script]
build-mingw64 TYPE='Release':
    mingw-env x86_64-w64-mingw
    mkdir build/mingw/{{TYPE}} || true
    x86_64-w64-mingw32-cmake -B build/mingw/{{TYPE}} -DCMAKE_BUILD_TYPE={{TYPE}}
    x86_64-w64-mingw32-cmake -B build/mingw/{{TYPE}} -DCMAKE_BUILD_TYPE={{TYPE}}
    cmake --build build/mingw/{{TYPE}}
    cp build/mingw/{{TYPE}}/_deps/benchmark-build/src/libbenchmark.dll build/mingw/{{TYPE}}/

# Runs MinGW Release app for an aggregate report, does not build for you.
[unix]
json-mingw REPS='15' FILTER='.':
    build/mingw/Release/{{APP}}.exe --benchmark_format=json --benchmark_repetitions={{REPS}} --benchmark_report_aggregates_only=true --benchmark_filter={{FILTER}}

# Configures and builds for msvc.
[unix]
build-msvc TYPE='Release':
    msvc-x64-cmake -B build/msvc/{{TYPE}} -DCMAKE_BUILD_TYPE={{TYPE}}
    msvc-x64-cmake --build build/msvc/{{TYPE}}

# Runs msvc Release app for an aggregate report, does not build for you.
[unix]
json-msvc REPS='15' FILTER='.':
    build/msvc/Release/{{APP}}.exe --benchmark_format=json --benchmark_repetitions={{REPS}} --benchmark_report_aggregates_only=true --benchmark_filter={{FILTER}}


[unix]
build-all TYPE='Release':
    just configure Release g++ gcc
    just build Release g++ gcc
    just configure Release clang++ clang
    just build Release clang++ clang
    just build-mingw64 Release
    just build-msvc Release
    

# Runs benchmarks in all compilers, builds and configures, outputs json aggregate.
[unix]
benchmark REPS='15' FILTER='.':
    just mode-performance
    sudo nice -n -20 taskset -c 0 just json {{REPS}} {{FILTER}} gcc > results_gcc.json
    sudo nice -n -20 taskset -c 0 just json {{REPS}} {{FILTER}} clang > results_clang.json
    sudo nice -n -20 taskset -c 0 just json-mingw {{REPS}} {{FILTER}} > results_mingw.json
    sudo nice -n -20 taskset -c 0 just json-msvc {{REPS}} {{FILTER}} > results_msvc.json
    just mode-powersave
    just mode-verify

# Same as benchmark recipe, but turns on google benchmark de-optimisers.
[unix, script]
benchmark-alot REPS='15' FILTER='.':
    just benchmark {{REPS}} {{FILTER}}
    mkdir -p results/noops || true
    cp results_*.json results/noops/
    CC_OP_X=CC_OP_BOTH just benchmark {{REPS}} {{FILTER}}
    mkdir -p results/both || true
    cp results_*.json results/both/
    CC_OP_X=CC_OP_A just benchmark {{REPS}} {{FILTER}}
    mkdir -p results/a || true
    cp results_*.json results/a/
    CC_OP_X=CC_OP_B just benchmark {{REPS}} {{FILTER}}
    mkdir -p results/b || true
    cp results_*.json results/b/
 
# Creates the virtual environment for the python scripts.
[unix, script, working-directory: 'gen']
charter-create-venv:
    python -m venv .venv
    source .venv/bin/activate
    pip install python-rapidjson
    pip install plotly[express]

# Charts the json files in the current directory.
[unix, script, working-directory: 'gen']
charter-run:
    source .venv/bin/activate
    python charter.py {{invocation_directory()}}

# Charts the json files in the base directory after moving to a specified directory.
[unix, script]
charter-run-dir DIR:
    source gen/.venv/bin/activate
    mkdir -p {{DIR}}
    cp results_*.json {{DIR}}
    python gen/charter.py {{DIR}}

