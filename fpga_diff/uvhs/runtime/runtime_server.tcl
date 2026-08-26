# Download a completed UVHS database and retain its owning runtime session.

proc uvhs_temp_dir {} {
    set path [file join $::uvhs_runtime_work_dir tmp]
    file mkdir $path
    return $path
}

proc uvhs_prepare_uhd_root {} {
    set path [file join $::uvhs_runtime_work_dir UHD]
    set writable_path $path
    if {![catch {file lstat $path attributes}] &&
        $attributes(type) eq "link"} {
        set writable_path [file readlink $path]
        if {[file pathtype $writable_path] ne "absolute"} {
            set writable_path [file join [file dirname $path] $writable_path]
        }
    }
    file mkdir $writable_path
    file attributes $writable_path -permissions 00777
    return $path
}

proc uvhs_parse_integer {name value} {
    if {![string is wideinteger -strict $value]} {
        error "$name is not an integer: $value"
    }
    return [expr {$value + 0}]
}

proc uvhs_read_binary {path} {
    set input [open $path rb]
    fconfigure $input -translation binary -encoding binary
    set data [read $input]
    close $input
    return $data
}

proc uvhs_write_binary {path data} {
    set output [open $path wb]
    fconfigure $output -translation binary -encoding binary
    puts -nonewline $output $data
    close $output
}

proc uvhs_write_atomic {path data} {
    file mkdir [file dirname $path]
    set temp_file "${path}.tmp.[pid]"
    uvhs_write_binary $temp_file $data
    file rename -force $temp_file $path
}

proc uvhs_hold_soc_for_download {} {
    foreach reset_name {rstn_sw6 rstn_sw5 rstn_sw4} {
        reset -name $reset_name -value 0
    }
    query -reset
}

proc uvhs_release_soc_after_download {} {
    foreach reset_name {rstn_sw6 rstn_sw5 rstn_sw4} {
        reset -name $reset_name -value 0
    }
    after 1000
    foreach reset_name {rstn_sw6 rstn_sw4} {
        reset -name $reset_name -value 1
    }
    after 1000
    reset -name rstn_sw5 -value 1
    after 1000
    query -reset
}

proc uvhs_halt_soc {} {
    reset -name rstn_sw5 -value 0
    query -reset
}

proc uvhs_reset_cpu {} {
    reset -name rstn_sw5 -value 0
    after 500
    reset -name rstn_sw5 -value 1
    after 500
    query -reset
}

proc uvhs_hold_cpu_for_memory {} {
    reset -name rstn_sw5 -value 0
    after 100
}

proc uvhs_release_cpu_after_memory {} {
    reset -name rstn_sw5 -value 1
    after 500
    query -reset
}

proc uvhs_find_gbus_endpoint {} {
    set ip_info [query -ipinfo -tclobj]
    set endpoints {}
    foreach line [split $ip_info "\n"] {
        if {[regexp -nocase {^\s*\S+\s+\S+\s+B([0-9]+)\.F([0-9]+)\s+[0-9]+\s+\S+\s+gbus\s+([0-9]+)} \
            $line -> board_index fpga_index instance]} {
            lappend endpoints [list $board_index f$fpga_index $instance]
        }
    }
    set endpoints [lsort -unique $endpoints]
    if {[llength $endpoints] != 1} {
        error "expected one generalBus endpoint, got [llength $endpoints]: $endpoints"
    }
    return [lindex $endpoints 0]
}

