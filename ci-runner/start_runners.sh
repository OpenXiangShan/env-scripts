#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Read configuration file
. "$SCRIPT_DIR/config.sh"

# Check if session already exists
if tmux has-session -t "$session_name" 2>/dev/null; then
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
tmux new-session -d -s "$session_name" -c "$base_dir"

# Create panes
for ((i=1; i<runner_count; i++)); do
    echo "Creating pane $i"
    tmux split-window -t "$session_name" -c "$base_dir"
    tmux select-layout -t "$session_name" tiled
done

# Brief pause
sleep 0.5

# Set up runners in each pane
for ((i=0; i<runner_count; i++)); do
    # Format index as two-digit number
    index=$(printf "%0${digits}d" $i)
    runner_name="${runner_base_name}-${hostname}-${index}"
    runner_dir="$base_dir/${runner_name}"

    pane_target="$session_name:0.$i"
    
    echo "Setting up pane $i"

    # Setup pane title
    tmux select-pane -t "$pane_target" -T "$runner_name"

    # Send commands
    tmux send-keys -t "$pane_target" "cd '$runner_dir'" C-m
    tmux send-keys -t "$pane_target" "proxychains ./run.sh" C-m

done

echo
echo "Complete! Session '$session_name' has been created"
echo "Connect: tmux attach -t $session_name"
echo "View: tmux list-panes -t $session_name -F \"Pane #{pane_index}: #{pane_current_command}\""
