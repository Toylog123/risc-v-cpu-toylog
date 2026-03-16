set script_dir [file dirname [file normalize [info script]]]
set vivado_dir [file dirname $script_dir]
set fpga_dir [file dirname $vivado_dir]
set project_root [file dirname $fpga_dir]
set repo_root [file dirname $project_root]

set build_dir [file normalize [file join $repo_root project]]
set report_dir [file join $build_dir reports]
set project_name YH_rv_cpu_nexys_a7_100
set top_name YH_rv_cpu_fpga_top
set part_name xc7a100tcsg324-1
set flow_mode synth
set rom_init_hex ""
set rom_bytes_override ""
set ram_bytes_override ""
set clock_period_ns 10.000

if {[llength $argv] >= 1} {
    set flow_mode [lindex $argv 0]
}

if {[info exists ::env(ROM_INIT_HEX_OVERRIDE)] && $::env(ROM_INIT_HEX_OVERRIDE) ne ""} {
    set rom_init_hex [file normalize $::env(ROM_INIT_HEX_OVERRIDE)]
}
if {[info exists ::env(ROM_BYTES_OVERRIDE)] && $::env(ROM_BYTES_OVERRIDE) ne ""} {
    set rom_bytes_override $::env(ROM_BYTES_OVERRIDE)
}
if {[info exists ::env(RAM_BYTES_OVERRIDE)] && $::env(RAM_BYTES_OVERRIDE) ne ""} {
    set ram_bytes_override $::env(RAM_BYTES_OVERRIDE)
}
if {[info exists ::env(CLOCK_PERIOD_NS_OVERRIDE)] && $::env(CLOCK_PERIOD_NS_OVERRIDE) ne ""} {
    set clock_period_ns $::env(CLOCK_PERIOD_NS_OVERRIDE)
}

set clock_tag [string map {. p} $clock_period_ns]
set report_dir [file join $report_dir clk_${clock_tag}ns]

set rtl_dir [file join $project_root rtl]
set fpga_src_dir [file join $vivado_dir src]
set constr_file [file join $vivado_dir constraints nexys_a7_100_template.xdc]
set clock_constr_file [file join $build_dir clock_${clock_tag}.xdc]
set rtl_files [lsort [glob -nocomplain [file join $rtl_dir *.v]]]
set fpga_files [lsort [glob -nocomplain [file join $fpga_src_dir *.v]]]

if {[llength $rtl_files] == 0} {
    error "未找到 RTL 源文件。"
}

file mkdir $build_dir
file mkdir $report_dir

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

run_checked "read_rtl" [list read_verilog -sv $rtl_files]

if {[llength $fpga_files] > 0} {
    run_checked "read_fpga_sources" [list read_verilog -sv $fpga_files]
}

if {[file exists $constr_file]} {
    run_checked "read_constraints" [list read_xdc $constr_file]
}
set clock_fd [open $clock_constr_file w]
puts $clock_fd [format {create_clock -name sys_clk -period %s [get_ports CLK100MHZ]} $clock_period_ns]
close $clock_fd
run_checked "read_clock_constraints" [list read_xdc $clock_constr_file]

set synth_cmd [list synth_design -top $top_name -part $part_name -flatten_hierarchy rebuilt]
if {$rom_init_hex ne ""} {
    puts "INFO: ROM_INIT_HEX override = $rom_init_hex"
    lappend synth_cmd -generic "ROM_INIT_HEX=$rom_init_hex"
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
run_checked "write_checkpoint" [list write_checkpoint -force [file join $build_dir ${project_name}_${clock_tag}_synth.dcp]]
run_checked "report_utilization" [list report_utilization -file [file join $report_dir synth_utilization.rpt]]
run_checked "report_timing_summary" [list report_timing_summary -file [file join $report_dir synth_timing_summary.rpt]]

puts "INFO: Clock period = ${clock_period_ns} ns"
puts "INFO: Synthesis completed. Reports written to $report_dir"
exit 0
