typedef unsigned char  u8;
typedef unsigned short u16;
typedef unsigned int   u32;

static volatile u32 *const UART_TX = (u32 *)0x10000000u;
static volatile u32 *const DONE_REG = (u32 *)0x10000004u;
static volatile u32 *const TIMER_LO = (u32 *)0x10000008u;
static volatile u32 *const TIMER_HI = (u32 *)0x1000000cu;
static volatile u32 *const TIMER_CTRL = (u32 *)0x10000018u;

#define BUF_BYTES 1024u
#define WORD_COUNT 256u
#define MAT_N 8u

static u8  buffer_a[BUF_BYTES];
static u8  buffer_b[BUF_BYTES];
static u32 words[WORD_COUNT];
static u16 next_idx[WORD_COUNT];
static u32 mat_a[MAT_N][MAT_N];
static u32 mat_b[MAT_N][MAT_N];
static u32 mat_c[MAT_N][MAT_N];
static volatile u32 demo_sink;

static void uart_putc(char ch)
{
    *UART_TX = (u32)(u8)ch;
}

static void uart_puts(const char *text)
{
    while (*text) {
        uart_putc(*text++);
    }
}

static void uart_put_hex32(u32 value)
{
    static const char digits[] = "0123456789abcdef";
    int shift;

    uart_puts("0x");
    for (shift = 28; shift >= 0; shift -= 4) {
        uart_putc(digits[(value >> shift) & 0xfu]);
    }
}

static u32 read_timer32(void)
{
    u32 hi0;
    u32 lo;
    u32 hi1;

    do {
        hi0 = *TIMER_HI;
        lo = *TIMER_LO;
        hi1 = *TIMER_HI;
    } while (hi0 != hi1);

    return lo;
}

static void init_data(void)
{
    u32 i;
    u32 r;
    u32 c;

    for (i = 0; i < BUF_BYTES; ++i) {
        buffer_a[i] = (u8)((i * 37u + 0x5au + (i >> 3)) & 0xffu);
        buffer_b[i] = 0u;
    }

    for (i = 0; i < WORD_COUNT; ++i) {
        words[i] = 0x9e3779b9u ^ (i * 0x10204081u);
        next_idx[i] = (u16)((i * 17u + 23u) & 0xffu);
    }

    for (r = 0; r < MAT_N; ++r) {
        for (c = 0; c < MAT_N; ++c) {
            mat_a[r][c] = ((r + 1u) * (c + 3u) + 7u) & 0xffu;
            mat_b[r][c] = ((r * 5u + c * 11u + 13u) & 0xffu);
            mat_c[r][c] = 0u;
        }
    }
}

static u32 workload_crc32(void)
{
    u32 crc = 0xffffffffu;
    u32 i;
    int bit;

    for (i = 0; i < 512u; ++i) {
        crc ^= buffer_a[i];
        for (bit = 0; bit < 8; ++bit) {
            u32 mask = 0u - (crc & 1u);
            crc = (crc >> 1) ^ (0xedb88320u & mask);
        }
    }

    return ~crc;
}

static u32 workload_matrix(void)
{
    u32 r;
    u32 c;
    u32 k;
    u32 sum = 0u;

    for (r = 0; r < MAT_N; ++r) {
        for (c = 0; c < MAT_N; ++c) {
            u32 acc = 0u;
            for (k = 0; k < MAT_N; ++k) {
                acc += mat_a[r][k] * mat_b[k][c];
            }
            mat_c[r][c] = acc;
        }
    }

    for (r = 0; r < MAT_N; ++r) {
        for (c = 0; c < MAT_N; ++c) {
            sum = (sum << 5) ^ (sum >> 27) ^ mat_c[r][c];
        }
    }

    return sum;
}