proc uvhs_write_flash_gbus {input_file base capacity} {
    if {![file isfile $input_file]} {
        error "flash image not found: $input_file"
    }

    lassign [uvhs_find_gbus_endpoint] board fpga instance
    # The generated generalBus DCP has one internal AXI port and one channel.
    # The port shown by query -ipinfo is its system-bus slot, not this port ID.
    set port 0
    set channel 0
    set base [uvhs_parse_integer "flash base" $base]
    set capacity [uvhs_parse_integer "flash capacity" $capacity]
    set payload [uvhs_read_binary $input_file]
    set payload_size [string length $payload]
    if {$payload_size == 0} {
        error "flash image is empty: $input_file"
    }
    if {$payload_size > $capacity} {
        error "flash image is $payload_size bytes, capacity is $capacity bytes"
    }

    set transfer_size [expr {($payload_size + 7) & ~7}]
    if {$transfer_size > $capacity} {
        error "8-byte-aligned flash transfer exceeds capacity: $transfer_size > $capacity"
    }
    append payload [string repeat "\x00" [expr {$transfer_size - $payload_size}]]

    set temp_dir [uvhs_temp_dir]
    set write_file [file join $temp_dir [format "flash-write-%d.bin" [pid]]]
    set read_file [file join $temp_dir [format "flash-read-%d.bin" [pid]]]
    uvhs_write_binary $write_file $payload
    file delete -force $read_file

    puts [format \
        "INFO: generalBus B%d.%s instance %d flash write 0x%llx, %d bytes" \
        $board $fpga $instance $base $transfer_size]
    set status [catch {
        gbus_dma_write -board $board -fpga $fpga -instance $instance -port $port \
            -addr $base -size $transfer_size -channel $channel -file $write_file
        gbus_dma_read -board $board -fpga $fpga -instance $instance -port $port \
            -addr $base -size $transfer_size -channel $channel -file $read_file
        set readback [uvhs_read_binary $read_file]
        if {![string equal $payload $readback]} {
            error "generalBus flash readback mismatch"
        }
    } message options]
    file delete -force $write_file $read_file
    if {$status != 0} {
        return -options $options $message
    }
    puts "INFO: generalBus flash full readback passed: $input_file"
}

proc uvhs_write_ddr_pairs {input_file rtl_path data_width} {
    if {![file isfile $input_file]} {
        error "DDR workload not found: $input_file"
    }
    if {![string is integer -strict $data_width] || $data_width ni {64 256}} {
        error "unsupported DDR AXI data width: $data_width"
    }

    set beat_bytes [expr {$data_width / 8}]
    set beat_chars [expr {$data_width / 4}]
    set input [open $input_file r]
    set segment 0
    set line_number 0

    while {[gets $input address_text] >= 0} {
        incr line_number
        if {[gets $input data_text] < 0} {
            close $input
            error "missing data line after line $line_number"
        }
        incr line_number
        set address_text [string trim $address_text]
        set data_text [string trim $data_text]
        if {![regexp {^[0-9a-fA-F]+$} $address_text]} {
            close $input
            error "invalid DDR address on line [expr {$line_number - 1}]: $address_text"
        }
        if {![regexp {^[0-9a-fA-F]+$} $data_text]} {
            close $input
            error "invalid DDR data on line $line_number"
        }
        if {[expr {[string length $data_text] % $beat_chars}] != 0} {
            close $input
            error "DDR data on line $line_number is not aligned to $data_width bits"
        }
        if {[scan $address_text %llx byte_address] != 1 ||
            [expr {$byte_address % $beat_bytes}] != 0} {
            close $input
            error "DDR address is not aligned to $beat_bytes bytes: $address_text"
        }

        set beat_count [expr {[string length $data_text] / $beat_chars}]
        set start_word [expr {$byte_address / $beat_bytes}]
        set end_word [expr {$start_word + $beat_count - 1}]
        set temp_file [file join [uvhs_temp_dir] \
            [format "ddr-%d-%d.hex" [pid] $segment]]
        incr segment

        set output [open $temp_file w]
        for {set beat 0} {$beat < $beat_count} {incr beat} {
            set first [expr {[string length $data_text] - ($beat + 1) * $beat_chars}]
            puts $output [string range $data_text $first \
                [expr {$first + $beat_chars - 1}]]
        }
        close $output

        puts [format "INFO: DDR backdoor write %s words 0x%llx..0x%llx" \
            $beat_count $start_word $end_word]
        set status [catch {
            writemem -rtl $rtl_path -start $start_word -end $end_word \
                -file $temp_file -hex
        } message options]
        file delete -force $temp_file
        if {$status != 0} {
            close $input
            return -options $options $message
        }
    }
    close $input
    puts "INFO: DDR backdoor write completed: $input_file"
}

proc uvhs_query_clock_frequency {clock} {
    set frequencies {}
    foreach line [split [query -clock -tclobj] "\n"] {
        set fields [regexp -all -inline {\S+} $line]
        if {[llength $fields] >= 6 && [lindex $fields 4] eq $clock &&
            [string is double -strict [lindex $fields 3]]} {
            lappend frequencies [expr {
                round(double([lindex $fields 3]) * 1000000.0)
            }]
        }
    }
    set frequencies [lsort -integer -unique $frequencies]
    if {[llength $frequencies] != 1} {
        error "expected one frequency for capture clock $clock, got $frequencies"
    }
    return [lindex $frequencies 0]
}

