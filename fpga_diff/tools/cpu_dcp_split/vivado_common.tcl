proc flow_require_file {path label} {
  if {![file exists $path]} {
    puts stderr "ERROR: $label not found: $path"
    exit 1
  }
}

proc flow_require_positive_int {value label} {
  if {$value ne "" && (![string is integer -strict $value] || $value < 1)} {
    puts stderr "ERROR: $label must be a positive integer, got '$value'"
    exit 1
  }
}

proc flow_require_choice {value choices label} {
  if {[lsearch -exact $choices $value] < 0} {
    puts stderr "ERROR: $label must be one of [join $choices /], got '$value'"
    exit 1
  }
}

proc flow_default_jobs {jobs_arg {half_default 0}} {
  if {$jobs_arg ne ""} {
    return $jobs_arg
  }

  set jobs 1
  if {![catch {exec nproc} nproc_out]} {
    set nproc_trim [string trim $nproc_out]
    if {[scan $nproc_trim "%d" jobs] != 1 || $jobs < 1} {
      set jobs 1
    } elseif {$half_default} {
      set jobs [expr {int(ceil($jobs / 2.0))}]
    }
  }
  if {$jobs < 1} {
    set jobs 1
  }
  return $jobs
}

proc flow_set_optional_property {name value obj} {
  if {[catch {set_property $name $value $obj} err]} {
    puts "WARNING: could not set $name on [get_property NAME $obj]: $err"
    return 0
  }
  return 1
}

proc flow_ensure_utils_file {path} {
  if {[llength [get_filesets -quiet utils_1]] == 0} {
    if {[catch {create_fileset -utils utils_1} err]} {
      puts "WARNING: could not create utils_1 fileset: $err"
      return 0
    }
  }
  if {[llength [get_files -quiet $path]] == 0} {
    if {[catch {add_files -fileset utils_1 -norecurse $path} err]} {
      puts "WARNING: could not add checkpoint to utils_1: $path: $err"
      return 0
    }
  }
  return 1
}

proc flow_write_checkpoint_mode {out_dcp mode} {
  set mode_file [file rootname $out_dcp].mode
  set mode_fh [open $mode_file w]
  puts $mode_fh "checkpoint_mode=$mode"
  close $mode_fh
}

proc flow_write_checkpoint_with_mode {out_dcp checkpoint_mode {record_mode 1}} {
  set actual_mode $checkpoint_mode
  if {$checkpoint_mode eq "incremental_synth"} {
    if {[catch {write_checkpoint -force -incremental_synth $out_dcp} err]} {
      puts "WARNING: write_checkpoint -incremental_synth failed: $err"
      puts "WARNING: Falling back to write_checkpoint -force. This is expected on Vivado 2024.1."
      set actual_mode "normal"
      if {[catch {write_checkpoint -force $out_dcp} fallback_err]} {
        puts stderr "ERROR: failed to write fallback synthesis checkpoint: $fallback_err"
        return -code error $fallback_err
      }
    }
  } else {
    write_checkpoint -force $out_dcp
  }
  if {$record_mode} {
    flow_write_checkpoint_mode $out_dcp $actual_mode
  }
  return $actual_mode
}
