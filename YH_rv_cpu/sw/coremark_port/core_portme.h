/*
Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#ifndef CORE_PORTME_H
#define CORE_PORTME_H

#include <stddef.h>

#ifndef HAS_FLOAT
/*
 * Keep the portable CoreMark path on integer-only reporting so the benchmark
 * binary stays small and smoke runs finish quickly on RV32I without an FPU.
 * Formal score reporting is derived host-side from raw ticks.
 */
#define HAS_FLOAT 0
#endif

#ifndef HAS_TIME_H
#define HAS_TIME_H 0
#endif

#ifndef USE_CLOCK
#define USE_CLOCK 0
#endif

#ifndef HAS_STDIO
#define HAS_STDIO 0
#endif

#ifndef HAS_PRINTF
#define HAS_PRINTF 0
#endif

#ifndef COMPILER_VERSION
#ifdef __GNUC__
#define COMPILER_VERSION "GCC " __VERSION__
#else
#define COMPILER_VERSION "Unknown GCC"
#endif
#endif

#ifndef COMPILER_FLAGS
#ifdef YH_COREMARK_OPT_O3UNROLL_LTO
#define COMPILER_FLAGS "-O3 -funroll-loops -flto -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_O3LTO)
#define COMPILER_FLAGS "-O3 -flto -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_OFAST_UNROLL)
#define COMPILER_FLAGS "-Ofast -funroll-loops -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_OFAST)
#define COMPILER_FLAGS "-Ofast -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_O3UNROLL_B1NOSCHED)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_O3UNROLL_B1NOSCHED_UALL800)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_O3UNROLL_B1NOSCHED_UALL800_INLINE_NOCROSS)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_O3UNROLL_B1NOSCHED_UALL800_INLINE_NOCROSS)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -march=rv32i_zmmul_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZBA_ZBB_ZBS_INLINE_NOCROSS)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -march=rv32i_zmmul_zba_zbb_zbs_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec -march=rv32i_zmmul_zba_zbb_zbs_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec -march=rv32i_zmmul_zba_zbb_zbs_zbc_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZICOND_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-auto-inc-dec -march=rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZICOND_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-auto-inc-dec -march=rv32i_zmmul_zba_zbb_zbs_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZICOND_XTHEAD_MEMIDX_O2SCHED_NOCALLER)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -march=rv32i_zmmul_zba_zbb_zbs_zbc_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZBKB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec -march=rv32i_zmmul_zba_zbb_zbs_zbc_zbkb_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32I_ZMMUL_ZBC_ZICOND_ZBKB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-auto-inc-dec -march=rv32i_zmmul_zba_zbb_zbs_zbc_zicond_zbkb_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32IM_ZBA_ZBB_ZBS_INLINE_NOCROSS)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -march=rv32im_zba_zbb_zbs_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32IM_STD_EXT_INLINE_NOCROSS)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -march=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32IM_STD_EXT_O2SCHED_NOCALLER)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -march=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_O2SCHED_NOCALLER)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -march=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_O2SCHED_NOCALLER_NOIFCONV)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -march=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_MEMIDX_O2SCHED_NOCALLER_NOIFCONV)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -march=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_RV32IM_ZB_XTHEAD_MEMIDX_NOAUTOINC_O2SCHED_NOCALLER_NOIFCONV)
#define COMPILER_FLAGS "-O3 -funroll-loops -mbranch-cost=1 -fno-schedule-insns -fno-schedule-insns2 -funroll-all-loops --param max-unrolled-insns=800 --param max-average-unrolled-insns=320 -finline-functions --param max-inline-insns-single=1000 --param max-inline-insns-auto=1000 --param inline-unit-growth=500 -fno-crossjumping -O2 -fschedule-insns -fschedule-insns2 -fno-caller-saves -fno-if-conversion -fno-if-conversion2 -fno-auto-inc-dec -march=rv32im_zba_zbb_zbs_zbc_zbkb_zicond_xtheadba_xtheadbb_xtheadbs_xtheadcondmov_xtheadmemidx_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_O3UNROLL)
#define COMPILER_FLAGS "-O3 -funroll-loops -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_O2UNROLL)
#define COMPILER_FLAGS "-O2 -funroll-loops -march=rv32im_zicsr -mabi=ilp32"
#elif defined(YH_COREMARK_OPT_O3)
#define COMPILER_FLAGS "-O3 -march=rv32im_zicsr -mabi=ilp32"
#elif __riscv_xlen == 64
#ifdef __riscv_mul
#define COMPILER_FLAGS "-O2 -march=rv64im_zicsr -mabi=lp64"
#else
#define COMPILER_FLAGS "-O2 -march=rv64i_zicsr -mabi=lp64"
#endif
#else
#ifdef __riscv_mul
#define COMPILER_FLAGS "-O2 -march=rv32im_zicsr -mabi=ilp32"
#else
#define COMPILER_FLAGS "-O2 -march=rv32i_zicsr -mabi=ilp32"
#endif
#endif
#endif

