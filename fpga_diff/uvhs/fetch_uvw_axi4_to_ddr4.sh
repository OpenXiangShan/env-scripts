#!/usr/bin/env bash
set -euo pipefail

remote_host=${1:?remote host is required}
remote_roots=${2:?remote root list is required}
out_dir=${3:?output directory is required}

mkdir -p "$out_dir/rtl/soc" "$out_dir/script"

copy_exact() {
    local description=$1
    local dst=$2
    shift 2

    local root
    local rel
    local remote_path

    for root in $remote_roots; do
        for rel in "$@"; do
            remote_path="$root/$rel"
            if ssh "$remote_host" "test -s '$remote_path'" 2>/dev/null; then
                scp "$remote_host:$remote_path" "$dst"
                echo "INFO: fetched $description from $remote_host:$remote_path"
                return 0
            fi
        done
    done

    return 1
}

copy_first() {
    local name=$1
    local dst=$2
    local found=
    local root

    for root in $remote_roots; do
        found=$(ssh "$remote_host" "find '$root' -type f -name '$name' ! -path '*blackbox_test*' -size +0c -print -quit" 2>/dev/null || true)
        if [[ -n "$found" ]]; then
            scp "$remote_host:$found" "$dst"
            echo "INFO: fetched $name from $remote_host:$found"
            return 0
        fi
    done

    echo "ERROR: failed to find $name under remote roots: $remote_roots" >&2
    return 1
}

copy_exact uvw_axi4_to_ddr4.dcp "$out_dir/rtl/soc/uvw_axi4_to_ddr4.dcp" \
    hw.dat/Synthesis/Dcp/uvw_axi4_to_ddr4/uvw_axi4_to_ddr4.dcp \
    rtl/soc/uvw_axi4_to_ddr4.dcp || \
    copy_first uvw_axi4_to_ddr4.dcp "$out_dir/rtl/soc/uvw_axi4_to_ddr4.dcp"

copy_exact uvw_axi4_to_ddr4_Stub.v "$out_dir/rtl/soc/uvw_axi4_to_ddr4_Stub.v" \
    rtl/soc/uvw_axi4_to_ddr4_Stub.v \
    hw.dat/Synthesis/Static_elab/Src/uvw_axi4_to_ddr4.v || \
    copy_first uvw_axi4_to_ddr4_Stub.v "$out_dir/rtl/soc/uvw_axi4_to_ddr4_Stub.v"

copy_exact uvw_axi4_to_ddr4_pblock.tcl "$out_dir/script/uvw_axi4_to_ddr4_pblock.tcl" \
    hw.dat/Compile/PnR/B0/F2/uvw_axi4_to_ddr4_pblock.tcl \
    script/uvw_axi4_to_ddr4_pblock.tcl || \
    copy_first uvw_axi4_to_ddr4_pblock.tcl "$out_dir/script/uvw_axi4_to_ddr4_pblock.tcl"

if ! copy_exact custom_parts_ddr4_KSM26SES8_2666.csv "$out_dir/script/custom_parts_ddr4_KSM26SES8_2666.csv" \
    script/custom_parts_ddr4_KSM26SES8_2666.csv \
    hw.dat/Compile/PnR/B0/F2/custom_parts_ddr4_KSM26SES8_2666.csv && \
    ! copy_first custom_parts_ddr4_KSM26SES8_2666.csv "$out_dir/script/custom_parts_ddr4_KSM26SES8_2666.csv"; then
    echo "INFO: optional custom_parts_ddr4_KSM26SES8_2666.csv not fetched"
fi
