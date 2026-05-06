if {[llength $argv] < 2} {
    puts stderr "Usage: report_hier_util_from_dcp.tcl <input.dcp> <output.rpt>"
    exit 1
}

set dcp_path [file normalize [lindex $argv 0]]
set rpt_path [file normalize [lindex $argv 1]]

if {![file exists $dcp_path]} {
    puts stderr "Missing checkpoint: $dcp_path"
    exit 1
}

file mkdir [file dirname $rpt_path]
open_checkpoint $dcp_path
report_utilization -hierarchical -file $rpt_path
close_project
