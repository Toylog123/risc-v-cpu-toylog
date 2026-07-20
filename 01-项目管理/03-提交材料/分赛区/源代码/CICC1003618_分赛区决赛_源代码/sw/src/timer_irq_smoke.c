static volatile unsigned int * const YH_UART_TX      = (unsigned int *)0x10000000u;
static volatile unsigned int * const YH_DONE         = (unsigned int *)0x10000004u;
static volatile unsigned int * const YH_TIMER_CMP_LO = (unsigned int *)0x10000010u;
static volatile unsigned int * const YH_TIMER_CMP_HI = (unsigned int *)0x10000014u;
static volatile unsigned int * const YH_TIMER_CTRL   = (unsigned int *)0x10000018u;

volatile unsigned int irq_seen = 0u;

extern void yh_timer_irq_handler(void);

static void putc_uart(char ch)
{
    *YH_UART_TX = (unsigned int)ch;
}

static void puts_uart(const char *text)
{
    while (*text) {
        putc_uart(*text++);
    }
}

int main(void)
{
    unsigned int handler = (unsigned int)&yh_timer_irq_handler;
    unsigned int mie_mt = 0x80u;
    unsigned int mstatus_mie = 0x8u;

    __asm__ volatile ("csrw mtvec, %0" :: "r"(handler));
    __asm__ volatile ("csrw mie, %0" :: "r"(mie_mt));
    __asm__ volatile ("csrw mstatus, %0" :: "r"(mstatus_mie));

    *YH_TIMER_CMP_LO = 30u;
    *YH_TIMER_CMP_HI = 0u;
    *YH_TIMER_CTRL = 3u;

    while (!irq_seen) {
    }

    puts_uart("irq ok\n");
    *YH_DONE = 1u;

    for (;;) {
    }
}
