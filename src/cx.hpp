#pragma once

#define CC_NO_OPTIMIZE
#define CC_CLOBBER()
#if defined(CC_OP_BOTH)
#define CC_NO_OPTIMIZE benchmark::DoNotOptimize
#define CC_CLOBBER benchmark::ClobberMemory
#endif
#if defined(CC_OP_A)
#define CC_NO_OPTIMIZE benchmark::DoNotOptimize
#endif
#if defined(CC_OP_B)
#define CC_CLOBBER benchmark::ClobberMemory
#endif