proc uvhs_configure_tmclk_from_cpu {} {
    # Keep the CPU-to-TMCLK relationship stable across sign-off frequencies.
    # The environment variable remains available for controlled experiments,
    # while the normal Make/runtime path supplies the fixed 50:1 default.
    set ratio_value 50
    if {[info exists ::env(UVHS_TMCLK_CPU_RATIO)] &&
        [string trim $::env(UVHS_TMCLK_CPU_RATIO)] ne ""} {
        set ratio_value $::env(UVHS_TMCLK_CPU_RATIO)
    }
    set ratio [uvhs_parse_integer "TMCLK-to-CPU clock ratio" $ratio_value]
    if {$ratio <= 0} {
        error "TMCLK-to-CPU clock ratio must be positive: $ratio"
    }

    set cpu_frequency [uvhs_query_clock_frequency clk5_p]
    set tmclk_frequency [expr {round(double($cpu_frequency) / $ratio)}]
    if {$tmclk_frequency <= 0} {
        error "derived TMCLK frequency is invalid: $tmclk_frequency"
    }

    puts [format \
        "INFO: setting clk8_p to %d Hz from clk5_p %d Hz at %d:1" \
        $tmclk_frequency $cpu_frequency $ratio]
    config -clock -name clk8_p -frequency $tmclk_frequency
}

proc uvhs_capture_station_counts {} {
    set counts {}
    foreach line [split [query -capture -tclobj] "\n"] {
        set fields [regexp -all -inline {\S+} $line]
        if {[llength $fields] < 5} {
            continue
        }

        set fpga ""
        set port_index 2
        set enable_index 3
        set enabled_values {yes true 1 enable enabled}
        if {[regexp -nocase {^(B[0-9]+)\.(F[0-9]+)$} \
                [lindex $fields 1] -> board fpga_id]} {
            set fpga [format "%s.%s" \
                [string toupper $board] [string toupper $fpga_id]]
        } elseif {[regexp -nocase {^B[0-9]+$} [lindex $fields 0]] &&
                  [regexp -nocase {^F[0-9]+$} [lindex $fields 1]]} {
            set fpga [format "%s.%s" \
                [string toupper [lindex $fields 0]] \
                [string toupper [lindex $fields 1]]]
            # Older UVHS Tcl objects expose an isDisable field here.
            set enabled_values {no false 0}
        } else {
            continue
        }

        if {![string is integer -strict [lindex $fields $port_index]] ||
            [string tolower [lindex $fields $enable_index]] ni $enabled_values} {
            continue
        }
        dict incr counts $fpga
    }
    if {[dict size $counts] == 0} {
        error "no enabled UHD capture stations found"
    }
    return $counts
}

proc uvhs_restore_ila_clock {} {
    if {![info exists ::uvhs_ila_original_clock_frequency]} {
        return
    }
    set clock $::uvhs_ila_clock
    set frequency $::uvhs_ila_original_clock_frequency
    if {[info exists ::uvhs_ila_adjusted_clock] && $::uvhs_ila_adjusted_clock} {
        puts "INFO: restoring $clock to $frequency Hz"
        config -clock -name $clock -frequency $frequency
        config -clock -commit
        query -clock
    }
    unset -nocomplain ::uvhs_ila_clock ::uvhs_ila_original_clock_frequency
    unset -nocomplain ::uvhs_ila_adjusted_clock
}

proc uvhs_prepare_ila_clock {clock} {
    uvhs_restore_ila_clock
    set original_frequency [uvhs_query_clock_frequency $clock]
    set station_counts [uvhs_capture_station_counts]
    set max_station_count 0
    dict for {fpga station_count} $station_counts {
        if {$station_count > $max_station_count} {
            set max_station_count $station_count
        }
    }

    # UVHS allows 102.336 Gbit/s per FPGA. Keep ten percent headroom for
    # frequency rounding and runtime database differences.
    set bandwidth_limit 102336000000
    set target_frequency [expr {
        ($bandwidth_limit * 9) / (10 * 512 * $max_station_count)
    }]
    set applied_frequency [expr {
        $original_frequency < $target_frequency ?
            $original_frequency : $target_frequency
    }]
    set ::uvhs_ila_clock $clock
    set ::uvhs_ila_original_clock_frequency $original_frequency
    set ::uvhs_ila_adjusted_clock [expr {
        $applied_frequency < $original_frequency
    }]

    puts "INFO: UHD capture stations per FPGA: $station_counts"
    puts [format \
        "INFO: UHD capture clock %s: signoff=%d Hz, limit=%d Hz, applied=%d Hz" \
        $clock $original_frequency $target_frequency $applied_frequency]
    if {$::uvhs_ila_adjusted_clock} {
        config -clock -name $clock -frequency $applied_frequency
        config -clock -commit
        query -clock
    }
    return $applied_frequency
}

