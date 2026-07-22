########################################################################
# Common helpers for parallel OOC partition declarations.
########################################################################

set ps_dir [file normalize [file dirname [info script]]]
set ps_partition_file [file normalize "$ps_dir/partitions.tcl"]

proc ps_load_partitions {} {
  global ps_partition_file ps_partition_specs ps_partitions
  global ps_partition_top ps_partition_blackboxes ps_partition_clocks

  unset -nocomplain ps_partition_specs ps_partition_clock_ports ps_partitions
  unset -nocomplain ps_partition_top ps_partition_blackboxes
  unset -nocomplain ps_partition_clocks

  source $ps_partition_file
  if {![info exists ps_partition_specs]} {
    error "partition file does not set ps_partition_specs: $ps_partition_file"
  }

  set ps_partitions {}
  array set seen_tops {}
  foreach spec $ps_partition_specs {
    if {[llength $spec] == 0} {
      continue
    }

    set kind [lindex $spec 0]
    switch -- $kind {
      module {
        if {[llength $spec] != 3} {
          error "invalid module partition declaration: $spec"
        }
        lassign $spec _ name top
        set blackboxes {}
      }
      without {
        if {[llength $spec] != 4} {
          error "invalid without partition declaration: $spec"
        }
        lassign $spec _ name top blackboxes
        if {[llength $blackboxes] == 0} {
          error "without partition needs at least one child module: $spec"
        }
      }
      default {
        error "unknown partition declaration '$kind': $spec"
      }
    }

    if {$name eq "" || $top eq ""} {
      error "partition name and top module must be nonempty: $spec"
    }
    if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $top]} {
      error "unsupported top module name '$top'"
    }
    foreach blackbox $blackboxes {
      if {![regexp {^[A-Za-z_][A-Za-z0-9_]*$} $blackbox]} {
        error "unsupported child module name '$blackbox'"
      }
    }
    if {[lsearch -exact $ps_partitions $name] >= 0} {
      error "duplicate partition name '$name'"
    }
    if {[info exists seen_tops($top)]} {
      error "module '$top' is the top of more than one partition"
    }

    lappend ps_partitions $name
    set ps_partition_top($name) $top
    set seen_tops($top) $name
    if {[llength $blackboxes] > 0} {
      set ps_partition_blackboxes($name) $blackboxes
    }
  }

  if {![info exists ps_partition_clock_ports]} {
    set ps_partition_clock_ports {}
  }
  if {[llength $ps_partition_clock_ports] % 2 != 0} {
    error "partition clock mapping must be a key/value list: $ps_partition_clock_ports"
  }
  array set declared_partition_clocks $ps_partition_clock_ports
  foreach partition [array names declared_partition_clocks] {
    if {[lsearch -exact $ps_partitions $partition] < 0} {
      error "clock mapping references unknown partition '$partition'"
    }
  }
  foreach partition $ps_partitions {
    set clocks {}
    if {[info exists declared_partition_clocks($partition)]} {
      unset -nocomplain seen_clock_names seen_port_names
      array set seen_clock_names {}
      array set seen_port_names {}
      foreach mapping $declared_partition_clocks($partition) {
        if {[llength $mapping] != 2} {
          error "invalid clock mapping for partition '$partition': $mapping"
        }
        lassign $mapping clock_name port_name
        if {$clock_name eq "" || $port_name eq ""} {
          error "clock mapping needs a clock and port for partition '$partition': $mapping"
        }
        if {[info exists seen_clock_names($clock_name)]} {
          error "duplicate clock '$clock_name' for partition '$partition'"
        }
        if {[info exists seen_port_names($port_name)]} {
          error "duplicate port '$port_name' for partition '$partition'"
        }
        set seen_clock_names($clock_name) 1
        set seen_port_names($port_name) 1
        lappend clocks [list $clock_name $port_name]
      }
    }
    set ps_partition_clocks($partition) $clocks
  }
}

proc ps_partition_top {partition} {
  global ps_partition_top
  return $ps_partition_top($partition)
}

proc ps_partition_blackboxes {partition} {
  global ps_partition_blackboxes
  if {[info exists ps_partition_blackboxes($partition)]} {
    return $ps_partition_blackboxes($partition)
  }
  return {}
}

proc ps_partition_clocks {partition} {
  global ps_partition_clocks
  return $ps_partition_clocks($partition)
}

if {[info exists argv0] && [file normalize $argv0] eq [file normalize [info script]]} {
  if {[llength $argv] != 1} {
    puts "Usage: tclsh defs.tcl partitions"
    exit 1
  }
  ps_load_partitions
  switch -- [lindex $argv 0] {
    partitions { puts [join $ps_partitions ","] }
    default {
      puts "Usage: tclsh defs.tcl partitions"
      exit 1
    }
  }
}
