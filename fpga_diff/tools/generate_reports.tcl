# ----------------------------------------
# Vivado Tcl Script for Reporting (No GUI)
# ----------------------------------------

# Suppress WARNING messages
catch { set_msg_config -severity {WARNING} -suppress }

# 1) Read required arguments: OUT_FILE and PROJECT(.xpr)
if {![info exists ::argv] || [llength $::argv] < 2} {
  puts "ERROR: Missing arguments."
  puts "USAGE: vivado -mode tcl -source generate_reports.tcl -tclargs <OUT_FILE> <PROJECT_XPR>"
  exit 1
}
set outfile [string trim [lindex $::argv 0]]
set proj    [string trim [lindex $::argv 1]]

if {$outfile eq ""} {
  puts "ERROR: OUT_FILE cannot be empty."
  exit 1
}
if {$proj eq ""} {
  puts "ERROR: PROJECT_XPR cannot be empty."
  exit 1
}
set proj [file normalize $proj]
if {![file exists $proj]} {
  puts "ERROR: Project file not found: $proj"
  exit 1
}

# 2) Prepare output file
set outfile [file normalize $outfile]
set odir [file dirname $outfile]
if {$odir ne "" && $odir ne "." && $odir ne "/"} {
  catch { file mkdir $odir }
}

# 3) Open output file; on failure, fall back to stdout
set fh stdout
if {[catch {open $outfile "w"} fhErr]} {
  puts "ERROR: cannot open file '$outfile' for writing: $fhErr"
  set fh stdout
} else {
  set fh $fhErr
  puts "INFO: Writing Vivado report to: $outfile"
}

proc ts {} { return [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %Z"] }

# Helper: section title
proc section {fh title} {
  puts $fh ""
  puts $fh "==================== $title ===================="
}

# Project
puts $fh "Vivado Report Generated: [ts]"
puts $fh "Vivado Version: [version -short]"
puts $fh "Project: $proj"
open_project $proj

# Prefer implementation; if not available, fall back to synthesis; otherwise report not found
if {[llength [get_runs impl_1]]} {
  section $fh "IMPLEMENTATION (impl_1)"
  # Uncomment to print run STATUS/PROGRESS:
  # puts $fh "STATUS: [get_property STATUS [get_runs impl_1]]  PROGRESS: [get_property PROGRESS [get_runs impl_1]]"
  open_run impl_1
  puts $fh "-- Utilization (Implementation) --"
  puts $fh [report_utilization -return_string]
  puts $fh "-- Route Status --"
  puts $fh [report_route_status -return_string]
  puts $fh "-- Timing Summary (Setup, worst 3 paths) --"
  puts $fh [report_timing_summary -delay_type max -max_paths 3 -return_string]
} elseif {[llength [get_runs synth_1]]} {
  section $fh "SYNTHESIS (synth_1)"
  # Uncomment to print run STATUS/PROGRESS:
  # puts $fh "STATUS: [get_property STATUS [get_runs synth_1]]  PROGRESS: [get_property PROGRESS [get_runs synth_1]]"
  open_run synth_1
  puts $fh "-- Utilization (Synthesis) --"
  puts $fh [report_utilization -return_string]
  puts $fh [report_timing_summary -max_paths 3 -return_string]
} else {
  section $fh "NO RUNS FOUND"
  puts $fh "Run impl_1 and synth_1 not found."
}

if {$fh ne "stdout"} { close $fh }
exit