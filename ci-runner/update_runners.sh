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

require_env "RUNNER_FILE"

runner_file="$RUNNER_FILE"
runner_version=$(basename "$runner_file" .tar.gz | cut -d- -f5)

# Verify runner archive exists
if [ ! -f "$runner_file" ]; then
    echo "Error: runner archive $runner_file not found!"
    exit 1
fi

# Verify filename format
if [[ -z "$runner_version" ]]; then
    echo "Error: Unable to extract runner version from filename '$runner_file'"
    exit 1
fi

# Load user configuration
. "$SCRIPT_DIR/config.sh"

# Create base directory if needed
run_cmd mkdir -p "$base_dir"

# 1. Extract runner archive to shared location (if not already extracted)
shared_runner_dir="$base_dir/runner-${runner_version}"
if [ ! -d "$shared_runner_dir" ]; then
    echo "Extracting $runner_file to $shared_runner_dir ..."
    run_cmd mkdir -p "$shared_runner_dir"
    run_cmd tar -xzf "$runner_file" -C "$shared_runner_dir"
else
    echo "Using existing extracted files at $shared_runner_dir"
fi

# Iterate runner_count times
for ((i=0; i<runner_count; i++)); do
    echo "Updating runner $i (0 .. $((runner_count - 1)))"

    INDEX=$(printf "%0${digits}d" "$i")

    # runner_name format: $(runner_base_name)-$(hostname)-$(i)
    runner_name="${runner_base_name}-${hostname}-${INDEX}"

    echo "runner_name: ${runner_name}"

    # Runner directory path is $(base_dir)/$(runner_name)
    runner_dir="${base_dir}/${runner_name}"
    
    echo "Ensuring runner directory exists: $runner_dir"
    run_cmd mkdir -p "$runner_dir"

    # 2. Copy other root files (excluding bin and externals)
    echo "Copying root runner files..."
    # Copy all files from shared_runner_dir to runner_dir except bin and externals
    # Using find to handle the exclusion and copy
    # run_cmd find "$shared_runner_dir" -maxdepth 1 -mindepth 1 -not -name 'bin' -not -name 'externals' -exec cp -rP {} "$runner_dir/" \;
    run_cmd find "$shared_runner_dir" -maxdepth 1 -mindepth 1 -not -name 'externals' -exec cp -rP {} "$runner_dir/" \;

    # 3. Symlink Switching
    echo "Updating symlinks..."
    
    # Handle 'bin' symlink
    # if [ -L "$runner_dir/bin" ]; then
    #     run_cmd rm "$runner_dir/bin"
    # elif [ -d "$runner_dir/bin" ]; then
    #     echo "Warning: removing legacy 'bin' dir"
    #     run_cmd rm -rf "$runner_dir/bin"
    # fi
    # run_cmd ln -s "$shared_runner_dir/bin" "$runner_dir/bin"

    # Handle 'externals' symlink
    if [ -L "$runner_dir/externals" ]; then
        run_cmd rm "$runner_dir/externals"
    elif [ -d "$runner_dir/externals" ]; then
        echo "Warning: removing legacy 'externals' dir"
        run_cmd rm -rf "$runner_dir/externals"
    fi
    run_cmd ln -s "$shared_runner_dir/externals" "$runner_dir/externals"
    
    echo "Runner $i update complete: $runner_name"
    echo "----------------------------------------"
done

echo "All $runner_count runners updated and configured!"
echo "Consider removing old shared runner directory if no longer needed: $(find "$base_dir" -maxdepth 1 -type d -name 'runner-*' ! -name "runner-${runner_version}")"
