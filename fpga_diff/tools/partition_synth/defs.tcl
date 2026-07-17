########################################################################
# Common helpers for partition synthesis declarations.
########################################################################

set ps_dir [file normalize [file dirname [info script]]]
set ps_partition_file [file normalize "$ps_dir/partitions.tcl"]

proc ps_load_partitions {} {
  global ps_partition_file ps_partition_specs ps_partitions
  global ps_partition_top ps_partition_blackboxes ps_partition_by_top
  global ps_partition_children ps_partition_clocks ps_link_order ps_root_partition

  unset -nocomplain ps_partition_specs ps_partition_clock_ports ps_partitions
  unset -nocomplain ps_partition_top ps_partition_blackboxes
  unset -nocomplain ps_partition_by_top ps_partition_children ps_partition_clocks
  unset -nocomplain ps_link_order ps_root_partition ps_visit_state

  source $ps_partition_file
  if {![info exists ps_partition_specs]} {
    error "partition file does not set ps_partition_specs: $ps_partition_file"
  }

  set ps_partitions {}
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
    if {[info exists ps_partition_by_top($top)]} {
      error "module '$top' is the top of more than one partition"
    }

    lappend ps_partitions $name
    set ps_partition_top($name) $top
    set ps_partition_by_top($top) $name
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

  array set referenced {}
  foreach partition $ps_partitions {
    set children {}
    foreach module [ps_partition_blackboxes $partition] {
      if {![info exists ps_partition_by_top($module)]} {
        error "partition '$partition' has no child partition for module '$module'"
      }
      set child $ps_partition_by_top($module)
      if {$child eq $partition} {
        error "partition '$partition' cannot contain itself"
      }
      lappend children $child
      set referenced($child) 1
    }
    set ps_partition_children($partition) $children
  }

  set roots {}
  foreach partition $ps_partitions {
    if {![info exists referenced($partition)]} {
      lappend roots $partition
    }
  }
  if {[llength $roots] != 1} {
    error "partition hierarchy must have one root, found: $roots"
  }
  set ps_root_partition [lindex $roots 0]

  set ps_link_order {}
  ps_visit_partition $ps_root_partition
  if {[llength $ps_link_order] != [llength $ps_partitions]} {
    error "some partitions are disconnected from root '$ps_root_partition'"
  }
}

proc ps_visit_partition {partition} {
  global ps_partition_children ps_link_order ps_visit_state

  if {[info exists ps_visit_state($partition)]} {
    if {$ps_visit_state($partition) eq "visiting"} {
      error "cycle detected at partition '$partition'"
    }
    return
  }

  set ps_visit_state($partition) visiting
  foreach child $ps_partition_children($partition) {
    ps_visit_partition $child
  }
  set ps_visit_state($partition) done
  lappend ps_link_order $partition
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

proc ps_partition_children {partition} {
  global ps_partition_children
  return $ps_partition_children($partition)
}

proc ps_partition_clocks {partition} {
  global ps_partition_clocks
  return $ps_partition_clocks($partition)
}

proc ps_root_partition {} {
  global ps_root_partition
  return $ps_root_partition
}

proc ps_link_order {} {
  global ps_link_order
  return $ps_link_order
}

if {[info exists argv0] && [file normalize $argv0] eq [file normalize [info script]]} {
  if {[llength $argv] != 1} {
    puts "Usage: tclsh defs.tcl partitions|link-order|root"
    exit 1
  }
  ps_load_partitions
  switch -- [lindex $argv 0] {
    partitions { puts [join $ps_partitions ","] }
    link-order { puts [join [ps_link_order] ","] }
    root { puts [ps_root_partition] }
    default {
      puts "Usage: tclsh defs.tcl partitions|link-order|root"
      exit 1
    }
  }
}
