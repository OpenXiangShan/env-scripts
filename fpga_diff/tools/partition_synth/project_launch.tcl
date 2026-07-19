########################################################################
# Launch previously configured project OOC runs through Vivado's run manager.
########################################################################

proc usage {} {
  puts "Usage:"
  puts {  vivado -mode batch -source tools/partition_synth/project_launch.tcl -tclargs}
  puts {    --project <xpr> --manifest <manifest.tsv> --parallel <n>}
  exit 1
}

proc parse_args {} {
  array set opt {
    --project ""
    --manifest ""
    --parallel ""
  }

  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set key [lindex $::argv $i]
    switch -- $key {
      --project -
      --manifest -
      --parallel {
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

  if {$opt(--project) eq "" || $opt(--manifest) eq "" || $opt(--parallel) eq ""} {
    usage
  }
  if {![string is integer -strict $opt(--parallel)] || $opt(--parallel) < 1} {
    puts "ERROR: --parallel must be a positive integer"
    usage
  }
  return [array get opt]
}

array set opt [parse_args]
set project [file normalize $opt(--project)]
set manifest_path [file normalize $opt(--manifest)]
if {![file isfile $project]} {
  error "project not found: $project"
}
if {![file isfile $manifest_path]} {
  error "manifest not found: $manifest_path"
}

set records {}
set manifest [open $manifest_path r]
while {[gets $manifest line] >= 0} {
  if {$line eq ""} {
    continue
  }
  set record [split $line "\t"]
  if {[llength $record] != 4} {
    error "invalid manifest entry: $line"
  }
  lappend records $record
}
close $manifest
if {[llength $records] == 0} {
  error "manifest is empty: $manifest_path"
}

open_project $project
set runs {}
foreach record $records {
  lassign $record partition top_module run_name run_dir
  set run [get_runs -quiet $run_name]
  if {[llength $run] != 1} {
    error "project run not found: $run_name"
  }
  lappend runs $run
}

foreach run $runs {
  reset_run $run
}
puts "INFO: launching [llength $runs] project OOC run(s) with -jobs $opt(--parallel)"
launch_runs $runs -jobs $opt(--parallel)
set failed_runs {}
foreach record $records run $runs {
  lassign $record partition top_module run_name run_dir
  wait_on_run $run
  set status [get_property STATUS $run]
  puts "INFO: $run_name status=$status"
  if {![string match "synth_design Complete*" $status]} {
    lappend failed_runs "$run_name ($status)"
  }
}
close_project
if {[llength $failed_runs] > 0} {
  error "project run(s) failed: [join $failed_runs {, }]"
}
