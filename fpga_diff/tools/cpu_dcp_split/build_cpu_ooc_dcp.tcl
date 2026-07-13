########################################################################
# Build a CPU out-of-context synthesis checkpoint from a
# FpgaDiff release RTL directory.
#
# Usage:
#   vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/build_cpu_ooc_dcp.tcl \
#     -tclargs <rtl-dir> <top-module> <out-dir> [part] [defines-csv]
#
# This is a prototype helper for studying CPU/DiffTest partitioning. It only
# proves whether a named CPU top can be synthesized as an OOC checkpoint from
# the release RTL. A reusable CPU DCP still requires a stable partition cell in
# the top-level design.
########################################################################

proc usage {} {
  puts stderr "USAGE: vivado -mode batch -source env-scripts/fpga_diff/tools/cpu_dcp_split/build_cpu_ooc_dcp.tcl -tclargs <rtl-dir> <top-module> <out-dir> ?part? ?defines-csv?"
}

if {[llength $::argv] < 3 || [llength $::argv] > 5} {
  usage
  exit 2
}

set rtl_dir [file normalize [lindex $::argv 0]]
set top_module [string trim [lindex $::argv 1]]
set out_dir [file normalize [lindex $::argv 2]]
set part [expr {[llength $::argv] >= 4 && [string trim [lindex $::argv 3]] ne "" ? [string trim [lindex $::argv 3]] : "xcvu19p-fsva3824-2-e"}]
set defines_csv [expr {[llength $::argv] >= 5 ? [string trim [lindex $::argv 4]] : ""}]

if {![file isdirectory $rtl_dir]} {
  puts stderr "ERROR: RTL directory not found: $rtl_dir"
  exit 1
}
if {$top_module eq ""} {
  puts stderr "ERROR: top-module is empty"
  exit 1
}
file mkdir $out_dir

proc collect_files {root patterns} {
  set result [list]
  foreach pattern $patterns {
    foreach path [glob -nocomplain -directory $root -types f -- $pattern] {
      lappend result [file normalize $path]
    }
  }
  foreach dir [glob -nocomplain -directory $root -types d -- *] {
    set result [concat $result [collect_files $dir $patterns]]
  }
  return $result
}

proc uniq_sorted {values} {
  set data [lsort -unique $values]
  return $data
}

proc split_csv {value} {
  set result [list]
  foreach item [split $value ","] {
    set item [string trim $item]
    if {$item ne ""} {
      lappend result $item
    }
  }
  return $result
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

set build_dir [file dirname $rtl_dir]
set rtl_files [uniq_sorted [collect_files $rtl_dir [list "*.v" "*.sv"]]]
set header_files [uniq_sorted [collect_files $build_dir [list "*.vh" "*.svh"]]]
set include_dirs [list $rtl_dir]
foreach header $header_files {
  lappend include_dirs [file dirname $header]
}
set include_dirs [uniq_sorted $include_dirs]

if {[llength $rtl_files] == 0} {
  puts stderr "ERROR: no RTL files found under $rtl_dir"
  exit 1
}

set dcp_path [file join $out_dir cpu-synth.dcp]
set util_path [file join $out_dir utilization.rpt]
set timing_path [file join $out_dir timing_synth.rpt]
set manifest_path [file join $out_dir manifest.json]

puts "INFO: RTL directory: $rtl_dir"
puts "INFO: Top module: $top_module"
puts "INFO: Part: $part"
puts "INFO: RTL files: [llength $rtl_files]"
puts "INFO: Header files: [llength $header_files]"
puts "INFO: Include dirs: [llength $include_dirs]"

set_property include_dirs $include_dirs [current_fileset]
read_verilog -sv $rtl_files

set define_args [list]
foreach define [split_csv $defines_csv] {
  lappend define_args -verilog_define $define
}

set synth_args [list -top $top_module -part $part -mode out_of_context -flatten_hierarchy rebuilt]
set synth_args [concat $synth_args $define_args]
puts "INFO: synth_design $synth_args"
synth_design {*}$synth_args

write_checkpoint -force $dcp_path
report_utilization -file $util_path
report_timing_summary -file $timing_path

set mf [open $manifest_path w]
puts $mf "{"
puts $mf "  \"rtl_dir\": [json_escape $rtl_dir],"
puts $mf "  \"top_module\": [json_escape $top_module],"
puts $mf "  \"part\": [json_escape $part],"
puts $mf "  \"defines_csv\": [json_escape $defines_csv],"
puts $mf "  \"rtl_file_count\": [llength $rtl_files],"
puts $mf "  \"header_file_count\": [llength $header_files],"
puts $mf "  \"include_dir_count\": [llength $include_dirs],"
puts $mf "  \"dcp\": [json_escape $dcp_path],"
puts $mf "  \"utilization_report\": [json_escape $util_path],"
puts $mf "  \"timing_report\": [json_escape $timing_path]"
puts $mf "}"
close $mf

puts "INFO: Wrote $dcp_path"
puts "INFO: Wrote $manifest_path"
