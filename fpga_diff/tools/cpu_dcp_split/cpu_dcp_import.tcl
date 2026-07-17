########################################################################
# Import CPU partition DCPs into a synthesized top design.
#
# Usage:
#   vivado -mode batch -source .../cpu_dcp_import.tcl \
#     -tclargs probe <project.xpr> <cpu-cell-path>|@<partition-import.tsv> \
#              <cpu-synth.dcp>|- [synth-run] [out-dir]
#
#   vivado -mode batch -source .../cpu_dcp_import.tcl \
#     -tclargs impl <project.xpr> <cpu-cell-path>|@<partition-import.tsv> \
#              <cpu-synth.dcp>|- [synth-run] [out-dir] \
#              [reference-routed.dcp] [route|bitstream] [Default|RuntimeOptimized]
########################################################################

proc usage {} {
  puts stderr "USAGE: vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/cpu_dcp_import.tcl -tclargs probe|impl <project.xpr> <cpu-cell-path>|@<partition-import.tsv> <cpu-synth.dcp>|- ?synth-run? ?out-dir? ?reference-routed.dcp? ?route|bitstream? ?Default|RuntimeOptimized?"
}

proc json_escape {value} {
  set s [string map {
    "\\" "\\\\"
    "\"" "\\\""
    "\n" "\\n"
    "\r" "\\r"
    "\t" "\\t"
  } $value]
  return "\"$s\""
}

proc write_json_manifest {path entries} {
  set fh [open $path w]
  puts $fh "{"
  set count [llength $entries]
  set i 0
  foreach entry $entries {
    incr i
    set key [lindex $entry 0]
    set value [lindex $entry 1]
    set comma [expr {$i < $count ? "," : ""}]
    puts $fh "  [json_escape $key]: [json_escape $value]$comma"
  }
  puts $fh "}"
  close $fh
}

proc read_partition_imports {cell_arg dcp_arg} {
  set entries [list]
  if {[string match {@*} $cell_arg]} {
    set path [file normalize [string range $cell_arg 1 end]]
    if {![file exists $path]} {
      puts stderr "ERROR: partition import TSV not found: $path"
      exit 1
    }
    set fh [open $path r]
    set line_no 0
    while {[gets $fh line] >= 0} {
      incr line_no
      set line [string trim $line]
      if {$line eq "" || [string match "#*" $line]} {
        continue
      }
      set fields [split $line "\t"]
      if {[llength $fields] < 3} {
        close $fh
        puts stderr "ERROR: malformed partition import TSV line $line_no in $path"
        exit 1
      }
      set role [string trim [lindex $fields 0]]
      set cell [string trim [lindex $fields 1]]
      set dcp [file normalize [string trim [lindex $fields 2]]]
      if {$role eq "" || $cell eq "" || $dcp eq ""} {
        close $fh
        puts stderr "ERROR: empty field in partition import TSV line $line_no in $path"
        exit 1
      }
      if {![file exists $dcp]} {
        close $fh
        puts stderr "ERROR: partition checkpoint not found for $role: $dcp"
        exit 1
      }
      lappend entries [list $role $cell $dcp]
    }
    close $fh
    if {[llength $entries] == 0} {
      puts stderr "ERROR: partition import TSV contains no entries: $path"
      exit 1
    }
    return $entries
  }

  if {$dcp_arg eq ""} {
    puts stderr "ERROR: CPU checkpoint path is empty"
    exit 1
  }
  lappend entries [list cpu $cell_arg $dcp_arg]
  return $entries
}

proc join_partition_field {entries index} {
  set values [list]
  foreach entry $entries {
    lappend values [lindex $entry $index]
  }
  return [join $values ";"]
}

proc find_cell_by_exact_name {cell_name} {
  set direct [get_cells -quiet $cell_name]
  if {[llength $direct] > 0} {
    return $direct
  }

  set matches [list]
  foreach c [get_cells -hierarchical -quiet *] {
    if {[get_property NAME $c] eq $cell_name} {
      lappend matches $c
    }
  }
  return $matches
}

