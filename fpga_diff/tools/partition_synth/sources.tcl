########################################################################
# RTL source and project-shell helpers.
########################################################################

source [file normalize [file join [file dirname [info script]] header_files.tcl]]

proc ps_require_file {path} {
  if {![file isfile $path]} {
    error "required file not found: $path"
  }
}

proc ps_module_declaration_index {module text} {
  set pattern [format \
    {^[ \t]*(?:\(\*[^\n]*\*\)[ \t]*)?module[ \t]+%s([ \t(#]|$)} $module]
  if {[regexp -line -indices -- $pattern $text match]} {
    return [lindex $match 0]
  }
  return -1
}

proc ps_module_declarations {text} {
  set declarations {}
  set pattern \
    {^[ \t]*(?:\(\*[^\n]*\*\)[ \t]*)?module[ \t]+([A-Za-z_][A-Za-z0-9_]*)}
  foreach {declaration module} [regexp -all -inline -line -- $pattern $text] {
    lappend declarations $module
  }
  return $declarations
}

proc ps_file_module_index {module file} {
  if {![file isfile $file] || [file extension $file] ni {.v .sv}} {
    return -1
  }
  set in [open $file r]
  set text [read $in]
  close $in
  return [ps_module_declaration_index $module $text]
}

proc ps_find_module_source {module files} {
  foreach file $files {
    if {[file tail $file] in [list "$module.sv" "$module.v"] &&
        [ps_file_module_index $module $file] >= 0} {
      return [file normalize $file]
    }
  }

  foreach file $files {
    if {[ps_file_module_index $module $file] >= 0} {
      return [file normalize $file]
    }
  }
  return ""
}

proc ps_find_blackbox_sources {modules files} {
  set sources {}
  array set source_modules {}
  foreach module $modules {
    set source [ps_find_module_source $module $files]
    if {$source eq ""} {
      error "cannot find source for module $module"
    }
    set source [file normalize $source]
    if {[info exists source_modules($source)]} {
      error "child modules $source_modules($source) and $module share source $source"
    }
    set source_modules($source) $module
    lappend sources $source
  }
  return $sources
}

proc ps_remove_source_files {files removed_sources} {
  array set removed {}
  foreach source $removed_sources {
    set removed([file normalize $source]) 1
  }

  set filtered {}
  foreach file $files {
    if {![info exists removed([file normalize $file])]} {
      lappend filtered $file
    }
  }
  return $filtered
}

proc ps_write_blackbox_stub {module src_file out_file} {
  ps_require_file $src_file

  set in [open $src_file r]
  set text [read $in]
  close $in

  set module_idx [ps_module_declaration_index $module $text]
  if {$module_idx < 0} {
    error "module $module not found in $src_file"
  }
  set declaration_count 0
  foreach declaration [ps_module_declarations $text] {
    if {$declaration eq $module} {
      incr declaration_count
    }
  }
  if {$declaration_count != 1} {
    error "expected one declaration of $module in $src_file, found $declaration_count"
  }
  set header_end [string first ";" $text $module_idx]
  if {$header_end < 0} {
    error "failed to find $module declaration terminator in $src_file"
  }
  if {![regexp -line -indices -start $header_end -- \
      {^[ \t]*endmodule[^\n]*} $text module_end_match] &&
      ![regexp -indices -start $header_end -- \
      {\mendmodule\M[^\n]*} $text module_end_match]} {
      error "failed to find $module endmodule in $src_file"
  }
  set module_end [lindex $module_end_match 1]

  file mkdir [file dirname $out_file]
  set out [open $out_file w]
  puts $out [string range $text 0 [expr {$module_idx - 1}]]
  puts $out "(* black_box *) [string range $text $module_idx $header_end]"
  puts $out "endmodule"
  puts -nonewline $out [string range $text [expr {$module_end + 1}] end]
  close $out
}

proc ps_add_blackbox_stubs {modules source_files run_dir} {
  set stubs {}
  foreach module $modules source_file $source_files {
    set stub_file [file normalize "$run_dir/${module}_blackbox.sv"]
    ps_write_blackbox_stub $module $source_file $stub_file
    lappend stubs $stub_file
  }
  return $stubs
}

proc ps_partition_source_config {origin_dir partition run_dir} {
  global fpga_primary_clock_specs

  set origin_dir [file normalize $origin_dir]
  set run_dir [file normalize $run_dir]
  set tcl_dir [file normalize "$origin_dir/src/tcl"]
  set clock_defs [file normalize "$origin_dir/src/constr/common/clock_defs.tcl"]

  foreach file [list \
    "$tcl_dir/common/defines.tcl" \
    "$tcl_dir/common/include_dirs.tcl" \
    "$tcl_dir/cpu_files.tcl" \
    $clock_defs] {
    ps_require_file $file
  }

  source "$tcl_dir/common/defines.tcl"
  source "$tcl_dir/common/include_dirs.tcl"
  source $clock_defs
  source "$tcl_dir/cpu_files.tcl"

  set chi_files {}
  if {[file isfile "$tcl_dir/chi_files.tcl"]} {
    source "$tcl_dir/chi_files.tcl"
  }

  set all_source_files [list {*}$cpu_files {*}$chi_files]
  if {[llength $all_source_files] == 0} {
    error "source_files is empty"
  }

  set partition_files [list {*}$all_source_files]
  set partition_include_dirs [list {*}$include_dirs]
  foreach source_file $all_source_files {
    set source_dir [file normalize [file dirname $source_file]]
    if {[lsearch -exact $partition_include_dirs $source_dir] < 0} {
      lappend partition_include_dirs $source_dir
    }
  }

  set partition_defines [list {*}$defines]
  if {[llength $chi_files] > 0} {
    lappend partition_defines MSI_MODE CONFIG_USE_XSCORE_CHI
  } else {
    lappend partition_defines CONFIG_USE_XSCORE_AXI
  }
  lappend partition_defines XDMA_PCIE_LANES=4

  set top_module [ps_partition_top $partition]
  set blackbox_modules [ps_partition_blackboxes $partition]
  set partition_clocks [ps_partition_clocks $partition]
  foreach mapping $partition_clocks {
    lassign $mapping clock_name port_name
    fpga_clock_period $clock_name
  }

  set missing 0
  foreach file $partition_files {
    if {![file isfile $file]} {
      puts "ERROR: missing source: $file"
      set missing 1
    }
  }
  if {$missing} {
    error "partition '$partition' has missing sources"
  }

  set generated_stubs {}
  if {[llength $blackbox_modules] > 0} {
    set blackbox_sources [ps_find_blackbox_sources $blackbox_modules $partition_files]
    set generated_stubs [ps_add_blackbox_stubs $blackbox_modules $blackbox_sources $run_dir]
    set partition_files [ps_remove_source_files $partition_files $blackbox_sources]
    lappend partition_files {*}$generated_stubs
  }
  if {[llength $partition_files] == 0} {
    error "partition_files($partition) is empty"
  }

  return [dict create \
    files $partition_files \
    include_dirs $partition_include_dirs \
    defines $partition_defines \
    top $top_module \
    blackboxes $blackbox_modules \
    clocks $partition_clocks \
    generated_stubs $generated_stubs]
}

proc ps_write_partition_clock_xdc {partition clocks run_dir} {
  if {[llength $clocks] == 0} {
    return ""
  }

  file mkdir $run_dir
  set clocks_xdc_file [file normalize "$run_dir/${partition}_clocks.xdc"]
  set clocks_xdc [open $clocks_xdc_file w]
  puts $clocks_xdc "# Generated from src/constr/common/clock_defs.tcl."
  foreach mapping $clocks {
    lassign $mapping clock_name port_name
    puts $clocks_xdc [format {create_clock -period %s -name %s [get_ports {%s}]} \
      [fpga_clock_period $clock_name] $clock_name $port_name]
  }
  close $clocks_xdc
  return $clocks_xdc_file
}

proc ps_project_source_files {} {
  set files {}
  foreach file [get_files -quiet -of_objects [get_filesets sources_1]] {
    if {[file extension $file] in {.v .sv} && [file isfile $file]} {
      lappend files [file normalize $file]
    }
  }
  return $files
}

proc ps_project_root_stubs {module} {
  set tail "${module}_partition_blackbox.sv"
  set stubs {}
  foreach file [get_files -quiet -of_objects [get_filesets sources_1]] {
    if {[file tail $file] eq $tail} {
      lappend stubs $file
    }
  }
  return $stubs
}

proc ps_restore_project_sources {module} {
  set stubs [ps_project_root_stubs $module]
  if {[llength $stubs] == 0} {
    return 0
  }

  remove_files $stubs
  set source [ps_find_module_source $module [ps_project_source_files]]
  if {$source eq ""} {
    error "cannot restore source for root module $module"
  }
  set_property USED_IN_SYNTHESIS true [get_files $source]
  update_compile_order -fileset sources_1
  puts "INFO: restored project source for $module: $source"
  return 1
}

proc ps_prepare_project_shell {module out_dir} {
  ps_restore_project_sources $module

  set source [ps_find_module_source $module [ps_project_source_files]]
  if {$source eq ""} {
    error "cannot find project source for root module $module"
  }

  set stub [file normalize "$out_dir/top_shell/${module}_partition_blackbox.sv"]
  ps_write_blackbox_stub $module $source $stub
  set_property USED_IN_SYNTHESIS false [get_files $source]
  set stub_object [add_files -norecurse -fileset sources_1 $stub]
  set_property file_type SystemVerilog $stub_object
  update_compile_order -fileset sources_1
  puts "INFO: project shell replaces $source with $stub"
  return $stub
}
