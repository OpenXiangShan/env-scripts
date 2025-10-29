#!/bin/bash
DATE_STR="$(date +%F)"
OUT_DIR="${OUT_DIR:-$PWD}"
OUT_FILE="${OUT_DIR}/${DATE_STR}-vivado-analyse.txt"

# Require CPU as the first positional argument
if [ -z "$1" ]; then
	# Print usage to stderr
	echo "Usage: $(basename "$0") <CPU>" 1>&2
	# If the script is sourced, avoid killing the interactive shell
	if [ -n "${ZSH_VERSION:-}" ]; then
		case $ZSH_EVAL_CONTEXT in *:file) return 1;; esac
	elif [ -n "${BASH_VERSION:-}" ]; then
		if [ "${BASH_SOURCE[0]}" != "$0" ]; then return 1; fi
	fi
	exit 1
fi
CPU="$1"

PROJ_FILE=fpga_${CPU}/fpga_${CPU}.xpr
vivado -mode tcl -nojournal -nolog -notrace -source generate_reports.tcl -tclargs "${OUT_FILE}" "${PROJ_FILE}"