proc write_missing_cell_candidates {path} {
  set max_candidates 500
  set count 0
  set fh [open $path w]
  puts $fh "# Candidate cells containing CPU-ish names. This file is capped at $max_candidates entries."
  foreach c [get_cells -hierarchical -quiet -regexp {.*(U_CPU_TOP|u_XSTop|cpu|XSTop|XSCore|XSTile|NutShell|frontend|backend|Frontend|Backend).*}] {
    incr count
    if {$count <= $max_candidates} {
      puts $fh [get_property NAME $c]
    }
  }
  if {$count > $max_candidates} {
    puts $fh "# truncated: total_candidates=$count written=$max_candidates"
  } else {
    puts $fh "# total_candidates=$count"
  }
  close $fh
}

proc resolve_partition_imports {partition_imports out_dir} {
  set resolved_imports [list]
  foreach entry $partition_imports {
    set role [lindex $entry 0]
    set cell [lindex $entry 1]
    set dcp [lindex $entry 2]
    set cell_obj [find_cell_by_exact_name $cell]
    if {[llength $cell_obj] == 0} {
      set candidates_file [file join $out_dir missing-cell-candidates.txt]
      write_missing_cell_candidates $candidates_file
      puts stderr "ERROR: CPU partition cell not found for $role: $cell"
      puts stderr "Candidate list: $candidates_file"
      exit 1
    }
    if {[llength $cell_obj] > 1} {
      puts stderr "ERROR: CPU partition cell path is ambiguous for $role: $cell"
      foreach c $cell_obj {
        puts stderr "  [get_property NAME $c]"
      }
      exit 1
    }
    set cell_obj [lindex $cell_obj 0]
    lappend resolved_imports [list $role [get_property NAME $cell_obj] $dcp]
  }
  return $resolved_imports
}

proc run_step {step_name command out_dir status_var message_var} {
  upvar $status_var status
  upvar $message_var message
  puts "INFO: Running $step_name"
  set step_log [file join $out_dir "${step_name}.log"]
  set fh [open $step_log w]
  puts $fh "command=$command"
  close $fh
  if {[catch {uplevel 1 $command} err]} {
    set status "${step_name}_failed"
    set message $err
    set fh [open $step_log a]
    puts $fh "status=$status"
    puts $fh "error=$err"
    close $fh
    return 0
  }
  set fh [open $step_log a]
  puts $fh "status=ok"
  close $fh
  return 1
}

proc project_has_scoped_cpu_dcp {cpu_dcp cpu_cell} {
  set normalized_cpu_dcp [file normalize $cpu_dcp]
  foreach f [get_files -quiet -all *] {
    if {[file normalize [get_property NAME $f]] ne $normalized_cpu_dcp} {
      continue
    }
    set scoped_cells ""
    if {![catch {get_property SCOPED_TO_CELLS $f} scoped_cells]} {
      if {[lsearch -exact $scoped_cells $cpu_cell] >= 0} {
        return 1
      }
    }
    set scoped_cell ""
    if {![catch {get_property SCOPED_TO_CELL $f} scoped_cell]} {
      if {$scoped_cell eq $cpu_cell} {
        return 1
      }
    }
  }
  return 0
}

proc import_cpu_checkpoint {role resolved_cell cpu_dcp out_dir status_var message_var import_mode_var} {
  upvar $status_var status
  upvar $message_var message
  upvar $import_mode_var import_mode

  set step_name "import_${role}_dcp"
  regsub -all {[^A-Za-z0-9_]} $step_name "_" step_name
  set command [list read_checkpoint -cell $resolved_cell $cpu_dcp]
  if {[run_step $step_name $command $out_dir status message]} {
    set import_mode "read_checkpoint_cell"
    return 1
  }

  if {[string first "is not a black-box" $message] >= 0 && [project_has_scoped_cpu_dcp $cpu_dcp $resolved_cell]} {
    puts "INFO: CPU cell is already populated from the scoped DCP in this project; continuing without a second read_checkpoint -cell."
    set import_mode "already_scoped_in_project"
    set status "unknown"
    set message ""
    set fh [open [file join $out_dir "${step_name}.log"] a]
    puts $fh "recovered_by=already_scoped_in_project"
    close $fh
    return 1
  }

  return 0
}

