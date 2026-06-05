# Hejian runtime flow for programming the board and loading a workload into DDR.
# This intentionally uses UVHS runtime memory commands, not Vivado JTAG scripts.

proc uvhs_env_or_default {name default_value} {
    if {[info exists ::env($name)] && $::env($name) ne ""} {
        return $::env($name)
    }
    return $default_value
}

proc uvhs_find_workload {script_dir} {
    if {[info exists ::env(UVHS_WORKLOAD_TXT)] && $::env(UVHS_WORKLOAD_TXT) ne ""} {
        return [file normalize $::env(UVHS_WORKLOAD_TXT)]
    }

    foreach candidate [list \
        [file join $script_dir .. ready-to-run microbench-nutshell.txt] \
        [file join $script_dir .. microbench-nutshell.txt] \
        [file join [pwd] microbench-nutshell.txt] \
    ] {
        if {[file exists $candidate]} {
            return [file normalize $candidate]
        }
    }

    error "UVHS_WORKLOAD_TXT is not set and no default microbench-nutshell.txt was found"
}

proc uvhs_parse_hex_uint {text label line_no} {
    set value 0
    set text [string trim $text]
    if {![regexp {^[0-9a-fA-F]+$} $text]} {
        error "invalid hex $label on line $line_no: $text"
    }
    scan $text %llx value
    return $value
}

proc uvhs_gcd {a b} {
    set a [expr {abs($a)}]
    set b [expr {abs($b)}]
    while {$b != 0} {
        set t [expr {$a % $b}]
        set a $b
        set b $t
    }
    return $a
}

proc uvhs_workload_range_from_txt {workload_txt unit_bytes_override} {
    if {$unit_bytes_override ne "auto"} {
        if {$unit_bytes_override <= 0} {
            error "UVHS_DDR_RANGE_UNIT_BYTES must be positive or auto"
        }
        set unit_bytes $unit_bytes_override
    } else {
        set unit_bytes 0
    }

    set fh [open $workload_txt r]
    set line_no 0
    set expect_addr 1
    set current_addr 0
    set previous_addr -1
    set min_addr -1
    set max_end 0

    while {[gets $fh line] >= 0} {
        incr line_no
        set line [string trim $line]
        if {$line eq "" || [string match "#*" $line]} {
            continue
        }

        if {$expect_addr} {
            set current_addr [uvhs_parse_hex_uint $line "address" $line_no]
            if {$previous_addr >= 0 && $current_addr > $previous_addr && $unit_bytes_override eq "auto"} {
                set addr_delta [expr {$current_addr - $previous_addr}]
                set unit_bytes [expr {$unit_bytes == 0 ? $addr_delta : [uvhs_gcd $unit_bytes $addr_delta]}]
            }
            set previous_addr $current_addr
            set expect_addr 0
            continue
        }

        if {[string length $line] % 2 != 0} {
            close $fh
            error "invalid odd-length hex data on line $line_no"
        }
        if {![regexp {^[0-9a-fA-F]+$} $line]} {
            close $fh
            error "invalid hex data on line $line_no"
        }

        set byte_count [expr {[string length $line] / 2}]
        if {$byte_count > 0} {
            if {$unit_bytes_override eq "auto"} {
                set unit_bytes [expr {$unit_bytes == 0 ? $byte_count : [uvhs_gcd $unit_bytes $byte_count]}]
            }
            set end_addr [expr {$current_addr + $byte_count}]
            if {$min_addr < 0 || $current_addr < $min_addr} {
                set min_addr $current_addr
            }
            if {$end_addr > $max_end} {
                set max_end $end_addr
            }
        }
        set expect_addr 1
    }
    close $fh

    if {!$expect_addr} {
        error "workload file ended after address without data: $workload_txt"
    }
    if {$min_addr < 0} {
        error "workload file has no data: $workload_txt"
    }
    if {$unit_bytes <= 0} {
        set unit_bytes [expr {$max_end - $min_addr}]
    }

    set range_start [expr {$min_addr / $unit_bytes}]
    set range_end [expr {($max_end + $unit_bytes - 1) / $unit_bytes - 1}]
    return [list "${range_start}:${range_end}" $min_addr $max_end $unit_bytes]
}

