#include "cx.hpp"
#include <benchmark/benchmark.h>

static void BM_Name(benchmark::State &state)
{
    int i = 0;
    for (auto _ : state)
    {
        CC_NO_OPTIMIZE(i++);
        CC_CLOBBER();
    }
}
BENCHMARK(BM_Name)->Name("Name");
