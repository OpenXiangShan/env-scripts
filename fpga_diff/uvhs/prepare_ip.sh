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

# Export the Vivado IP owned by this repository.
vivado=$UV_XILINX_VIVADO/bin/vivado
version=$("$vivado" -version | awk '/^Vivado v/ { sub(/^Vivado v/, ""); sub(/ .*/, ""); print; exit }')
[[ -n $version ]] || {
  echo "ERROR: unable to determine Vivado version from $vivado" >&2
  exit 1
}
vivado_args=(
  --origin_dir "$origin_dir" --out_dir "$work_dir"
  --vivado_version "$version" --core_dir "$core_dir" --jobs "$jobs"
)
[[ $force != 1 ]] || vivado_args+=(--force)
export VIVADO_HOME=$UV_XILINX_VIVADO XILINX_VIVADO=$UV_XILINX_VIVADO
"$vivado" -mode batch -source "$origin_dir/uvhs/export_vivado_ip.tcl" \
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
  grep -Fq 'shutil.copy2(f_dcp_in, f_dcp_out)' "$generator"
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
