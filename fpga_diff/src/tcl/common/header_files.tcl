########################################################################
# Mark files that are parsed through include as Verilog headers.
########################################################################

proc fpga_append_unique {var_name value} {
  upvar 1 $var_name values
  if {[lsearch -exact $values $value] < 0} {
    lappend values $value
  }
}

proc fpga_included_source_files {files include_dirs} {
  array set known_files {}
  set search_dirs {}

  foreach dir $include_dirs {
    if {[file isdirectory $dir]} {
      fpga_append_unique search_dirs [file normalize $dir]
    }
  }
  foreach file $files {
    if {![file isfile $file]} {
      continue
    }
    set path [file normalize $file]
    set known_files($path) 1
  }

  array set included_files {}
  foreach file [array names known_files] {
    set in [open $file r]
    while {[gets $in line] >= 0} {
      if {![regexp {^[[:space:]]*\x60include[[:space:]]+["<]([^">]+)[">]} $line -> include_path]} {
        continue
      }

      if {[file pathtype $include_path] eq "absolute"} {
        set candidates [list [file normalize $include_path]]
      } else {
        set candidates [list [file normalize [file join [file dirname $file] $include_path]]]
        foreach dir $search_dirs {
          lappend candidates [file normalize [file join $dir $include_path]]
        }
      }

      foreach candidate $candidates {
        if {[info exists known_files($candidate)]} {
          set included_files($candidate) 1
          break
        }
      }
    }
    close $in
  }
  return [array names included_files]
}

proc fpga_set_header_file_types {files include_dirs} {
  array set header_files {}
  foreach file [fpga_included_source_files $files $include_dirs] {
    set header_files($file) 1
  }

  foreach file $files {
    set objects [get_files -quiet $file]
    if {[llength $objects] == 0} {
      continue
    }

    set extension [string tolower [file extension $file]]
    set path [file normalize $file]
    if {$extension in {.svh .vh} || [info exists header_files($path)]} {
      set_property -name file_type -value {Verilog Header} -objects $objects
    } elseif {$extension eq ".v"} {
      set_property -name file_type -value {SystemVerilog} -objects $objects
    }
  }
}