static u32 workload_memory(void)
{
    u32 pass;
    u32 i;
    u32 sum = 0u;

    for (i = 0; i < BUF_BYTES; ++i) {
        buffer_b[i] = 0xa5u;
    }

    for (pass = 0; pass < 4u; ++pass) {
        for (i = 0; i < BUF_BYTES; ++i) {
            buffer_b[i] = (u8)(buffer_a[(i + pass * 13u) & (BUF_BYTES - 1u)] ^ pass);
        }
    }

    for (i = 0; i < BUF_BYTES; ++i) {
        sum += ((u32)buffer_b[i]) * (i + 1u);
    }

    return sum;
}

static u32 workload_branch(void)
{
    u32 i;
    u32 state = 0x13579bdfu;

    for (i = 0; i < 4096u; ++i) {
        if (((state ^ i) & 7u) < 3u) {
            state = (state << 3) ^ (state >> 5) ^ 0xa5a55a5au ^ i;
        } else if ((state & 0x80000000u) != 0u) {
            state = state + (i * 33u) + 0x10203u;
        } else {
            state = state ^ (i * 0x45d9f3bu);
        }
    }

    return state;
}

static u32 workload_load_use(void)
{
    u32 i;
    u32 idx = 7u;
    u32 acc = 0x2468ace0u;

    for (i = 0; i < 2048u; ++i) {
        u32 value;
        u32 mix;

        idx = next_idx[idx];
        value = words[idx];
        mix = acc + value;
        acc = (mix << 7) | (mix >> 25);
        acc ^= idx * 0x9e37u;
        words[idx] = value + acc + i;
    }

    return acc;
}

static u32 run_section(const char *name, u32 numerator, u32 expected, u32 (*fn)(void), u32 *total_cycles)
{
    u32 start;
    u32 stop;
    u32 cycles;
    u32 value;

    uart_puts(name);
    uart_puts(" begin\n");

    start = read_timer32();
    value = fn();
    stop = read_timer32();
    cycles = stop - start;
    *total_cycles += cycles;
    demo_sink ^= value;

    uart_puts(name);
    uart_puts(" cycles=");
    uart_put_hex32(cycles);
    uart_puts(" units=");
    uart_put_hex32(numerator);
    uart_puts(" checksum=");
    uart_put_hex32(value);
    uart_putc(' ');
    uart_puts((value == expected) ? "PASS\n" : "FAIL\n");

    return value;
}

int main(void)
{
    u32 total = 0u;
    u32 final = 0x31415926u;
    u32 crc_value;
    u32 mat_value;
    u32 mem_value;
    u32 branch_value;
    u32 load_value;

    *DONE_REG = 0u;
    *TIMER_CTRL = 2u;
    init_data();

    uart_puts("YH_rv_cpu Performance Demo Suite\n");
    uart_puts("baseline=freeze-timingclosed-cpu25-20260605 cpu_clk=25MHz\n");

    crc_value = run_section("CRC32", 512u, 0x3287d9afu, workload_crc32, &total);
    mat_value = run_section("MATMUL8", 1024u, 0x44da4cfbu, workload_matrix, &total);
    mem_value = run_section("MEMCPYFILL", 4096u, 0x04053d00u, workload_memory, &total);
    branch_value = run_section("BRANCH", 4096u, 0x8bad48bcu, workload_branch, &total);
    load_value = run_section("LOADUSE", 2048u, 0x76962aa8u, workload_load_use, &total);

    final = (final << 5) ^ (final >> 27) ^ crc_value;
    final = (final << 5) ^ (final >> 27) ^ mat_value;
    final = (final << 5) ^ (final >> 27) ^ mem_value;
    final = (final << 5) ^ (final >> 27) ^ branch_value;
    final = (final << 5) ^ (final >> 27) ^ load_value;

    uart_puts("PERF_DEMO ");
    if (final == 0xe727358bu) {
        uart_puts("PASS checksum=");
    } else {
        uart_puts("FAIL checksum=");
    }
    uart_put_hex32(final);
    uart_puts(" total_cycles=");
    uart_put_hex32(total);
    uart_putc('\n');

    *DONE_REG = 1u;
    for (;;) {
        __asm__ volatile("wfi");
    }
}
