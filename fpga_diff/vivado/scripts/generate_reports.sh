#!/usr/bin/env bash
set -euo pipefail
# Require bash (avoid running with `sh` which can cause "bad substitution")
if [ -z "${BASH_VERSION:-}" ]; then
  echo "ERROR: this script requires bash. Run with: bash $0 <CPU>  or: CPU=<name> $0" >&2
  exit 1
fi

# Directory where this script resides (supports being called via relative/absolute path or from another cwd)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OUT_DIR="${OUT_DIR:-$PWD}"
# Use a stable default filename (no date prefix)
OUT_FILE="${OUT_DIR}/vivado-analyse.txt"

# CPU can be provided as the first positional argument or via the environment variable CPU
if [ $# -ge 1 ]; then
  CPU="$1"
elif [ -n "${CPU:-}" ]; then
  CPU="$CPU"
else
  echo "Usage: $(basename "$0") <CPU>  OR  CPU=<name> $(basename "$0")" >&2
  # If the script is being sourced, avoid exiting the interactive shell
  if [ -n "${ZSH_VERSION:-}" ]; then
    case $ZSH_EVAL_CONTEXT in *:file) return 1;; esac
  elif [ -n "${BASH_VERSION:-}" ]; then
    if [ "${BASH_SOURCE[0]}" != "$0" ]; then return 1; fi
  fi
  exit 1
fi

# Locate the TCL script (same dir as this script) and the project .xpr relative to script dir
TCL_SCRIPT="${SCRIPT_DIR}/generate_reports.tcl"
PROJ_FILE="fpga_${CPU}/fpga_${CPU}.xpr"

# Check that the TCL script exists
if [ ! -f "$TCL_SCRIPT" ]; then
  echo "ERROR: tcl script not found: $TCL_SCRIPT" >&2
  exit 1
fi

# Check that the Vivado project file exists
if [ ! -f "$PROJ_FILE" ]; then
  echo "ERROR: project file not found: $PROJ_FILE" >&2
  exit 1
fi

# Run Vivado in TCL mode to generate the reports
vivado -mode tcl -nojournal -nolog -notrace -source "$TCL_SCRIPT" -tclargs "${OUT_FILE}" "${PROJ_FILE}"

echo "Report written to: ${OUT_FILE}"
