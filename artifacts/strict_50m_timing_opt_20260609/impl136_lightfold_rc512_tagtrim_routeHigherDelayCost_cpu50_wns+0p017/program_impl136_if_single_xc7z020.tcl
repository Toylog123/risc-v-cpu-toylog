set script_dir [file dirname [file normalize [info script]]]
set bit_path [file join $script_dir impl136_lightfold_rc512_tagtrim_routeHigherDelayCost_cpu50.bit]
set status_path [file join $script_dir program_impl136.status.txt]
set fh [open $status_path w]

proc emit {fh msg} {
    puts $msg
    puts $fh $msg
    flush $fh
}

emit $fh "PROGRAM_START impl136"
emit $fh "BITSTREAM=$bit_path"

if {![file exists $bit_path]} {
    emit $fh "PROGRAM_RESULT=missing_bitstream"
    close $fh
    exit 1
}

if {[catch {open_hw_manager} err]} {
    emit $fh "PROGRAM_RESULT=open_hw_manager_failed"
    emit $fh "ERROR=$err"
    close $fh
    exit 1
}

if {[catch {connect_hw_server} err]} {
    emit $fh "PROGRAM_RESULT=connect_hw_server_failed"
    emit $fh "ERROR=$err"
    close $fh
    exit 1
}

if {[catch {get_hw_targets *} targets]} {
    emit $fh "PROGRAM_RESULT=get_hw_targets_failed"
    emit $fh "ERROR=$targets"
    close $fh
    exit 1
}

set xc7z020_devices {}
foreach target $targets {
    if {[catch {current_hw_target $target} err]} {
        emit $fh "TARGET_SELECT_FAILED=$target ERROR=$err"
        continue
    }
    if {[catch {open_hw_target} err]} {
        emit $fh "TARGET_OPEN_FAILED=$target ERROR=$err"
        continue
    }
    foreach dev [get_hw_devices *] {
        set part ""
        catch {set part [get_property PART $dev]}
        emit $fh "DEVICE=$dev PART=$part"
        if {[string match -nocase "*xc7z020*" $part] || [string match -nocase "*xc7z020*" $dev]} {
            lappend xc7z020_devices $dev
        }
    }
}

emit $fh "XC7Z020_DEVICE_COUNT=[llength $xc7z020_devices]"
if {[llength $xc7z020_devices] != 1} {
    emit $fh "PROGRAM_RESULT=refused_expected_single_xc7z020"
    close $fh
    exit 1
}

set dev [lindex $xc7z020_devices 0]
current_hw_device $dev
refresh_hw_device $dev
set_property PROGRAM.FILE $bit_path $dev

if {[catch {program_hw_devices $dev} err]} {
    emit $fh "PROGRAM_RESULT=program_failed"
    emit $fh "ERROR=$err"
    close $fh
    exit 1
}

emit $fh "PROGRAM_OK device=$dev bitstream=$bit_path"
emit $fh "PROGRAM_RESULT=program_ok"
close $fh
exit 0
