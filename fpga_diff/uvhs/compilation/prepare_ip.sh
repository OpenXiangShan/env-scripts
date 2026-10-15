#!/usr/bin/env bash
set -euo pipefail

[[ $# == 7 ]] || {
  echo "Usage: $0 ORIGIN_DIR WORK_DIR CORE_DIR JOBS FORCE DDR_SOURCE DDR_WIDTH" >&2
  exit 64
}
: "${UV_ROOT:?UV_ROOT is not set}"
: "${UV_XILINX_VIVADO:?UV_XILINX_VIVADO is not set}"

origin_dir=$1
work_dir=$2
core_dir=$3
jobs=$4
force=$5
ddr_source=$6
ddr_width=$7
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

require_file() {
  [[ -s $1 ]] || {
    echo "ERROR: required UVHS IP file is missing or empty: $1" >&2
    exit 1
  }
}

require_stub_port() {
  local stub=$1
  local pattern=$2
  local description=$3
  grep -Eq "$pattern" "$stub" || {
    echo "ERROR: generated IP stub has the wrong $description: $stub" >&2
    exit 1
  }
}

generalbus_stub_is_64() {
  grep -Eq 'output[[:space:]]+\[63:0\][[:space:]]*dut_axi_wdata' "$1" &&
    grep -Eq 'input[[:space:]]+\[63:0\][[:space:]]*dut_axi_rdata' "$1"
}

generalbus_stub_is_256() {
  grep -Eq 'output[[:space:]]+\[255:0\][[:space:]]*dut_axi_wdata' "$1" &&
    grep -Eq 'input[[:space:]]+\[255:0\][[:space:]]*dut_axi_rdata' "$1"
}

sanitize_generalbus_generator() {
  local generator=$1
  sed -i '/os[.]popen.*f_dcp_in.*f_dcp_out/c\    shutil.copy2(f_dcp_in, f_dcp_out)' \
    "$generator"
  sed -i 's|#!/bin/tcsh|#!/usr/bin/env bash|' "$generator"
  grep -Fq 'shutil.copy2(f_dcp_in, f_dcp_out)' "$generator"
  grep -Fq '#!/usr/bin/env bash' "$generator"
}

generate_generalbus() {
  local data_width=$1
  local gbus_source=$UV_ROOT/platform/U2.2/Prototype/ips/uvw_gbus.3.1
  local gbus_gen=$work_dir/ip-gen/generalbus_${data_width}
  local gbus_release=$gbus_gen/uvw_general_bus
  local width_check=generalbus_stub_is_${data_width}

  require_file "$gbus_source/gen_generalbus_ip.py"
  require_file "$gbus_source/uvw_axi3_generalbus.json"
  if [[ $force == 1 || ! -s $gbus_release/uvw_general_bus.dcp ||
        ! -s $gbus_release/uvw_general_bus_Stub.v ]] ||
      ! "$width_check" "$gbus_release/uvw_general_bus_Stub.v"; then
    rm -rf "$gbus_gen"
    mkdir -p "$gbus_gen"
    cp -a "$gbus_source" "$gbus_gen/ip-src"
    local generator=$gbus_gen/ip-src/gen_generalbus_ip.py
    sanitize_generalbus_generator "$generator"
    local json=$gbus_gen/uvw_axi3_generalbus.json
    cp -f "$gbus_source/uvw_axi3_generalbus.json" "$json"
    sed -i -E \
      "s|(\"IP_LOCATION\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"$gbus_gen/ip-src\"|; \
       s|(\"DATA_WIDTH\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"$data_width\"|" "$json"
    (cd "$gbus_gen" && PATH="$UV_XILINX_VIVADO/bin:$PATH" \
      python3 "$generator" -j "$json")
  fi
  require_file "$gbus_release/uvw_general_bus.dcp"
  require_file "$gbus_release/uvw_general_bus_Stub.v"
  "$width_check" "$gbus_release/uvw_general_bus_Stub.v"
  rm -rf "$work_dir/rtl/soc/uvw_general_bus"
  mkdir -p "$work_dir/rtl/soc" "$work_dir/rtl/stubs"
  cp -a "$gbus_release" "$work_dir/rtl/soc/uvw_general_bus"
  cp -f "$gbus_release/uvw_general_bus_Stub.v" \
    "$work_dir/rtl/soc/uvw_general_bus/uvw_general_bus_Stub.v"
  cp -f "$gbus_release/uvw_general_bus_Stub.v" "$work_dir/rtl/stubs/uvw_general_bus.v"
  echo "INFO: prepared ${data_width}-bit UVHS generalBus DCP"
}

validate_generalbd_resource() {
  python3 - "$@" <<'PY'
import ast, pathlib, re, sys

report = pathlib.Path(sys.argv[1])
in_primitives = False
used = 0
for line in report.read_text().splitlines():
    heading = re.match(r'^\d+\.\s*([\w/]+)', line)
    if heading:
        in_primitives = heading.group(1) == "Primitives"
    if in_primitives:
        row = line.split("|")
        if len(row) >= 4 and row[2].strip().isdigit():
            used += int(row[2].strip())
if not used:
    sys.exit(f"ERROR: GeneralBD utilization lacks used Primitives: {report}")
if len(sys.argv) == 4:
    resource = pathlib.Path(sys.argv[2])
    values = {}
    for line in resource.read_text().splitlines():
        item = re.fullmatch(r'(REG|LUT|RAMLUT|BRAM|URAM|LUT6|DSP|CARRY8)\s*:\s*(\d+)', line.strip())
        if not item or item.group(1) in values:
            sys.exit(f"ERROR: malformed GeneralBD resources: {resource}")
        values[item.group(1)] = int(item.group(2))
    if len(values) != 8 or not sum(values.values()):
        sys.exit(f"ERROR: incomplete or empty GeneralBD resources: {resource}")
    parser = pathlib.Path(sys.argv[3])
    definitions = [node for node in ast.parse(parser.read_text()).body
                   if isinstance(node, ast.FunctionDef) and node.name == "gen_resource_file"]
    if len(definitions) != 1:
        sys.exit(f"ERROR: GeneralBD vendor resource parser not found: {parser}")
    namespace = {"re": re}
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(parser), "exec"), namespace)
    expected = namespace["gen_resource_file"](report.read_text().splitlines(keepends=True))
    if resource.read_text() != expected:
        sys.exit(f"ERROR: packaged GeneralBD resources differ from vendor report: {resource}")
