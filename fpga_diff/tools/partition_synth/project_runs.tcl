########################################################################
# Create GUI-visible OOC synthesis runs in an existing top-level project.
########################################################################

source [file normalize [file join [file dirname [info script]] defs.tcl]]
source [file normalize [file join [file dirname [info script]] sources.tcl]]

proc usage {} {
  puts "Usage:"
  puts {  vivado -mode batch -source tools/partition_synth/project_runs.tcl -tclargs}
  puts {    --project <xpr> --origin-dir <fpga_diff_dir> --out-dir <out_dir>}
  puts {    --partitions <comma-separated-list> [--jobs <n>]}
  exit 1
}

proc parse_args {} {
  array set opt {
    --project ""
    --origin-dir .
    --out-dir partition-synth
    --partitions ""
    --jobs ""
  }

  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set key [lindex $::argv $i]
    switch -- $key {
      --project -
      --origin-dir -
      --out-dir -
      --partitions -
      --jobs {
        incr i
        if {$i >= [llength $::argv]} { usage }
        set opt($key) [lindex $::argv $i]
      }
      --help { usage }
      default {
        puts "ERROR: unknown argument '$key'"
        usage
      }
    }
  }

  if {$opt(--project) eq "" || $opt(--partitions) eq ""} {
    usage
  }
  if {$opt(--jobs) ne "" &&
      (![string is integer -strict $opt(--jobs)] || $opt(--jobs) < 1)} {
    puts "ERROR: --jobs must be a positive integer"
    usage
  }
  return [array get opt]
}

proc ps_project_run_name {partition} {
  return "partition_synth_$partition"
}

proc ps_project_srcset_name {partition} {
  return "partition_synth_${partition}_srcs"
}

proc ps_project_constrset_name {partition} {
  return "partition_synth_${partition}_constrs"
}

proc ps_remove_project_run {partition} {
  set run_name [ps_project_run_name $partition]
  set old_run [get_runs -quiet $run_name]
  if {[llength $old_run] > 0} {
    set old_dir [get_property DIRECTORY [lindex $old_run 0]]
    delete_runs $old_run
    if {[file exists $old_dir]} {
      file delete -force $old_dir
    }
  }

  foreach fileset_name [list \
    [ps_project_srcset_name $partition] \
    [ps_project_constrset_name $partition]] {
    set fileset [get_filesets -quiet $fileset_name]
    if {[llength $fileset] > 0} {
      delete_fileset $fileset
    }
  }
}

proc ps_write_project_pre_hook {path jobs} {
  set hook [open $path w]
  puts $hook "set_param general.maxThreads $jobs"
  close $hook
}

proc ps_write_project_post_hook {path utilization_rpt clocks_rpt} {
  set hook [open $path w]
  puts $hook [format {report_utilization -file {%s}} $utilization_rpt]
  if {$clocks_rpt ne ""} {
    puts $hook [format {report_clocks -file {%s}} $clocks_rpt]
  }
  close $hook
}

array set opt [parse_args]
set project [file normalize $opt(--project)]
set origin_dir [file normalize $opt(--origin-dir)]
set out_dir [file normalize $opt(--out-dir)]
ps_require_file $project
ps_load_partitions

set partitions [split $opt(--partitions) ,]
foreach partition $partitions {
  if {[lsearch -exact $ps_partitions $partition] < 0} {
    error "unknown partition '$partition'; expected one of: [join $ps_partitions {, }]"
  }
}

file mkdir $out_dir
set project_runs_dir [file normalize "$out_dir/project_runs"]
file mkdir $project_runs_dir
set manifest_path [file normalize "$project_runs_dir/manifest.tsv"]

open_project $project
ps_restore_project_sources [ps_partition_top [ps_root_partition]]
set project_part [get_property PART [current_project]]
if {$project_part eq ""} {
  error "project has no part: $project"
}

