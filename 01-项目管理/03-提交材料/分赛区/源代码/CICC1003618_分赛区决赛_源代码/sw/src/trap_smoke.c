static volatile unsigned int * const TOYLOG_UART_TX = (unsigned int *)0x10000000u;
static volatile unsigned int * const TOYLOG_DONE    = (unsigned int *)0x10000004u;

extern void toylog_trap_handler(void);

static void putc_uart(char ch)
{
    *TOYLOG_UART_TX = (unsigned int)ch;
}

static void puts_uart(const char *text)
{
    while (*text) {
        putc_uart(*text++);
    }
}

int main(void)
{
    unsigned int handler = (unsigned int)&toylog_trap_handler;

    __asm__ volatile ("csrw mtvec, %0" :: "r"(handler));
    __asm__ volatile ("ecall");

    puts_uart("rap ok\n");
    *TOYLOG_DONE = 1u;

    for (;;) {
    }
}
