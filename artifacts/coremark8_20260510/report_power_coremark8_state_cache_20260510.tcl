set repo_root [file normalize [file join [file dirname [info script]] .. ..]]
set dcp_file [file join $repo_root vivado_program coremark8_state_cache_20260510 YH_rv_cpu_pynq_z2_coremark8_state_cache_cpu50_20260510_impl.dcp]
set report_dir [file join $repo_root vivado_program coremark8_state_cache_20260510 power]
file mkdir $report_dir
open_checkpoint $dcp_file
report_power -file [file join $report_dir impl_power_default_activity.rpt]
close_design
exit 0