proc uvhs_ila_arm {
    trigger_file position clock gated_clocks
} {
    if {![file isfile $trigger_file]} {
        error "trigger condition file not found: $trigger_file"
    }
    set position [uvhs_parse_integer "capture position" $position]
    if {$position < 0 || $position > 100} {
        error "capture position must be between 0 and 100: $position"
    }
    if {$clock eq ""} {
        error "capture clock is empty"
    }

    unset -nocomplain ::uvhs_ila_position
    trigger -clear
    query -trigger
    trigger -ini_check $trigger_file
    set status [catch {
        set capture_frequency [uvhs_prepare_ila_clock $clock]
        foreach gated_clock [split $gated_clocks ","] {
            set gated_clock [string trim $gated_clock]
            if {$gated_clock eq ""} {
                continue
            }
            trigger -set -gatedclk $gated_clock \
                -frequency $capture_frequency -polarity H
        }
        trigger -set -condition $trigger_file -position $position
        capture -enable
        trigger -enable
    } message options]
    if {$status != 0} {
        if {[catch {uvhs_restore_ila_clock} restore_message]} {
            append message "\nfailed to restore capture clock: $restore_message"
        }
        return -options $options $message
    }
    set ::uvhs_ila_position $position
    puts "INFO: UVHS waveform capture armed at position $position"
}

proc uvhs_ila_upload {output_name timeout depth clock} {
    if {![info exists ::uvhs_ila_position]} {
        error "UVHS waveform capture is not armed; run ila_arm first"
    }
    if {![regexp {^[A-Za-z0-9_.-]+$} $output_name]} {
        error "capture output name contains unsupported characters: $output_name"
    }
    set timeout [uvhs_parse_integer "capture timeout" $timeout]
    set depth [uvhs_parse_integer "capture depth" $depth]
    if {$timeout <= 0 || $depth <= 0} {
        error "capture timeout and depth must be positive"
    }
    if {$clock eq ""} {
        error "capture clock is empty"
    }
    if {[info exists ::uvhs_ila_clock] && $clock ne $::uvhs_ila_clock} {
        error "upload clock $clock does not match armed clock $::uvhs_ila_clock"
    }

    set status [catch {
        set trigger_status [trigger -status -wait 1 -timeout $timeout -tclobj]
        puts "INFO: UVHS trigger status: $trigger_status"
        if {![regexp -nocase {Waveform Data Ready\s+true} $trigger_status]} {
            error "UVHS waveform data is not ready"
        }

        set output_dir [file join [uvhs_prepare_uhd_root] $output_name]
        file delete -force $output_dir
        set upload_options [list -depth $depth \
            -position $::uvhs_ila_position -clock $clock -out $output_name]
        upload_uhd {*}$upload_options
        wavegen -bindir [file join UHD $output_name]

        set usdb [file join $output_dir UvData.usdb]
        if {![file exists $usdb] || [file size $usdb] == 0} {
            error "UVHS waveform database was not generated: $usdb"
        }
        puts "INFO: UVHS waveform database generated: $usdb"
    } message options]
    set restore_status [catch {uvhs_restore_ila_clock} restore_message restore_options]
    if {$status != 0} {
        return -options $options $message
    }
    if {$restore_status != 0} {
        return -options $restore_options $restore_message
    }
}

proc uvhs_ila_clear {} {
    set status [catch {trigger -clear} message options]
    set restore_status [catch {uvhs_restore_ila_clock} restore_message restore_options]
    unset -nocomplain ::uvhs_ila_position
    if {$status != 0} {
        return -options $options $message
    }
    if {$restore_status != 0} {
        return -options $restore_options $restore_message
    }
    puts "INFO: UVHS trigger conditions and capture are disabled"
}

