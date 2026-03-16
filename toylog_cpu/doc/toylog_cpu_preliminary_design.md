# toylog_cpu Preliminary Design

## 1. Project Position

`toylog_cpu` is the formal implementation name for the Qixingwei competition topic:
`RISC-V high-performance CPU design and FPGA verification`.

The current objective is to build an original competition-oriented CPU baseline that can
grow into the final submission without depending on copied open-source core RTL.

## 2. Phase-1 Objective

Phase-1 is the engineering baseline phase, not the final submission.

Current phase targets:

- self-written `RV32I` integer core baseline
- 5-stage in-order single-issue pipeline baseline
- clean decoder / ALU / register file / branch / load-store path
- smoke-test-oriented verification path
- firmware build path for later SoC integration

## 3. Architecture Choice

### 3.1 ISA

- baseline: `RV32I`
- planned next extension: `RV32M`
- reason: reduce bring-up risk before optimization and FPGA closure

### 3.2 Pipeline

The baseline microarchitecture is a 5-stage pipeline:

1. IF: instruction fetch and next-PC selection
2. ID: decode and register file read
3. EX: ALU, branch decision, jump target, address generation
4. MEM: load extraction and store write-enable generation
5. WB: final register write-back selection

### 3.3 Hazard Strategy

The current baseline already includes:

- one-cycle bubble insertion for load-use hazards
- EX/MEM forwarding for ALU-producing instructions
- MEM/WB forwarding for later results
- redirect flush for taken branch and jump

### 3.4 Memory Interface

- instruction memory: separate read interface
- data memory: separate read/write interface
- reason: matches the topic recommendation to avoid structural conflicts

## 4. Current Module Set

- `toylog_cpu`: 5-stage top-level core with pipeline registers
- `toylog_cpu_if_stage`
- `toylog_cpu_id_stage`
- `toylog_cpu_ex_stage`
- `toylog_cpu_mem_stage`
- `toylog_cpu_wb_stage`
- `toylog_cpu_hazard_unit`
- `toylog_cpu_decoder`
- `toylog_cpu_alu`
- `toylog_cpu_regfile`

## 5. Planned Competition Optimizations

The topic requires at least two optimization items. The initial plan is:

1. forwarding / bypass network strengthening
2. branch handling optimization, starting from static policy and leaving room for a small predictor

These two directions are aligned with the topic suggestions and are realistic for the
first competition-ready version.

## 6. Toolchain Plan

### 6.1 Current Phase

- `iverilog` for fast syntax validation
- `xsim`, `ModelSim`, or `Questa` for more stable functional simulation on Windows
- `riscv32-unknown-elf-gcc` or `riscv64-unknown-elf-gcc` for bare-metal firmware build
- matching `objdump` and `objcopy`

### 6.2 FPGA Phase

- `Vivado` for synthesis, implementation, bitstream generation, and timing closure
- UART / JTAG tools for board debug

### 6.3 Later Validation

- `riscv-tests`
- `CoreMark`

## 7. Software Bring-Up Baseline

The reserved early memory map is:

- ROM: `0x0000_0000`
- RAM: `0x0000_4000`
- UART TX register: `0x1000_0000`
- DONE register: `0x1000_0004`

This is only the early planning baseline and can be refined when the SoC wrapper is added.

## 8. Current Risks

- the current pipeline is only the first baseline and has not yet been run through `riscv-tests`
- CSR, interrupt, and timer support are not present yet
- FPGA top-level integration is not ready until a SoC wrapper is added
- performance data cannot be collected before firmware and FPGA bring-up

## 9. Immediate Next Tasks

1. add CSR, timer, and trap plumbing
2. add a small SoC wrapper with ROM, RAM, UART, and timer
3. run a firmware image from the SoC wrapper
4. connect the core to `riscv-tests`
5. integrate CoreMark and resource / frequency measurement
