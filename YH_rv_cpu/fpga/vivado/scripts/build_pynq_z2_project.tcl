set script_dir [file dirname [file normalize [info script]]]
set vivado_dir [file dirname $script_dir]
set fpga_dir [file dirname $vivado_dir]
set project_root [file dirname $fpga_dir]
set repo_root [file dirname $project_root]

set build_dir [file normalize [file join $repo_root project]]
set report_dir [file join $build_dir reports]
set project_name YH_rv_cpu_pynq_z2
set top_name YH_rv_cpu_fpga_top
set part_name xc7z020clg400-1
set flow_mode synth
set rom_init_hex ""
set rom_init_mem32_hex ""
set ram_base_override ""
set rom_bytes_override ""
set ram_bytes_override ""
set input_clock_period_ns 8.000
set synth_retiming 1
set synth_no_timing_driven 0
set quick_util_only 0
set cpu_clk_freq_hz 62500000
set use_clk_mmcm_62m5 1
set use_clk_mmcm_50m 0
set enable_m_extension 0
set enable_zmmul_extension 0
set enable_bitmanip_extension 0
set enable_zbc_extension 0
set enable_zicond_extension 0
set enable_zbkb_extension 0
set enable_xthead_extension 0
set enable_xthead_crc_extension 1
set enable_xthead_mul_extension 1
set enable_xthead_cond_move 0
set enable_xthead_addsl_extension 0
set enable_xthead_mempair_extension 1
set enable_xthead_base_update_extension 1
set enable_id_branch_ex_forward 0
set enable_id_branch_fold 0
set enable_id_branch_fold_next_cache 1
set enable_id_branch_not_taken_load_fold 0
set enable_id_alu_pair_fold 0
set enable_id_alu_dep_fold 0
set enable_redirect_target_cache 1
set enable_redirect_cache_regular_lookup 1
set enable_fetch_redirect_reuse 0
set redirect_cache_entries 1024
set redirect_cache_xor_index 0
set enable_dynamic_branch_predict 0
set branch_bht_entries 64
set branch_static_predict_mode 0
set dmem_negedge_read 0
set dmem_read_preissue 0
set dcache_en 0
set dcache_size_bytes 4096
set enable_dcache_load_use_spec 0
set enable_dcache_next_prefetch 0
set enable_dcache_word_only 0
set icache_en 0

if {[llength $argv] >= 1} {
    set flow_mode [lindex $argv 0]
}

