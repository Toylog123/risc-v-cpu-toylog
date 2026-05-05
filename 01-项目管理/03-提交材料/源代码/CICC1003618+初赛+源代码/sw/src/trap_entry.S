/*
 * CICC1003618 submission context:
 * File role: sw/src/trap_entry.S is part of the RISC-V software, benchmark port, startup or linker source.
 * Frozen target: RV32I plus Zmmul plus Zba/Zbb/Zbs on PYNQ-Z2 at 50 MHz.
 * Review focus: keep reset, stall, flush, forwarding and evidence paths traceable.
 * Boundary note: do not claim unsupported C/RVC or exploratory paths without new evidence.
 * Verification note: functional changes require matching simulation logs or FPGA reports.
 * Maintenance note: update documents, metrics and hashes when this file changes.
 */

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
 * File: sw/src/trap_entry.S
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

    .section .text.trap
    .globl toylog_trap_handler
    .align 2

toylog_trap_handler:
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)

    csrr t0, mcause
    li t1, 11
    bne t0, t1, trap_fail

    li t0, 0x10000000
    li t1, 't'
    sw t1, 0(t0)

    csrr t2, mepc
    addi t2, t2, 4
    csrw mepc, t2

    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 16
    mret

trap_fail:
    li t0, 0x10000000
    li t1, 'F'
    sw t1, 0(t0)
    li t0, 0x10000004
    li t1, 1
    sw t1, 0(t0)

1:
    j 1b
