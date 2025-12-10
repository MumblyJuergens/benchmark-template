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
    cmake . -B build/{{TYPE}} -DCMAKE_BUILD_TYPE={{TYPE}} -DCMAKE_CXX_COMPILER={{CXX}} -DCMAKE_C_COMPILER={{CC}}
    cmake . -B build/{{TYPE}} -DCMAKE_BUILD_TYPE={{TYPE}} -DCMAKE_CXX_COMPILER={{CXX}} -DCMAKE_C_COMPILER={{CC}}

# CMake build step. May configure fist.
[unix]
build TYPE='Release' CXX='g++' CC='gcc': (configure TYPE CXX CC)
    cmake --build build/{{TYPE}} --config {{TYPE}}

# Runs the program. May build or configure and build first.
[unix]
run TYPE='Release' CXX='g++' CC='gcc' FILTER='.': (build TYPE CXX CC)
    build/{{TYPE}}/{{APP}} --benchmark_filter={{FILTER}}

# Runs app for an aggregate report, does not build for you.
[unix]
json REPS='15' FILTER='.':
    build/Release/{{APP}} --benchmark_format=json --benchmark_repetitions={{REPS}} --benchmark_report_aggregates_only=true --benchmark_filter={{FILTER}} --benchmark_perf_counters=CACHE-MISSES,CACHE-REFERENCES,CYCLES,INSTRUCTIONS,BRANCHES

# Configures and builds for MinGW.
[unix, script]
build-mingw64 TYPE='Release':
    mingw-env x86_64-w64-mingw
    mkdir build/mingwbuild || true
    x86_64-w64-mingw32-cmake -B build/mingwbuild -DCMAKE_BUILD_TYPE={{TYPE}}
    x86_64-w64-mingw32-cmake -B build/mingwbuild -DCMAKE_BUILD_TYPE={{TYPE}}
    cmake --build build/mingwbuild
    cp build/mingwbuild/_deps/benchmark-build/src/libbenchmark.dll build/mingwbuild/

# Runs MinGW app for an aggregate report, does not build for you.
[unix]
json-mingw REPS='15' FILTER='.':
    build/mingwbuild/{{APP}}.exe --benchmark_format=json --benchmark_repetitions={{REPS}} --benchmark_report_aggregates_only=true --benchmark_filter={{FILTER}}

# Runs benchmarks in all compilers, builds and configures, outputs json aggregate.
[unix]
benchmark REPS='15' FILTER='.':
    just mode-performance
    just configure Release g++ gcc
    just build Release g++ gcc
    sudo nice -n -20 taskset -c 0 just json {{REPS}} {{FILTER}} > results_gcc.json
    just configure Release clang++ clang
    just build Release clang++ clang
    sudo nice -n -20 taskset -c 0 just json {{REPS}} {{FILTER}} > results_clang.json
    just build-mingw64 Release
    sudo nice -n -20 taskset -c 0 just json-mingw {{REPS}} {{FILTER}} > results_mingw.json
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
