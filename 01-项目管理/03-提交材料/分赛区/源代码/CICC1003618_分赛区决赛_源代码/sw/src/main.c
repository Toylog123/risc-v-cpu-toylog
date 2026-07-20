static volatile unsigned int * const TOYLOG_UART_TX = (unsigned int *)0x10000000u;
static volatile unsigned int * const TOYLOG_DONE    = (unsigned int *)0x10000004u;

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
    puts_uart("YH_rv_cpu boot\n");
    *TOYLOG_DONE = 1u;

    for (;;) {
    }
}
