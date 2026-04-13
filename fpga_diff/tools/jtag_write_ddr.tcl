puts "workload path:"
puts [lindex $argv 0]
set file_name [lindex $argv 0]

# 3rd argument: .ltx probe file path for VIO halt (sw6=0)
set ltx_file [lindex $argv 2]
if {$ltx_file eq "" || ![file exists $ltx_file]} {
    puts "ERROR: .ltx probe file required as 3rd argument"
    puts "Usage: jtag_write_ddr.tcl <workload.txt> <axi_width> <probes.ltx>"
    exit 1
}

# Initialize LabTools system
if {[catch {open_hw_manager} errmsg]} {
    puts "Error initializing LabTools system: $errmsg"
    exit
} else {
    puts "LabTools system initialized"
}

# Connect to hardware server
if {[catch {connect_hw_server} errmsg]} {
    puts "Error connecting to hardware server: $errmsg"
    exit
} else {
    puts "Connected to hardware server"
}

# Open hardware target (JTAG device)
if {[catch {open_hw_target} errmsg]} {
    puts "Error opening hardware target: $errmsg"
    exit
} else {
    puts "Opened hardware target"
}

set_property PARAM.FREQUENCY 12000000 [current_hw_target]

# Get JTAG device handle
set hw_device [lindex [get_hw_devices] 0]
if {$hw_device eq ""} {
    puts "Error: No hardware device found. Please check the hardware connection."
    exit
} else {
    puts "Hardware device found: $hw_device"
}
puts "Refreshing hardware device..."
refresh_hw_device $hw_device

# Halt system (sw6=0) before DDR write to prevent CPU from modifying DDR.
# This avoids the need for a separate reset_ddr.tcl call (and its destructive
# DDR controller warm-reset via sw4 toggle).
puts "Loading probes from $ltx_file for system halt..."
set_property PROBES.FILE $ltx_file [current_hw_device]
refresh_hw_device [current_hw_device]
refresh_hw_vio hw_vio_1
# vio_sw6 0 (halt system)
set_property OUTPUT_VALUE 0 [get_hw_probes vio_sw6 -of_objects [get_hw_vios hw_vio_1]]
commit_hw_vio [get_hw_probes {vio_sw6} -of_objects [get_hw_vios hw_vio_1]]
puts "System halted (sw6=0)"
after 500

# List all AXI interfaces
set hw_axi_list [get_hw_axis]
if {[llength $hw_axi_list] == 0} {
    puts "No AXI interfaces found. Please check the hardware design."
    exit
} else {
    puts "Available AXI interfaces:"
    foreach axi $hw_axi_list {
        puts $axi
    }
}

# Get AXI interface handle
set hw_axi [get_hw_axis hw_axi_1]
if {$hw_axi eq ""} {
    puts "Error: hw_axi_1 not found. Please check the AXI interface configuration."
    exit
} else {
    puts "hw_axi_1 found: $hw_axi"
}

set hw_axi_data_width 64
if {[llength $argv] > 1} {
    set arg_width [lindex $argv 1]
    if {[string is integer -strict $arg_width] && $arg_width == 32} {
        set hw_axi_data_width $arg_width
        puts "Using AXI data width from argument: $hw_axi_data_width"
    } else {
        puts "Warning: AXI width argument must be 32 to override default. Using default 64."
    }
}
puts "Using AXI data width: $hw_axi_data_width"

proc write_to_ddr {fn hw_axi hw_axi_data_width} {
  puts "Write to DDR: $fn ..."
  set fdata [open $fn r]
  set idx 0
  set total 0
  set line 0
  while {[gets $fdata dummy] >= 0} {
      incr line
  }
  if {$line % 2 != 0} {
      puts "Error: input file has odd number of lines, expected address/data pairs."
      close $fdata
      return -code error
  }
  set total [expr {$line / 2}]
  seek $fdata 0 start

  set prev_percent -1
  set terminal_width 80
  if {[catch {exec tput cols} terminal_width] || $terminal_width < 1} {
      set terminal_width 80
  }
  set progress_bar_length [expr {int($terminal_width * 0.4)}]
  set start_time [clock seconds]
  set beat_bytes [expr {$hw_axi_data_width / 8}]
  set beat_hex_chars [expr {$beat_bytes * 2}]
  set max_len 256

  if {$total == 0} {
      puts "No data to write."
      close $fdata
      return
  }

  while {1} {
    if {[gets $fdata aline] < 0} {
        break
    }
    if {[gets $fdata dline] < 0} {
        puts "Error: missing data line for address line: $aline"
        close $fdata
        return -code error
    }

    set AddrString [string trim $aline]
    set DataString [string trim $dline]
    if {$AddrString eq "" || $DataString eq ""} {
      break
    }

    if {[expr {[string length $DataString] % $beat_hex_chars}] != 0} {
        puts "Error: DataString length is not aligned to ${hw_axi_data_width}-bit beats."
        close $fdata
        return -code error
    }

    if {[scan $AddrString "%llx" addr_val] != 1} {
        puts "Error: Invalid address format: $AddrString"
        close $fdata
        return -code error
    }

    if {[expr {$addr_val % $beat_bytes}] != 0} {
        puts "Error: Address is not ${beat_bytes}-byte aligned: $AddrString"
        close $fdata
        return -code error
    }

    set len [expr {[string length $DataString] / $beat_hex_chars}]
    if {$len < 1} {
        puts "Error: DataString contains no beats."
        close $fdata
        return -code error
    }

    set start_addr $addr_val
    set remaining_len $len
    while {$remaining_len > 0} {
        set chunk_len [expr {$remaining_len > $max_len ? $max_len : $remaining_len}]
        set chunk_hex_chars [expr {$chunk_len * $beat_hex_chars}]
        set DataChunk [string range $DataString 0 [expr {$chunk_hex_chars - 1}]]

        create_hw_axi_txn wr_txn $hw_axi -address [format "%llx" $start_addr] -data $DataChunk -len $chunk_len -burst INCR -type write
        run_hw_axi wr_txn
        delete_hw_axi_txn wr_txn

        set start_addr [expr {$start_addr + $chunk_len * $beat_bytes}]
        set DataString [string range $DataString $chunk_hex_chars end]
        set remaining_len [expr {$remaining_len - $chunk_len}]
    }

    incr idx
    set percent [expr {int(($idx * 100) / $total)}]
    if {$percent > $prev_percent || $idx == $total} {
        set completed_length [expr {int(($percent * $progress_bar_length) / 100)}]
        set progress [string repeat "#" $completed_length]
        set spaces [string repeat " " [expr {$progress_bar_length - $completed_length}]]

        set end_time [clock seconds]
        set time_diff [expr {$end_time - $start_time}]
        set minutes [expr {$time_diff / 60}]
        set seconds [expr {$time_diff % 60}]
        set progress_bar [format "\r\[%s%s\] %3d%% | %d/%d Total %02d:%02d" $progress $spaces $percent $idx $total $minutes $seconds]
        puts -nonewline $progress_bar
        flush stdout
        set prev_percent $percent
    }
  }
  close $fdata
}

if {[catch {[write_to_ddr $file_name $hw_axi $hw_axi_data_width]} errmsg]} {
  puts "ErrorMsg: $errmsg"
}
puts "After"

exit
