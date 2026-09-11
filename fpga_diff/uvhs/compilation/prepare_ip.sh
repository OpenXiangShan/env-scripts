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

generalbd_source_default() {
  # Keep the checked-in pair as the default.  The GeneralBD and generalBus
  # checkpoints are a matched UVHS ABI; selecting a different vendor example
  # can leave [GENERAL_BUS] empty in binding.log even though both blackboxes
  # elaborate successfully.  Regeneration remains available explicitly via
  # UVHS_GBUS_REGENERATE=1.
  local candidate
  for candidate in \
    "$script_dir/../../third_party/gbus_ip/generalBD/generalBD.dcp" \
    "${UVHS_GBUS_IP_ROOT:-$script_dir/../../third_party/gbus_ip}/generalBD/generalBD.dcp" \
    "$UV_ROOT/doc/UVHS/example/gbus_demo/generalBD_gbus/generalBD.dcp" \
    "$UV_ROOT/doc/UVHS/example/gbd_demo/src/ip/generalBD/generalBD.dcp" \
    "$UV_ROOT/doc/UVHS-2/example/gbus_demo/src/ip/generalBD/generalBD.dcp"; do
    if [[ -s $candidate ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  find "$UV_ROOT/doc/UVHS" -path '*/gBD_force_monitor/gbd_ip/generalBD.dcp' \
    -type f -size +0c -print -quit
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

# Generate the vendor generalBus from a private copy. Its original generator
# removes the Vivado project before an asynchronous DCP copy has completed.
gbus_source=$UV_ROOT/platform/U2.2/Prototype/ips/uvw_gbus.3.1
gbus_gen=$work_dir/ip-gen/generalbus
gbus_release=$gbus_gen/uvw_general_bus
gbus_asset_root=${UVHS_GBUS_IP_ROOT:-$(cd "$script_dir/../../third_party/gbus_ip" 2>/dev/null && pwd || true)}
require_file "$gbus_source/gen_generalbus_ip.py"
require_file "$gbus_source/uvw_axi3_generalbus.json"
gbus_bundled_dcp=${UVHS_GBUS_DCP:-$gbus_asset_root/uvw_general_bus/uvw_general_bus.dcp}
gbus_bundled_stub=${UVHS_GBUS_STUB:-$gbus_asset_root/uvw_general_bus/uvw_general_bus_Stub.v}
if [[ ${UVHS_GBUS_REGENERATE:-0} != 1 && -s $gbus_bundled_dcp && -s $gbus_bundled_stub ]]; then
  rm -rf "$work_dir/rtl/soc/uvw_general_bus"
  mkdir -p "$work_dir/rtl/soc" "$work_dir/rtl/stubs"
  mkdir -p "$work_dir/rtl/soc/uvw_general_bus"
  cp -a "$gbus_asset_root/uvw_general_bus"/. "$work_dir/rtl/soc/uvw_general_bus/"
  cp -f "$gbus_bundled_stub" "$work_dir/rtl/stubs/uvw_general_bus.v"
  generalbus_stub_is_256 "$work_dir/rtl/stubs/uvw_general_bus.v"
  echo "INFO: using checked-in UVHS generalBus DCP $gbus_bundled_dcp"
else
  if [[ $force == 1 || ! -s $gbus_release/uvw_general_bus.dcp ||
        ! -s $gbus_release/uvw_general_bus_Stub.v ]] ||
      ! generalbus_stub_is_256 "$gbus_release/uvw_general_bus_Stub.v"; then
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
     s|(\"DATA_WIDTH\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"256\"|" "$json"
    (cd "$gbus_gen" && PATH="$UV_XILINX_VIVADO/bin:$PATH" \
      python3 "$generator" -j "$json")
  fi
  require_file "$gbus_release/uvw_general_bus.dcp"
  require_file "$gbus_release/uvw_general_bus_Stub.v"
  generalbus_stub_is_256 "$gbus_release/uvw_general_bus_Stub.v"
  rm -rf "$work_dir/rtl/soc/uvw_general_bus"
  mkdir -p "$work_dir/rtl/soc" "$work_dir/rtl/stubs"
  cp -a "$gbus_release" "$work_dir/rtl/soc/uvw_general_bus"
  cp -f "$gbus_release/uvw_general_bus_Stub.v" "$work_dir/rtl/stubs/uvw_general_bus.v"
  echo "INFO: prepared regenerated 256-bit UVHS generalBus DCP"
fi

# GENERALBD is a protected UVHS endpoint referenced by core_def_xdma in GBus
# mode.  Keep its platform DCP alongside the other imported IPs so frontend
# elaboration can resolve the metadata-bearing blackbox.
generalbd_dcp=${UVHS_GENERALBD_DCP:-$(generalbd_source_default)}
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
