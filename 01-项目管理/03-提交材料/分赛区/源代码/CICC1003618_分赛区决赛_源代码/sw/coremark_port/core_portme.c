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

#include "coremark.h"
#include "core_portme.h"

#ifndef YH_COREMARK_EXEC_MASK
#define YH_COREMARK_EXEC_MASK 0
#endif

static volatile ee_u32 * const YH_UART_TX      = (ee_u32 *)0x10000000u;
static volatile ee_u32 * const YH_DONE         = (ee_u32 *)0x10000004u;
static volatile ee_u32 * const YH_TIMER_VALUE_LO = (ee_u32 *)0x10000008u;
static volatile ee_u32 * const YH_TIMER_VALUE_HI = (ee_u32 *)0x1000000cu;
static volatile ee_u32 * const YH_TIMER_CTRL   = (ee_u32 *)0x10000018u;

#if VALIDATION_RUN
volatile ee_s32 seed1_volatile = 0x3415;
volatile ee_s32 seed2_volatile = 0x3415;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PERFORMANCE_RUN
volatile ee_s32 seed1_volatile = 0x0;
volatile ee_s32 seed2_volatile = 0x0;
volatile ee_s32 seed3_volatile = 0x66;
#endif
#if PROFILE_RUN
volatile ee_s32 seed1_volatile = 0x8;
volatile ee_s32 seed2_volatile = 0x8;
volatile ee_s32 seed3_volatile = 0x8;
#endif
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = YH_COREMARK_EXEC_MASK;

static CORETIMETYPE start_time_val;
static CORETIMETYPE stop_time_val;

static ee_u32
read_timer_low32(void)
{
    ee_u32 hi_before;
    ee_u32 lo_value;
    ee_u32 hi_after;

    do
    {
        hi_before = *YH_TIMER_VALUE_HI;
        lo_value = *YH_TIMER_VALUE_LO;
        hi_after = *YH_TIMER_VALUE_HI;
    } while (hi_before != hi_after);

    return lo_value;
}

CORETIMETYPE
barebones_clock(void)
{
    return read_timer_low32();
}

void
start_time(void)
{
    start_time_val = barebones_clock();
}

void
stop_time(void)
{
    stop_time_val = barebones_clock();
}

CORE_TICKS
get_time(void)
{
    return (CORE_TICKS)(stop_time_val - start_time_val);
}

secs_ret
time_in_secs(CORE_TICKS ticks)
{
    return ((secs_ret)ticks) / (secs_ret)EE_TICKS_PER_SEC;
}

ee_u32 default_num_contexts = 1;

void
portable_init(core_portable *p, int *argc, char *argv[])
{
    (void)argc;
    (void)argv;

    *YH_DONE = 0u;
    *YH_TIMER_CTRL = 2u;

    if (sizeof(ee_ptr_int) != sizeof(ee_u8 *))
    {
        ee_printf(
            "ERROR! Please define ee_ptr_int to a type that holds a pointer!\n");
    }
    if (sizeof(ee_u32) != 4)
    {
        ee_printf("ERROR! Please define ee_u32 to a 32b unsigned type!\n");
    }
    p->portable_id = 1;
}

void
portable_fini(core_portable *p)
{
    p->portable_id = 0;
    *YH_DONE = 1u;
}

void *
portable_malloc(ee_size_t size)
{
    (void)size;
    return NULL;
}

void
portable_free(void *p)
{
    (void)p;
}
