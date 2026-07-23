#!/usr/bin/env bash
# Print, check, or source the Hejian UVHS PCIe fpga_diff x4 preset.
#
# The defaults mirror the enumerable Hejian XDMA EP x4 loopback configuration:
# F2/HGC7 x4 lanes, endpoint device ID 10ee:9048, BAR0 512 KiB, BAR1 64 KiB.
# They are fpga_diff/UVHS flow-level defaults. This preset intentionally uses
# the checked official XDMA EP x4 DCP instead of patching the Vivado IP Tcl
# sources.
# Existing environment values are kept so accidental overrides remain visible
# to the preflight checks instead of being silently replaced.

_uvhs_hejian_pcie_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
_uvhs_hejian_pcie_root_dir="$(cd -- "$_uvhs_hejian_pcie_script_dir/.." && pwd -P)"
_uvhs_hejian_pcie_project_root="$(cd -- "$_uvhs_hejian_pcie_root_dir/../.." && pwd -P)"

export XDMA_LINK_WIDTH="${XDMA_LINK_WIDTH:-X4}"
export XDMA_ENABLE_PF0_BAR1="${XDMA_ENABLE_PF0_BAR1:-1}"
export XDMA_AXILITE_MASTER_SCALE="${XDMA_AXILITE_MASTER_SCALE:-Kilobytes}"
export XDMA_AXILITE_MASTER_SIZE="${XDMA_AXILITE_MASTER_SIZE:-512}"
export XDMA_EXPECTED_VENDOR="${XDMA_EXPECTED_VENDOR:-0x10ee}"
export XDMA_EXPECTED_DEVICE="${XDMA_EXPECTED_DEVICE:-0x9048}"
export XDMA_EXPECTED_BAR0_SIZE="${XDMA_EXPECTED_BAR0_SIZE:-0x80000}"
export XDMA_EXPECTED_BAR1_SIZE="${XDMA_EXPECTED_BAR1_SIZE:-0x10000}"
export UVHS_XDMA_EP_EXAMPLE_DIR="${UVHS_XDMA_EP_EXAMPLE_DIR:-$_uvhs_hejian_pcie_project_root/uvhs_1ep_test_0417_x4_xdma_loopback}"
export UVHS_XDMA_EP_DEFAULT_DCP_SHA256="${UVHS_XDMA_EP_DEFAULT_DCP_SHA256:-e40002b4ccab73d4d7a1398630f59428add0a64b9f33d284d3789595bb791b32}"
export UVHS_XDMA_EP_DEFAULT_DCP_VIVADO="${UVHS_XDMA_EP_DEFAULT_DCP_VIVADO:-2024.2}"
export UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT="${UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT:-$UVHS_XDMA_EP_EXAMPLE_DIR/script/1B_4F_HGC_assemble.tcl}"
export UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256="${UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256:-0e44f3ced8e5628a6f9b60a36d15194f03f6eddefcf29d0221a8abf140ecb18b}"
export UVHS_ALLOW_DCP_VIVADO_MISMATCH="${UVHS_ALLOW_DCP_VIVADO_MISMATCH:-0}"
if [[ -z "${UVHS_XDMA_EP_DCP:-}" && -s "$UVHS_XDMA_EP_EXAMPLE_DIR/rtl/xdma_ep.dcp" ]]; then
  export UVHS_XDMA_EP_DCP="$UVHS_XDMA_EP_EXAMPLE_DIR/rtl/xdma_ep.dcp"
  export UVHS_XDMA_EP_DCP_SHA256="${UVHS_XDMA_EP_DCP_SHA256:-$UVHS_XDMA_EP_DEFAULT_DCP_SHA256}"
else
  export UVHS_XDMA_EP_DCP="${UVHS_XDMA_EP_DCP:-}"
  export UVHS_XDMA_EP_DCP_SHA256="${UVHS_XDMA_EP_DCP_SHA256:-}"
fi
if [[ -z "${UVHS_BASE_ASSEMBLE_FILE:-}" && -s "$UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT" ]]; then
  export UVHS_BASE_ASSEMBLE_FILE="$UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT"
  export UVHS_BASE_ASSEMBLE_SHA256="${UVHS_BASE_ASSEMBLE_SHA256:-$UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256}"
