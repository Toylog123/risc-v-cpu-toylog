proc env_or_default {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc run_checked {step_name cmd_list} {
    puts "STEP: $step_name BEGIN"
    set rc [catch {uplevel 1 $cmd_list} err opts]
    if {$rc != 0} {
        puts "ERROR: $step_name failed: $err"
        if {[dict exists $opts -errorinfo]} {
            puts [dict get $opts -errorinfo]
        }
        exit 1
    }
    puts "STEP: $step_name DONE"
}

if {[llength $argv] < 3} {
    puts "Usage: vivado -mode batch -source impl_from_synth_checkpoint.tcl -tclargs <synth.dcp> <report_dir> <impl.dcp> ?bitstream.bit?"
    exit 1
}

set synth_dcp [file normalize [lindex $argv 0]]
set report_dir [file normalize [lindex $argv 1]]
set impl_dcp [file normalize [lindex $argv 2]]
set bitstream_file ""
if {[llength $argv] >= 4} {
    set bitstream_file [file normalize [lindex $argv 3]]
}

set opt_directive [env_or_default PYNQ_OPT_DIRECTIVE_OVERRIDE Explore]
set place_directive [env_or_default PYNQ_PLACE_DIRECTIVE_OVERRIDE Explore]
set phys_opt_pre_directive [env_or_default PYNQ_PHYS_OPT_PRE_DIRECTIVE_OVERRIDE Explore]
set route_directive [env_or_default PYNQ_ROUTE_DIRECTIVE_OVERRIDE Explore]
set phys_opt_post_directive [env_or_default PYNQ_PHYS_OPT_POST_DIRECTIVE_OVERRIDE Explore]
set skip_phys_opt [env_or_default PYNQ_SKIP_PHYS_OPT_OVERRIDE 0]
set impl_write_bitstream [env_or_default PYNQ_IMPL_WRITE_BITSTREAM_OVERRIDE 0]

file mkdir $report_dir
file mkdir [file dirname $impl_dcp]
if {$bitstream_file ne ""} {
    file mkdir [file dirname $bitstream_file]
}

puts "INFO: synth_dcp = $synth_dcp"
puts "INFO: report_dir = $report_dir"
puts "INFO: impl_dcp = $impl_dcp"
puts "INFO: bitstream_file = $bitstream_file"
puts "INFO: OPT_DIRECTIVE = $opt_directive"
puts "INFO: PLACE_DIRECTIVE = $place_directive"
puts "INFO: PHYS_OPT_PRE_DIRECTIVE = $phys_opt_pre_directive"
puts "INFO: ROUTE_DIRECTIVE = $route_directive"
puts "INFO: PHYS_OPT_POST_DIRECTIVE = $phys_opt_post_directive"
puts "INFO: SKIP_PHYS_OPT = $skip_phys_opt"
puts "INFO: IMPL_WRITE_BITSTREAM = $impl_write_bitstream"

run_checked "open_checkpoint" [list open_checkpoint $synth_dcp]
run_checked "opt_design" [list opt_design -directive $opt_directive]
run_checked "place_design" [list place_design -directive $place_directive]
if {$skip_phys_opt eq "0"} {
    run_checked "phys_opt_design_pre_route" [list phys_opt_design -directive $phys_opt_pre_directive]
}
run_checked "route_design" [list route_design -directive $route_directive]
if {$skip_phys_opt eq "0"} {
    run_checked "phys_opt_design_post_route" [list phys_opt_design -directive $phys_opt_post_directive]
}

run_checked "report_impl_utilization" [list report_utilization -file [file join $report_dir impl_utilization.rpt]]
run_checked "report_impl_timing_summary" [list report_timing_summary -file [file join $report_dir impl_timing_summary.rpt]]
run_checked "report_impl_timing_setup_top20" [list report_timing -max_paths 20 -nworst 5 -delay_type max -sort_by group -file [file join $report_dir impl_timing_setup_top20.rpt]]
run_checked "report_impl_timing_hold_top20" [list report_timing -max_paths 20 -nworst 5 -delay_type min -sort_by group -file [file join $report_dir impl_timing_hold_top20.rpt]]
run_checked "report_impl_methodology" [list report_methodology -file [file join $report_dir impl_methodology.rpt]]
run_checked "report_impl_route_status" [list report_route_status -file [file join $report_dir impl_route_status.rpt]]
run_checked "write_checkpoint_impl" [list write_checkpoint -force $impl_dcp]

if {($impl_write_bitstream ne "0") && ($bitstream_file ne "")} {
    run_checked "write_bitstream" [list write_bitstream -force $bitstream_file]
}

puts "INFO: Implementation completed from synth checkpoint."