PY
}

prepare_generalbd() {
  local vendor_gbd=$UV_ROOT/platform/U2.2/Prototype/ips/gbd/generalBD
  local vendor_dcp=$vendor_gbd/generalBD.dcp
  local vendor_stub=$vendor_gbd/output/generalBD_stub.v
  local vendor_resource=$vendor_gbd/output/generalBD_resource.v
  local prepare_ip_py=$UV_ROOT/etc/auxtools/prepare_ip/prepare_ip.py
  local gbd_gen=$work_dir/ip-gen/generalbd
  local gbd_release=$gbd_gen/generalBD
  local rebuilt=0
  local proof_files=(
    "$vendor_dcp" "$vendor_gbd/script/generalBD.json"
    "$prepare_ip_py" "$script_dir/prepare_ip.sh"
    "$gbd_gen/output/generalBD_stub.v" "$gbd_gen/output/generalBD_resource.v"
    "$gbd_gen/generalBD.json" "$gbd_release/generalBD.dcp"
    "$gbd_release/generalBD_Stub.v" "$gbd_release/generalBD_Resource.txt"
  )

  require_file "$vendor_dcp"
  require_file "$prepare_ip_py"
  require_file "$vendor_gbd/script/generalBD.json"
  if [[ $force == 1 || ! -s $gbd_release/generalBD.dcp ||
        ! -s $gbd_release/generalBD_Stub.v ||
        ! -s $gbd_release/generalBD_Resource.txt ||
        ! -s $gbd_gen/prepare.complete ]] ||
      ! sha256sum "${proof_files[@]}" 2>/dev/null | cmp -s - "$gbd_gen/prepare.complete"; then
    rm -rf "$gbd_gen"
    mkdir -p "$gbd_gen/output"
    if [[ ! -s $vendor_stub || ! -s $vendor_resource ]] ||
        ! validate_generalbd_resource "$vendor_resource" >/dev/null 2>&1; then
      echo "INFO: regenerating GeneralBD synth stub and utilization from vendor DCP"
      cat >"$gbd_gen/write_stub.tcl" <<'TCL'
set dcp [lindex $argv 0]
set stub [lindex $argv 1]
set resource [lindex $argv 2]
open_checkpoint $dcp
file mkdir [file dirname $stub]
write_verilog -force -mode synth_stub $stub
report_utilization -file $resource
close_design
TCL
      "$UV_XILINX_VIVADO/bin/vivado" -mode batch -nojournal -nolog \
        -source "$gbd_gen/write_stub.tcl" \
        -tclargs "$vendor_dcp" "$gbd_gen/output/generalBD_stub.v" \
        "$gbd_gen/output/generalBD_resource.v"
      vendor_stub=$gbd_gen/output/generalBD_stub.v
      vendor_resource=$gbd_gen/output/generalBD_resource.v
    else
      cp -f "$vendor_stub" "$gbd_gen/output/generalBD_stub.v"
      vendor_stub=$gbd_gen/output/generalBD_stub.v
      cp -f "$vendor_resource" "$gbd_gen/output/generalBD_resource.v"
      vendor_resource=$gbd_gen/output/generalBD_resource.v
    fi
    require_file "$vendor_stub"
    require_file "$vendor_resource"
    validate_generalbd_resource "$vendor_resource"
    cp -f "$vendor_dcp" "$gbd_gen/output/generalBD.dcp"
    python3 - "$vendor_gbd/script/generalBD.json" "$gbd_gen" <<'PY'
import json, pathlib, sys
src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
data = json.loads(src.read_text())
data["RESOURCE_FILE"] = str(dst / "output/generalBD_resource.v")
data["STUB_FILE"] = str(dst / "output/generalBD_stub.v")
data["DCP_FILE"] = str(dst / "output/generalBD.dcp")
(dst / "generalBD.json").write_text(json.dumps(data, indent=2) + "\n")
PY
    (cd "$gbd_gen" && python3 "$prepare_ip_py" -j "$gbd_gen/generalBD.json" \
      -p U2 --gbd --nolib)
    rebuilt=1
  fi
  require_file "$gbd_release/generalBD.dcp"
  require_file "$gbd_release/generalBD_Stub.v"
  require_file "$gbd_release/generalBD_Resource.txt"
  validate_generalbd_resource "$gbd_gen/output/generalBD_resource.v" \
    "$gbd_release/generalBD_Resource.txt" "$prepare_ip_py"
  require_stub_port "$gbd_release/generalBD_Stub.v" \
    'input[[:space:]]+\[255:0\][[:space:]]*gbd_sysbus_i' \
    'GeneralBD sysbus width; expected 256 bits'
  require_stub_port "$gbd_release/generalBD_Stub.v" \
    'uvw_generalBD[[:space:]]*=[[:space:]]*1' 'GeneralBD annotation'
  cmp -s "$vendor_dcp" "$gbd_release/generalBD.dcp" || {
    echo "ERROR: packaged GeneralBD checkpoint differs from vendor DCP" >&2
    exit 1
  }
  mkdir -p "$work_dir/rtl/soc" "$work_dir/rtl/stubs"
  cp -f "$gbd_release/generalBD.dcp" "$work_dir/rtl/soc/generalBD.dcp"
  cp -f "$gbd_release/generalBD_Stub.v" "$work_dir/rtl/stubs/generalBD.v"
  if [[ $rebuilt == 1 ]]; then
    sha256sum "${proof_files[@]}" >"$gbd_gen/prepare.complete.tmp"
    mv -f "$gbd_gen/prepare.complete.tmp" "$gbd_gen/prepare.complete"
  fi
  echo "INFO: prepared UVHS GeneralBD DCP from vendor IP"
}

