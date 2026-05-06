#include <stdarg.h>
#include <stddef.h>

static volatile unsigned int *const YH_UART_TX = (unsigned int *)0x10000000u;
static volatile unsigned int *const YH_TIMER_LO = (unsigned int *)0x10000008u;
static volatile unsigned int *const YH_TIMER_HI = (unsigned int *)0x1000000cu;
static volatile unsigned int *const YH_TIMER_CTRL = (unsigned int *)0x10000018u;

#define YH_HAS_ZERO_BYTE(word_) ((((word_) - 0x01010101u) & ~(word_) & 0x80808080u) != 0u)

static void
uart_putc(char ch)
{
    *YH_UART_TX = (unsigned int)(unsigned char)ch;
}

static void
uart_puts(const char *text)
{
    if (!text)
    {
        return;
    }

    while (*text)
    {
        uart_putc(*text++);
    }
}

static void
uart_put_unsigned(unsigned long value)
{
    char buffer[16];
    int  index = 0;

    if (value == 0)
    {
        uart_putc('0');
        return;
    }

    while (value != 0 && index < (int)sizeof(buffer))
    {
        buffer[index++] = (char)('0' + (value % 10u));
        value /= 10u;
    }

    while (index > 0)
    {
        uart_putc(buffer[--index]);
    }
}

static void
uart_put_signed(long value)
{
    if (value < 0)
    {
        uart_putc('-');
        uart_put_unsigned((unsigned long)(-value));
    }
    else
    {
        uart_put_unsigned((unsigned long)value);
    }
}

static void
uart_put_hex(unsigned long value)
{
    char        buffer[16];
    const char *digits = "0123456789abcdef";
    int         index  = 0;

    if (value == 0)
    {
        uart_putc('0');
        return;
    }

    while (value != 0 && index < (int)sizeof(buffer))
    {
        buffer[index++] = digits[value & 0xfu];
        value >>= 4;
    }

    while (index > 0)
    {
        uart_putc(buffer[--index]);
    }
}

void
setStats(int enable)
{
    (void)enable;
}

void
yh_dhrystone_timer_reset(void)
{
    *YH_TIMER_CTRL = 2u;
}

long
yh_dhrystone_timer_cycles(void)
{
    unsigned int hi_before;
    unsigned int lo_value;
    unsigned int hi_after;

    do
    {
        hi_before = *YH_TIMER_HI;
        lo_value  = *YH_TIMER_LO;
        hi_after  = *YH_TIMER_HI;
    } while (hi_before != hi_after);

    return (long)lo_value;
}

int
putchar(int ch)
{
    uart_putc((char)ch);
    return ch;
}

int
puts(const char *text)
{
    uart_puts(text);
    uart_putc('\n');
    return 0;
}

int
printf(const char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);
    while (*fmt)
    {
        int long_qual = 0;

        if (*fmt != '%')
        {
            uart_putc(*fmt++);
            continue;
        }

        ++fmt;
        if (*fmt == 'l')
        {
            long_qual = 1;
            ++fmt;
        }

        switch (*fmt)
        {
            case 's':
            {
                const char *text = va_arg(args, const char *);
                uart_puts(text ? text : "(null)");
                break;
            }
            case 'd':
            case 'i':
                if (long_qual)
                {
                    uart_put_signed(va_arg(args, long));
                }
                else
                {
                    uart_put_signed((long)va_arg(args, int));
                }
                break;
            case 'u':
                if (long_qual)
                {
                    uart_put_unsigned(va_arg(args, unsigned long));
                }
                else
                {
                    uart_put_unsigned((unsigned long)va_arg(args, unsigned int));
                }
                break;
            case 'x':
            case 'X':
                if (long_qual)
                {
                    uart_put_hex(va_arg(args, unsigned long));
                }
                else
                {
                    uart_put_hex((unsigned long)va_arg(args, unsigned int));
                }
                break;
            case 'c':
                uart_putc((char)va_arg(args, int));
                break;
            case '%':
                uart_putc('%');
                break;
            default:
                uart_putc('%');
                if (*fmt)
                {
                    uart_putc(*fmt);
                }
                break;
        }

        if (*fmt)
        {
            ++fmt;
        }
    }
    va_end(args);
    return 0;
}

char *
strcpy(char *dst, const char *src)
{
    char *ret = dst;

    if ((((unsigned long)dst | (unsigned long)src) & 3u) == 0u)
    {
        unsigned int *      dst_word = (unsigned int *)dst;
        const unsigned int *src_word = (const unsigned int *)src;

        while (1)
        {
            unsigned int word0 = src_word[0];
            unsigned int word1 = src_word[1];

            if (!YH_HAS_ZERO_BYTE(word0) && !YH_HAS_ZERO_BYTE(word1))
            {
                dst_word[0] = word0;
                dst_word[1] = word1;
                src_word += 2;
                dst_word += 2;
                continue;
            }

            if (YH_HAS_ZERO_BYTE(word0))
            {
                dst = (char *)dst_word;
                src = (const char *)src_word;
                break;
            }

            *dst_word++ = word0;
            dst = (char *)dst_word;
            src = (const char *)(src_word + 1);
            break;
        }
    }

    while ((*dst++ = *src++) != '\0')
    {
    }
    return ret;
}

int
strcmp(const char *lhs, const char *rhs)
{
    if ((((unsigned long)lhs | (unsigned long)rhs) & 3u) == 0u)
    {
        const unsigned int *lhs_word = (const unsigned int *)lhs;
        const unsigned int *rhs_word = (const unsigned int *)rhs;

        while (1)
        {
            unsigned int left0 = lhs_word[0];
            unsigned int right0 = rhs_word[0];
            unsigned int left1 = lhs_word[1];
            unsigned int right1 = rhs_word[1];

            if ((left0 == right0) && !YH_HAS_ZERO_BYTE(left0) &&
                (left1 == right1) && !YH_HAS_ZERO_BYTE(left1))
            {
                lhs_word += 2;
                rhs_word += 2;
                continue;
            }

            if ((left0 != right0) || YH_HAS_ZERO_BYTE(left0))
            {
                lhs = (const char *)lhs_word;
                rhs = (const char *)rhs_word;
                break;
            }

            lhs = (const char *)(lhs_word + 1);
            rhs = (const char *)(rhs_word + 1);
            break;
        }
    }

    while (*lhs && (*lhs == *rhs))
    {
        ++lhs;
        ++rhs;
    }
    return (int)((unsigned char)*lhs - (unsigned char)*rhs);
}

size_t
strlen(const char *text)
{
    size_t length = 0;
    while (text && text[length] != '\0')
    {
        ++length;
    }
    return length;
}

void *
memcpy(void *dst, const void *src, size_t count)
{
    unsigned char *      dst_bytes = (unsigned char *)dst;
    const unsigned char *src_bytes = (const unsigned char *)src;
    size_t               index;

    for (index = 0; index < count; ++index)
    {
        dst_bytes[index] = src_bytes[index];
    }
    return dst;
}

void *
memset(void *dst, int value, size_t count)
{
    unsigned char *dst_bytes = (unsigned char *)dst;
    size_t         index;

    for (index = 0; index < count; ++index)
    {
        dst_bytes[index] = (unsigned char)value;
    }
    return dst;
}
