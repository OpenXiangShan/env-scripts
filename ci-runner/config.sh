# Default configuration
hostname=$(hostname -s)
runner_base_name="xiangshan"
session_name="ci-${runner_base_name}-runners"
base_dir="/nfs/home/xuzefan/test"
runner_count=6
dry_run=false

function help() {
    echo "Usage: $0 [-r runner_name] [-d base_directory] [-n runner_count] [-c config.json#key] [--dry-run]"
    echo "  -r, --runner       Base name for runners (default: $runner_base_name)"
    echo "  -d, --directory    Base directory for runners (default: $base_dir)"
    echo "  -n, --count        Maximum number of runners (default: $runner_count)"
    echo "  -c, --config       Path to configuration json"
    echo "  -h, --help         Show this help message and exit"
    echo "  --dry-run          Show what would be done without actually doing it"
    exit 0
}

function run_cmd() {
    # Avoid eval so arguments (especially trailing \;) are preserved exactly
    if [[ "$dry_run" == true ]]; then
        echo "  (DRY RUN) -> $*" >&2
    else
        echo "  -> $*" >&2
        "$@"
    fi
    return $?
}

function load_config_json() {
    local json_key="$1"
    if [[ "$json_key" != *"#"* ]]; then
        echo "Error: --config must be in the format 'path/to/config.json#key'"
        exit 1
    fi
    local json=$(echo "$json_key" | cut -d'#' -f1)
    local key=$(echo "$json_key" | cut -d'#' -f2)

    if [[ ! -f "$json" ]]; then
        echo "Error: --config file $json not found."
        exit 1
    fi

    local cfg=$(jq -r ."[\"$key\"]" "$json")

    if [[ "$cfg" == "null" ]]; then
        echo "Key '$key' not found in JSON configuration."
        exit 1
    fi

    _runner_base_name=$(jq -r .basename <<< "$cfg")
    if [[ -n "$_runner_base_name" && "$_runner_base_name" != "null" ]]; then
        runner_base_name="$_runner_base_name"
        session_name="ci-${runner_base_name}-runners"
    fi

    _base_dir=$(jq -r .directory <<< "$cfg")
    if [[ -n "$_base_dir" && "$_base_dir" != "null" ]]; then
        base_dir="$_base_dir"
    fi

    _runner_count=$(jq -r .count <<< "$cfg")
    if [[ -n "$_runner_count" && "$_runner_count" != "null" ]]; then
        runner_count="$_runner_count"
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--runner)
            runner_base_name="$2"
            session_name="ci-${runner_base_name}-runners"
            shift 2
            ;;
        -d|--directory)
            base_dir="$2"
            shift 2
            ;;
        -n|--count)
            runner_count="$2"
            shift 2
            ;;
        -c|--config)
            load_config_json "$2"
            shift 2
            ;;
        -h|--help)
            help
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            exit 1
            ;;
    esac
done

echo "Configuration:"
echo "  Hostname: $hostname"
echo "  Runner name: $runner_base_name"
echo "  Session: $session_name"
echo "  Base directory: $base_dir"
echo "  Runner count: $runner_count"
echo

# Calculate digit width
max_index=$(($runner_count - 1))
digits=${#max_index}

if [[ "$dry_run" == true ]]; then
    echo "  (DRY RUN) Dry run mode activated, no actual commands will be executed."
    echo "Runner names will be: ${runner_base_name}-$(printf "%0${digits}d" "0") to ${runner_base_name}-$(printf "%0${digits}d" "$max_index")"
fi
