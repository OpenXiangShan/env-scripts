# Default configuration
hostname=$(hostname -s)
runner_base_name="xiangshan"
session_name="ci-${runner_base_name}-runners"
base_dir="/nfs/home/xuzefan/test"
runner_count=6

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
            echo "Usage: $0 [-r runner_name] [-d base_directory] [-n runner_count]"
            echo "Default: runner=$runner_base_name, directory=$base_dir, count=$runner_count"
            exit 0
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
