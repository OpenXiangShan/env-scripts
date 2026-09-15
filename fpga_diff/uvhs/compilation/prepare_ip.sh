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

generalbus_stub_is_256() {
  grep -Eq 'output[[:space:]]+\[255:0\][[:space:]]*dut_axi_wdata' "$1" &&
    grep -Eq 'input[[:space:]]+\[255:0\][[:space:]]*dut_axi_rdata' "$1"
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

# GeneralBus is protected UVHS IP. Keep the approved release assets with the
# UVHS flow while allowing a site to select another matching release pair.
gbus_asset_root=$script_dir/../ip/gbus
gbus_dcp=${UVHS_GBUS_DCP:-$gbus_asset_root/uvw_general_bus/uvw_general_bus.dcp}
gbus_stub=${UVHS_GBUS_STUB:-$gbus_asset_root/uvw_general_bus/uvw_general_bus_Stub.v}
require_file "$gbus_dcp"
require_file "$gbus_stub"
generalbus_stub_is_256 "$gbus_stub" || {
  echo "ERROR: UVHS GeneralBus stub is not 256-bit: $gbus_stub" >&2
  exit 1
}
echo "INFO: using UVHS GeneralBus DCP $gbus_dcp"
rm -rf "$work_dir/rtl/soc/uvw_general_bus"
mkdir -p "$work_dir/rtl/soc/uvw_general_bus" "$work_dir/rtl/stubs"
cp -f "$gbus_dcp" "$work_dir/rtl/soc/uvw_general_bus/uvw_general_bus.dcp"
cp -f "$gbus_stub" "$work_dir/rtl/soc/uvw_general_bus/uvw_general_bus_Stub.v"
cp -f "$gbus_stub" "$work_dir/rtl/stubs/uvw_general_bus.v"

# GeneralBD is the protected endpoint paired with GeneralBus. A site may select
# another matching release pair explicitly.
generalbd_dcp=${UVHS_GENERALBD_DCP:-$gbus_asset_root/generalBD/generalBD.dcp}
[[ -n "$generalbd_dcp" && -s "$generalbd_dcp" ]] || {
  echo "ERROR: UVHS GENERALBD DCP not found; set UVHS_GENERALBD_DCP" >&2
  exit 1
}
cp -f "$generalbd_dcp" "$work_dir/rtl/soc/generalBD.dcp"
echo "INFO: prepared UVHS generalBD DCP from $generalbd_dcp"

# The GENERALBD metadata stub is part of the protected-IP contract, not an
# optional Vivado stub.  UVHS uses its UV_HW_IP to pair GENERALBD with the
# GENERALBUS system-bus endpoint; without it the generated static elaboration
# leaves gbd_sysbus_i/o unconnected even when the DCP was imported with
# -generalbd.
generalbd_stub=${UVHS_GENERALBD_STUB:-${generalbd_dcp%.dcp}_Stub.v}
if [[ ! -s "$generalbd_stub" ]]; then
  generalbd_stub=$(dirname "$generalbd_dcp")/generalBD_Stub.v
fi
[[ -s "$generalbd_stub" ]] || {
  echo "ERROR: UVHS GENERALBD metadata stub not found next to $generalbd_dcp; set UVHS_GENERALBD_STUB" >&2
  exit 1
}
cp -f "$generalbd_stub" "$work_dir/rtl/stubs/generalBD.v"
echo "INFO: prepared UVHS generalBD metadata stub from $generalbd_stub"

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
  if [[ -n $source_file ]]; then
    mkdir -p "$(dirname "$destination")"
    if [[ "$(realpath -m "$source_file")" != "$(realpath -m "$destination")" ]]; then
      cp -f "$source_file" "$destination"
    fi
  fi
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
