#!/usr/bin/env bash
set -euo pipefail

[[ $# == 9 ]] || {
  echo "Usage: $0 ORIGIN_DIR WORK_DIR CORE_DIR JOBS FORCE DDR_SOURCE DDR_WIDTH DDR_ADDR_WIDTH DDR_ID_WIDTH" >&2
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
ddr_addr_width=$8
ddr_id_width=$9
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

require_file() {
  [[ -s $1 ]] || {
    echo "ERROR: required UVHS IP file is missing or empty: $1" >&2
    exit 1
  }
}

generalbus_stub_is_64() {
  grep -Eq 'output[[:space:]]+\[63:0\][[:space:]]*dut_axi_wdata' "$1" &&
    grep -Eq 'input[[:space:]]+\[63:0\][[:space:]]*dut_axi_rdata' "$1"
}

ddr_files=(
  rtl/soc/uvw_axi4_to_ddr4.dcp rtl/soc/uvw_axi4_to_ddr4_Stub.v
  script/uvw_axi4_to_ddr4_pblock.tcl script/custom_parts_ddr4_KSM26SES8_2666.csv
)
"$script_dir/validate_ddr_asset.sh" \
  "$ddr_source" "$ddr_width" "$ddr_addr_width" "$ddr_id_width"

# Export the Vivado IP owned by this repository.
vivado=$UV_XILINX_VIVADO/bin/vivado
vivado_args=(
  --origin_dir "$origin_dir" --out_dir "$work_dir"
  --core_dir "$core_dir" --jobs "$jobs"
)
[[ $force != 1 ]] || vivado_args+=(--force)
export VIVADO_HOME=$UV_XILINX_VIVADO XILINX_VIVADO=$UV_XILINX_VIVADO
"$vivado" -mode batch -source "$script_dir/export_vivado_ip.tcl" \
  -tclargs "${vivado_args[@]}"

# Generate the vendor generalBus from a private copy. Its original generator
# removes the Vivado project before an asynchronous DCP copy has completed.
gbus_source=$UV_ROOT/platform/U2.2/Prototype/ips/uvw_gbus.3.1
gbus_gen=$work_dir/ip-gen/generalbus
gbus_release=$gbus_gen/uvw_general_bus
require_file "$gbus_source/gen_generalbus_ip.py"
require_file "$gbus_source/uvw_axi3_generalbus.json"
if [[ $force == 1 || ! -s $gbus_release/uvw_general_bus.dcp ||
      ! -s $gbus_release/uvw_general_bus_Stub.v ]] ||
    ! generalbus_stub_is_64 "$gbus_release/uvw_general_bus_Stub.v"; then
  rm -rf "$gbus_gen"
  mkdir -p "$gbus_gen"
  cp -a "$gbus_source" "$gbus_gen/ip-src"
  generator=$gbus_gen/ip-src/gen_generalbus_ip.py
  sed -i '/os[.]popen.*f_dcp_in.*f_dcp_out/c\    shutil.copy2(f_dcp_in, f_dcp_out)' \
    "$generator"
  sed -i 's|#!/bin/tcsh|#!/usr/bin/env bash|' "$generator"
  grep -Fq 'shutil.copy2(f_dcp_in, f_dcp_out)' "$generator"
  grep -Fq '#!/usr/bin/env bash' "$generator"
  json=$gbus_gen/uvw_axi3_generalbus.json
  cp -f "$gbus_source/uvw_axi3_generalbus.json" "$json"
  sed -i -E \
    "s|(\"IP_LOCATION\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"$gbus_gen/ip-src\"|; \
     s|(\"DATA_WIDTH\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"64\"|" "$json"
  (cd "$gbus_gen" && PATH="$UV_XILINX_VIVADO/bin:$PATH" \
    python3 "$generator" -j "$json")
fi
require_file "$gbus_release/uvw_general_bus.dcp"
require_file "$gbus_release/uvw_general_bus_Stub.v"
generalbus_stub_is_64 "$gbus_release/uvw_general_bus_Stub.v"
rm -rf "$work_dir/rtl/soc/uvw_general_bus"
mkdir -p "$work_dir/rtl/soc" "$work_dir/rtl/stubs"
cp -a "$gbus_release" "$work_dir/rtl/soc/uvw_general_bus"
cp -f "$gbus_release/uvw_general_bus_Stub.v" "$work_dir/rtl/stubs/uvw_general_bus.v"
echo "INFO: prepared 64-bit UVHS generalBus DCP"

# Import the validated external DDR asset using canonical work-tree names.
for rel in "${ddr_files[@]}"; do
  destination=$work_dir/$rel
  mkdir -p "$(dirname "$destination")"
  cp -f "$ddr_source/$rel" "$destination"
done
for rel in "${ddr_files[@]}"; do require_file "$work_dir/$rel"; done
ddr_stub=$work_dir/rtl/soc/uvw_axi4_to_ddr4_Stub.v
if gzip -t "$ddr_stub" 2>/dev/null; then
  gzip -dc "$ddr_stub" >"$ddr_stub.decompressed"
  mv -f "$ddr_stub.decompressed" "$ddr_stub"
fi
echo "INFO: prepared validated UVHS DDR asset"
