#!/usr/bin/env bash
set -euo pipefail
export CCACHE_DISABLE=1
export OBJCACHE=
root="$(cd "$(dirname "$0")/.." && pwd)"
obj_dir="${TMPDIR:-/tmp}/uvhs_gbus_c2h_dma_obj_${USER}"
rm -rf "$obj_dir"
# Only intentionally unconnected FIFO metadata and reserved control bits are
# suppressed; all other Verilator warnings remain fatal.
/usr/local/bin/verilator --cc --exe --assert -Wall \
  -Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL \
  --top-module uvhs_gbus_c2h_dma \
  --Mdir "$obj_dir" \
  "$root/src/rtl/common/uvhs_gbus_c2h_dma.sv" \
  "$root/src/rtl/common/uvhs_axis_async_fifo.sv" \
  "$root/tests/uvhs_gbus_c2h_dma_test.cpp" \
  -CFLAGS '-std=c++17' --build
"$obj_dir/Vuvhs_gbus_c2h_dma"
