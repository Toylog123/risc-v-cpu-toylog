set repo_root [file normalize [file join [file dirname [info script]] .. ..]]
set dcp_file [file join $repo_root project YH_rv_cpu_pynq_z2_sysclk_8p000ns_cpu50_impl.dcp]
set report_dir [file join $repo_root artifacts coremark7_dmips5_20260508 power_noidbr]
file mkdir $report_dir
open_checkpoint $dcp_file
report_power -file [file join $report_dir impl_power_default_activity.rpt]
close_design
exit 0
