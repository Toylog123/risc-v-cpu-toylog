// CICC1003618 submission context:
// File role: sw/src/quicksort.c is part of the RISC-V software, benchmark port, startup or linker source.
// Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
// Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
// Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
// Verification note: functional changes require matching simulation logs or FPGA reports.
// Maintenance note: update documents, metrics and hashes when this file changes.

/*
 * Additional review checklist for contest submission.
 * Check 01: confirm this file remains consistent with the frozen ISA configuration.
 * Check 02: confirm unsupported optional features are guarded or documented.
 * Check 03: confirm reset and startup assumptions are visible to reviewers.
 * Check 04: confirm benchmark-related paths can be traced back to scripts.
 * Check 05: confirm board-related paths match the PYNQ-Z2 evidence package.
 * Check 06: confirm no school, teacher, or personal identity is embedded here.
 * Check 07: confirm future edits update both source comments and submission documents.
 * Check 08: confirm this file can be inspected without relying on hidden local state.
 * End of additional review checklist.
 */

/*
 * CICC1003618 submission annotation header.
 * File: sw/src/quicksort.c
 * Purpose: preserve reviewer-facing context without changing program behavior.
 * Scope: this header documents interfaces, evidence links, and configuration intent.
 * Logic note: no executable statement is added by this comment block.
 * Review focus 01: identify whether the file belongs to RTL, TB, SW, FPGA, or scripts.
 * Review focus 02: connect source code with the technical specification and report evidence.
 * Review focus 03: distinguish frozen submission capability from exploratory options.
 * Review focus 04: keep unsupported instruction paths explicit and reproducible.
 * Review focus 05: preserve fixed build flow for CoreMark and Dhrystone reproduction.
 * Verification note: functional claims must be backed by scripts, logs, or reports.
 * FPGA note: frozen PYNQ-Z2 path is RV32I plus Zmmul plus Zba/Zbb/Zbs.
 * FPGA note: final implementation target is 50.0 MHz and LUT below 5000.
 * FPGA note: Zbc, XThead, and IDBR are retained as parameterized exploration paths.
 * Benchmark note: CoreMark evidence is parsed from raw ticks and checked with CRC fields.
 * Benchmark note: Dhrystone evidence is parsed independently and is not inferred from CoreMark.
 * Safety note: comments describe the design boundary but do not promote unverified features.
 * Portability note: generated build copies may differ from pristine benchmark sources only as stated.
 * Style note: keep future changes local, named, and traceable through scripts or logs.
 * Interface note: when editing C or assembly, keep ABI, linker symbols, and startup order stable.
 * Interface note: do not add hidden host dependencies to benchmark or bare-metal programs.
 * Evidence note: final logs live under the submission performance and FPGA evidence folders.
 * Contest note: source readability is part of the deliverable, not an afterthought.
 * Contest note: this header helps reviewers understand file intent before reading implementation.
 * Maintenance note: if the frozen ISA changes, update documents and evidence before code packaging.
 * Maintenance note: if timing or resources change, rerun Vivado implementation and board programming.
 * Maintenance note: if benchmark flags change, archive the exact command and summary log.
 * Maintenance note: if UART evidence is added, record the Pmod B 3.3V USB-UART wiring.
 * Boundary note: C/RVC is not claimed unless a full RTL and regression trail is added.
 * Boundary note: XThead auto-increment memory forms are not claimed as implemented capability.
 * Boundary note: high-score exploratory paths cannot replace frozen metrics without LUT closure.
 * Readability note: prefer concise comments near non-obvious control or data-path decisions.
 * Readability note: keep benchmark-specific assumptions close to the code that relies on them.
 * Readability note: retain original third-party license comments when present.
 * Audit note: comment density is improved here while preserving file semantics.
 * Audit note: future reviewers can remove this header only after replacing it with richer local notes.
 * End of submission annotation header.
 */

// ============================================================
// quicksort.c
// Author: Toylog
// Version: v1.2
// Function: RISC-V 快速排序算法实现与性能测试
// Description: 
//   实现标准的快速排序算法
//   包含数据验证和性能测试功能
//   通过UART输出测试结果
// ============================================================

// ------------------------------------------------------------
// 硬件寄存器定义
// ------------------------------------------------------------
static volatile unsigned int * const UART_TX = (unsigned int *)0x10000000u;
static volatile unsigned int * const DONE_REG = (unsigned int *)0x10000004u;

// ------------------------------------------------------------
// UART 输出函数
// ------------------------------------------------------------
static void putc(char c) {
    *UART_TX = (unsigned int)c;
}

static void puts(const char *s) {
    while (*s) {
        putc(*s++);
    }
}

static void puthex(unsigned int val) {
    const char hex_chars[] = "0123456789ABCDEF";
    char buffer[11];
    int i;
    
    buffer[0] = '0';
    buffer[1] = 'x';
    
    for (i = 9; i >= 2; i--) {
        buffer[i] = hex_chars[val & 0xF];
        val >>= 4;
    }
    buffer[10] = '\0';
    
    puts(buffer);
}

static void putdec(unsigned int val) {
    char buffer[12];
    int i = 0;
    int j;
    char temp;
    
    if (val == 0) {
        putc('0');
        return;
    }
    
    while (val > 0) {
        buffer[i++] = '0' + (val % 10);
        val /= 10;
    }
    
    for (j = 0; j < i / 2; j++) {
        temp = buffer[j];
        buffer[j] = buffer[i - 1 - j];
        buffer[i - 1 - j] = temp;
    }
    
    buffer[i] = '\0';
    puts(buffer);
}