if {[info exists ::env(ROM_INIT_HEX_OVERRIDE)] && $::env(ROM_INIT_HEX_OVERRIDE) ne ""} {
    set rom_init_hex [file normalize $::env(ROM_INIT_HEX_OVERRIDE)]
}
if {[info exists ::env(ROM_INIT_MEM32_HEX_OVERRIDE)] && $::env(ROM_INIT_MEM32_HEX_OVERRIDE) ne ""} {
    set rom_init_mem32_hex [file normalize $::env(ROM_INIT_MEM32_HEX_OVERRIDE)]
}
if {[info exists ::env(RAM_BASE_OVERRIDE)] && $::env(RAM_BASE_OVERRIDE) ne ""} {
    set ram_base_override $::env(RAM_BASE_OVERRIDE)
}
if {[info exists ::env(ROM_BYTES_OVERRIDE)] && $::env(ROM_BYTES_OVERRIDE) ne ""} {
    set rom_bytes_override $::env(ROM_BYTES_OVERRIDE)
}
if {[info exists ::env(RAM_BYTES_OVERRIDE)] && $::env(RAM_BYTES_OVERRIDE) ne ""} {
    set ram_bytes_override $::env(RAM_BYTES_OVERRIDE)
}
if {[info exists ::env(PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE)] && $::env(PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE) ne ""} {
    set input_clock_period_ns $::env(PYNQ_INPUT_CLOCK_PERIOD_NS_OVERRIDE)
}
if {[info exists ::env(PYNQ_SYNTH_RETIMING_OVERRIDE)] && $::env(PYNQ_SYNTH_RETIMING_OVERRIDE) ne ""} {
    set synth_retiming $::env(PYNQ_SYNTH_RETIMING_OVERRIDE)
}
if {[info exists ::env(PYNQ_SYNTH_NO_TIMING_DRIVEN_OVERRIDE)] && $::env(PYNQ_SYNTH_NO_TIMING_DRIVEN_OVERRIDE) ne ""} {
    set synth_no_timing_driven $::env(PYNQ_SYNTH_NO_TIMING_DRIVEN_OVERRIDE)
}
if {[info exists ::env(PYNQ_QUICK_UTIL_ONLY_OVERRIDE)] && $::env(PYNQ_QUICK_UTIL_ONLY_OVERRIDE) ne ""} {
    set quick_util_only $::env(PYNQ_QUICK_UTIL_ONLY_OVERRIDE)
}
if {[info exists ::env(PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE)] && $::env(PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE) ne ""} {
    set cpu_clk_freq_hz $::env(PYNQ_CPU_CLK_FREQ_HZ_OVERRIDE)
}
if {[info exists ::env(PYNQ_USE_CLK_MMCM_62M5_OVERRIDE)] && $::env(PYNQ_USE_CLK_MMCM_62M5_OVERRIDE) ne ""} {
    set use_clk_mmcm_62m5 $::env(PYNQ_USE_CLK_MMCM_62M5_OVERRIDE)
}
if {[info exists ::env(PYNQ_USE_CLK_MMCM_50M_OVERRIDE)] && $::env(PYNQ_USE_CLK_MMCM_50M_OVERRIDE) ne ""} {
    set use_clk_mmcm_50m $::env(PYNQ_USE_CLK_MMCM_50M_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_M_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_M_EXTENSION_OVERRIDE) ne ""} {
    set enable_m_extension $::env(PYNQ_ENABLE_M_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE) ne ""} {
    set enable_zmmul_extension $::env(PYNQ_ENABLE_ZMMUL_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE) ne ""} {
    set enable_bitmanip_extension $::env(PYNQ_ENABLE_BITMANIP_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE) ne ""} {
    set enable_zbc_extension $::env(PYNQ_ENABLE_ZBC_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE) ne ""} {
    set enable_zicond_extension $::env(PYNQ_ENABLE_ZICOND_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE) ne ""} {
    set enable_zbkb_extension $::env(PYNQ_ENABLE_ZBKB_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE) ne ""} {
    set enable_xthead_extension $::env(PYNQ_ENABLE_XTHEAD_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_XTHEAD_CRC_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_XTHEAD_CRC_EXTENSION_OVERRIDE) ne ""} {
    set enable_xthead_crc_extension $::env(PYNQ_ENABLE_XTHEAD_CRC_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_XTHEAD_MUL_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_XTHEAD_MUL_EXTENSION_OVERRIDE) ne ""} {
    set enable_xthead_mul_extension $::env(PYNQ_ENABLE_XTHEAD_MUL_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE)] && $::env(PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE) ne ""} {
    set enable_xthead_cond_move $::env(PYNQ_ENABLE_XTHEAD_COND_MOVE_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_XTHEAD_ADDSL_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_XTHEAD_ADDSL_EXTENSION_OVERRIDE) ne ""} {
    set enable_xthead_addsl_extension $::env(PYNQ_ENABLE_XTHEAD_ADDSL_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_XTHEAD_MEMPAIR_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_XTHEAD_MEMPAIR_EXTENSION_OVERRIDE) ne ""} {
    set enable_xthead_mempair_extension $::env(PYNQ_ENABLE_XTHEAD_MEMPAIR_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_XTHEAD_BASE_UPDATE_EXTENSION_OVERRIDE)] && $::env(PYNQ_ENABLE_XTHEAD_BASE_UPDATE_EXTENSION_OVERRIDE) ne ""} {
    set enable_xthead_base_update_extension $::env(PYNQ_ENABLE_XTHEAD_BASE_UPDATE_EXTENSION_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE)] && $::env(PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE) ne ""} {
    set enable_id_branch_ex_forward $::env(PYNQ_ENABLE_ID_BRANCH_EX_FORWARD_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ID_BRANCH_FOLD_OVERRIDE)] && $::env(PYNQ_ENABLE_ID_BRANCH_FOLD_OVERRIDE) ne ""} {
    set enable_id_branch_fold $::env(PYNQ_ENABLE_ID_BRANCH_FOLD_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ID_BRANCH_FOLD_NEXT_CACHE_OVERRIDE)] && $::env(PYNQ_ENABLE_ID_BRANCH_FOLD_NEXT_CACHE_OVERRIDE) ne ""} {
    set enable_id_branch_fold_next_cache $::env(PYNQ_ENABLE_ID_BRANCH_FOLD_NEXT_CACHE_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD_OVERRIDE)] && $::env(PYNQ_ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD_OVERRIDE) ne ""} {
    set enable_id_branch_not_taken_load_fold $::env(PYNQ_ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ID_ALU_PAIR_FOLD_OVERRIDE)] && $::env(PYNQ_ENABLE_ID_ALU_PAIR_FOLD_OVERRIDE) ne ""} {
    set enable_id_alu_pair_fold $::env(PYNQ_ENABLE_ID_ALU_PAIR_FOLD_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_ID_ALU_DEP_FOLD_OVERRIDE)] && $::env(PYNQ_ENABLE_ID_ALU_DEP_FOLD_OVERRIDE) ne ""} {
    set enable_id_alu_dep_fold $::env(PYNQ_ENABLE_ID_ALU_DEP_FOLD_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_REDIRECT_TARGET_CACHE_OVERRIDE)] && $::env(PYNQ_ENABLE_REDIRECT_TARGET_CACHE_OVERRIDE) ne ""} {
    set enable_redirect_target_cache $::env(PYNQ_ENABLE_REDIRECT_TARGET_CACHE_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP_OVERRIDE)] && $::env(PYNQ_ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP_OVERRIDE) ne ""} {
    set enable_redirect_cache_regular_lookup $::env(PYNQ_ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_FETCH_REDIRECT_REUSE_OVERRIDE)] && $::env(PYNQ_ENABLE_FETCH_REDIRECT_REUSE_OVERRIDE) ne ""} {
    set enable_fetch_redirect_reuse $::env(PYNQ_ENABLE_FETCH_REDIRECT_REUSE_OVERRIDE)
}
if {[info exists ::env(PYNQ_REDIRECT_CACHE_ENTRIES_OVERRIDE)] && $::env(PYNQ_REDIRECT_CACHE_ENTRIES_OVERRIDE) ne ""} {
    set redirect_cache_entries $::env(PYNQ_REDIRECT_CACHE_ENTRIES_OVERRIDE)
}
if {[info exists ::env(PYNQ_REDIRECT_CACHE_XOR_INDEX_OVERRIDE)] && $::env(PYNQ_REDIRECT_CACHE_XOR_INDEX_OVERRIDE) ne ""} {
    set redirect_cache_xor_index $::env(PYNQ_REDIRECT_CACHE_XOR_INDEX_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_DYNAMIC_BRANCH_PREDICT_OVERRIDE)] && $::env(PYNQ_ENABLE_DYNAMIC_BRANCH_PREDICT_OVERRIDE) ne ""} {
    set enable_dynamic_branch_predict $::env(PYNQ_ENABLE_DYNAMIC_BRANCH_PREDICT_OVERRIDE)
}
if {[info exists ::env(PYNQ_BRANCH_BHT_ENTRIES_OVERRIDE)] && $::env(PYNQ_BRANCH_BHT_ENTRIES_OVERRIDE) ne ""} {
    set branch_bht_entries $::env(PYNQ_BRANCH_BHT_ENTRIES_OVERRIDE)
}
if {[info exists ::env(PYNQ_BRANCH_STATIC_PREDICT_MODE_OVERRIDE)] && $::env(PYNQ_BRANCH_STATIC_PREDICT_MODE_OVERRIDE) ne ""} {
    set branch_static_predict_mode $::env(PYNQ_BRANCH_STATIC_PREDICT_MODE_OVERRIDE)
}
if {[info exists ::env(PYNQ_DMEM_NEGEDGE_READ_OVERRIDE)] && $::env(PYNQ_DMEM_NEGEDGE_READ_OVERRIDE) ne ""} {
    set dmem_negedge_read $::env(PYNQ_DMEM_NEGEDGE_READ_OVERRIDE)
}
if {[info exists ::env(PYNQ_DMEM_READ_PREISSUE_OVERRIDE)] && $::env(PYNQ_DMEM_READ_PREISSUE_OVERRIDE) ne ""} {
    set dmem_read_preissue $::env(PYNQ_DMEM_READ_PREISSUE_OVERRIDE)
}
if {[info exists ::env(PYNQ_DCACHE_EN_OVERRIDE)] && $::env(PYNQ_DCACHE_EN_OVERRIDE) ne ""} {
    set dcache_en $::env(PYNQ_DCACHE_EN_OVERRIDE)
}
if {[info exists ::env(PYNQ_DCACHE_SIZE_BYTES_OVERRIDE)] && $::env(PYNQ_DCACHE_SIZE_BYTES_OVERRIDE) ne ""} {
    set dcache_size_bytes $::env(PYNQ_DCACHE_SIZE_BYTES_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_DCACHE_LOAD_USE_SPEC_OVERRIDE)] && $::env(PYNQ_ENABLE_DCACHE_LOAD_USE_SPEC_OVERRIDE) ne ""} {
    set enable_dcache_load_use_spec $::env(PYNQ_ENABLE_DCACHE_LOAD_USE_SPEC_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_DCACHE_NEXT_PREFETCH_OVERRIDE)] && $::env(PYNQ_ENABLE_DCACHE_NEXT_PREFETCH_OVERRIDE) ne ""} {
    set enable_dcache_next_prefetch $::env(PYNQ_ENABLE_DCACHE_NEXT_PREFETCH_OVERRIDE)
}
if {[info exists ::env(PYNQ_ENABLE_DCACHE_WORD_ONLY_OVERRIDE)] && $::env(PYNQ_ENABLE_DCACHE_WORD_ONLY_OVERRIDE) ne ""} {
    set enable_dcache_word_only $::env(PYNQ_ENABLE_DCACHE_WORD_ONLY_OVERRIDE)
}
if {[info exists ::env(PYNQ_ICACHE_EN_OVERRIDE)] && $::env(PYNQ_ICACHE_EN_OVERRIDE) ne ""} {
    set icache_en $::env(PYNQ_ICACHE_EN_OVERRIDE)
}