else
  export UVHS_BASE_ASSEMBLE_FILE="${UVHS_BASE_ASSEMBLE_FILE:-}"
  export UVHS_BASE_ASSEMBLE_SHA256="${UVHS_BASE_ASSEMBLE_SHA256:-}"
fi

export UVHS_DESIGN_NAME="${UVHS_DESIGN_NAME:-VU19P_X4}"
export PLATFORM="${PLATFORM:-U2.2}"
export UVHS_TARGET_BOARD="${UVHS_TARGET_BOARD:-B0}"
export UVHS_TARGET_PACK="${UVHS_TARGET_PACK:-$UVHS_TARGET_BOARD}"
export UVHS_TARGET_FPGA="${UVHS_TARGET_FPGA:-F2}"
export UVHS_TARGET_FPGA_LOWER="${UVHS_TARGET_FPGA_LOWER:-$(printf '%s.%s' "$UVHS_TARGET_PACK" "$UVHS_TARGET_FPGA" | tr '[:upper:]' '[:lower:]')}"
export UVHS_FPGA_COUNT="${UVHS_FPGA_COUNT:-1}"
export UVHS_CPU_CLK_PERIOD_NS="${UVHS_CPU_CLK_PERIOD_NS:-40}"
export UVHS_CPU_DEBUG_CLK="${UVHS_CPU_DEBUG_CLK:-1}"
export UVHS_PNR_STRATEGY="${UVHS_PNR_STRATEGY:-Strategy_uv_high_fanout_explore}"
export UVHS_COMPILE_STRATEGY_NUM="${UVHS_COMPILE_STRATEGY_NUM:-1}"
export UVHS_COMPILE_STRATEGY0="${UVHS_COMPILE_STRATEGY0:-uv_high_fanout_explore}"
export UVHS_FRONTEND_THREADS="${UVHS_FRONTEND_THREADS:-4}"
export UVHS_FRONTEND_PROCESSES="${UVHS_FRONTEND_PROCESSES:-16}"
export UVHS_FPGA_THREADS="${UVHS_FPGA_THREADS:-4}"
export UVHS_FPGA_PROCESSES="${UVHS_FPGA_PROCESSES:-8}"

export UVHS_ASSEMBLE_FILE="${UVHS_ASSEMBLE_FILE:-$_uvhs_hejian_pcie_root_dir/uvhs/assemble_uvhs.tcl}"
export UVHS_ASSIGN_PIN_FILE="${UVHS_ASSIGN_PIN_FILE:-$_uvhs_hejian_pcie_root_dir/uvhs/assign_pin_nutshell_f2.tcl}"

export UVHS_MEM_ARRAY_DC="${UVHS_MEM_ARRAY_DC:-none}"
export UVHS_MEM_ARRAY_CONNECTOR="${UVHS_MEM_ARRAY_CONNECTOR:-b0.F2_FMC1}"
export UVHS_AUX_DDR_DC="${UVHS_AUX_DDR_DC:-none}"

export XDMA_BDF="${XDMA_BDF:-0000:01:00.0}"

uvhs_hejian_pcie_print_env() {
  for name in \
    XDMA_LINK_WIDTH \
    XDMA_ENABLE_PF0_BAR1 \
    XDMA_AXILITE_MASTER_SCALE \
    XDMA_AXILITE_MASTER_SIZE \
    XDMA_EXPECTED_VENDOR \
    XDMA_EXPECTED_DEVICE \
    XDMA_EXPECTED_BAR0_SIZE \
    XDMA_EXPECTED_BAR1_SIZE \
    UVHS_XDMA_EP_EXAMPLE_DIR \
    UVHS_XDMA_EP_DCP \
    UVHS_XDMA_EP_DCP_SHA256 \
    UVHS_XDMA_EP_DEFAULT_DCP_VIVADO \
    UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT \
    UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256 \
    UVHS_BASE_ASSEMBLE_FILE \
    UVHS_BASE_ASSEMBLE_SHA256 \
    UVHS_ALLOW_DCP_VIVADO_MISMATCH \
    UVHS_DESIGN_NAME \
    PLATFORM \
    UVHS_TARGET_PACK \
    UVHS_TARGET_FPGA \
    UVHS_TARGET_FPGA_LOWER \
    UVHS_FPGA_COUNT \
    UVHS_CPU_CLK_PERIOD_NS \
    UVHS_CPU_DEBUG_CLK \
    UVHS_PNR_STRATEGY \
    UVHS_COMPILE_STRATEGY_NUM \
    UVHS_COMPILE_STRATEGY0 \
    UVHS_FRONTEND_THREADS \
    UVHS_FRONTEND_PROCESSES \
    UVHS_FPGA_THREADS \
    UVHS_FPGA_PROCESSES \
    UVHS_ASSEMBLE_FILE \
    UVHS_ASSIGN_PIN_FILE \
    UVHS_MEM_ARRAY_DC \
    UVHS_MEM_ARRAY_CONNECTOR \
    UVHS_AUX_DDR_DC \
    XDMA_BDF; do
    printf '%s=%q\n' "$name" "${!name}"
  done
}