proc write_reports {out_dir} {
  foreach report_cmd {
    {report_timing_summary -file timing_summary.rpt}
    {report_utilization -file utilization.rpt}
    {report_route_status -file route_status.rpt}
    {report_drc -file drc.rpt}
  } {
    set cmd [lindex $report_cmd 0]
    set file_name [lindex $report_cmd 2]
    if {[catch {$cmd -file [file join $out_dir $file_name]} err]} {
      puts "WARNING: $cmd failed: $err"
    }
  }
}

proc write_incremental_reuse_report {out_dir name} {
  if {[catch {report_incremental_reuse -file [file join $out_dir $name]} err]} {
    puts "WARNING: report_incremental_reuse failed for $name: $err"
  }
}

proc write_impl_manifest {out_dir proj_path synth_run resolved_cell resolved_dcp import_mode partition_count reference_dcp stop_after impl_directive routed_dcp bitstream_path status message} {
  write_json_manifest [file join $out_dir cpu-dcp-import-impl.json] [list \
    [list project $proj_path] \
    [list synth_run $synth_run] \
    [list cpu_cell $resolved_cell] \
    [list cpu_dcp $resolved_dcp] \
    [list import_mode $import_mode] \
    [list partition_count $partition_count] \
    [list reference_dcp $reference_dcp] \
    [list final_step $stop_after] \
    [list implementation_directive $impl_directive] \
    [list routed_dcp $routed_dcp] \
    [list bitstream $bitstream_path] \
    [list status $status] \
    [list message $message]]
}

proc prepare_design {proj_path run_name out_dir_suffix out_dir_arg open_name} {
  puts "INFO: Opening project: $proj_path"
  open_project $proj_path

  set project_dir [get_property DIRECTORY [current_project]]
  set out_dir $out_dir_arg
  if {$out_dir eq ""} {
    set out_dir [file normalize [file join $project_dir $out_dir_suffix]]
  }
  file mkdir $out_dir

  set run_obj [get_runs -quiet $run_name]
  if {[llength $run_obj] == 0} {
    puts stderr "ERROR: synthesis run not found: $run_name"
    exit 1
  }

  puts "INFO: Opening synthesis run: $run_name"
  open_run $run_name -name $open_name
  return $out_dir
}

proc run_probe {proj_path cpu_cell cpu_dcp run_name out_dir_arg} {
  set out_dir [prepare_design $proj_path $run_name cpu-dcp-import-probe $out_dir_arg cpu_dcp_import_probe]
  set resolved_imports [resolve_partition_imports [read_partition_imports $cpu_cell $cpu_dcp] $out_dir]
  set resolved_cell [join_partition_field $resolved_imports 1]
  set resolved_dcp [join_partition_field $resolved_imports 2]

  set manifest [file join $out_dir cpu-dcp-import-probe.json]
  set log [file join $out_dir cpu-dcp-import-probe.log]
  set status "read_checkpoint_ok"
  set message ""

  puts "INFO: Importing CPU checkpoint into cell: $resolved_cell"
  set log_fh [open $log w]
  puts $log_fh "project=$proj_path"
  puts $log_fh "run=$run_name"
  puts $log_fh "cpu_cell=$resolved_cell"
  puts $log_fh "cpu_dcp=$resolved_dcp"
  puts $log_fh "partition_count=[llength $resolved_imports]"

  foreach entry $resolved_imports {
    set role [lindex $entry 0]
    set cell [lindex $entry 1]
    set dcp [lindex $entry 2]
    puts "INFO: Importing CPU checkpoint into $role cell: $cell"
    puts $log_fh "import_role=$role"
    puts $log_fh "import_cell=$cell"
    puts $log_fh "import_dcp=$dcp"
    if {[catch {read_checkpoint -cell $cell $dcp} err]} {
      set status "read_checkpoint_failed"
      set message $err
      puts $log_fh "status=$status"
      puts $log_fh "error=$err"
      break
    }
  }
  if {$status eq "read_checkpoint_ok"} {
    puts $log_fh "status=$status"
    if {[catch {report_utilization -hierarchical -file [file join $out_dir utilization_after_import.rpt]} err]} {
      puts $log_fh "report_utilization_error=$err"
    }
    if {[catch {write_checkpoint -force [file join $out_dir top-after-cpu-import.dcp]} err]} {
      puts $log_fh "write_checkpoint_error=$err"
    }
  }
  close $log_fh

  write_json_manifest $manifest [list \
    [list project $proj_path] \
    [list run $run_name] \
    [list cpu_cell $resolved_cell] \
    [list cpu_dcp $resolved_dcp] \
    [list partition_count [llength $resolved_imports]] \
    [list status $status] \
    [list message $message] \
    [list log $log]]

  puts "INFO: Wrote $manifest"
  if {$status ne "read_checkpoint_ok"} {
    puts stderr "ERROR: CPU DCP import failed: $message"
    exit 1
  }
}

