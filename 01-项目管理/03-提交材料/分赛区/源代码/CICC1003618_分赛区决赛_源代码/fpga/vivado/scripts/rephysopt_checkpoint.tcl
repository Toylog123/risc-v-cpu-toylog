if {[llength $argv] < 2} {
    puts stderr "usage: rephysopt_checkpoint.tcl <input_impl_dcp> <output_dir> ?phys_opt_directive?"
    exit 2
}

set input_dcp [file normalize [lindex $argv 0]]
set output_dir [file normalize [lindex $argv 1]]
set phys_opt_directive Explore
if {[llength $argv] >= 3 && [lindex $argv 2] ne ""} {
    set phys_opt_directive [lindex $argv 2]
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

if {![file exists $input_dcp]} {
    puts stderr "missing checkpoint: $input_dcp"
    exit 2
}

file mkdir $output_dir
puts "INFO: input_dcp = $input_dcp"
puts "INFO: output_dir = $output_dir"
puts "INFO: phys_opt_directive = $phys_opt_directive"

run_checked "open_checkpoint" [list open_checkpoint $input_dcp]
run_checked "report_timing_summary_before" [list report_timing_summary -file [file join $output_dir timing_summary_before.rpt]]

if {$phys_opt_directive ne "none"} {
    run_checked "phys_opt_design_post_route" [list phys_opt_design -directive $phys_opt_directive]
}

run_checked "report_utilization" [list report_utilization -file [file join $output_dir impl_utilization.rpt]]
run_checked "report_timing_summary" [list report_timing_summary -file [file join $output_dir impl_timing_summary.rpt]]
run_checked "report_timing_setup_top20" [list report_timing -max_paths 20 -nworst 5 -delay_type max -sort_by group -file [file join $output_dir impl_timing_setup_top20.rpt]]
run_checked "report_timing_hold_top20" [list report_timing -max_paths 20 -nworst 5 -delay_type min -sort_by group -file [file join $output_dir impl_timing_hold_top20.rpt]]
run_checked "report_methodology" [list report_methodology -file [file join $output_dir impl_methodology.rpt]]
run_checked "report_route_status" [list report_route_status -file [file join $output_dir impl_route_status.rpt]]
run_checked "write_checkpoint" [list write_checkpoint -force [file join $output_dir rephysopt_${phys_opt_directive}.dcp]]

puts "INFO: rephysopt completed. Reports written to $output_dir"
exit 0
