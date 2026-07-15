set script_dir [file dirname [file normalize [info script]]]
set status_path [file join $script_dir hw_probe_impl136.status.txt]
set fh [open $status_path w]

proc emit {fh msg} {
    puts $msg
    puts $fh $msg
    flush $fh
}

emit $fh "HW_PROBE_START impl136"
emit $fh "SCRIPT_DIR=$script_dir"

if {[catch {open_hw_manager} err]} {
    emit $fh "HW_PROBE_RESULT=open_hw_manager_failed"
    emit $fh "ERROR=$err"
    close $fh
    exit 0
}

if {[catch {connect_hw_server} err]} {
    emit $fh "HW_PROBE_RESULT=connect_hw_server_failed"
    emit $fh "ERROR=$err"
    close $fh
    exit 0
}

if {[catch {get_hw_targets *} targets]} {
    emit $fh "HW_PROBE_RESULT=get_hw_targets_failed"
    emit $fh "ERROR=$targets"
    close $fh
    exit 0
}
emit $fh "HW_TARGET_COUNT=[llength $targets]"

set target_index 0
foreach target $targets {
    emit $fh "HW_TARGET[$target_index]=$target"
    foreach prop {NAME URL IS_OPEN} {
        if {![catch {get_property $prop $target} value]} {
            emit $fh "HW_TARGET[$target_index].$prop=$value"
        }
    }
    incr target_index
}

set opened_count 0
set device_count 0
foreach target $targets {
    if {[catch {current_hw_target $target} err]} {
        emit $fh "HW_TARGET_OPEN_SKIP=$target ERROR=$err"
        continue
    }
    if {[catch {open_hw_target} err]} {
        emit $fh "HW_TARGET_OPEN_FAILED=$target ERROR=$err"
        continue
    }
    incr opened_count
    set devices [get_hw_devices *]
    emit $fh "HW_DEVICE_COUNT_FOR_TARGET=$target [llength $devices]"
    set device_index 0
    foreach dev $devices {
        emit $fh "HW_DEVICE[$device_count]=$dev"
        foreach prop {PART IDCODE JTAG_CHAIN_POSITION PROGRAM.FILE PROGRAM.IS_SUPPORTED} {
            if {![catch {get_property $prop $dev} value]} {
                emit $fh "HW_DEVICE[$device_count].$prop=$value"
            }
        }
        incr device_index
        incr device_count
    }
    catch {close_hw_target}
}

emit $fh "HW_TARGET_OPENED_COUNT=$opened_count"
emit $fh "HW_DEVICE_TOTAL_COUNT=$device_count"
if {$device_count > 0} {
    emit $fh "HW_PROBE_RESULT=devices_detected"
} else {
    emit $fh "HW_PROBE_RESULT=no_devices_detected"
}

close $fh
exit 0