set uvhs_script_dir [file dirname [file normalize [info script]]]

set uvhs_db_path [uvhs_env_or_default UVHS_DB_PATH [file normalize [file join $uvhs_script_dir .. hw.dat]]]
set uvhs_workload_txt [uvhs_find_workload $uvhs_script_dir]
set uvhs_ddr_rtl [uvhs_env_or_default UVHS_DDR_RTL fpga_top_debug.core_def.U_JTAG_DDR_SUBSYS.mmp_i.DDR_MODEL_U0.u_mmk_ddr5_core_cha_rank0.u_array.memory]
set uvhs_mem_cmd [uvhs_env_or_default UVHS_MEM_CMD writeback_memory]
set uvhs_readback [uvhs_env_or_default UVHS_READBACK 0]
set uvhs_keepalive [uvhs_env_or_default UVHS_KEEPALIVE 0]
set uvhs_auto_ddr_range [uvhs_env_or_default UVHS_AUTO_DDR_RANGE 1]
set uvhs_ddr_range_unit_bytes [uvhs_env_or_default UVHS_DDR_RANGE_UNIT_BYTES auto]

if {[info exists ::env(UVHS_DDR_RANGE)] && $::env(UVHS_DDR_RANGE) ne ""} {
    append uvhs_ddr_rtl {[} $::env(UVHS_DDR_RANGE) {]}
} elseif {$uvhs_auto_ddr_range ne "0"} {
    set uvhs_auto_range_info [uvhs_workload_range_from_txt $uvhs_workload_txt $uvhs_ddr_range_unit_bytes]
    set uvhs_auto_range [lindex $uvhs_auto_range_info 0]
    set uvhs_auto_min_addr [lindex $uvhs_auto_range_info 1]
    set uvhs_auto_max_end [lindex $uvhs_auto_range_info 2]
    set uvhs_auto_unit_bytes [lindex $uvhs_auto_range_info 3]
    puts "INFO: auto DDR range $uvhs_auto_range from workload byte span 0x[format %x $uvhs_auto_min_addr]..0x[format %x [expr {$uvhs_auto_max_end - 1}]] with unit $uvhs_auto_unit_bytes byte(s)"
    append uvhs_ddr_rtl {[} $uvhs_auto_range {]}
}

puts "INFO: loading runtime database $uvhs_db_path"
load_db -db $uvhs_db_path

config -connector
query -connector -type fmc
query -voltage

reset -name rstn_sw6 -value 0
reset -name rstn_sw5 -value 0
reset -name rstn_sw4 -value 0
query -reset

download
query -ipinfo
initialize
after 1000

reset -name rstn_sw6 -value 0
reset -name rstn_sw5 -value 0
reset -name rstn_sw4 -value 0
after 1000

reset -name rstn_sw6 -value 1
reset -name rstn_sw4 -value 1
after 1000

puts "INFO: writing workload $uvhs_workload_txt to DDR RTL $uvhs_ddr_rtl with $uvhs_mem_cmd"
if {$uvhs_mem_cmd eq "writeback_memory"} {
    writeback_memory -rtl $uvhs_ddr_rtl -file $uvhs_workload_txt -hex
} else {
    writemem -rtl $uvhs_ddr_rtl -file $uvhs_workload_txt -hex
}
after 1000

if {$uvhs_readback ne "0"} {
    set uvhs_readback_file [uvhs_env_or_default UVHS_READBACK_FILE "${uvhs_workload_txt}.readback"]
    puts "INFO: reading DDR RTL $uvhs_ddr_rtl back to $uvhs_readback_file"
    readmem -rtl $uvhs_ddr_rtl -file $uvhs_readback_file -hex
}

reset -name rstn_sw5 -value 1
after 1000
query -reset
query -fpgas -all

if {$uvhs_keepalive ne "0"} {
    set ::uvhs_keepalive 0
    vwait ::uvhs_keepalive
}

exit
