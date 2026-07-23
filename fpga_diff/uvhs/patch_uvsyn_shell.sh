#!/usr/bin/env bash
set -euo pipefail

module_makefile=${1:?usage: $0 /path/to/module.makefile}

for _ in $(seq 1 12000); do
    if [[ -f "$module_makefile" ]]; then
        if grep -Eq 'bash[[:space:]]+([^[:space:]]*/)?uv_shell[[:space:]]' "$module_makefile"; then
            printf 'INFO: UVHS module worker already invokes uv_shell through bash: %s\n' "$module_makefile"
            exit 0
        fi
        sed -E -i \
            -e 's/until[[:space:]]+sh[[:space:]]+-c/until bash -c/' \
            -e 's#(^|[[:space:]])(/[^[:space:]]*/bin/uv_shell)([[:space:]])#\1bash \2\3#g' \
            -e 's#(^|[[:space:]])(uv_shell)([[:space:]])#\1bash \2\3#g' \
            "$module_makefile"
        if grep -Eq 'bash[[:space:]]+([^[:space:]]*/)?uv_shell[[:space:]]' "$module_makefile"; then
            printf 'INFO: patched UVHS module worker uv_shell invocation: %s\n' "$module_makefile"
            : >"${module_makefile}.uvhs_bash_patch.ok"
            exit 0
        fi
        echo "ERROR: module.makefile appeared but uv_shell invocation was not patched: $module_makefile" >&2
        exit 1
    fi
    sleep 0.05
done

echo "ERROR: timed out waiting for UVHS module makefile: $module_makefile" >&2
exit 1