set clock_tag [string map {. p} $input_clock_period_ns]
set cpu_clk_tag direct125
if {$use_clk_mmcm_62m5 ne "0"} {
    set cpu_clk_tag cpu62p5
}
if {$use_clk_mmcm_50m ne "0"} {
    set cpu_clk_tag cpu50
}
if {$cpu_clk_tag eq "cpu62p5"} {
    set report_dir [file join $report_dir pynq_z2_sysclk_${clock_tag}ns]
} else {
    set report_dir [file join $report_dir pynq_z2_sysclk_${clock_tag}ns_${cpu_clk_tag}]
}
set bitstream_file [file join $build_dir ${project_name}_sysclk_${clock_tag}ns_${cpu_clk_tag}.bit]

set rtl_dir [file join $project_root rtl]
set fpga_src_dir [file join $vivado_dir src]
set constr_file [file join $vivado_dir constraints pynq_z2_template.xdc]
set clock_constr_file [file join $build_dir pynq_z2_clock_${clock_tag}.xdc]
set rtl_files [lsort [glob -nocomplain [file join $rtl_dir *.v]]]
set fpga_files [lsort [glob -nocomplain [file join $fpga_src_dir *.v]]]

if {[llength $rtl_files] == 0} {
    error "No RTL source files found under $rtl_dir"
}

