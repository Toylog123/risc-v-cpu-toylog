#ifndef YH_DHRYSTONE_PORT_WRAPPER_H
#define YH_DHRYSTONE_PORT_WRAPPER_H

#include "../../build/external/riscv-tests/benchmarks/dhrystone/dhrystone.h"

#ifdef __riscv

#ifndef YH_DHRYSTONE_TIMER_HZ
#define YH_DHRYSTONE_TIMER_HZ 100000000L
#endif

#ifndef YH_DHRYSTONE_MIN_TICKS
#define YH_DHRYSTONE_MIN_TICKS 1L
#endif

#ifndef YH_DHRYSTONE_RUNS
#define YH_DHRYSTONE_RUNS 10
#endif

#undef HZ
#define HZ YH_DHRYSTONE_TIMER_HZ

#undef Too_Small_Time
#define Too_Small_Time YH_DHRYSTONE_MIN_TICKS

#undef CLOCK_TYPE
#define CLOCK_TYPE "YH timer"

#undef NUMBER_OF_RUNS
#define NUMBER_OF_RUNS YH_DHRYSTONE_RUNS

long yh_dhrystone_timer_cycles(void);
void yh_dhrystone_timer_reset(void);

#undef Start_Timer
#define Start_Timer()                 \
    do                               \
    {                                \
        yh_dhrystone_timer_reset();  \
        Begin_Time = yh_dhrystone_timer_cycles(); \
    } while (0)

#undef Stop_Timer
#define Stop_Timer()                  \
    do                               \
    {                                \
        End_Time = yh_dhrystone_timer_cycles();   \
    } while (0)

#endif

#endif