proc uvhs_execute_command {args} {
    if {[llength $args] == 0} {
        error "missing UVHS runtime command"
    }
    set command [lindex $args 0]
    puts "INFO: executing UVHS runtime command: $command"
    switch -- $command {
        halt_soc {
            if {[llength $args] != 1} { error "halt_soc expects no arguments" }
            uvhs_halt_soc
        }
        reset_cpu {
            if {[llength $args] != 1} { error "reset_cpu expects no arguments" }
            uvhs_reset_cpu
        }
        write_ddr {
            if {[llength $args] != 4} { error "write_ddr expects 3 arguments" }
            uvhs_hold_cpu_for_memory
            uvhs_write_ddr_pairs {*}[lrange $args 1 3]
        }
        write_flash {
            if {[llength $args] != 4} { error "write_flash expects 3 arguments" }
            uvhs_hold_cpu_for_memory
            uvhs_write_flash_gbus {*}[lrange $args 1 3]
            uvhs_release_cpu_after_memory
        }
        ila_arm {
            if {[llength $args] != 5} { error "ila_arm expects 4 arguments" }
            uvhs_ila_arm {*}[lrange $args 1 4]
        }
        ila_upload {
            if {[llength $args] != 5} { error "ila_upload expects 4 arguments" }
            uvhs_ila_upload {*}[lrange $args 1 4]
        }
        ila_clear {
            if {[llength $args] != 1} { error "ila_clear expects no arguments" }
            uvhs_ila_clear
        }
        stop {
            if {[llength $args] != 1} { error "stop expects no arguments" }
            set ::uvhs_keepalive 1
        }
        default {
            error "unknown UVHS runtime command: $command"
        }
    }
    puts "INFO: completed UVHS runtime command: $command"
}

proc uvhs_signal_runtime_ready {} {
    uvhs_write_atomic $::uvhs_ready_file "[pid]\n"
    puts "INFO: UVHS runtime command service is ready"
}

proc uvhs_clear_runtime_ready {} {
    file delete -force $::uvhs_ready_file
}

proc uvhs_write_command_result {result_file status message} {
    if {$result_file eq ""} {
        return
    }
    uvhs_write_atomic $result_file "$status\n$message"
}

proc uvhs_poll_command_file {} {
    set command_file $::uvhs_command_file
    if {[file exists $command_file]} {
        set running_file "${command_file}.running"
        set uvhs_result_file ""
        set command_status [catch {
            file rename -force $command_file $running_file
            puts "INFO: sourcing UVHS runtime command: $running_file"
            source $running_file
        } command_message]
        if {$command_status != 0} {
            set command_message "UVHS runtime command failed: $command_message"
        }
        catch {file delete -force $running_file}
        uvhs_write_command_result $uvhs_result_file $command_status $command_message
        if {$command_status != 0} {
            puts stderr "ERROR: $command_message"
        }
    }
    after 500 uvhs_poll_command_file
}

proc uvhs_serve_runtime_commands {} {
    foreach variable {
        UVHS_COMMAND_FILE UVHS_RUNTIME_READY_FILE UVHS_RUNTIME_WORK_DIR
    } {
        if {![info exists ::env($variable)] || $::env($variable) eq ""} {
            error "$variable is not set"
        }
    }
    set ::uvhs_command_file $::env(UVHS_COMMAND_FILE)
    set ::uvhs_ready_file $::env(UVHS_RUNTIME_READY_FILE)
    set ::uvhs_runtime_work_dir $::env(UVHS_RUNTIME_WORK_DIR)
    set ::uvhs_keepalive 0
    uvhs_signal_runtime_ready
    uvhs_poll_command_file
    vwait ::uvhs_keepalive
    uvhs_clear_runtime_ready
}

proc uvhs_initialize_runtime {} {
    query -user
    query -fpgas -all
    query -version

    if {[info exists ::env(UVHS_DB_PATH)] && $::env(UVHS_DB_PATH) ne ""} {
        set db_path $::env(UVHS_DB_PATH)
    } else {
        set db_path [file normalize [file join [pwd] .. hw.dat]]
    }
    puts "INFO: loading runtime database $db_path"
    load_db -db $db_path

    config -connector
    query -connector -type fmc
    query -voltage

    # A release database can lack sign-off defaults. In that case the replay
    # clock values already stored in the database remain active.
    if {[catch {query -clock -default} clock_error]} {
        puts "WARN: retaining database replay clocks: $clock_error"
    } else {
        config -clock -default
    }
    # Keep clk5_p at the system sign-off frequency committed in this runtime DB.
    # It varies with the partition and PnR result, so it must not be hard-coded.
    config -clock -name clk6_p -frequency 50000000
    uvhs_configure_tmclk_from_cpu
    config -clock -commit
    query -clock

    uvhs_hold_soc_for_download
    download
    query -ipinfo
    initialize
    after 1000
    uvhs_release_soc_after_download
    query -fpgas -all
}

uvhs_initialize_runtime
uvhs_serve_runtime_commands
