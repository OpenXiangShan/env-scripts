proc env_or_default {name default} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default
}

proc open_uvhs_hw_session {} {
    open_hw_manager

    set hw_server_url [env_or_default HW_SERVER_URL "TCP:localhost:3121"]
    if {[catch {connect_hw_server -url $hw_server_url} err]} {
        puts stderr "ERROR: connect_hw_server failed for $hw_server_url: $err"
        exit 1
    }

    set hw_target_pattern [env_or_default HW_TARGET ""]
    if {$hw_target_pattern ne ""} {
        set hw_targets [get_hw_targets -quiet $hw_target_pattern]
        if {[llength $hw_targets] == 0} {
            puts stderr "ERROR: no hw_target matched pattern: $hw_target_pattern"
            exit 1
        }
        if {[catch {open_hw_target [lindex $hw_targets 0]} err]} {
            puts stderr "ERROR: open_hw_target failed for $hw_target_pattern: $err"
            exit 1
        }
    } else {
        if {[catch {open_hw_target} err]} {
            puts stderr "ERROR: open_hw_target failed: $err"
            exit 1
        }
    }
}
