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
require_env "RUNNER_VERSION"
require_env "RUNNER_EXTRACT_DIR"

runner_file="$RUNNER_FILE"
runner_version="$RUNNER_VERSION"
extract_dir="$RUNNER_EXTRACT_DIR"

# Load user configuration
. "$SCRIPT_DIR/config.sh"

# 1. Prepare Extracted Assets (Once)
# If the extract directory does not have the 'bin' folder, we assume it needs extraction.
if [ ! -d "$extract_dir/bin" ]; then
    echo "Extracting $runner_file to $extract_dir ..."
    
    if [ ! -f "$runner_file" ]; then
        echo "Error: runner archive $runner_file not found!"
        exit 1
    fi
    
    mkdir -p "$extract_dir"
    tar -xzf "$runner_file" -C "$extract_dir"
else
    echo "Using existing extracted files at $extract_dir"
fi

# Create base directory if needed
mkdir -p "$base_dir"

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
    mkdir -p "$runner_dir"

    # 2. Files Distribution (Manual Update Logic)
    target_bin_dir="${runner_dir}/bin.${runner_version}"
    target_ext_dir="${runner_dir}/externals.${runner_version}"

    # a) Copy bin directory
    if [ ! -d "$target_bin_dir" ]; then
        echo "Creating $target_bin_dir..."
        mkdir -p "$target_bin_dir"
        cp -rP "$extract_dir/bin/." "$target_bin_dir/"
    else
        echo "$target_bin_dir already exists, skipping copy."
    fi

    # b) Copy externals directory
    if [ ! -d "$target_ext_dir" ]; then
        echo "Creating $target_ext_dir..."
        mkdir -p "$target_ext_dir"
        cp -rP "$extract_dir/externals/." "$target_ext_dir/"
    else
        echo "$target_ext_dir already exists, skipping copy."
    fi

    # c) Copy other root files (excluding bin and externals)
    echo "Copying root runner files..."
    # Copy all files from extract_dir to runner_dir except bin and externals
    # Using find to handle the exclusion and copy
    find "$extract_dir" -maxdepth 1 -mindepth 1 -not -name 'bin' -not -name 'externals' -exec cp -rP {} "$runner_dir/" \;

    # 3. Symlink Switching
    echo "Updating symlinks..."
    
    # Handle 'bin' symlink
    if [ -L "$runner_dir/bin" ]; then
        rm "$runner_dir/bin"
    elif [ -d "$runner_dir/bin" ]; then
        echo "Warning: moving existing processing directory 'bin' to 'bin.old.$(date "+%Y%m%d")'"
        mv "$runner_dir/bin" "$runner_dir/bin.old.$(date "+%Y%m%d")"
    fi
    ln -s "bin.${runner_version}" "$runner_dir/bin"

    # Handle 'externals' symlink
    if [ -L "$runner_dir/externals" ]; then
        rm "$runner_dir/externals"
    elif [ -d "$runner_dir/externals" ]; then
        echo "Warning: moving existing directory 'externals' to 'externals.old.$(date "+%Y%m%d")'"
        mv "$runner_dir/externals" "$runner_dir/externals.old.$(date "+%Y%m%d")"
    fi
    ln -s "externals.${runner_version}" "$runner_dir/externals"
    
    echo "Runner $i update complete: $runner_name"
    echo "----------------------------------------"
done

echo "All $runner_count runners updated and configured!"