uvhs_hejian_pcie_check_env() {
  local failures=0

  check_equal() {
    local name=$1
    local expected=$2
    local actual=${!name}
    if [[ "$actual" == "$expected" ]]; then
      printf 'OK: %s=%s\n' "$name" "$actual"
    else
      printf 'FAIL: %s=%s, expected %s\n' "$name" "$actual" "$expected" >&2
      failures=$((failures + 1))
    fi
  }

  check_file() {
    local label=$1
    local path=$2
    if [[ -f "$path" ]]; then
      printf 'OK: %s: %s\n' "$label" "$path"
    else
      printf 'FAIL: missing %s: %s\n' "$label" "$path" >&2
      failures=$((failures + 1))
    fi
  }

  check_grep() {
    local label=$1
    local pattern=$2
    local path=$3
    if [[ -f "$path" ]] && grep -Eq "$pattern" "$path"; then
      printf 'OK: %s\n' "$label"
    else
      printf 'FAIL: %s\n' "$label" >&2
      failures=$((failures + 1))
    fi
  }

  dcp_vivado_version() {
    local dcp=$1
    command -v unzip >/dev/null 2>&1 || return 0
    unzip -p "$dcp" dcp.xml 2>/dev/null \
      | sed -n 's/.*<PRODUCT Name="Vivado v\([^ "]*\).*/\1/p' \
      | head -n 1
  }

  active_vivado_version() {
    local vivado_bin=
    if [[ -n "${UV_XILINX_VIVADO:-}" ]]; then
      vivado_bin="$UV_XILINX_VIVADO/bin/vivado"
    elif [[ -n "${VIVADO_HOME:-}" ]]; then
      vivado_bin="$VIVADO_HOME/bin/vivado"
    elif command -v vivado >/dev/null 2>&1; then
      vivado_bin=$(command -v vivado)
    fi
    [[ -n "$vivado_bin" && -x "$vivado_bin" ]] || return 0
    "$vivado_bin" -version 2>/dev/null \
      | sed -n 's/^Vivado v\([^ ]*\).*/\1/p' \
      | head -n 1
  }

  check_equal XDMA_LINK_WIDTH X4
  check_equal XDMA_ENABLE_PF0_BAR1 1
  check_equal XDMA_AXILITE_MASTER_SCALE Kilobytes
  check_equal XDMA_AXILITE_MASTER_SIZE 512
  check_equal XDMA_EXPECTED_VENDOR 0x10ee
  check_equal XDMA_EXPECTED_DEVICE 0x9048
  check_equal XDMA_EXPECTED_BAR0_SIZE 0x80000
  check_equal XDMA_EXPECTED_BAR1_SIZE 0x10000
  if [[ -n "$UVHS_XDMA_EP_DCP" ]]; then
    check_file "verified Hejian XDMA EP DCP" "$UVHS_XDMA_EP_DCP"
    if [[ -s "$UVHS_XDMA_EP_DCP" && -n "$UVHS_XDMA_EP_DCP_SHA256" ]]; then
      actual_sha256=$(sha256sum "$UVHS_XDMA_EP_DCP" | awk '{print $1}')
      if [[ "$actual_sha256" == "$UVHS_XDMA_EP_DCP_SHA256" ]]; then
        printf 'OK: UVHS_XDMA_EP_DCP sha256=%s\n' "$actual_sha256"
      else
        printf 'FAIL: UVHS_XDMA_EP_DCP sha256=%s, expected %s\n' "$actual_sha256" "$UVHS_XDMA_EP_DCP_SHA256" >&2
        failures=$((failures + 1))
      fi
    fi
    dcp_vivado=$(dcp_vivado_version "$UVHS_XDMA_EP_DCP")
    if [[ -n "$dcp_vivado" ]]; then
      printf 'OK: UVHS_XDMA_EP_DCP Vivado version=%s\n' "$dcp_vivado"
      if [[ "$UVHS_XDMA_EP_DCP" == "$UVHS_XDMA_EP_EXAMPLE_DIR/rtl/xdma_ep.dcp" \
        && "$dcp_vivado" != "$UVHS_XDMA_EP_DEFAULT_DCP_VIVADO" ]]; then
        printf 'FAIL: default XDMA DCP Vivado version=%s, expected %s\n' "$dcp_vivado" "$UVHS_XDMA_EP_DEFAULT_DCP_VIVADO" >&2
        failures=$((failures + 1))
      fi
      uvhs_vivado=$(active_vivado_version)
      if [[ -n "$uvhs_vivado" ]]; then
        if [[ "$uvhs_vivado" == "$dcp_vivado" ]]; then
          printf 'OK: active Vivado version matches XDMA DCP: %s\n' "$uvhs_vivado"
        elif [[ "$UVHS_ALLOW_DCP_VIVADO_MISMATCH" == "1" ]]; then
          printf 'WARN: active Vivado version=%s, XDMA DCP version=%s; mismatch allowed by UVHS_ALLOW_DCP_VIVADO_MISMATCH=1\n' "$uvhs_vivado" "$dcp_vivado"
        else
          printf 'FAIL: active Vivado version=%s cannot consume XDMA DCP version=%s; regenerate xdma_ep.dcp with Vivado %s or run UVHS with Vivado %s\n' "$uvhs_vivado" "$dcp_vivado" "$uvhs_vivado" "$dcp_vivado" >&2
          failures=$((failures + 1))
        fi
      else
        printf 'INFO: active Vivado version unavailable; skip XDMA DCP/Vivado compatibility check\n'
      fi
    else
      printf 'INFO: unable to read Vivado version from UVHS_XDMA_EP_DCP; skip compatibility check\n'
    fi
  else
    printf 'FAIL: UVHS_XDMA_EP_DCP is unset; copy or point to the verified XDMA x4 loopback xdma_ep.dcp\n' >&2
    failures=$((failures + 1))
  fi
  if [[ -n "$UVHS_BASE_ASSEMBLE_FILE" ]]; then
    check_file "verified Hejian x4 base assemble" "$UVHS_BASE_ASSEMBLE_FILE"
    if [[ -s "$UVHS_BASE_ASSEMBLE_FILE" && -n "$UVHS_BASE_ASSEMBLE_SHA256" ]]; then
      actual_sha256=$(sha256sum "$UVHS_BASE_ASSEMBLE_FILE" | awk '{print $1}')
      if [[ "$actual_sha256" == "$UVHS_BASE_ASSEMBLE_SHA256" ]]; then
        printf 'OK: UVHS_BASE_ASSEMBLE_FILE sha256=%s\n' "$actual_sha256"
      else
        printf 'FAIL: UVHS_BASE_ASSEMBLE_FILE sha256=%s, expected %s\n' "$actual_sha256" "$UVHS_BASE_ASSEMBLE_SHA256" >&2
        failures=$((failures + 1))
      fi
    fi
    if [[ "$UVHS_BASE_ASSEMBLE_FILE" == "$UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT" ]]; then
      check_grep "loopback x4 base leaves F2_HGC7 local cable disconnected" '^#config_hw -connect_fpga \{b0[.]F2_HGC7 b0[.]F3_HGC7\}' "$UVHS_BASE_ASSEMBLE_FILE"
      check_grep "loopback x4 base leaves F2_HGC6 local cable disconnected" '^#config_hw -connect_fpga \{b0[.]F2_HGC6 b0[.]F3_HGC6\}' "$UVHS_BASE_ASSEMBLE_FILE"
    fi
  else
    printf 'FAIL: UVHS_BASE_ASSEMBLE_FILE is unset; point to the checked loopback x4 1B_4F_HGC_assemble.tcl\n' >&2
    failures=$((failures + 1))
  fi
  check_equal UVHS_DESIGN_NAME VU19P_X4
  check_equal PLATFORM U2.2
  check_equal UVHS_TARGET_PACK B0
  check_equal UVHS_TARGET_FPGA F2
  check_equal UVHS_TARGET_FPGA_LOWER b0.f2
  check_equal UVHS_FPGA_COUNT 1
  check_equal UVHS_CPU_CLK_PERIOD_NS 40
  check_equal UVHS_CPU_DEBUG_CLK 1
  check_equal UVHS_PNR_STRATEGY Strategy_uv_high_fanout_explore
  check_equal UVHS_COMPILE_STRATEGY_NUM 1
  check_equal UVHS_COMPILE_STRATEGY0 uv_high_fanout_explore
  check_equal UVHS_FRONTEND_THREADS 4
  check_equal UVHS_FRONTEND_PROCESSES 16
  check_equal UVHS_FPGA_THREADS 4
  check_equal UVHS_FPGA_PROCESSES 8
  check_equal UVHS_MEM_ARRAY_DC none
  check_equal UVHS_AUX_DDR_DC none
  check_equal XDMA_BDF 0000:01:00.0

  check_file "UVHS assembly overlay" "$UVHS_ASSEMBLE_FILE"
  check_file "NutShell F2 pin file" "$UVHS_ASSIGN_PIN_FILE"
  check_file "public Vivado xdma_ep Tcl source" "$_uvhs_hejian_pcie_root_dir/src/tcl/common/xdma_ep.tcl"
  if command -v git >/dev/null 2>&1 \
    && git -C "$_uvhs_hejian_pcie_root_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$_uvhs_hejian_pcie_root_dir" diff --quiet -- src/tcl/common/xdma_ep.tcl \
      && git -C "$_uvhs_hejian_pcie_root_dir" diff --cached --quiet -- src/tcl/common/xdma_ep.tcl; then
      printf 'OK: public Vivado xdma_ep.tcl has no local diff\n'
    else
      printf 'FAIL: public Vivado xdma_ep.tcl has local diff; keep Hejian x4 alignment in fpga_diff/uvhs scripts and UVHS_XDMA_EP_DCP\n' >&2
      failures=$((failures + 1))
    fi
  else
    printf 'INFO: skip git diff check for public Vivado xdma_ep.tcl\n'
  fi
  check_grep "pin file gates lanes by XDMA_LINK_WIDTH" 'XDMA_LINK_WIDTH' "$UVHS_ASSIGN_PIN_FILE"
  check_grep "pin file uses official HGC7 x4 lane group" 'b0[.]F2_HGC7' "$UVHS_ASSIGN_PIN_FILE"
  check_grep "fpga_diff UVHS Makefile defaults BAR1 on" 'XDMA_ENABLE_PF0_BAR1[[:space:]]+[?]?=[[:space:]]+1' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS Makefile defaults BAR0 512 KiB" 'XDMA_AXILITE_MASTER_SIZE[[:space:]]+[?]?=[[:space:]]+512' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS Makefile records the verified xdma_ep.dcp" 'UVHS_XDMA_EP_DEFAULT_DCP' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS Makefile has explicit Hejian x4 UVHS environment" 'UVHS_HEJIAN_FLOW_ENV.*XDMA_LINK_WIDTH=.*UVHS_DESIGN_NAME=.*PLATFORM=' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS frontend passes Hejian x4 environment to uv_shell" 'UVHS_HEJIAN_FLOW_ENV.*UVHS_FILELIST=.*uv_shell.*UVHS_FRONTEND_TCL' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS backend passes Hejian x4 environment to uv_shell" 'UVHS_HEJIAN_FLOW_ENV.*UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP=.*uv_shell.*backend_run[.]tcl' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "Hejian x4 target auto-syncs the verified xdma_ep.dcp" '^uvhs_hejian_pcie_x4_nutshell_all:[[:space:]]+UVHS_XDMA_EP_DCP[[:space:]]*=[[:space:]]*[$][(]UVHS_XDMA_EP_DEFAULT_DCP[)]' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "Hejian x4 target uses the verified official base assemble" '^uvhs_hejian_pcie_x4_nutshell_all:[[:space:]]+UVHS_BASE_ASSEMBLE_FILE[[:space:]]*=[[:space:]]*[$][(]UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT[)]' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "Hejian x4 target pins official U2.2 platform" '^uvhs_hejian_pcie_x4_nutshell_all:[[:space:]]+PLATFORM[[:space:]]*=[[:space:]]*U2[.]2' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS Makefile skips xdma_ep export when DCP is selected" 'UVHS_EFFECTIVE_SKIP_VIVADO_EXPORT.*UVHS_XDMA_EP_DCP' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS Makefile passes base assemble into UVHS scripts" 'UVHS_HEJIAN_FLOW_ENV.*UVHS_BASE_ASSEMBLE_FILE=' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS Makefile defaults official PnR strategy" 'UVHS_PNR_STRATEGY[[:space:]]+[?]?=[[:space:]]+Strategy_uv_high_fanout_explore' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS Makefile has Hejian x4 NutShell build target" '^uvhs_hejian_pcie_x4_nutshell_all:' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS x4 target uses 25 MHz NutShell CPU clock" '^uvhs_hejian_pcie_x4_nutshell_all:[[:space:]]+UVHS_CPU_CLK_PERIOD_NS[[:space:]]*=[[:space:]]*40' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS x4 target selects the 25 MHz clock input" '^uvhs_hejian_pcie_x4_nutshell_all:[[:space:]]+UVHS_CPU_DEBUG_CLK[[:space:]]*=[[:space:]]*1' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS x4 target disables memory array DC" '^uvhs_hejian_pcie_x4_nutshell_all:[[:space:]]+UVHS_MEM_ARRAY_DC[[:space:]]*=[[:space:]]*none' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff UVHS x4 target disables auxiliary DDR DC" '^uvhs_hejian_pcie_x4_nutshell_all:[[:space:]]+UVHS_AUX_DDR_DC[[:space:]]*=[[:space:]]*none' "$_uvhs_hejian_pcie_root_dir/uvhs/Makefile"
  check_grep "fpga_diff backend defaults official compile strategy" 'uv_high_fanout_explore' "$_uvhs_hejian_pcie_root_dir/uvhs/backend_run.tcl"

  if [[ "$failures" -ne 0 ]]; then
    printf 'FAIL: %d Hejian PCIe x4 preset check(s) failed\n' "$failures" >&2
    return 1
  fi
  printf 'OK: Hejian PCIe x4 preset checks passed\n'
}

