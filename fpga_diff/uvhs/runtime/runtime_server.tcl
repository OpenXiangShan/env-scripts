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

proc uvhs_write_flash_gbus {input_file board fpga port channel base capacity} {
    if {![file isfile $input_file]} {
        error "flash image not found: $input_file"
    }

    if {[regexp -nocase {^b([0-9]+)$} $board -> board_index]} {
        set board $board_index
    }
    if {![string is integer -strict $board]} {
        error "generalBus board must be an index or B<index>: $board"
    }
    if {![regexp -nocase {^f([0-9]+)$} $fpga -> fpga_index]} {
        error "generalBus FPGA must be F<index>: $fpga"
    }
    set fpga f$fpga_index
    set port [uvhs_parse_integer "generalBus port" $port]
    set channel [uvhs_parse_integer "generalBus channel" $channel]
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

    puts [format "INFO: generalBus flash write 0x%llx, %d bytes" $base $transfer_size]
    set status [catch {
        gbus_dma_write -board $board -fpga $fpga -port $port \
            -addr $base -size $transfer_size -channel $channel -file $write_file
        gbus_dma_read -board $board -fpga $fpga -port $port \
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

proc uvhs_ila_arm {
    trigger_file position gated_clock gated_clock_frequency
} {
    if {![file isfile $trigger_file]} {
        error "trigger condition file not found: $trigger_file"
    }
    set position [uvhs_parse_integer "capture position" $position]
    if {$position < 0 || $position > 100} {
        error "capture position must be between 0 and 100: $position"
    }
    if {$gated_clock ne ""} {
        set gated_clock_frequency [uvhs_parse_integer \
            "gated capture clock frequency" $gated_clock_frequency]
        if {$gated_clock_frequency <= 0} {
            error "gated capture clock frequency must be positive"
        }
    }

    unset -nocomplain ::uvhs_ila_position
    trigger -clear
    query -trigger
    trigger -ini_check $trigger_file
    if {$gated_clock ne ""} {
        trigger -set -gatedclk $gated_clock \
            -frequency $gated_clock_frequency -polarity H
    }
    trigger -set -condition $trigger_file -position $position
    capture -enable
    trigger -enable
    set ::uvhs_ila_position $position
    puts "INFO: UVHS waveform capture armed at position $position"
}

proc uvhs_ila_wait {output_name timeout depth clock} {
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

    set trigger_status [trigger -status -wait 1 -timeout $timeout -tclobj]
    puts "INFO: UVHS trigger status: $trigger_status"
    if {![regexp -nocase {Waveform Data Ready\s+true} $trigger_status]} {
        error "UVHS waveform data is not ready"
    }

    set output_dir [file join [uvhs_prepare_uhd_root] $output_name]
    file delete -force $output_dir
    set upload_options [list -depth $depth \
        -position $::uvhs_ila_position]
    if {$clock ne ""} {
        lappend upload_options -clock $clock
    }
    lappend upload_options -out $output_name
    upload_uhd {*}$upload_options
    wavegen -bindir [file join UHD $output_name]

    set usdb [file join $output_dir UvData.usdb]
    if {![file exists $usdb] || [file size $usdb] == 0} {
        error "UVHS waveform database was not generated: $usdb"
    }
    puts "INFO: UVHS waveform database generated: $usdb"
}

proc uvhs_ila_clear {} {
    trigger -clear
    unset -nocomplain ::uvhs_ila_position
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
            if {[llength $args] != 8} { error "write_flash expects 7 arguments" }
            uvhs_hold_cpu_for_memory
            uvhs_write_flash_gbus {*}[lrange $args 1 7]
            uvhs_release_cpu_after_memory
        }
        ila_arm {
            if {[llength $args] != 5} { error "ila_arm expects 4 arguments" }
            uvhs_ila_arm {*}[lrange $args 1 4]
        }
        ila_wait {
            if {[llength $args] != 5} { error "ila_wait expects 4 arguments" }
            uvhs_ila_wait {*}[lrange $args 1 4]
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
    config -clock -name clk5_p -frequency 25000000
    config -clock -name clk6_p -frequency 50000000
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
