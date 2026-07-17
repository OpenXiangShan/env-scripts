proc usage {} {
  puts "Usage: vivado -mode tcl -source tools/jtag_write_flash.tcl -tclargs <bin>"
  puts "  flash base is 0x10000000, capacity is 32 KiB, max burst is 256 words."
}

if {[llength $argv] < 1} {
  usage
  exit 1
}

set file_name [lindex $argv 0]
set flash_base 0x10000000
set flash_size_bytes 0x8000
set flash_axi_name flash
set max_burst_words 256

if {![file exists $file_name]} {
  puts "Error: input binary not found: $file_name"
  exit 1
}

proc parse_addr {value} {
  if {[scan $value "%llx" parsed] == 1} {
    return $parsed
  }
  error "invalid address: $value"
}

proc parse_positive_int {value name} {
  if {![string is integer -strict $value]} {
    error "$name must be an integer: $value"
  }
  set parsed [expr {$value}]
  if {$parsed < 1 || $parsed > 256} {
    error "$name must be in range 1..256: $value"
  }
  return $parsed
}

proc open_target {} {
  if {[catch {open_hw_manager} errmsg]} {
    puts "Error initializing LabTools system: $errmsg"
    exit 1
  }
  if {[catch {connect_hw_server} errmsg]} {
    puts "Error connecting to hardware server: $errmsg"
    exit 1
  }
  if {[catch {open_hw_target} errmsg]} {
    puts "Error opening hardware target: $errmsg"
    exit 1
  }

  set_property PARAM.FREQUENCY 12000000 [current_hw_target]

  set hw_device [lindex [get_hw_devices] 0]
  if {$hw_device eq ""} {
    puts "Error: No hardware device found. Please check the hardware connection."
    exit 1
  }
  puts "Hardware device found: $hw_device"
  refresh_hw_device $hw_device
}

proc select_axi {axi_name} {
  set hw_axi_list [get_hw_axis]
  if {[llength $hw_axi_list] == 0} {
    puts "Error: No AXI interfaces found. Please check the hardware design."
    exit 1
  }

  puts "Available AXI interfaces:"
  foreach axi $hw_axi_list {
    puts "  $axi"
  }

  if {$axi_name eq "flash"} {
    set flash_axi_list {}
    foreach axi $hw_axi_list {
      if {[get_property AXI_DATA_WIDTH $axi] == 32} {
        lappend flash_axi_list $axi
      }
    }
    if {[llength $flash_axi_list] != 1} {
      puts "Error: flash AXI selection is ambiguous. Pass the flash AXI name explicitly."
      exit 1
    }
    return [lindex $flash_axi_list 0]
  }

  set hw_axi [get_hw_axis $axi_name]
  if {$hw_axi eq ""} {
    puts "Error: $axi_name not found."
    exit 1
  }
  return $hw_axi
}

proc check_flash_axi {hw_axi} {
  set data_width [get_property AXI_DATA_WIDTH $hw_axi]
  set core_uuid [get_property CORE_UUID $hw_axi]
  puts "Selected AXI data width: $data_width"
  puts "Selected AXI core UUID: $core_uuid"
  if {$data_width != 32} {
    error "$hw_axi is ${data_width}-bit, not the 32-bit flash JTAG AXI"
  }
}

proc read_binary {fn} {
  set f [open $fn rb]
  fconfigure $f -translation binary
  set data [read $f]
  close $f
  binary scan $data c* signed_bytes

  set bytes {}
  foreach b $signed_bytes {
    lappend bytes [expr {$b & 0xff}]
  }
  return $bytes
}

proc check_flash_size {bytes capacity} {
  set byte_count [llength $bytes]
  if {$byte_count > $capacity} {
    error "binary size $byte_count bytes exceeds flash capacity $capacity bytes"
  }
  puts [format "Flash capacity: %d bytes (0x%x), input: %d bytes" $capacity $capacity $byte_count]
}