_uvhs_hejian_pcie_executed=0
_uvhs_hejian_pcie_status=0
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  _uvhs_hejian_pcie_executed=1
  case "${1:-print}" in
    print|env)
      uvhs_hejian_pcie_print_env
      ;;
    check|preflight)
      uvhs_hejian_pcie_check_env || _uvhs_hejian_pcie_status=$?
      ;;
    -h|--help|help)
      cat <<'USAGE'
Usage:
  uvhs/hejian_pcie_x4_env.sh [print|check]

Preferred fpga_diff build entry:
  make -C env-scripts/fpga_diff uvhs_hejian_pcie_x4_nutshell_all CORE_DIR=/path/to/NutShell

Source it only when interactive shell overrides are useful:
  source env-scripts/fpga_diff/uvhs/hejian_pcie_x4_env.sh

Execute it to print or validate the current effective environment:
  env-scripts/fpga_diff/uvhs/hejian_pcie_x4_env.sh print
  env-scripts/fpga_diff/uvhs/hejian_pcie_x4_env.sh check
USAGE
      ;;
    *)
      printf 'ERROR: unknown mode: %s\n' "$1" >&2
      _uvhs_hejian_pcie_status=2
      ;;
  esac
fi

unset -f uvhs_hejian_pcie_print_env uvhs_hejian_pcie_check_env dcp_vivado_version active_vivado_version 2>/dev/null || true
unset _uvhs_hejian_pcie_script_dir _uvhs_hejian_pcie_root_dir _uvhs_hejian_pcie_project_root
if [[ "$_uvhs_hejian_pcie_executed" == "1" ]]; then
  exit "$_uvhs_hejian_pcie_status"
fi
unset _uvhs_hejian_pcie_executed _uvhs_hejian_pcie_status
