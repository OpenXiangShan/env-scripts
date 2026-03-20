#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Preserve raw CLI args because config.sh will parse and shift them.
original_args=("$@")

# Read configuration file and parse common arguments
. "$SCRIPT_DIR/config.sh"

# Ensure required GitHub runner environment variables are provided
require_env() {
    local var_name="$1"
    local value="${!var_name:-}"
    if [ -z "$value" ]; then
        echo "Error: environment variable ${var_name} is not set." >&2
        exit 1
    fi
}

# Check whether runner-related processes are still active on a pane's TTY.
is_runner_active_in_pane() {
    local pane_target="$1"
    local pane_tty

    pane_tty="$(tmux display-message -p -t "$pane_target" '#{pane_tty}')"
    if [ -z "$pane_tty" ]; then
        return 1
    fi

    if ps -t "$pane_tty" -o comm= 2>/dev/null | grep -Eq 'Runner\.Listener|Runner\.Worker|run\.sh|runsvc\.sh|proxychains|proxychains4'; then
        return 0
    fi
    return 1
}

# Capture the last non-empty line from a pane for idle-state detection.
get_last_nonempty_line() {
    local pane_target="$1"
    # -S -200: include recent scrollback; -J: join wrapped physical lines into logical lines.
    # This avoids missing keywords when pane width is too small and long lines wrap.
    tmux capture-pane -pJ -S -200 -t "$pane_target" 2>/dev/null | awk '
        {
            gsub(/\r/, "", $0)
            if (NF) {
                line=$0
            }
        }
        END {
            print line
        }
    '
}

# A pane is considered idle if the last non-empty line contains one of idle markers.
is_pane_idle() {
    local pane_target="$1"
    local last_line

    last_line="$(get_last_nonempty_line "$pane_target")"

    if [[ "$last_line" == *"completed with result"* ]] || [[ "$last_line" == *"Listening for Jobs"* ]]; then
        return 0
    fi
    return 1
}

wait_until_all_runners_stopped() {
    local poll_interval=3
    local iteration=0
    local has_pending=1

    # Use dynamic variable names to avoid requiring bash 4+ associative arrays.
    for ((i=0; i<runner_count; i++)); do
        eval "stop_sent_${i}=0"
    done

    while [ "$has_pending" -eq 1 ]; do
        has_pending=0
        iteration=$((iteration + 1))

        echo "Check iteration #$iteration"

        for ((i=0; i<runner_count; i++)); do
            local index
            local runner_name
            local pane_target
            local stop_sent

            index=$(printf "%0${digits}d" "$i")
            runner_name="${runner_base_name}-${hostname}-${index}"
            pane_target="$session_name:0.$i"

            if ! tmux list-panes -t "$pane_target" >/dev/null 2>&1; then
                echo "Error: pane '$pane_target' for runner '$runner_name' does not exist"
                return 1
            fi

            eval "stop_sent=\${stop_sent_${i}}"

            if ! is_runner_active_in_pane "$pane_target"; then
                echo "  [$runner_name] already stopped (no runner process on pane tty)"
                continue
            fi

            has_pending=1

            if [ "$stop_sent" -eq 1 ]; then
                echo "  [$runner_name] waiting to stop... (runner process still active)"
                continue
            fi

            if is_pane_idle "$pane_target"; then
                local last_line
                last_line="$(get_last_nonempty_line "$pane_target")"
                echo "  [$runner_name] idle, sending Ctrl+C (last line: $last_line)"
                run_cmd tmux send-keys -t "$pane_target" C-c
                eval "stop_sent_${i}=1"
            else
                local last_line
                last_line="$(get_last_nonempty_line "$pane_target")"
                echo "  [$runner_name] busy, keep waiting (last line: ${last_line:-<empty>})"
            fi
        done

        if [ "$has_pending" -eq 1 ]; then
            run_cmd sleep "$poll_interval"
        fi
    done

    echo "All runners in session '$session_name' have stopped."
    return 0
}

# Safety checks
if [[ "$dry_run" == true ]]; then
    echo "Dry run mode: skip safe-stop probing and chain existing scripts in dry-run mode"
else
    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Error: Session '$session_name' does not exist"
        exit 1
    fi
fi

# 1-3. Wait until each runner is idle and then stop it with Ctrl+C; loop until all are stopped.
if [[ "$dry_run" != true ]]; then
    if ! wait_until_all_runners_stopped; then
        echo "Error: failed while waiting runners to stop safely"
        exit 1
    fi
fi

# 4. Close tmux session.
echo "Killing session: $session_name"
run_cmd tmux kill-session -t "$session_name"

# 5. Update runners (reusing update_runners.sh)
require_env "RUNNER_FILE"
echo "Updating runners via $SCRIPT_DIR/update_runners.sh"
if ! "$SCRIPT_DIR/update_runners.sh" "${original_args[@]}"; then
    echo "Error: update_runners.sh failed"
    exit 1
fi

# 6. Restart runners (reusing start_runners.sh)
echo "Starting runners via $SCRIPT_DIR/start_runners.sh"
if ! "$SCRIPT_DIR/start_runners.sh" "${original_args[@]}"; then
    echo "Error: start_runners.sh failed"
    exit 1
fi

echo
echo "Complete! Safe update flow finished for session '$session_name'"