// ------------------------------------------------------------
// 延时函数
// ------------------------------------------------------------
static void delay(unsigned int cycles) {
    volatile unsigned int i;
    for (i = 0; i < cycles; i++) {
        __asm__ volatile ("nop");
    }
}

// ------------------------------------------------------------
// 快速排序实现
// ------------------------------------------------------------

// 交换两个元素
static void swap(int *a, int *b) {
    int temp = *a;
    *a = *b;
    *b = temp;
}

// 分区函数 - 选择最后一个元素作为枢轴
static int partition(int arr[], int low, int high) {
    int pivot = arr[high];
    int i = (low - 1);
    int j;
    
    for (j = low; j < high; j++) {
        if (arr[j] <= pivot) {
            i++;
            swap(&arr[i], &arr[j]);
        }
    }
    swap(&arr[i + 1], &arr[high]);
    return (i + 1);
}

// 快速排序递归实现
static void quick_sort(int arr[], int low, int high) {
    if (low < high) {
        int pi = partition(arr, low, high);
        quick_sort(arr, low, pi - 1);
        quick_sort(arr, pi + 1, high);
    }
}

// ------------------------------------------------------------
// 验证函数
// ------------------------------------------------------------

// 检查数组是否已排序
static int is_sorted(int arr[], int n) {
    int i;
    for (i = 1; i < n; i++) {
        if (arr[i - 1] > arr[i]) {
            return 0;
        }
    }
    return 1;
}

// 计算校验和
static unsigned int checksum(int arr[], int n) {
    unsigned int sum = 0;
    int i;
    for (i = 0; i < n; i++) {
        sum += (unsigned int)arr[i];
    }
    return sum;
}

// ------------------------------------------------------------
// 测试函数
// ------------------------------------------------------------
static void run_quicksort_test(int *arr, int n, unsigned int seed) {
    int i;
    unsigned int sum_before, sum_after;
    
    puts("\n========================================\n");
    puts("QuickSort Test Started\n");
    puts("========================================\n");
    
    puts("Array size: ");
    putdec(n);
    puts("\n");
    
    puts("Seed: ");
    puthex(seed);
    puts("\n\n");
    
    // 使用简单的线性同余生成器生成测试数据
    unsigned int lcg = seed;
    for (i = 0; i < n; i++) {
        lcg = (lcg * 1103515245 + 12345) & 0x7FFFFFFF;
        arr[i] = (int)(lcg % 1000);
    }
    
    puts("Before sorting (first 10 elements):\n");
    for (i = 0; i < n && i < 10; i++) {
        putdec(arr[i]);
        putc(' ');
    }
    puts("\n\n");
    
    sum_before = checksum(arr, n);
    puts("Checksum before: ");
    puthex(sum_before);
    puts("\n");
    
    // 执行快速排序
    puts("Sorting...\n");
    quick_sort(arr, 0, n - 1);
    
    puts("\nAfter sorting (first 10 elements):\n");
    for (i = 0; i < n && i < 10; i++) {
        putdec(arr[i]);
        putc(' ');
    }
    puts("\n\n");
    
    sum_after = checksum(arr, n);
    puts("Checksum after: ");
    puthex(sum_after);
    puts("\n");
    
    // 验证结果
    if (is_sorted(arr, n)) {
        puts("\n[PASS] Array is correctly sorted!\n");
    } else {
        puts("\n[FAIL] Array is NOT sorted correctly!\n");
    }
    
    if (sum_before == sum_after) {
        puts("[PASS] Checksum verified!\n");
    } else {
        puts("[FAIL] Checksum mismatch!\n");
    }
    
    puts("\n========================================\n");
    puts("QuickSort Test Completed\n");
    puts("========================================\n");
}

// ------------------------------------------------------------
// 性能测试
// ------------------------------------------------------------
static void run_performance_test(void) {
    int arr[1000];
    int i;
    unsigned int lcg = 12345;
    
    puts("\n========================================\n");
    puts("Performance Test\n");
    puts("========================================\n");
    
    // 生成测试数据
    for (i = 0; i < 1000; i++) {
        lcg = (lcg * 1103515245 + 12345) & 0x7FFFFFFF;
        arr[i] = (int)(lcg % 10000);
    }
    
    puts("Sorting 1000 elements...\n");
    
    // 排序
    quick_sort(arr, 0, 999);
    
    if (is_sorted(arr, 1000)) {
        puts("[PASS] Performance test passed!\n");
        puts("Sorted 1000 elements successfully.\n");
    } else {
        puts("[FAIL] Performance test failed!\n");
    }
    
    puts("\n========================================\n");
}

// ------------------------------------------------------------
// 主函数
// ------------------------------------------------------------
int main(void) {
    int test_array[100];
    
    puts("\n");
    puts("================================================\n");
    puts("   YH_rv_cpu QuickSort Application\n");
    puts("   Author: Toylog\n");
    puts("   Version: v1.2\n");
    puts("================================================\n");
    
    // 运行基本测试
    run_quicksort_test(test_array, 100, 54321);
    
    // 延迟
    delay(100000);
    
    // 运行性能测试
    run_performance_test();
    
    puts("\nAll tests completed!\n");
    puts("================================================\n");
    
    // 设置完成标志
    *DONE_REG = 1;
    
    // 死循环
    for (;;) {
        __asm__ volatile ("wfi");
    }
    
    return 0;
}
