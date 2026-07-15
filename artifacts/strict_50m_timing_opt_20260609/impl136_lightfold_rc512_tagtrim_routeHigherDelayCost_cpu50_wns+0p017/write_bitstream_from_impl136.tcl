set script_dir [file dirname [file normalize [info script]]]
set dcp_path [file join $script_dir dcp cpu50_impl.dcp]
set bit_path [file join $script_dir impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit]

open_checkpoint $dcp_path
report_timing_summary -file [file join $script_dir bitstream_from_dcp_timing_summary.rpt]
report_utilization -file [file join $script_dir bitstream_from_dcp_utilization.rpt]
report_drc -file [file join $script_dir bitstream_from_dcp_drc.rpt]
write_bitstream -force $bit_path
close_design
exit