file mkdir $build_dir
file mkdir $report_dir
puts "INFO: Board = PYNQ-Z2"
puts "INFO: Flow mode = $flow_mode"
puts "INFO: Input clock period = ${input_clock_period_ns} ns"
puts "INFO: SYNTH_RETIMING = ${synth_retiming}"
puts "INFO: SYNTH_NO_TIMING_DRIVEN = ${synth_no_timing_driven}"
puts "INFO: QUICK_UTIL_ONLY = ${quick_util_only}"
puts "INFO: CPU clock frequency generic = ${cpu_clk_freq_hz} Hz"
puts "INFO: USE_CLK_MMCM_62M5 = ${use_clk_mmcm_62m5}"
puts "INFO: USE_CLK_MMCM_50M = ${use_clk_mmcm_50m}"
puts "INFO: ENABLE_M_EXTENSION = ${enable_m_extension}"
puts "INFO: ENABLE_ZMMUL_EXTENSION = ${enable_zmmul_extension}"
puts "INFO: ENABLE_BITMANIP_EXTENSION = ${enable_bitmanip_extension}"
puts "INFO: ENABLE_ZBC_EXTENSION = ${enable_zbc_extension}"
puts "INFO: ENABLE_ZICOND_EXTENSION = ${enable_zicond_extension}"
puts "INFO: ENABLE_ZBKB_EXTENSION = ${enable_zbkb_extension}"
puts "INFO: ENABLE_XTHEAD_EXTENSION = ${enable_xthead_extension}"
puts "INFO: ENABLE_XTHEAD_CRC_EXTENSION = ${enable_xthead_crc_extension}"
puts "INFO: ENABLE_XTHEAD_MUL_EXTENSION = ${enable_xthead_mul_extension}"
puts "INFO: ENABLE_XTHEAD_COND_MOVE = ${enable_xthead_cond_move}"
puts "INFO: ENABLE_XTHEAD_ADDSL_EXTENSION = ${enable_xthead_addsl_extension}"
puts "INFO: ENABLE_XTHEAD_MEMPAIR_EXTENSION = ${enable_xthead_mempair_extension}"
puts "INFO: ENABLE_XTHEAD_BASE_UPDATE_EXTENSION = ${enable_xthead_base_update_extension}"
puts "INFO: ENABLE_ID_BRANCH_EX_FORWARD = ${enable_id_branch_ex_forward}"
puts "INFO: ENABLE_ID_BRANCH_FOLD = ${enable_id_branch_fold}"
puts "INFO: ENABLE_ID_BRANCH_FOLD_NEXT_CACHE = ${enable_id_branch_fold_next_cache}"
puts "INFO: ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD = ${enable_id_branch_not_taken_load_fold}"
puts "INFO: ENABLE_ID_ALU_PAIR_FOLD = ${enable_id_alu_pair_fold}"
puts "INFO: ENABLE_ID_ALU_DEP_FOLD = ${enable_id_alu_dep_fold}"
puts "INFO: ENABLE_REDIRECT_TARGET_CACHE = ${enable_redirect_target_cache}"
puts "INFO: ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP = ${enable_redirect_cache_regular_lookup}"
puts "INFO: ENABLE_FETCH_REDIRECT_REUSE = ${enable_fetch_redirect_reuse}"
puts "INFO: REDIRECT_CACHE_ENTRIES = ${redirect_cache_entries}"
puts "INFO: REDIRECT_CACHE_XOR_INDEX = ${redirect_cache_xor_index}"
puts "INFO: ENABLE_DYNAMIC_BRANCH_PREDICT = ${enable_dynamic_branch_predict}"
puts "INFO: BRANCH_BHT_ENTRIES = ${branch_bht_entries}"
puts "INFO: BRANCH_STATIC_PREDICT_MODE = ${branch_static_predict_mode}"
puts "INFO: DMEM_NEGEDGE_READ = ${dmem_negedge_read}"
puts "INFO: DMEM_READ_PREISSUE = ${dmem_read_preissue}"
puts "INFO: DCACHE_EN = ${dcache_en}"
puts "INFO: DCACHE_SIZE_BYTES = ${dcache_size_bytes}"
puts "INFO: ENABLE_DCACHE_LOAD_USE_SPEC = ${enable_dcache_load_use_spec}"
puts "INFO: ENABLE_DCACHE_NEXT_PREFETCH = ${enable_dcache_next_prefetch}"
puts "INFO: ENABLE_DCACHE_WORD_ONLY = ${enable_dcache_word_only}"
puts "INFO: ICACHE_EN = ${icache_en}"

