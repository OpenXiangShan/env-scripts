# Default configuration
hostname=$(hostname -s)
runner_base_name="xiangshan"
session_name="ci-${runner_base_name}-runners"
base_dir="/nfs/home/xuzefan/test"
runner_count=6
dry_run=false

function help() {
    echo "Usage: $0 [-r runner_name] [-d base_directory] [-n runner_count] [--dry-run]"
    echo "  -r, --runner       Base name for runners (default: $runner_base_name)"
    echo "  -d, --directory    Base directory for runners (default: $base_dir)"
    echo "  -n, --count        Maximum number of runners (default: $runner_count)"
    echo "  -h, --help         Show this help message and exit"
    echo "  --dry-run          Show what would be done without actually doing it"
    exit 0
}

function run_cmd() {
    # Avoid eval so arguments (especially trailing \;) are preserved exactly
    if [[ "$dry_run" == true ]]; then
        echo "  (DRY RUN) -> $*"
    else
        echo "  -> $*"
        "$@"
    fi
    return $?
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
