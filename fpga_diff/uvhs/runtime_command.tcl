if {[llength [info commands uvhs_reset_cpu]] == 0} {
    set uvhs_script_dir [file dirname [file normalize [info script]]]
    source [file join $uvhs_script_dir runtime_control.tcl]
}

proc uvhs_temp_dir {} {
    if {[info exists ::env(UVHS_RUNTIME_TMP_DIR)] && $::env(UVHS_RUNTIME_TMP_DIR) ne ""} {
        set path $::env(UVHS_RUNTIME_TMP_DIR)
    } else {
        set path [pwd]
    }
    file mkdir $path
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

proc uvhs_write_flash_gbus {input_file board fpga port channel base capacity} {
    if {![file exists $input_file]} {
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
    if {![file exists $input_file]} {
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
        if {[scan $address_text %llx byte_address] != 1 || [expr {$byte_address % $beat_bytes}] != 0} {
            close $input
            error "DDR address is not aligned to $beat_bytes bytes: $address_text"
        }

        set beat_count [expr {[string length $data_text] / $beat_chars}]
        set start_word [expr {$byte_address / $beat_bytes}]
        set end_word [expr {$start_word + $beat_count - 1}]
        set temp_file [file join [uvhs_temp_dir] [format "ddr-%d-%d.hex" [pid] $segment]]
        incr segment

        set output [open $temp_file w]
        for {set beat 0} {$beat < $beat_count} {incr beat} {
            set first [expr {[string length $data_text] - ($beat + 1) * $beat_chars}]
            puts $output [string range $data_text $first [expr {$first + $beat_chars - 1}]]
        }
        close $output

        puts [format "INFO: DDR backdoor write %s words 0x%llx..0x%llx" \
            $beat_count $start_word $end_word]
        set status [catch {
            writemem -rtl $rtl_path -start $start_word -end $end_word -file $temp_file -hex
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

if {[llength $argv] == 0} {
    error "missing UVHS runtime command"
}

set uvhs_command [lindex $argv 0]
puts "INFO: executing UVHS runtime command: $uvhs_command"
switch -- $uvhs_command {
    halt_soc {
        uvhs_halt_soc
    }
    reset_cpu {
        uvhs_reset_cpu
    }
    write_ddr {
        if {[llength $argv] < 4} {
            error "write_ddr expects 3 arguments"
        }
        uvhs_hold_cpu_for_memory
        uvhs_write_ddr_pairs [lindex $argv 1] [lindex $argv 2] [lindex $argv 3]
    }
    write_flash {
        if {[llength $argv] < 8} {
            error "write_flash expects 7 arguments"
        }
        uvhs_hold_cpu_for_memory
        uvhs_write_flash_gbus {*}[lrange $argv 1 7]
        uvhs_release_cpu_after_memory
    }
    stop {
        set ::uvhs_keepalive 1
    }
    default {
        error "unknown UVHS runtime command: $uvhs_command"
    }
}
puts "INFO: completed UVHS runtime command: $uvhs_command"
