#!/usr/bin/env bash

# Copy this file to uvhs/setenv.local.sh and fill in local values.
# Do not commit uvhs/setenv.local.sh.

export UV_ROOT=
export UV_XILINX_VIVADO=
export XILINX_HLS=
export UV_LICENSE=

# Optional overrides:
# export UVS_HOME=
# export UVD_HOME=
# export UVEC_HOME=
# export HW_SERVER_URL=
# export HW_TARGET=
# export UVHS_UVW_AXI4_TO_DDR4_SRC=/path/to/verified/uvw_axi4_to_ddr4/source
# export UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5=bbd428f1fa2ede1628e11b7ab14d1072

# Optional Hejian PCIe x4 preset used by the enumerable XDMA EP smoke.
# The preferred fpga_diff build entry is:
#   make -C env-scripts/fpga_diff uvhs_hejian_pcie_x4_nutshell_all CPU=nutshell
# Source the script only for interactive environment inspection/overrides.
# It only sets fpga_diff/UVHS flow environment; it does not patch Vivado Tcl.
# source /path/to/env-scripts/fpga_diff/uvhs/hejian_pcie_x4_env.sh
