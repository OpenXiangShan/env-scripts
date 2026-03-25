#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Read configuration file
. "$SCRIPT_DIR/config.sh"

# Check if session already exists
if [[ "$dry_run" == true ]]; then
    echo "  (DRY RUN) Skipping session existence check for '$session_name'"
elif tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Error: Session '$session_name' already exists, exiting"
    echo "You may use following command to kill it:"
    echo "    tmux kill-session -t $session_name"
    exit 1
fi

# Check if base directory exists
if [ ! -d "$base_dir" ]; then
    echo "Error: Directory '$base_dir' does not exist"
    exit 1
fi

# Create new tmux session
echo "Creating session: $session_name"
run_cmd tmux new-session -d -s "$session_name" -c "$base_dir"

# Create panes
for ((i=1; i<runner_count; i++)); do
    echo "Creating pane $i"
    run_cmd tmux split-window -t "$session_name" -c "$base_dir"
    run_cmd tmux select-layout -t "$session_name" tiled
done

# Brief pause
run_cmd sleep 0.5

# Set up runners in each pane
for ((i=0; i<runner_count; i++)); do
    # Format index as two-digit number
    index=$(printf "%0${digits}d" $i)
    runner_name="${runner_base_name}-${hostname}-${index}"
    runner_dir="$base_dir/${runner_name}"

    pane_target="$session_name:0.$i"
    
    echo "Setting up pane $i"

    # Setup pane title
    run_cmd tmux select-pane -t "$pane_target" -T "$runner_name"

    # Send commands
    run_cmd tmux send-keys -t "$pane_target" "cd '$runner_dir'" C-m
    run_cmd tmux send-keys -t "$pane_target" "proxychains -q ./run.sh" C-m

done

echo
echo "Complete! Session '$session_name' has been created"
echo "Connect: tmux attach -t $session_name"
echo "View: tmux list-panes -t $session_name -F \"Pane #{pane_index}: #{pane_current_command}\""
