#!/usr/bin/env bash
set -euo pipefail

module_makefile=${1:?usage: $0 /path/to/module.makefile}

for _ in $(seq 1 600); do
    if [[ -f "$module_makefile" ]]; then
        sed -i \
            -e 's/until sh -c /until bash -lc /' \
            -e 's#/nfs/tools/UVHS/UVH_P3_1229/bin/uv_shell#bash /nfs/tools/UVHS/UVH_P3_1229/bin/uv_shell#g' \
            "$module_makefile"
        exit 0
    fi
    sleep 1
done
