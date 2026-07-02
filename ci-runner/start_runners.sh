#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Read configuration file
. "$SCRIPT_DIR/config.sh"

function session_exists() {
    tmux has-session -t "$session_name" 2>/dev/null
}

function find_pane_by_title() {
    local title="$1"
    tmux list-panes -t "$session_name" -F '#{pane_id} #{pane_title}' 2>/dev/null | awk -v target="$title" '$2 == target { print $1; exit }'
}

function first_pane_id() {
    tmux list-panes -t "$session_name" -F '#{pane_id}' 2>/dev/null | head -n 1
}

function is_runner_active_in_pane() {
    local pane_target="$1"
    local pane_tty

    pane_tty="$(tmux display-message -p -t "$pane_target" '#{pane_tty}' 2>/dev/null)"
    if [ -z "$pane_tty" ]; then
        return 1
    fi

    if ps -t "$pane_tty" -o comm= 2>/dev/null | grep -Eq 'Runner\.Listener|Runner\.Worker|run\.sh|runsvc\.sh|proxychains|proxychains4'; then
        return 0
    fi
    return 1
}

# Check if session already exists
session_created=false
if session_exists; then
    echo "Session '$session_name' already exists, reusing"
else
    echo "Creating session: $session_name"
    run_cmd tmux new-session -d -s "$session_name" -c "$base_dir"
    session_created=true
fi

# Check if base directory exists
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory '$base_dir' does not exist"
    exit 1
fi

for ((i=0; i<runner_count; i++)); do
    # Format index as two-digit number
    index=$(printf "%0${digits}d" $i)
    runner_name="${runner_base_name}-${hostname}-${index}"
    runner_dir="$base_dir/${runner_name}"

    pane_target=$(find_pane_by_title "$runner_name")

    if [[ -z "$pane_target" ]]; then
        echo "Creating pane for $runner_name"
        if [[ "$session_created" == true && "$i" -eq 0 ]]; then
            pane_target=$(first_pane_id)
        else
            pane_target=$(run_cmd tmux split-window -t "$session_name" -c "$base_dir" -P -F '#{pane_id}')
            # dry_run mode does not have pane_target, using placeholder
            if [[ "$dry_run" == true ]]; then
              pane_target="dry_run_pane_$runner_name"
            fi

            run_cmd tmux select-layout -t "$session_name" tiled
        fi
        echo "Created: $pane_target"
    else
        echo "Found existing pane for $runner_name: $pane_target"
    fi

    if is_runner_active_in_pane "$pane_target"; then
        echo "Runner $runner_name is already active in $pane_target, skip setting up"
    else
        echo "Setting up runner $runner_name"
        run_cmd tmux select-pane -t "$pane_target" -T "$runner_name"
        run_cmd tmux send-keys -t "$pane_target" " cd '$runner_dir'" C-m
        run_cmd tmux send-keys -t "$pane_target" " proxychains -q ./run.sh" C-m
    fi

done

echo
echo "Complete! Session '$session_name' runners have been started"
echo "Connect: tmux attach -t $session_name"
echo "View: tmux list-panes -t $session_name -F \"Pane #{pane_index}: #{pane_current_command}\""
