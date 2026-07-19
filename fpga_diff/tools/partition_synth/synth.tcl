########################################################################
# Partition synthesis for FPGA DiffTest experiments.
#
# This script reuses the normal fpga_diff file lists. It is an experiment
# helper, not a replacement for the project creation script.
########################################################################

source [file normalize [file join [file dirname [info script]] defs.tcl]]
source [file normalize [file join [file dirname [info script]] sources.tcl]]

proc usage {} {
  puts "Usage:"
  puts "  vivado -mode batch -source tools/partition_synth/synth.tcl -tclargs \\"
  puts "    --origin-dir <fpga_diff_dir> --out-dir <out_dir> \\"
  puts "    --partition <name> \[--jobs <n>\] \[--dry-run\]"
  exit 1
}

proc parse_args {} {
  array set opt {
    --origin-dir .
    --out-dir partition-synth
    --partition ""
    --jobs ""
    --dry-run 0
  }

  for {set i 0} {$i < [llength $::argv]} {incr i} {
    set key [lindex $::argv $i]
    switch -- $key {
      --origin-dir -
      --out-dir -
      --partition -
      --jobs {
        incr i
        if {$i >= [llength $::argv]} { usage }
        set opt($key) [lindex $::argv $i]
      }
      --dry-run {
        set opt(--dry-run) 1
      }
      --help {
        usage
      }
      default {
        puts "ERROR: unknown argument '$key'"
        usage
      }
    }
  }

  if {$opt(--jobs) ne ""} {
    if {![string is integer -strict $opt(--jobs)] || $opt(--jobs) < 1} {
      puts "ERROR: --jobs must be a positive integer"
      usage
    }
  }

  return [array get opt]
}

array set opt [parse_args]

set origin_dir [file normalize $opt(--origin-dir)]
set out_dir [file normalize $opt(--out-dir)]
set partition $opt(--partition)
ps_load_partitions

if {$partition eq ""} {
  puts "ERROR: --partition is required"
  usage
}
if {[lsearch -exact $ps_partitions $partition] < 0} {
  puts "ERROR: --partition must be one of: [join $ps_partitions {, }]"
  usage
}

file mkdir $out_dir
set run_dir [file normalize "$out_dir/$partition"]
file mkdir $run_dir
set partition_config [ps_partition_source_config $origin_dir $partition $run_dir]
set partition_files [dict get $partition_config files]
set partition_include_dirs [dict get $partition_config include_dirs]
set partition_defines [dict get $partition_config defines]
set top_module [dict get $partition_config top]
set blackbox_modules [dict get $partition_config blackboxes]
set partition_clocks [dict get $partition_config clocks]
set generated_stubs [dict get $partition_config generated_stubs]
set dcp_file [file normalize "$out_dir/$partition.dcp"]
set rpt_file [file normalize [format "%s/%s_utilization_synth.rpt" $out_dir $partition]]
set clocks_rpt_file [file normalize [format "%s/%s_clocks_synth.rpt" $out_dir $partition]]

puts "INFO: origin_dir=$origin_dir"
puts "INFO: out_dir=$out_dir"
puts "INFO: partition=$partition"
puts "INFO: top_module=$top_module"
if {[llength $blackbox_modules] > 0} {
  puts "INFO: blackbox_modules=$blackbox_modules"
}
if {[llength $partition_clocks] > 0} {
  puts "INFO: partition_clocks=$partition_clocks"
}
puts "INFO: source_count=[llength $partition_files]"
puts "INFO: include_dir_count=[llength $partition_include_dirs]"
puts "INFO: dcp_file=$dcp_file"
if {[llength $generated_stubs] > 0} {
  puts "INFO: generated_files=$generated_stubs"
}

if {$opt(--dry-run)} {
  puts "INFO: dry-run requested; exiting before Vivado project creation"
  exit 0
}

if {$opt(--jobs) ne ""} {
  set max_threads $opt(--jobs)
  if {$max_threads > 32} {
    puts "WARNING: clamping --jobs $max_threads to Vivado general.maxThreads limit 32"
    set max_threads 32
  }
  set_param general.maxThreads $max_threads
}

cd $run_dir
create_project "ps_$partition" . -part xcvu19p-fsva3824-2-e -force
set_property -name source_mgmt_mode -value "None" -objects [current_project]
set_property -name xpm_libraries -value "XPM_CDC XPM_MEMORY" -objects [current_project]

set srcset [get_filesets sources_1]
add_files -norecurse -fileset $srcset $partition_files
fpga_set_header_file_types $partition_files $partition_include_dirs

set_property -name include_dirs -value $partition_include_dirs -objects $srcset
set_property -name verilog_define -value $partition_defines -objects $srcset
set_property -name top -value $top_module -objects $srcset
set_property -name top_auto_set -value 0 -objects $srcset

set clocks_xdc_file [ps_write_partition_clock_xdc $partition $partition_clocks $run_dir]
if {$clocks_xdc_file ne ""} {
  set constrset [get_filesets constrs_1]
  add_files -norecurse -fileset $constrset $clocks_xdc_file
  set_property used_in_implementation false [get_files -quiet $clocks_xdc_file]
  puts "INFO: clocks_xdc=$clocks_xdc_file"
}

update_compile_order -fileset sources_1

synth_design \
  -mode out_of_context \
  -top $top_module \
  -part xcvu19p-fsva3824-2-e \
  -gated_clock_conversion auto \
  -bufg 52 \
  -directive AlternateRoutability

write_checkpoint -force $dcp_file
report_utilization -file $rpt_file
if {[llength $partition_clocks] > 0} {
  report_clocks -file $clocks_rpt_file
}
puts "INFO: partition synthesis complete: $dcp_file"
