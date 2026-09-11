#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 wait-module MODULE_MAKEFILE | wait-vivado VIVADO_DIR | patch-pnr PNR_DIR | patch-signoff SIGNOFF_DIR | clear-stale-lock WORKSPACE" >&2
  exit 2
}

clear_stale_lock() {
  local workspace=$1 lock pid
  lock=$(find "$workspace" -maxdepth 1 -type f -name '.lock_*' -print -quit 2>/dev/null || true)
  [[ -z "$lock" ]] && return 0
  pid=${lock##*.lock_}
  if kill -0 "$pid" 2>/dev/null; then
    echo "ERROR: UVHS workspace lock is held by live PID $pid: $lock" >&2
    return 1
  fi
  rm -f -- "$lock"
  echo "INFO: removed stale UVHS workspace lock $lock"
}

patch_makefile() {
  local makefile=$1
  local temporary before after marker

  # UVHS writes Vivado worker makefiles in-place.  Never run sed -i on a
  # file while UVHS is still appending its recipes: doing so can leave a
  # truncated file (for example, an isolated `synth:` target).  Transform a
  # snapshot and replace it only if the source did not change meanwhile.
  # Require the complete worker skeleton and two identical snapshots.  This
  # avoids racing UVHS while it appends `clean:`/recipe lines after creating
  # the file and before dispatching `make all`.
  grep -Eq '^all:' "$makefile" || return 0
  # Uvsyn's module.makefile has only the `all` recipe and invokes uv_shell
  # through `until sh -c`; Vivado worker makefiles normally also contain a
  # clean target and a vivado command.  Accept both forms so the module
  # dispatcher is switched to bash before it starts workers.
  if ! grep -Eq 'until[[:space:]]+sh[[:space:]]+-c' "$makefile"; then
    grep -Eq '^clean:' "$makefile" || return 0
    grep -Eq '(^|[[:space:]])(\$\{VIVADO_HOME\}/)?bin/vivado([[:space:]]|$)|(^|[[:space:]])vivado([[:space:]]|$)' "$makefile" || return 0
  fi
  marker="${makefile}.fpga-diff-patched"
  # The polling helper runs throughout frontend synthesis.  Avoid replacing
  # an already transformed Makefile on every 50 ms pass; repeated inode
  # replacement can itself race a worker that is invoking `make`.
  [[ -e $marker ]] && return 0
  before=$(stat -c '%s:%y:%i' "$makefile") || return 1
  sleep 0.10
  after=$(stat -c '%s:%y:%i' "$makefile") || return 1
  [[ $before == "$after" ]] || return 0
  temporary="${makefile}.fpga-diff.$$"

  cp -p -- "$makefile" "$temporary" || return 1
  sed -E -i \
    -e 's/^MAX_RETRIES=[0-9]+$/MAX_RETRIES=3/' \
    -e 's/[[:space:]]>&[[:space:]]*([^[:space:]]+)/ >\1 2>\&1/g' \
    -e 's/until[[:space:]]+sh[[:space:]]+-c/until bash -c/' \
    -e 's#(^|[[:space:]&;@])(/[^[:space:]]*/bin/uv_shell)([[:space:]])#\1bash \2\3#g' \
    -e 's#(^|[[:space:]&;@])(uv_shell)([[:space:]])#\1bash \2\3#g' \
    -e 's#(^|[[:space:]&;(@])(bash[[:space:]]+)+(/[^[:space:]]*/bin/uv_shell)#\1bash \3#g' \
    -e 's#(^|[[:space:]&;(@])(bash[[:space:]]+)+(uv_shell)#\1bash \3#g' \
    "$temporary"
  after=$(stat -c '%s:%y:%i' "$makefile") || {
    rm -f -- "$temporary"
    return 1
  }
  if [[ $before == "$after" ]]; then
    chmod --reference="$makefile" "$temporary"
    mv -f -- "$temporary" "$makefile"
    : > "$marker"
  else
    # UVHS changed the file while we were transforming the snapshot.  Leave
    # its newer contents untouched; a later polling pass will retry.
    rm -f -- "$temporary"
  fi
}

patch_pool_command() {
  local makefile=$1 helper_dir
  helper_dir=$(cd "$(dirname "$0")" && pwd)
  sed -E -i "s#(^|[[:space:];&])python([[:space:]]+hw\.dat/Compile/PnR/[^[:space:]]*process_pool_\.py)#\\1${helper_dir}/python\\2#g" "$makefile"
}

patch_signoff_worker() {
  local worker=$1
  local helper=$2
  local marker='# fpga_diff UVHS signoff compatibility'
  local temporary="${worker}.fpga-diff.$$"

  if grep -Fxq "$marker" "$worker"; then
    return
  fi
  if ! awk -v marker="$marker" -v helper="$helper" '
    $0 == "if {[file exists $dumpPath/cstr.tcl]} {" {
      print marker
      print "exec bash {" helper "} patch-signoff $dumpPath"
      inserted++
    }
    { print }
    END { if (inserted != 1) exit 1 }
  ' "$worker" > "$temporary"; then
    rm -f "$temporary"
    echo "ERROR: unsupported generated signoff worker: $worker" >&2
    exit 1
  fi
  chmod --reference="$worker" "$temporary"
  mv "$temporary" "$worker"
}

patch_signoff_constraints() {
  local signoff_dir=$1
  local udc="$signoff_dir/cstr/FPGA_filtered.udc"
  local clock_map="$signoff_dir/cstr.tcl"
  local alias_count
  local ddr_map_count
  local ddr_master_clock
  local identity_map_count
  local master_clock_count
  local reset_count
  local multiplier_count_before
  local multiplier_count_after

  [[ -f $udc && -f $clock_map ]] || {
    echo "ERROR: signoff constraints not found under $signoff_dir" >&2
    exit 1
  }

  alias_count=$(grep -c '^create_generated_clock -name DDR_UI_CLK ' "$udc" || true)
  ddr_map_count=$(grep -oE '\{DDR_UI_CLK [^}]+\}' "$clock_map" | wc -l || true)
  identity_map_count=$(grep -cF '{DDR_UI_CLK DDR_UI_CLK}' "$clock_map" || true)

  ((alias_count <= 1 && ddr_map_count <= 1 && identity_map_count <= 1)) || {
    echo "ERROR: ambiguous DDR signoff clock constraints in $signoff_dir" >&2
    exit 1
  }
  if ((alias_count == 1)); then
    ddr_master_clock=$(sed -nE '
      /^create_generated_clock -name DDR_UI_CLK .*\/ddr4ip_ddr4_user_clk]$/ {
        s/.* -master_clock \[get_clocks ([^]]+)\] \[get_pins .*/\1/p
      }
    ' "$udc")
    [[ $ddr_master_clock =~ ^[[:alnum:]_.:/-]+$ ]] || {
      echo "ERROR: unsupported DDR signoff clock alias in $udc" >&2
      exit 1
    }
    master_clock_count=$(grep -cF \
      "create_generated_clock -name $ddr_master_clock " "$udc" || true)
    ((identity_map_count == 1 && ddr_map_count == 1 &&
      master_clock_count == 1)) || {
      echo "ERROR: DDR signoff clock mapping has no unique MIG MMCM clock" >&2
      exit 1
    }
    sed -i "s/{DDR_UI_CLK DDR_UI_CLK}/{DDR_UI_CLK $ddr_master_clock}/" \
      "$clock_map"
    sed -i '/^create_generated_clock -name DDR_UI_CLK .*\/ddr4ip_ddr4_user_clk]$/d' \
      "$udc"
    grep -Fq "{DDR_UI_CLK $ddr_master_clock}" "$clock_map" || {
      echo "ERROR: failed to map DDR signoff clock to $ddr_master_clock" >&2
      exit 1
    }
  fi

  reset_count=$(awk '
    /^set_multicycle_path / && / -reset_path / { count++ }
    END { print count + 0 }
  ' "$udc")
  multiplier_count_before=$(grep -c ' -path_multiplier ' "$udc" || true)
  if ((reset_count > 0)); then
    sed -E -i '
      /^set_multicycle_path .* -reset_path .* [0-9]+$/ {
        s/ -reset_path//
        s/ ([0-9]+)$/ -path_multiplier \1/
      }
    ' "$udc"
  fi
  multiplier_count_after=$(grep -c ' -path_multiplier ' "$udc" || true)

  ! grep -q '^create_generated_clock -name DDR_UI_CLK ' "$udc" || {
    echo "ERROR: failed to remove DDR signoff clock alias" >&2
    exit 1
  }
  ! grep -q '^set_multicycle_path .* -reset_path ' "$udc" || {
    echo "ERROR: failed to translate Vivado reset-path constraints" >&2
    exit 1
  }
  ((multiplier_count_after == multiplier_count_before + reset_count)) || {
    echo "ERROR: incomplete multicycle-path translation in $udc" >&2
    exit 1
  }
  echo "INFO: normalized UVHS signoff constraints: DDR aliases=$alias_count, reset paths=$reset_count"
}

wait_for_module_makefile() {
  local module_makefile=$1
  local uv_shell_bin="${UV_ROOT:-}/bin/uv_shell"
  local recipe_template
  recipe_template=$(cd "$(dirname "$0")" && pwd)/module.makefile.template
  local empty_attempts=0

  for ((attempt = 0; attempt < 12000; attempt++)); do
    # UVHS creates the module makefile atomically in two phases.  Seeing the
    # path is not sufficient: an empty placeholder makes every worker fail
    # with “No rule to make target all”.
    if [[ -s $module_makefile ]] && grep -Eq '(^|[[:space:]])all([[:space:]]*:|[[:space:]])' "$module_makefile"; then
      patch_makefile "$module_makefile"
      # The generated recipe invokes `bash -c` and runs uv_shell inside that
      # command string; checking for a literal `bash /path/uv_shell` is
      # incorrect and rejected valid patched recipes before any worker ran.
      grep -Eq 'until[[:space:]]+bash[[:space:]]+-c' "$module_makefile" || {
        echo "ERROR: failed to select Bash for $module_makefile" >&2
        exit 1
      }
      echo "INFO: selected Bash for UVHS frontend workers: $module_makefile"
      return
    fi
    # UVHS 2506p4 can leave an empty placeholder here when block synthesis is
    # enabled for a large design.  The dispatcher starts workers as soon as
    # the path exists, so they otherwise all fail with "No rule to make target
    # all".  After a short grace period, install the same module recipe used
    # by working UVHS releases.  Use an atomic replace and only do this while
    # the file is still empty; a real generated recipe is never overwritten.
    if [[ -f $module_makefile && ! -s $module_makefile ]]; then
      ((empty_attempts += 1))
      if ((empty_attempts == 20)); then
        [[ -x $uv_shell_bin ]] || {
          echo "ERROR: UV_ROOT/bin/uv_shell is not executable; cannot seed $module_makefile" >&2
          exit 1
        }
        [[ -s $recipe_template ]] || {
          echo "ERROR: compatible module.makefile template missing: $recipe_template" >&2
          exit 1
        }
        local temporary="${module_makefile}.fpga-diff.$$"
        cp -f -- "$recipe_template" "$temporary"
        sed -i "s#@UVHS_UV_SHELL@#${uv_shell_bin}#g" "$temporary"
        chmod 755 "$temporary"
        if [[ ! -s $module_makefile ]]; then
          mv -f -- "$temporary" "$module_makefile"
          echo "WARN: UVHS emitted an empty module.makefile; seeded compatible recipe at $module_makefile" >&2
        else
          rm -f -- "$temporary"
        fi
      fi
    else
      empty_attempts=0
    fi
    sleep 0.05
  done
  echo "ERROR: timed out waiting for $module_makefile" >&2
  exit 1
}

wait_for_vivado_makefiles() {
  local rundir=$1
  for ((attempt = 0; attempt < 144000; attempt++)); do
    if [[ -d $rundir ]]; then
      while IFS= read -r -d '' makefile; do
        # A Vivado worker Makefile is emitted in-place.  Only touch it after
        # the actual Vivado recipe is present; an intermediate file may have
        # just `synth:` and patching that placeholder makes the worker report
        # success without producing a DCP.
        if grep -Eq '(^|[[:space:]])(\$\{VIVADO_HOME\}/)?bin/vivado([[:space:]]|$)' "$makefile" ||
           grep -Eq '(^|[[:space:]])vivado([[:space:]]|$)' "$makefile"; then
          patch_makefile "$makefile"
        fi
      done < <(find "$rundir" -type f -name Makefile -print0 2>/dev/null)
    fi
    sleep 0.05
  done
}

patch_pnr_scripts() {
  local pnr_dir=$1
  local helper
  local wrapper_count=0
  local makefile_count=0
  local worker_count=0

  helper=$(realpath "$0")
  export LD_LIBRARY_PATH="/tmp/fpga-diff-lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

  [[ -d $pnr_dir ]] || {
    echo "ERROR: PnR script directory not found: $pnr_dir" >&2
    exit 1
  }
  while IFS= read -r -d '' wrapper; do
    sed -i '1s|^#!/bin/sh$|#!/bin/bash|' "$wrapper"
    head -n 1 "$wrapper" | grep -Fxq '#!/bin/bash' || {
      echo "ERROR: unsupported generated wrapper shell: $wrapper" >&2
      exit 1
    }
    chmod 755 "$wrapper"
    ((wrapper_count += 1))
  done < <(find "$pnr_dir" -type f -name uv_vivado_wrapper.sh -print0)
  while IFS= read -r -d '' makefile; do
    patch_makefile "$makefile"
    patch_pool_command "$makefile"
    ((makefile_count += 1))
  done < <(find "$pnr_dir" -type f -name Makefile -print0)
  # UVHS exports its bundled PCRE2 libraries while supervising workers.  A
  # host /usr/bin/grep inherited by run.sh then fails at worker teardown with
  # an unresolved pcre2_set_compile_extra_options_8 symbol.  The diagnostic
  # dmesg pipeline is best-effort already, so run it with the host library
  # search path isolated from UVHS.
  while IFS= read -r -d '' runner; do
    sed -E -i \
      's#(^|\|[[:space:]]*)grep #\1env -u LD_LIBRARY_PATH -u LD_PRELOAD /usr/bin/grep #g' \
      "$runner"
  done < <(find "$pnr_dir" -type f -name run.sh -print0)
  while IFS= read -r -d '' worker; do
    patch_signoff_worker "$worker" "$helper"
    ((worker_count += 1))
  done < <(find "$pnr_dir" -type f -name signoff_worker.tcl -print0)

  ((wrapper_count > 0)) || {
    echo "ERROR: no generated Vivado wrapper found under $pnr_dir" >&2
    exit 1
  }
  ((makefile_count > 0)) || {
    echo "ERROR: no generated PnR Makefile found under $pnr_dir" >&2
    exit 1
  }
  ((worker_count > 0)) || {
    echo "ERROR: no generated signoff worker found under $pnr_dir" >&2
    exit 1
  }
  echo "INFO: selected Bash in $wrapper_count wrappers and $makefile_count PnR Makefiles; patched $worker_count signoff workers"
}

[[ $# -eq 2 ]] || usage
case $1 in
  clear-stale-lock) clear_stale_lock "$2" ;;
  wait-module) wait_for_module_makefile "$2" ;;
  wait-vivado) wait_for_vivado_makefiles "$2" ;;
  patch-pnr) patch_pnr_scripts "$2" ;;
  patch-signoff) patch_signoff_constraints "$2" ;;
  *) usage ;;
esac
