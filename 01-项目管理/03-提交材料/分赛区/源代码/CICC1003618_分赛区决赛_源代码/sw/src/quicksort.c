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
