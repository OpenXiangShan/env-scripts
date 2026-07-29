proc uvhs_temp_dir {} {
    if {[info exists ::env(UVHS_RUNTIME_TMP_DIR)] && $::env(UVHS_RUNTIME_TMP_DIR) ne ""} {
        set path $::env(UVHS_RUNTIME_TMP_DIR)
    } else {
        set path [pwd]
    }
    file mkdir $path
    return $path
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
        reset -name rstn_sw5 -value 0
        query -reset
    }
    reset_cpu {
        reset -name rstn_sw5 -value 0
        after 500
        reset -name rstn_sw5 -value 1
        after 500
        query -reset
    }
    write_ddr {
        if {[llength $argv] < 4} {
            error "write_ddr expects 3 arguments"
        }
        reset -name rstn_sw5 -value 0
        after 100
        uvhs_write_ddr_pairs [lindex $argv 1] [lindex $argv 2] [lindex $argv 3]
    }
    stop {
        set ::uvhs_keepalive 1
    }
    default {
        error "unknown UVHS runtime command: $uvhs_command"
    }
}
puts "INFO: completed UVHS runtime command: $uvhs_command"