proc run_impl {proj_path cpu_cell cpu_dcp synth_run out_dir_arg reference_dcp stop_after impl_directive} {
  set out_dir [prepare_design $proj_path $synth_run cpu-dcp-import-impl $out_dir_arg cpu_dcp_import_impl]
  set resolved_imports [resolve_partition_imports [read_partition_imports $cpu_cell $cpu_dcp] $out_dir]
  set resolved_cell [join_partition_field $resolved_imports 1]
  set resolved_dcp [join_partition_field $resolved_imports 2]

  set status "unknown"
  set message ""
  set import_mode "unknown"
  set routed_dcp ""
  set bitstream_path ""

  foreach entry $resolved_imports {
    set role [lindex $entry 0]
    set cell [lindex $entry 1]
    set dcp [lindex $entry 2]
    if {![import_cpu_checkpoint $role $cell $dcp $out_dir status message import_mode]} {
      write_impl_manifest $out_dir $proj_path $synth_run $resolved_cell $resolved_dcp $import_mode [llength $resolved_imports] $reference_dcp $stop_after $impl_directive $routed_dcp $bitstream_path $status $message
      puts stderr "ERROR: CPU DCP import failed for $role: $message"
      exit 1
    }
  }

  if {![run_step opt_design {opt_design} $out_dir status message]} {
    write_reports $out_dir
    write_checkpoint -force [file join $out_dir failed-post-opt_design.dcp]
    write_impl_manifest $out_dir $proj_path $synth_run $resolved_cell $resolved_dcp $import_mode [llength $resolved_imports] $reference_dcp $stop_after $impl_directive $routed_dcp $bitstream_path $status $message
    puts stderr "ERROR: opt_design failed: $message"
    exit 1
  }

  if {$reference_dcp ne ""} {
    if {![run_step read_incremental_checkpoint [list read_checkpoint -incremental -directive $impl_directive $reference_dcp] $out_dir status message]} {
      write_impl_manifest $out_dir $proj_path $synth_run $resolved_cell $resolved_dcp $import_mode [llength $resolved_imports] $reference_dcp $stop_after $impl_directive $routed_dcp $bitstream_path $status $message
      puts stderr "ERROR: incremental checkpoint setup failed: $message"
      exit 1
    }
  }

  set place_cmd [expr {$impl_directive eq "Default" ? [list place_design] : [list place_design -directive $impl_directive]}]
  set route_cmd [expr {$impl_directive eq "Default" ? [list route_design] : [list route_design -directive $impl_directive]}]
  foreach step [list \
    [list place_design $place_cmd] \
    {phys_opt_design {phys_opt_design}} \
    [list route_design $route_cmd]] {
    set step_name [lindex $step 0]
    set command [lindex $step 1]
    if {![run_step $step_name $command $out_dir status message]} {
      write_reports $out_dir
      write_checkpoint -force [file join $out_dir failed-post-${step_name}.dcp]
      write_impl_manifest $out_dir $proj_path $synth_run $resolved_cell $resolved_dcp $import_mode [llength $resolved_imports] $reference_dcp $stop_after $impl_directive $routed_dcp $bitstream_path $status $message
      puts stderr "ERROR: $step_name failed: $message"
      exit 1
    }
    if {$reference_dcp ne "" && $step_name eq "place_design"} {
      write_incremental_reuse_report $out_dir post-place-incremental-reuse.rpt
    }
    if {$reference_dcp ne "" && $step_name eq "route_design"} {
      write_incremental_reuse_report $out_dir post-route-incremental-reuse.rpt
    }
  }

  write_reports $out_dir
  if {$reference_dcp ne ""} {
    write_incremental_reuse_report $out_dir final-incremental-reuse.rpt
  }
  set routed_dcp [file join $out_dir post-route-cpu-dcp-import.dcp]
  write_checkpoint -force $routed_dcp

  if {$stop_after eq "bitstream"} {
    set bitstream_path [file join $out_dir fpga_top_debug.bit]
    if {![run_step write_bitstream [list write_bitstream -force $bitstream_path] $out_dir status message]} {
      write_impl_manifest $out_dir $proj_path $synth_run $resolved_cell $resolved_dcp $import_mode [llength $resolved_imports] $reference_dcp $stop_after $impl_directive $routed_dcp $bitstream_path $status $message
      puts stderr "ERROR: write_bitstream failed: $message"
      exit 1
    }
  }

  set status "implementation_ok"
  set message ""
  write_impl_manifest $out_dir $proj_path $synth_run $resolved_cell $resolved_dcp $import_mode [llength $resolved_imports] $reference_dcp $stop_after $impl_directive $routed_dcp $bitstream_path $status $message

  puts "INFO: Wrote [file join $out_dir cpu-dcp-import-impl.json]"
  puts "INFO: Wrote routed checkpoint: $routed_dcp"
  if {$bitstream_path ne ""} {
    puts "INFO: Wrote bitstream: $bitstream_path"
  }
}

