if {[llength $argv] < 1} {
    puts stderr "Usage: program_hw_bitstream.tcl <bitstream.bit>"
    exit 1
}

set bitstream_file [file normalize [lindex $argv 0]]
if {![file exists $bitstream_file]} {
    puts stderr "ERROR: bitstream not found: $bitstream_file"
    exit 1
}

open_hw_manager
connect_hw_server -allow_non_jtag

set targets [get_hw_targets]
puts "INFO: HW targets: $targets"
if {[llength $targets] == 0} {
    puts stderr "ERROR: no hardware targets detected"
    close_hw_manager
    exit 2
}

open_hw_target [lindex $targets 0]
set devices [get_hw_devices]
puts "INFO: HW devices: $devices"

set fpga_devices [get_hw_devices -quiet xc7z020*]
if {[llength $fpga_devices] == 0} {
    set fpga_devices $devices
}
if {[llength $fpga_devices] == 0} {
    puts stderr "ERROR: no programmable hardware device detected"
    close_hw_manager
    exit 3
}

set fpga [lindex $fpga_devices 0]
current_hw_device $fpga
refresh_hw_device -update_hw_probes false $fpga
set_property PROGRAM.FILE $bitstream_file $fpga
puts "INFO: Programming $fpga with $bitstream_file"
program_hw_devices $fpga
refresh_hw_device -update_hw_probes false $fpga

puts "PROGRAM_OK: $fpga $bitstream_file"
close_hw_manager
exit 0
