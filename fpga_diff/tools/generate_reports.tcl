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

# Summarize timing: call report_timing_summary but keep only key lines
proc summarize_timing {run fh max_paths} {
  if {[catch { open_run $run } openErr]} {
    puts $fh "WARNING: open_run $run failed in summarize_timing: $openErr"
    return
  }
  set out ""
  if {[string match *impl* $run]} {
    if {[catch { set out [report_timing_summary -delay_type max -max_paths $max_paths -return_string] } terr]} {
      puts $fh "WARNING: report_timing_summary failed for $run: $terr"
      return
    }
  } else {
    if {[catch { set out [report_timing_summary -max_paths $max_paths -return_string] } terr]} {
      puts $fh "WARNING: report_timing_summary failed for $run: $terr"
      return
    }
  }

  # split into lines and keep only lines with key keywords to reduce verbosity
  set lines [split $out "\n"]
  set filtered {}
  foreach line $lines {
    if {[regexp -nocase {wns|tns|slack|worst|endpoint|startpoint|clock|path|Data Path} $line]} {
      lappend filtered $line
    }
  }
  if {[llength $filtered] == 0} {
    # fallback: take the first 12 non-empty lines
    set cnt 0
    foreach line $lines {
      if {[string trim $line] ne ""} {
        lappend filtered $line
        incr cnt
      }
      if {$cnt >= 12} { break }
    }
  }
  # print a concise block
  puts $fh "";
  foreach l $filtered { puts $fh $l }
}

# Print hierarchical utilization but filter to max_levels and remove device/total summary lines
proc print_hierarchical_filtered {fh hier_str max_levels} {
  set lines [split $hier_str "\n"]
  # We'll print only table rows that start with '|' and have instance text,
  # calculating depth from leading spaces after the first '|'.
  set printed_header 0
  foreach line $lines {
    # skip separator lines and empty lines
    if {[string match "+*" [string trim $line]] || [string trim $line] eq ""} { continue }
    if {[string index $line 0] eq "|"} {
      # get content after first '|'
      set rest [string range $line 1 end]
      # skip header-like lines that contain 'Tool Version' or 'Command' or column titles
      if {[regexp -nocase {tool version|command|design|device|table of contents|total|available|util%|used|primitive|instantiated|clock summary} $rest]} {
        # still allow the first table header row (contains 'Instance' or 'Module' headings)
        if {[regexp -nocase {instance.+module|utilization by hierarchy} $rest] && !$printed_header} {
          puts $fh $line
          set printed_header 1
        }
        continue
      }
      # count leading spaces
      set leading 0
      foreach char [split $rest ""] {
        if {$char eq " " } { incr leading } else { break }
      }
      # map spaces to depth: depth = floor((leading-1)/2)
      set depth 0
      if {$leading > 0} {
        set depth [expr {int(($leading-1)/2)}]
      }
      if {$depth < $max_levels} {
        puts $fh $line
      }
    }
  }
}

# Helper to report utilization/route/timing for a given run name (e.g. impl_1 or synth_1)
proc report_for_run {run fh max_depth} {
  # open the run (may throw if run not launched)
  open_run $run
  puts $fh "-- Utilization ([get_property RUN_NAME [get_runs $run]]) --"
  puts $fh [report_utilization -return_string]
  puts $fh "-- Route Status --"
  puts $fh [report_route_status -return_string]
  # Timing summary moved to the end of the script to reduce interleaved output

  puts $fh ""
  puts $fh "---- Hierarchical utilization (filtered, max depth: $max_depth) ----"
  if {[catch { set hier_out [report_utilization -hierarchical -return_string] } err]} {
    puts $fh "WARNING: hierarchical report failed: $err"
  } else {
    # Filter the hierarchical output to the requested max depth and avoid device totals
    print_hierarchical_filtered $fh $hier_out $max_depth
  }
}

# Project
puts $fh "Vivado Report Generated: [ts]"
puts $fh "Vivado Version: [version -short]"
puts $fh "Project: $proj"
open_project $proj
# Prefer implementation; if not available or not launched, fall back to synthesis; otherwise report not found
;# Allow overriding HIER_MAX_DEPTH via environment variable, default to 4 (within 3..5)
if {[info exists ::env(HIER_MAX_DEPTH)]} {
  set HIER_MAX_DEPTH [expr {$::env(HIER_MAX_DEPTH) < 3 ? 3 : ($::env(HIER_MAX_DEPTH) > 5 ? 5 : $::env(HIER_MAX_DEPTH))}]
} else {
  set HIER_MAX_DEPTH 4
}
set reported_run ""
if {[llength [get_runs impl_1]]} {
  # Try to report impl_1; open_run may fail if the run was never launched
  if {[catch { report_for_run impl_1 $fh $HIER_MAX_DEPTH } err]} {
    puts $fh "WARNING: reporting impl_1 failed: $err"
    if {[llength [get_runs synth_1]]} {
      if {[catch { report_for_run synth_1 $fh $HIER_MAX_DEPTH } err2]} {
        puts $fh "ERROR: reporting synth_1 failed: $err2"
      } else {
        set reported_run synth_1
      }
    } else {
      section $fh "NO RUNS FOUND"
      puts $fh "Run impl_1 could not be used and synth_1 not found."
    }
  } else {
    set reported_run impl_1
  }
} elseif {[llength [get_runs synth_1]]} {
  if {[catch { report_for_run synth_1 $fh $HIER_MAX_DEPTH } err]} {
    puts $fh "ERROR: reporting synth_1 failed: $err"
  } else {
    set reported_run synth_1
  }
} else {
  section $fh "NO RUNS FOUND"
  puts $fh "Run impl_1 and synth_1 not found."
}

## Output the summary of the sequence of events after all the reports have been completed.
set max_paths_val 1
puts $fh ""
puts $fh "==================== Timing Summaries (end) ===================="
if {[info exists reported_run] && $reported_run ne ""} {
  summarize_timing $reported_run $fh $max_paths_val
} else {
  puts $fh "No successful run was reported earlier; skipping timing summaries."
}

# Close output file and exit
if {$fh ne "stdout"} { close $fh }
exit