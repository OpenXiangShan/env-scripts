#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# Ensure required GitHub runner environment variables are provided
require_env() {
    local var_name="$1"
    local value="${!var_name:-}"
    if [ -z "$value" ]; then
        echo "Error: environment variable ${var_name} is not set." >&2
        exit 1
    fi
}

require_env "RUNNER_URL"
require_env "RUNNER_TOKEN"
require_env "RUNNER_LABELS"
require_env "RUNNER_FILE"

url="$RUNNER_URL"
token="$RUNNER_TOKEN"
label="$RUNNER_LABELS"
runner_file="$RUNNER_FILE"

# Load user configuration
. "$SCRIPT_DIR/config.sh"

# Verify runner archive exists
if [ ! -f "$runner_file" ]; then
    echo "Error: runner archive $runner_file not found!"
    exit 1
fi

# Create base directory if needed
mkdir -p "$base_dir"

# Iterate runner_count times
for ((i=0; i<runner_count; i++)); do
    echo "Setting runner $i (0 .. $((runner_count - 1)))"

    continue

    INDEX=$(printf "%0${digits}d" "$i")

    # runner_name format: $(runner_base_name)-$(host_name)-$(i)
    runner_name="${runner_base_name}-${host_name}-${INDEX}"

    echo "runner_name: ${runner_name}"

    # Runner directory path is $(base_dir)/$(runner_name)
    runner_dir="${base_dir}/${runner_name}"
    
    echo "Creating runner directory: $runner_dir"
    mkdir -p "$runner_dir"

    # Skip extraction if config.sh already exists (avoid redundant unpack)
    if [ -f "${runner_dir}/config.sh" ]; then
        echo "config.sh exists in ${runner_dir}, skipping actions-runner extraction"
    else
        # Extract actions-runner into the directory
        echo "Extracting actions-runner to $runner_dir"
        tar -xzf "$runner_file" -C "$runner_dir"
    fi

    # Enter directory and configure runner
    echo "Configuring runner: $runner_name"
    cd "$runner_dir" || exit 1
    
    # Run configuration command
    echo "Executing configuration command"
    echo "    proxychains ./config.sh --unattended --url $url --token $token --replace --name $runner_name --labels $label"
    proxychains ./config.sh --unattended --url $url --token $token --replace --name $runner_name --labels $label
    # proxychains ./config.sh remove --token $token

    
    # Return to original directory
    cd - > /dev/null
    
    echo "Runner $i configuration complete: $runner_name"
    echo "----------------------------------------"
done

echo "All $runner_count runners configured!"