proc word_hex {bytes start} {
  set parts {}
  for {set i 3} {$i >= 0} {incr i -1} {
    set idx [expr {$start + $i}]
    if {$idx < [llength $bytes]} {
      set b [lindex $bytes $idx]
    } else {
      set b 0
    }
    append parts [format "%02x" $b]
  }
  return $parts
}

proc write_flash {bytes hw_axi base_addr max_len} {
  set beat_bytes 4
  set total_words [expr {([llength $bytes] + $beat_bytes - 1) / $beat_bytes}]
  if {$total_words == 0} {
    puts "No data to write."
    return
  }

  puts "Writing [llength $bytes] bytes, $total_words 32-bit words, base [format 0x%08llx $base_addr], max burst $max_len"
  set word_index 0
  set prev_percent -1
  set start_time [clock seconds]

  while {$word_index < $total_words} {
    set chunk_len [expr {$total_words - $word_index}]
    if {$chunk_len > $max_len} {
      set chunk_len $max_len
    }

    set data_hex ""
    # Vivado maps the rightmost data beat to the lowest INCR address.
    for {set i [expr {$chunk_len - 1}]} {$i >= 0} {incr i -1} {
      append data_hex [word_hex $bytes [expr {($word_index + $i) * $beat_bytes}]]
    }

    set addr [expr {$base_addr + $word_index * $beat_bytes}]
    create_hw_axi_txn wr_flash_txn $hw_axi -address [format "%llx" $addr] -data $data_hex -len $chunk_len -burst INCR -type write
    run_hw_axi wr_flash_txn
    delete_hw_axi_txn wr_flash_txn

    incr word_index $chunk_len
    set percent [expr {int(($word_index * 100) / $total_words)}]
    if {$percent > $prev_percent || $word_index == $total_words} {
      set end_time [clock seconds]
      set time_diff [expr {$end_time - $start_time}]
      set minutes [expr {$time_diff / 60}]
      set seconds [expr {$time_diff % 60}]
      puts [format "  %3d%% | %d/%d words | %02d:%02d" $percent $word_index $total_words $minutes $seconds]
      set prev_percent $percent
    }
  }
}

proc read_word {hw_axi addr} {
  create_hw_axi_txn rd_flash_txn $hw_axi -address [format "%llx" $addr] -len 1 -type read
  run_hw_axi rd_flash_txn
  set data [get_property DATA [get_hw_axi_txns rd_flash_txn]]
  delete_hw_axi_txn rd_flash_txn
  return [string tolower [string range $data 0 7]]
}

proc verify_samples {bytes hw_axi base_addr} {
  set total_words [expr {([llength $bytes] + 3) / 4}]
  set samples [list 0]
  if {$total_words > 2} {
    lappend samples [expr {$total_words / 2}]
  }
  if {$total_words > 1} {
    lappend samples [expr {$total_words - 1}]
  }

  puts "Readback samples:"
  foreach word_index $samples {
    set addr [expr {$base_addr + $word_index * 4}]
    set expected [word_hex $bytes [expr {$word_index * 4}]]
    set actual [read_word $hw_axi $addr]
    puts [format "  addr 0x%08llx expected %s actual %s" $addr $expected $actual]
    if {$actual ne $expected} {
      error "readback mismatch at [format 0x%08llx $addr]: expected $expected actual $actual"
    }
  }
}

if {[catch {
  set base_addr [parse_addr $flash_base]
  set max_len [parse_positive_int $max_burst_words "max_burst_words"]
  set bytes [read_binary $file_name]
  check_flash_size $bytes $flash_size_bytes
  open_target
  set hw_axi [select_axi $flash_axi_name]
  puts "Using flash AXI interface: $hw_axi"
  check_flash_axi $hw_axi
  write_flash $bytes $hw_axi $base_addr $max_len
  verify_samples $bytes $hw_axi $base_addr
  puts "Flash write and sample readback passed."
} errmsg]} {
  puts "ErrorMsg: $errmsg"
  exit 1
}

exit 0
