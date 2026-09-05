#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Preserve raw CLI args because config.sh will parse and shift them.
original_args=("$@")

# Read configuration file and parse common arguments
. "$SCRIPT_DIR/config.sh"

# 1. Stop runners safely and close tmux session.
echo "Stopping runners safely via $SCRIPT_DIR/stop_runners_safe.sh"
if ! "$SCRIPT_DIR/stop_runners_safe.sh" "${original_args[@]}"; then
    echo "Error: stop_runners_safe.sh failed"
    exit 1
fi

# 2. Restart runners (reusing start_runners.sh)
echo "Starting runners via $SCRIPT_DIR/start_runners.sh"
if ! "$SCRIPT_DIR/start_runners.sh" "${original_args[@]}"; then
    echo "Error: start_runners.sh failed"
    exit 1
fi

echo
echo "Complete! Safe restart flow finished for session '$session_name'"