set manifest [open $manifest_path w]
set run_records {}
array set seen_files {}
array set seen_include_dirs {}
set all_files {}
set all_include_dirs {}
foreach partition $partitions {
  set setup_dir [file normalize "$project_runs_dir/$partition"]
  file delete -force $setup_dir
  file mkdir $setup_dir
  set config [ps_partition_source_config $origin_dir $partition $setup_dir]
  set files [dict get $config files]
  set include_dirs [dict get $config include_dirs]
  set defines [dict get $config defines]
  set top_module [dict get $config top]
  set clocks [dict get $config clocks]

  ps_remove_project_run $partition
  set srcset_name [ps_project_srcset_name $partition]
  set constrset_name [ps_project_constrset_name $partition]
  create_fileset -srcset $srcset_name
  create_fileset -constrset $constrset_name
  set srcset [get_filesets $srcset_name]
  set constrset [get_filesets $constrset_name]
  add_files -norecurse -fileset $srcset $files
  foreach file $files {
    set normalized_file [file normalize $file]
    if {![info exists seen_files($normalized_file)]} {
      set seen_files($normalized_file) 1
      lappend all_files $normalized_file
    }
  }
  foreach include_dir $include_dirs {
    set normalized_dir [file normalize $include_dir]
    if {![info exists seen_include_dirs($normalized_dir)]} {
      set seen_include_dirs($normalized_dir) 1
      lappend all_include_dirs $normalized_dir
    }
  }
  set_property include_dirs $include_dirs $srcset
  set_property verilog_define $defines $srcset
  set_property top $top_module $srcset
  set_property top_auto_set 0 $srcset

  set clocks_xdc [ps_write_partition_clock_xdc $partition $clocks $setup_dir]
  if {$clocks_xdc ne ""} {
    add_files -norecurse -fileset $constrset $clocks_xdc
    set_property used_in_implementation false [get_files -quiet $clocks_xdc]
  }

  set run_name [ps_project_run_name $partition]
  create_run -name $run_name -part $project_part \
    -flow {Vivado Synthesis 2020} -strategy {Vivado Synthesis Defaults} \
    -report_strategy {Vivado Synthesis Default Reports} \
    -constrset $constrset -srcset $srcset
  set run [get_runs $run_name]
  set_property AUTO_INCREMENTAL_CHECKPOINT 0 $run
  set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} \
    -value {-mode out_of_context} -objects $run
  set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION auto $run
  set_property STEPS.SYNTH_DESIGN.ARGS.BUFG 52 $run
  set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE AlternateRoutability $run

  set utilization_rpt [file normalize "$out_dir/${partition}_utilization_synth.rpt"]
  set clocks_rpt ""
  if {[llength $clocks] > 0} {
    set clocks_rpt [file normalize "$out_dir/${partition}_clocks_synth.rpt"]
  }
  set post_hook [file normalize "$setup_dir/${partition}_post.tcl"]
  ps_write_project_post_hook $post_hook $utilization_rpt $clocks_rpt
  set_property STEPS.SYNTH_DESIGN.TCL.POST $post_hook $run
  if {$opt(--jobs) ne ""} {
    set pre_hook [file normalize "$setup_dir/${partition}_pre.tcl"]
    ps_write_project_pre_hook $pre_hook $opt(--jobs)
    set_property STEPS.SYNTH_DESIGN.TCL.PRE $pre_hook $run
  }

  lappend run_records [list $partition $top_module $run_name]
}

fpga_set_header_file_types $all_files $all_include_dirs
foreach record $run_records {
  lassign $record partition top_module run_name
  set run_dir [file normalize [get_property DIRECTORY [get_runs $run_name]]]
  puts $manifest [join [list $partition $top_module $run_name $run_dir] "\t"]
  puts "INFO: configured $run_name (top=$top_module, run_dir=$run_dir)"
}
close $manifest
close_project
puts "INFO: project OOC runs configured: $manifest_path"