proc add_project_files {rtl_files fpga_files constr_file rtl_dir} {
    add_files -norecurse $rtl_files
    if {[llength $fpga_files] > 0} {
        add_files -norecurse $fpga_files
    }
    if {[file exists $constr_file]} {
        add_files -fileset constrs_1 -norecurse $constr_file
    }
    set_property include_dirs [list $rtl_dir] [current_fileset]
    update_compile_order -fileset sources_1
}

proc run_checked {label command_body} {
    puts "STEP: $label BEGIN"
    if {[catch {uplevel 1 $command_body} result options]} {
        puts stderr "ERROR: $label FAILED"
        puts stderr $result
        if {[dict exists $options -errorinfo]} {
            puts stderr [dict get $options -errorinfo]
        }
        exit 1
    }
    puts "STEP: $label DONE"
}

if {$flow_mode eq "project"} {
    run_checked "create_project" [list create_project $project_name $build_dir -force -part $part_name]
    set_property target_language Verilog [current_project]
    set_property default_lib xil_defaultlib [current_project]
    add_project_files $rtl_files $fpga_files $constr_file $rtl_dir
    puts "INFO: Vivado project skeleton generated at $build_dir"
    close_project
    exit 0
}

if {$flow_mode ne "synth" && $flow_mode ne "impl"} {
    error "Unsupported flow mode: $flow_mode"
}

