# DingTalk Robots

Daily XiangShan updates and reusable DingTalk helpers. Run all commands from the repository root.

## Setup

Requires Python 3.9+ and Git; no third-party Python packages are needed.

```bash
cp dingtalk_robot/config.example.json dingtalk_robot/config.json
```

Edit `dingtalk_robot/config.json`:

- `dingtalk`: Webhook and signing secret for the general-purpose robot.
- `github`: GitHub token (or `token_file`), proxy, and connection settings.
- `xiangshan_monitor`: AI API endpoint and key, debug/release robots, and gift rules.

Repository lists, schedules, and timeouts are configured in `xiangshan_monitor/repositories.json`; message instructions are in `xiangshan_monitor/prompt.txt`.
Credentials, reports, and delivery history are stored locally and excluded from Git.

## Daily XiangShan Updates

Summarizes mainline commits and GitHub stars, then generates Chinese messages recognizing contributors. Supports gift draws and limited-time gifts. Use `per_day` to set a daily gift quantity, or `per_person: true` to give one to each featured contributor.
Binary files and SVG/drawio diagrams retain only their filenames; other files retain their diffs. Long reports are split automatically.

```bash
# Workday delivery: start at 18:00, send to debug first, then release at 18:30 (Beijing time)
python3 -m dingtalk_robot.xiangshan_monitor.xiangshan_monitor --workday-delivery

# Run immediately and send to debug only
python3 -m dingtalk_robot.xiangshan_monitor.xiangshan_monitor --debug-now

# Check the workday calendar and scheduling window without network access
python3 -m dingtalk_robot.xiangshan_monitor.xiangshan_monitor --workday-delivery --dry-run

# Collect commits from the last 7 days
python3 -m dingtalk_robot.xiangshan_monitor.xiangshan_monitor --stage pull --window 7d
```

Workday mode uses `workdays.json` and resumes collection from the cutoff of the last successful release. The scheduled start window is 18:00–18:30 Beijing time. If all repositories fail to update, no messages are sent. Missing star data does not block delivery; AI failures are reported to debug only.
The `pull`, `talk`, and `push` stages can also run separately. See `--help` for all options.

`robot.py` provides reusable `send_text`, `send_markdown`, and signed-message helpers.

For monthly community reports, see [OSS statistics](../oss_stats/README.md).
