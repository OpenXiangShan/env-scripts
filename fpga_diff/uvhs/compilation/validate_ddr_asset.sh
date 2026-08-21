#!/usr/bin/env bash
set -euo pipefail

[[ $# == 4 ]] || {
  echo "Usage: $0 DDR_SOURCE DATA_WIDTH ADDR_WIDTH ID_WIDTH" >&2
  exit 64
}

ddr_source=$1
data_width=$2
addr_width=$3
id_width=$4
manifest=$ddr_source/SHA256SUMS
required_files=(
  rtl/soc/uvw_axi4_to_ddr4.dcp
  rtl/soc/uvw_axi4_to_ddr4_Stub.v
  script/uvw_axi4_to_ddr4_pblock.tcl
  script/custom_parts_ddr4_KSM26SES8_2666.csv
)

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -d $ddr_source ]] || fail "UVHS DDR asset directory not found: $ddr_source"
[[ $data_width == 64 || $data_width == 256 ]] ||
  fail "unsupported UVHS DDR AXI data width: $data_width"
for value in "$addr_width" "$id_width"; do
  [[ $value =~ ^[1-9][0-9]*$ ]] || fail "invalid UVHS DDR AXI width: $value"
done

for rel in "${required_files[@]}"; do
  [[ -s $ddr_source/$rel ]] ||
    fail "required UVHS DDR asset file is missing or empty: $ddr_source/$rel"
done
[[ -s $manifest ]] || fail "required UVHS DDR asset manifest is missing or empty: $manifest"

for rel in "${required_files[@]}"; do
  count=$(awk -v path="$rel" '$2 == path || $2 == "*" path { count++ } END { print count + 0 }' "$manifest")
  [[ $count == 1 ]] || fail "UVHS DDR asset manifest must list exactly one checksum for: $rel"
done
(cd "$ddr_source" && sha256sum --strict -c SHA256SUMS)

stub=$ddr_source/rtl/soc/uvw_axi4_to_ddr4_Stub.v
temporary_stub=
cleanup() {
  [[ -z $temporary_stub ]] || rm -f "$temporary_stub"
}
trap cleanup EXIT
if gzip -t "$stub" 2>/dev/null; then
  temporary_stub=$(mktemp)
  gzip -dc "$stub" >"$temporary_stub"
  stub=$temporary_stub
fi

require_stub_pattern() {
  local description=$1
  local pattern=$2
  grep -Eq "$pattern" "$stub" ||
    fail "UVHS DDR stub does not declare $description"
}

addr_last=$((addr_width - 1))
data_last=$((data_width - 1))
id_last=$((id_width - 1))
require_stub_pattern "uv_axi2ddr metadata for ADDR=$addr_width DATA=$data_width" \
  "uv_axi2ddr.*ADDR_WIDTH:$addr_width,DATA_WIDTH:$data_width"
require_stub_pattern "UV_HW_IP metadata for ADDR=$addr_width DATA=$data_width" \
  "UV_HW_IP.*ADDR_WIDTH:<$addr_width>,DATA_WIDTH:<$data_width>"

for port in ddr4ip_dut_axi_awaddr ddr4ip_dut_axi_araddr; do
  require_stub_pattern "$addr_width-bit $port" \
    "input[[:space:]]+\[$addr_last:0\][[:space:]]*$port"
done
for port in ddr4ip_dut_axi_awid ddr4ip_dut_axi_arid; do
  require_stub_pattern "$id_width-bit $port" \
    "input[[:space:]]+\[$id_last:0\][[:space:]]*$port"
done
for port in ddr4ip_dut_axi_bid ddr4ip_dut_axi_rid; do
  require_stub_pattern "$id_width-bit $port" \
    "output[[:space:]]+\[$id_last:0\][[:space:]]*$port"
done
require_stub_pattern "$data_width-bit ddr4ip_dut_axi_wdata" \
  "input[[:space:]]+\[$data_last:0\][[:space:]]*ddr4ip_dut_axi_wdata"
require_stub_pattern "$data_width-bit ddr4ip_dut_axi_rdata" \
  "output[[:space:]]+\[$data_last:0\][[:space:]]*ddr4ip_dut_axi_rdata"

echo "INFO: verified UVHS DDR asset: $ddr_source"
echo "INFO: verified UVHS DDR AXI contract: ADDR=$addr_width DATA=$data_width ID=$id_width"
sha256sum "${required_files[@]/#/$ddr_source/}"