run_checked "read_rtl" [list read_verilog -sv $rtl_files]

if {[llength $fpga_files] > 0} {
    run_checked "read_fpga_sources" [list read_verilog -sv $fpga_files]
}

if {[file exists $constr_file]} {
    run_checked "read_constraints" [list read_xdc $constr_file]
}

set clock_fd [open $clock_constr_file w]
puts $clock_fd [format {create_clock -name pynq_sys_clk -period %s [get_ports CLK100MHZ]} $input_clock_period_ns]
close $clock_fd
run_checked "read_clock_constraints" [list read_xdc $clock_constr_file]

set synth_cmd [list synth_design -top $top_name -part $part_name -flatten_hierarchy rebuilt -fanout_limit 32]
if {$synth_retiming ne "0"} {
    lappend synth_cmd -retiming
}
if {$synth_no_timing_driven ne "0"} {
    lappend synth_cmd -no_timing_driven
}
lappend synth_cmd -generic "CLK_FREQ_HZ=$cpu_clk_freq_hz"
lappend synth_cmd -generic "USE_CLK_MMCM_62M5=$use_clk_mmcm_62m5"
lappend synth_cmd -generic "USE_CLK_MMCM_50M=$use_clk_mmcm_50m"
lappend synth_cmd -generic "ENABLE_M_EXTENSION=$enable_m_extension"
lappend synth_cmd -generic "ENABLE_ZMMUL_EXTENSION=$enable_zmmul_extension"
lappend synth_cmd -generic "ENABLE_BITMANIP_EXTENSION=$enable_bitmanip_extension"
lappend synth_cmd -generic "ENABLE_ZBC_EXTENSION=$enable_zbc_extension"
lappend synth_cmd -generic "ENABLE_ZICOND_EXTENSION=$enable_zicond_extension"
lappend synth_cmd -generic "ENABLE_ZBKB_EXTENSION=$enable_zbkb_extension"
lappend synth_cmd -generic "ENABLE_XTHEAD_EXTENSION=$enable_xthead_extension"
lappend synth_cmd -generic "ENABLE_XTHEAD_CRC_EXTENSION=$enable_xthead_crc_extension"
lappend synth_cmd -generic "ENABLE_XTHEAD_MUL_EXTENSION=$enable_xthead_mul_extension"
lappend synth_cmd -generic "ENABLE_XTHEAD_COND_MOVE=$enable_xthead_cond_move"
lappend synth_cmd -generic "ENABLE_XTHEAD_ADDSL_EXTENSION=$enable_xthead_addsl_extension"
lappend synth_cmd -generic "ENABLE_XTHEAD_MEMPAIR_EXTENSION=$enable_xthead_mempair_extension"
lappend synth_cmd -generic "ENABLE_XTHEAD_BASE_UPDATE_EXTENSION=$enable_xthead_base_update_extension"
lappend synth_cmd -generic "ENABLE_ID_BRANCH_EX_FORWARD=$enable_id_branch_ex_forward"
lappend synth_cmd -generic "ENABLE_ID_BRANCH_FOLD=$enable_id_branch_fold"
lappend synth_cmd -generic "ENABLE_ID_BRANCH_FOLD_NEXT_CACHE=$enable_id_branch_fold_next_cache"
lappend synth_cmd -generic "ENABLE_ID_BRANCH_NOT_TAKEN_LOAD_FOLD=$enable_id_branch_not_taken_load_fold"
lappend synth_cmd -generic "ENABLE_ID_ALU_PAIR_FOLD=$enable_id_alu_pair_fold"
lappend synth_cmd -generic "ENABLE_ID_ALU_DEP_FOLD=$enable_id_alu_dep_fold"
lappend synth_cmd -generic "ENABLE_REDIRECT_TARGET_CACHE=$enable_redirect_target_cache"
lappend synth_cmd -generic "ENABLE_REDIRECT_CACHE_REGULAR_LOOKUP=$enable_redirect_cache_regular_lookup"
lappend synth_cmd -generic "ENABLE_FETCH_REDIRECT_REUSE=$enable_fetch_redirect_reuse"
lappend synth_cmd -generic "REDIRECT_CACHE_ENTRIES=$redirect_cache_entries"
lappend synth_cmd -generic "REDIRECT_CACHE_XOR_INDEX=$redirect_cache_xor_index"
lappend synth_cmd -generic "ENABLE_DYNAMIC_BRANCH_PREDICT=$enable_dynamic_branch_predict"
lappend synth_cmd -generic "BRANCH_BHT_ENTRIES=$branch_bht_entries"
lappend synth_cmd -generic "BRANCH_STATIC_PREDICT_MODE=$branch_static_predict_mode"
lappend synth_cmd -generic "DMEM_NEGEDGE_READ=$dmem_negedge_read"
lappend synth_cmd -generic "DMEM_READ_PREISSUE=$dmem_read_preissue"
lappend synth_cmd -generic "DCACHE_EN=$dcache_en"
lappend synth_cmd -generic "DCACHE_SIZE_BYTES=$dcache_size_bytes"
lappend synth_cmd -generic "ENABLE_DCACHE_LOAD_USE_SPEC=$enable_dcache_load_use_spec"
lappend synth_cmd -generic "ENABLE_DCACHE_NEXT_PREFETCH=$enable_dcache_next_prefetch"
lappend synth_cmd -generic "ENABLE_DCACHE_WORD_ONLY=$enable_dcache_word_only"
lappend synth_cmd -generic "ICACHE_EN=$icache_en"
if {$rom_init_hex ne ""} {
    puts "INFO: ROM_INIT_HEX override = $rom_init_hex"
    lappend synth_cmd -generic "ROM_INIT_HEX=$rom_init_hex"
}
if {$rom_init_mem32_hex ne ""} {
    puts "INFO: ROM_INIT_MEM32_HEX override = $rom_init_mem32_hex"
    lappend synth_cmd -generic "ROM_INIT_MEM32_HEX=$rom_init_mem32_hex"
}
if {$ram_base_override ne ""} {
    puts "INFO: RAM_BASE override = $ram_base_override"
    lappend synth_cmd -generic "RAM_BASE=$ram_base_override"
}
if {$rom_bytes_override ne ""} {
    puts "INFO: ROM_BYTES override = $rom_bytes_override"
    lappend synth_cmd -generic "ROM_BYTES=$rom_bytes_override"
}
if {$ram_bytes_override ne ""} {
    puts "INFO: RAM_BYTES override = $ram_bytes_override"
    lappend synth_cmd -generic "RAM_BYTES=$ram_bytes_override"
}
run_checked "synth_design" $synth_cmd