# Export the Vivado IP owned by this repository.
vivado=$UV_XILINX_VIVADO/bin/vivado
vivado_args=(
  --origin_dir "$origin_dir" --out_dir "$work_dir"
  --core_dir "$core_dir" --jobs "$jobs"
  --hostif "${DIFFTEST_HOSTIF:-XDMA}"
)
[[ $force != 1 ]] || vivado_args+=(--force)
export VIVADO_HOME=$UV_XILINX_VIVADO XILINX_VIVADO=$UV_XILINX_VIVADO
"$vivado" -mode batch -source "$script_dir/export_vivado_ip.tcl" \
  -tclargs "${vivado_args[@]}"

hostif=${DIFFTEST_HOSTIF:-XDMA}
if [[ $hostif == GBUS ]]; then
  generate_generalbus 256
  prepare_generalbd
else
  # XDMA still needs the 64-bit vendor generalBus used by the existing UVHS
  # flash/runtime path. Generate it locally instead of checking in a DCP.
  generate_generalbus 64
fi

# Import the externally generated DDR DCP using its canonical work-tree names.
[[ $ddr_width == 64 || $ddr_width == 256 ]] || {
  echo "ERROR: unsupported UVHS DDR AXI width: $ddr_width" >&2
  exit 1
}
ddr_files=(
  rtl/soc/uvw_axi4_to_ddr4.dcp rtl/soc/uvw_axi4_to_ddr4_Stub.v
  script/uvw_axi4_to_ddr4_pblock.tcl script/custom_parts_ddr4_KSM26SES8_2666.csv
)
for rel in "${ddr_files[@]}"; do
  base=${rel##*/}
  destination=$work_dir/$rel
  source_file=
  for candidate in "$ddr_source/$rel" "$ddr_source/$base"; do
    [[ ! -f $candidate ]] || { source_file=$candidate; break; }
  done
  [[ -n $source_file ]] || source_file=$(find "$ddr_source" -type f -name "$base" -size +0c -print -quit)
  [[ -z $source_file ]] || { mkdir -p "$(dirname "$destination")"; cp -f "$source_file" "$destination"; }
done
for rel in "${ddr_files[@]:0:3}"; do require_file "$work_dir/$rel"; done
ddr_stub=$work_dir/rtl/soc/uvw_axi4_to_ddr4_Stub.v
if gzip -t "$ddr_stub" 2>/dev/null; then
  gzip -dc "$ddr_stub" >"$ddr_stub.decompressed"
  mv -f "$ddr_stub.decompressed" "$ddr_stub"
fi
last_bit=$((ddr_width - 1))
grep -Eq "input[[:space:]]+\[$last_bit:0\][[:space:]]*ddr4ip_dut_axi_wdata" "$ddr_stub"
grep -Eq "output[[:space:]]+\[$last_bit:0\][[:space:]]*ddr4ip_dut_axi_rdata" "$ddr_stub"
echo "INFO: verified UVHS DDR DCP AXI data width: $ddr_width"
