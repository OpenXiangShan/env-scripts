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

# Extract runner archive to shared location (if not already extracted)
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
    echo "Setting runner $i (0 .. $((runner_count - 1)))"

    INDEX=$(printf "%0${digits}d" "$i")

    # runner_name format: $(runner_base_name)-$(hostname)-$(i)
    runner_name="${runner_base_name}-${hostname}-${INDEX}"

    echo "runner_name: ${runner_name}"

    # Runner directory path is $(base_dir)/$(runner_name)
    runner_dir="${base_dir}/${runner_name}"
    
    echo "Creating runner directory: $runner_dir"
    run_cmd mkdir -p "$runner_dir"

    # Skip extraction if config.sh already exists
    if [ -f "${runner_dir}/config.sh" ]; then
        echo "config.sh exists in ${runner_dir}, skipping actions-runner creation"
    else
        # Copy all files (except bin and externals) from shared_runner_dir to runner_dir
        echo "Copying runner files to $runner_dir..."
        # run_cmd find "$shared_runner_dir" -maxdepth 1 -mindepth 1 -not -name 'bin' -not -name 'externals' -exec cp -rP {} "$runner_dir/" \;
        run_cmd find "$shared_runner_dir" -maxdepth 1 -mindepth 1 -not -name 'externals' -exec cp -rP {} "$runner_dir/" \;

        # And link bin and externals to shared location
        # run_cmd ln -s "$shared_runner_dir/bin" "$runner_dir/bin"
        run_cmd ln -s "$shared_runner_dir/externals" "$runner_dir/externals"
    fi

    # Enter directory and configure runner
    echo "Configuring runner: $runner_name"
    run_cmd cd "$runner_dir" || exit 1

    # Run configuration command
    echo "Executing configuration command"
    run_cmd proxychains ./config.sh --unattended --url $url --token $token --replace --name $runner_name --labels $label

    # Workaround: GitHub action runner ./bin/Runner.Listener writes .runner files to absolute path of parent of bin/ (i.e. shared_runner_dir)
    #             We need to move them back to runner_dir to avoid conflicts between runners sharing the same shared_runner_dir
    # if [ -f "${shared_runner_dir}/.runner" ]; then
    #     run_cmd mv "${shared_runner_dir}/.credentials" "${runner_dir}/.credentials"
    #     run_cmd mv "${shared_runner_dir}/.credentials_rsaparams" "${runner_dir}/.credentials_rsaparams"
    #     run_cmd mv "${shared_runner_dir}/_diag" "${runner_dir}/_diag"
    #     run_cmd mv "${shared_runner_dir}/_work" "${runner_dir}/_work"
    #     run_cmd mv "${shared_runner_dir}/.runner" "${runner_dir}/.runner"
    #     run_cmd mv "${shared_runner_dir}/svc.sh" "${runner_dir}/svc.sh"
    # fi

    # Return to original directory
    run_cmd cd - > /dev/null

    echo "Runner $i configuration complete: $runner_name"
    echo "----------------------------------------"
done

echo "All $runner_count runners configured!"
