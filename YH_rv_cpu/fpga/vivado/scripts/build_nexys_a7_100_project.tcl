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

if {[llength $argv] >= 1} {
    set flow_mode [lindex $argv 0]
}

set rtl_dir [file join $project_root rtl]
set fpga_src_dir [file join $vivado_dir src]
set constr_file [file join $vivado_dir constraints nexys_a7_100_template.xdc]
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

if {$flow_mode eq "project"} {
    create_project $project_name $build_dir -force -part $part_name
    set_property target_language Verilog [current_project]
    set_property default_lib xil_defaultlib [current_project]
    add_project_files $rtl_files $fpga_files $constr_file $rtl_dir
    puts "INFO: 已生成 Vivado 工程骨架，目录为 $build_dir"
    close_project
    exit 0
}

if {[catch {
    read_verilog -sv $rtl_files

    if {[llength $fpga_files] > 0} {
        read_verilog -sv $fpga_files
    }

    if {[file exists $constr_file]} {
        read_xdc $constr_file
    }

    synth_design -top $top_name -part $part_name -flatten_hierarchy rebuilt

    write_checkpoint -force [file join $build_dir ${project_name}_synth.dcp]
    report_utilization -file [file join $report_dir synth_utilization.rpt]
    report_timing_summary -file [file join $report_dir synth_timing_summary.rpt]
} result]} {
    puts stderr "ERROR: 综合流程失败"
    puts stderr $result
    puts stderr $::errorInfo
    exit 1
}

puts "INFO: 综合完成，报告已输出到 $report_dir"
exit 0