run_checked "report_utilization" [list report_utilization -file [file join $report_dir synth_utilization.rpt]]
run_checked "report_utilization_hierarchical" [list report_utilization -hierarchical -hierarchical_depth 6 -file [file join $report_dir synth_utilization_hierarchical.rpt]]
if {$quick_util_only ne "0"} {
    puts "INFO: QUICK_UTIL_ONLY set; stopping after synth utilization report."
    close_project
    exit 0
}

run_checked "write_checkpoint" [list write_checkpoint -force [file join $build_dir ${project_name}_sysclk_${clock_tag}ns_${cpu_clk_tag}_synth.dcp]]
run_checked "report_timing_summary" [list report_timing_summary -file [file join $report_dir synth_timing_summary.rpt]]

puts "INFO: Input clock period = ${input_clock_period_ns} ns"
if {$flow_mode eq "synth"} {
    puts "INFO: PYNQ-Z2 synthesis completed. Reports written to $report_dir"
    exit 0
}

run_checked "opt_design" [list opt_design -directive Explore]
run_checked "place_design" [list place_design -directive Explore]
run_checked "phys_opt_design_pre_route" [list phys_opt_design -directive Explore]
run_checked "route_design" [list route_design -directive Explore]
run_checked "phys_opt_design_post_route" [list phys_opt_design -directive Explore]
run_checked "report_impl_utilization" [list report_utilization -file [file join $report_dir impl_utilization.rpt]]
run_checked "report_impl_timing_summary" [list report_timing_summary -file [file join $report_dir impl_timing_summary.rpt]]
run_checked "write_impl_checkpoint" [list write_checkpoint -force [file join $build_dir ${project_name}_sysclk_${clock_tag}ns_${cpu_clk_tag}_impl.dcp]]
run_checked "write_bitstream" [list write_bitstream -force $bitstream_file]

puts "INFO: PYNQ-Z2 implementation completed. Reports written to $report_dir"
puts "INFO: Bitstream written to $bitstream_file"
exit 0
