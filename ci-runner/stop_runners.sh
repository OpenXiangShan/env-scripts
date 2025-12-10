#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Read configuration file
. "$SCRIPT_DIR/config.sh"

# Check if session already exists
if ! tmux has-session -t "$session_name" 2>/dev/null; then
    echo "Note: Session '$session_name' does not exist, exiting"
    exit 1
fi

# Set up runners in each pane
for ((i=0; i<runner_count; i++)); do
    # Format index as two-digit number
    index=$(printf "%0${digits}d" $i)
    runner_name="${runner_base_name}-${hostname}-${index}"

    pane_target="$session_name:0.$i"

    echo "Stopping runner ($runner_name) in pane $i"

    # Send commands
    tmux send-keys -t "$pane_target" C-c

done

# Brief pause to ensure all runners have stopped
sleep 5

# kill the tmux session
tmux kill-session -t "$session_name"

echo
echo "Complete! Session '$session_name' has been stopped"
