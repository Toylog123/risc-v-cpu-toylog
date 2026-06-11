set script_dir [file dirname [file normalize [info script]]]
set dcp_file [file join $script_dir YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_impl.dcp]
set bit_file [file join $script_dir YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_impl60.bit]

if {![file exists $dcp_file]} {
    error "Missing routed checkpoint: $dcp_file"
}

open_checkpoint $dcp_file
report_utilization -file [file join $script_dir bitstream_from_dcp_utilization.rpt]
report_timing_summary -file [file join $script_dir bitstream_from_dcp_timing_summary.rpt]
write_bitstream -force $bit_file
puts "INFO: Bitstream written to $bit_file"