#ifndef MEM_LOCATION
#define MEM_LOCATION "SoC ROM/RAM"
#endif

typedef signed short   ee_s16;
typedef unsigned short ee_u16;
typedef signed int     ee_s32;
typedef double         ee_f32;
typedef unsigned char  ee_u8;
typedef unsigned int   ee_u32;

#if __riscv_xlen == 64
typedef unsigned long ee_ptr_int;
#else
typedef ee_u32 ee_ptr_int;
#endif

typedef size_t ee_size_t;

#ifndef NULL
#define NULL ((void *)0)
#endif

#define align_mem(x) (void *)(4 + (((ee_ptr_int)(x)-1) & ~3))

#define CORETIMETYPE ee_u32
typedef ee_u32 CORE_TICKS;

#ifndef SEED_METHOD
#define SEED_METHOD SEED_VOLATILE
#endif

#ifndef MEM_METHOD
#define MEM_METHOD MEM_STATIC
#endif

#ifndef MULTITHREAD
#define MULTITHREAD 1
#define USE_PTHREAD 0
#define USE_FORK    0
#define USE_SOCKET  0
#endif

#ifndef MAIN_HAS_NOARGC
#define MAIN_HAS_NOARGC 1
#endif

#ifndef MAIN_HAS_NORETURN
#define MAIN_HAS_NORETURN 0
#endif

#ifndef YH_COREMARK_TIMER_HZ
/*
 * Smoke runs use a coarse default timer rate for readable integer seconds.
 * Submission-grade reports pass the real core clock (for example 100000000UL)
 * and parse raw ticks on the host because HAS_FLOAT=0 truncates in-program
 * seconds/Iterations-Sec output.
 */
#define YH_COREMARK_TIMER_HZ 1000UL
#endif

#define CLOCKS_PER_SEC             YH_COREMARK_TIMER_HZ
#define TIMER_RES_DIVIDER          1
#define SAMPLE_TIME_IMPLEMENTATION 1
#define EE_TICKS_PER_SEC           (CLOCKS_PER_SEC / TIMER_RES_DIVIDER)
#define PARALLEL_METHOD            "None"

extern ee_u32 default_num_contexts;

typedef struct CORE_PORTABLE_S
{
    ee_u8 portable_id;
} core_portable;

void portable_init(core_portable *p, int *argc, char *argv[]);
void portable_fini(core_portable *p);
void *portable_malloc(ee_size_t size);
void portable_free(void *p);

#if !defined(PROFILE_RUN) && !defined(PERFORMANCE_RUN) \
    && !defined(VALIDATION_RUN)
#if (TOTAL_DATA_SIZE == 1200)
#define PROFILE_RUN 1
#elif (TOTAL_DATA_SIZE == 2000)
#define PERFORMANCE_RUN 1
#else
#define VALIDATION_RUN 1
#endif
#endif

int ee_printf(const char *fmt, ...);

#endif
