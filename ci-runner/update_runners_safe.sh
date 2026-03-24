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

# pre-check env, same as update_runners.sh, to fail fast before stopping runners if config is invalid
require_env "RUNNER_FILE"

# 1. Stop runners safely and close tmux session.
echo "Stopping runners safely via $SCRIPT_DIR/stop_runners_safe.sh"
if ! "$SCRIPT_DIR/stop_runners_safe.sh" "${original_args[@]}"; then
    echo "Error: stop_runners_safe.sh failed"
    exit 1
fi

# 2. Update runners (reusing update_runners.sh)
echo "Updating runners via $SCRIPT_DIR/update_runners.sh"
if ! "$SCRIPT_DIR/update_runners.sh" "${original_args[@]}"; then
    echo "Error: update_runners.sh failed"
    exit 1
fi

# 3. Restart runners (reusing start_runners.sh)
echo "Starting runners via $SCRIPT_DIR/start_runners.sh"
if ! "$SCRIPT_DIR/start_runners.sh" "${original_args[@]}"; then
    echo "Error: start_runners.sh failed"
    exit 1
fi

echo
echo "Complete! Safe update flow finished for session '$session_name'"