if {[llength $::argv] < 4 || [llength $::argv] > 9} {
  usage
  exit 2
}

set mode [string trim [lindex $::argv 0]]
if {[lsearch -exact {probe impl} $mode] < 0} {
  usage
  exit 2
}
if {$mode eq "probe" && [llength $::argv] > 6} {
  usage
  exit 2
}

set proj_path [file normalize [lindex $::argv 1]]
set cpu_cell [string trim [lindex $::argv 2]]
set cpu_dcp_arg [string trim [lindex $::argv 3]]
set cpu_dcp [expr {$cpu_dcp_arg eq "" || $cpu_dcp_arg eq "-" ? "" : [file normalize $cpu_dcp_arg]}]
set run_name [expr {[llength $::argv] >= 5 && [string trim [lindex $::argv 4]] ne "" ? [string trim [lindex $::argv 4]] : "synth_1"}]
set out_dir ""
if {[llength $::argv] >= 6 && [string trim [lindex $::argv 5]] ne ""} {
  set out_dir [file normalize [lindex $::argv 5]]
}
set reference_dcp ""
if {$mode eq "impl" && [llength $::argv] >= 7 && [string trim [lindex $::argv 6]] ne ""} {
  set reference_dcp [file normalize [lindex $::argv 6]]
}
set stop_after "route"
if {$mode eq "impl" && [llength $::argv] >= 8 && [string trim [lindex $::argv 7]] ne ""} {
  set stop_after [string trim [lindex $::argv 7]]
}
set impl_directive "RuntimeOptimized"
if {$mode eq "impl" && [llength $::argv] >= 9 && [string trim [lindex $::argv 8]] ne ""} {
  set impl_directive [string trim [lindex $::argv 8]]
}

if {![file exists $proj_path]} {
  puts stderr "ERROR: project not found: $proj_path"
  exit 1
}
if {$cpu_cell eq ""} {
  puts stderr "ERROR: cpu-cell-path or partition import TSV is empty"
  exit 1
}
if {$cpu_dcp ne "" && ![file exists $cpu_dcp]} {
  puts stderr "ERROR: CPU checkpoint not found: $cpu_dcp"
  exit 1
}
if {$reference_dcp ne "" && ![file exists $reference_dcp]} {
  puts stderr "ERROR: reference routed checkpoint not found: $reference_dcp"
  exit 1
}
if {[lsearch -exact {route bitstream} $stop_after] < 0} {
  puts stderr "ERROR: final step must be route or bitstream, got '$stop_after'"
  exit 1
}
if {[lsearch -exact {Default RuntimeOptimized} $impl_directive] < 0} {
  puts stderr "ERROR: implementation directive must be Default or RuntimeOptimized, got '$impl_directive'"
  exit 1
}

if {$mode eq "probe"} {
  run_probe $proj_path $cpu_cell $cpu_dcp $run_name $out_dir
} else {
  run_impl $proj_path $cpu_cell $cpu_dcp $run_name $out_dir $reference_dcp $stop_after $impl_directive
}
