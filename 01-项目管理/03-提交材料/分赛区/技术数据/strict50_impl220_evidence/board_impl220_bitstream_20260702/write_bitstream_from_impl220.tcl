set script_dir [file dirname [file normalize [info script]]]
set artifact_root [file dirname $script_dir]
set candidate_dir [file join $artifact_root impl220_impl200_optExploreArea_routeAdvancedSkewModeling_postAggressive_cpu50]
set dcp_file [file join $candidate_dir dcp cpu50_impl.dcp]
set bit_file [file join $script_dir YH_rv_cpu_pynq_z2_strict50_impl220_20260702.bit]

if {![file exists $dcp_file]} {
    error "Missing routed checkpoint: $dcp_file"
}

open_checkpoint $dcp_file
report_drc -file [file join $script_dir bitstream_from_dcp_drc.rpt]
report_utilization -file [file join $script_dir bitstream_from_dcp_utilization.rpt]
report_timing_summary -file [file join $script_dir bitstream_from_dcp_timing_summary.rpt]
report_route_status -file [file join $script_dir bitstream_from_dcp_route_status.rpt]
write_bitstream -force $bit_file
puts "INFO: Bitstream written to $bit_file"
