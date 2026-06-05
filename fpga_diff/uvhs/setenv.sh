#!/usr/bin/env bash

# Generic UVHS environment entry point.
#
# Put machine-specific paths, licenses, and host settings in
#   uvhs/setenv.local.sh
# or point UVHS_LOCAL_ENV at another local file before sourcing this script.

if [ -n "${BASH_SOURCE:-}" ]; then
  _uvhs_source="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION:-}" ]; then
  _uvhs_source="${(%):-%x}"
else
  _uvhs_source="$0"
fi

_uvhs_script_dir="$(cd "$(dirname "$_uvhs_source")" && pwd)"
_uvhs_repo_dir="$(cd "$_uvhs_script_dir/.." && pwd)"
_uvhs_local_env="${UVHS_LOCAL_ENV:-$_uvhs_script_dir/setenv.local.sh}"

if [ -f "$_uvhs_local_env" ]; then
  # shellcheck source=/dev/null
  source "$_uvhs_local_env"
fi

if [ -z "${UVHS_UVW_AXI4_TO_DDR4_SRC:-}" ]; then
  for _uvhs_ddr_ip_src in \
    "$_uvhs_repo_dir/uvhs_nutshell-uvhs-ddr-uvw-ip-bind" \
    "$_uvhs_repo_dir/uvhs_uvw_axi4_to_ddr4_remote" \
    "$_uvhs_repo_dir/uvhs_nutshell-uvhs-ddr-uvw-ip"; do
    if [ -s "$_uvhs_ddr_ip_src/rtl/soc/uvw_axi4_to_ddr4.dcp" ]; then
      export UVHS_UVW_AXI4_TO_DDR4_SRC="$_uvhs_ddr_ip_src"
      break
    fi
  done
fi

export UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5="${UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5:-bbd428f1fa2ede1628e11b7ab14d1072}"

export PS1="${PS1:-\[\033[01;33m\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ }"

_uvhs_prepend_path() {
  [ -n "$1" ] || return 0
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

_uvhs_prepend_ld_path() {
  [ -n "$1" ] || return 0
  case ":${LD_LIBRARY_PATH:-}:" in
    *":$1:"*) ;;
    *) export LD_LIBRARY_PATH="$1:${LD_LIBRARY_PATH:-}" ;;
  esac
}

if [ -n "${UV_ROOT:-}" ]; then
  _uvhs_prepend_path "$UV_ROOT/bin"
  _uvhs_prepend_path "$UV_ROOT/lib/venv3.8/bin"
  _uvhs_prepend_path "$UV_ROOT/lib/gcc10.3/bin"

  export UVS_HOME="${UVS_HOME:-$UV_ROOT/uvd/uvs}"
  export UVD_HOME="${UVD_HOME:-$UV_ROOT/uvd}"
  _uvhs_prepend_path "$UVS_HOME/bin"
  _uvhs_prepend_path "$UVD_HOME/bin"

  export UVEC_FLOW="${UVEC_FLOW:-1}"
  export UVEC_HOME="${UVEC_HOME:-$UV_ROOT/uvec}"
  export UV_ECIR_HOME="${UV_ECIR_HOME:-$UVEC_HOME}"
  _uvhs_prepend_path "$UVEC_HOME/bin"
fi

if [ -n "${UV_XILINX_VIVADO:-}" ]; then
  export VIVADO_HOME="$UV_XILINX_VIVADO"
  export XILINX_VIVADO="$UV_XILINX_VIVADO"
fi

if [ -n "${VIVADO_HOME:-}" ]; then
  _uvhs_prepend_path "$VIVADO_HOME/bin"
fi

if [ -n "${XILINX_HLS:-}" ]; then
  _uvhs_prepend_path "$XILINX_HLS/bin"
fi

_uvhs_prepend_path "${FIRTOOL_TOOLS:-}"
_uvhs_prepend_path "${RISCV_TOOLS:-}"
_uvhs_prepend_path "${MC_OBJTOOLS:-}"

if [ -d "$_uvhs_script_dir/make_compat" ]; then
  _uvhs_prepend_path "$_uvhs_script_dir/make_compat"
fi

if [ -d "$_uvhs_script_dir/libffi_compat" ]; then
  _uvhs_prepend_ld_path "$_uvhs_script_dir/libffi_compat"
fi

alias uvec='${UVEC_HOME:?UVEC_HOME is not set}/bin/uvec -emu'
alias gdiff='vimdiff'
alias g='vim'
alias ll='ls -alhF --color=auto'
alias ls='ls -aF'

cd ()
{
  builtin cd "$@" && ls -alhF --color=auto
}

unset _uvhs_source _uvhs_script_dir _uvhs_repo_dir _uvhs_local_env _uvhs_ddr_ip_src
