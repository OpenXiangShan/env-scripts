# Github 自托管运行器 维护脚本

## Python 管理器

推荐使用 `python3 manager.py` 管理新建或显式导入的 runner。需要 **Linux、Python 3.12+ 和 tmux**，自动安装包选择支持 x64/arm64。管理器不运行守护进程；命令结束后 runner 留在 tmux 中运行。原 Bash 脚本保留供未迁移的 runner 使用。

业务参数通过命令行或保存的配置传递，不读取 `RUNNER_URL`、`RUNNER_TOKEN`、`RUNNER_FILE` 等环境变量。以下命令中的 `demo` 是组名，名称允许字母、数字、下划线和连字符，首字符必须是字母或数字。

### 创建与扩容

```bash
python3 manager.py create \
  --url https://github.com/OWNER/REPO \
  --token '<token>' \
  --dir /path/to/runners \
  --count 10 --labels label1,label2 \
  --runner-file /path/to/actions-runner-linux-x64-2.333.0.tar.gz \
  demo

# 扩容到 11 个；不是再增加 11 个
python3 manager.py create --count 11 --token '<token>' demo
```

首次创建必须提供 `--dir`、`--url`、`--count` 和 `--token`。`--labels` 可省略；目录、URL、标签、运行代理和安装包信息会保存。同组后续 create 可省略这些参数；显式指定与现有配置冲突的值会报错。相同目标重复 create 不新增实例，缩容必须使用 remove。创建不会自动启动新增实例。

实例从 0 编号，名称为 `<组名>-<短hostname>-<补零索引>`，宽度取决于最大下标。因此 10→11 会把 `demo-host-0` 改为 `demo-host-00`，100→101 会把 `demo-host-00` 改为 `demo-host-000`。跨位数变更会等待受影响的 runner 停止，注销旧名称、重命名目录、重新注册，并恢复原先运行的保留实例。工作目录和日志随实例目录保留。

注册和注销都统一使用 `--token`，来自 GitHub runner 配置页面；跨位数操作将同一值传入两个步骤，具体权限由 GitHub 校验。管理器不保存或打印 token；token 过期或权限不足时，提供新的 token 重试同一命令即可。命令行参数可能被同机进程列表查看。

### 启动、状态与停止

```bash
python3 manager.py start demo
python3 manager.py status demo
python3 manager.py status --verbose demo  # 当前任务、耗时及上次执行结果
python3 manager.py status          # 本机所有组
python3 manager.py status --json
python3 manager.py status --verbose --json demo
python3 manager.py stop --timeout 3600 demo
python3 manager.py stop --force demo
```

每组使用一个独立 session，每个 runner 一个 window。status 展示实际 session/pane，可使用 `tmux attach -t <session>` 查看。管理器通过元数据和进程识别实例，不依赖 window 编号、标题或 pane 排列。runner 退出后保留 window 供诊断，stop 会清理已停止的受管理 window。重复 start 不创建重复进程，重复 stop 成功返回。

`status --verbose`（或 `-v`）从 tmux 捕获的输出解析活动信息，按以下格式显示：

```text
demo-host-0: 2026-10-23T10:00:00-07:00
  State: Running
  Task: build
  Elapsed: 00:03:15
demo-host-1: 2026-10-23T10:00:01-07:00
  State: Idle
  Last Task: test
  Result: Success
```

头部时间取本次启动后首次 `Listening for Jobs` 的时间，使用带时区的本地 ISO 8601 格式；`Elapsed` 从当前任务的 `Running job` 时间计算。`Result` 将 runner 的 Succeeded、Failed、Canceled 分别显示为 Success、Failed、Cancelled。尚无历史任务、时间或输出已滚出 tmux 历史时显示 `-`；停止、异常状态分别显示 Stopped、Error 或 Unknown。JSON 模式额外提供 `started_at`、`current_task`、`elapsed`（秒）、`last_task` 和 `result`，缺失信息使用 `null`。

stop、update、remove 和需要重命名的 create 默认等待任务结束，再发送 Ctrl-C，并确认进程退出。`--timeout` 指定本次停止阶段的总等待秒数，不指定则无限等待；超时保留进度。`--force` 允许立即中断任务，10 秒宽限期后强制终止受管理进程。

忙闲判断结合本地进程和最近输出。`unknown` 表示无法确认，此时默认继续等待；本地判断不能完全消除刚结束任务又立即接到新任务的竞争。进程若在管理器之外运行，会拒绝继续修改对应目录。

### 安装包、更新与代理

```bash
python3 manager.py update demo
python3 manager.py update --runner-file /path/to/actions-runner-linux-x64-2.334.0.tar.gz demo

python3 manager.py create \
  --url https://github.com/OWNER/REPO --token '<token>' \
  --dir /path/to/runners --count 4 --labels label1,label2 \
  --proxy-command 'proxychains -q' demo
```

`--runner-file` 使用匹配本机平台的本地安装包，并纳入入口目录的 `.cache/`。没有该参数时，create 优先选择缓存中的最高稳定版本，无缓存才下载；update 总是查询最新稳定 Release，缓存命中则复用。已有组扩容继续使用该组已选择的安装包；导入组尚未选定安装包时按缓存规则选择。

下载会校验 GitHub Release 提供的 SHA-256；没有可验证摘要时拒绝自动安装，需自行提供可信本地包。本地包按内容摘要缓存，不代表管理器验证了其发布者身份。解压拒绝路径逃逸和不安全链接。

更新先准备安装包，再停止受影响实例、覆盖程序文件并恢复原运行集合。相同版本且内容相同的重复更新不重启；注册文件、工作目录和日志保留。每实例有独立 `bin`，`externals` 链接到缓存中的版本目录；不要删除仍被实例引用的 `.cache/`。管理器不自动清理旧缓存。新注册 runner 使用 `--disableupdate`，由 manager 统一更新。

`--proxy-command` 是注册、注销和 runner 运行时的命令前缀，会保存在组配置中。下载不使用该参数，也不读取 HTTP 代理环境配置；需要代理下载时自行执行 `proxychains python3 manager.py ...`。前缀按参数列表执行，不支持管道、重定向或 shell 变量展开。

### 缩容与清空

```bash
# 最终保留 8 个，删除下标 8 及之后的实例
python3 manager.py remove --count 8 --token '<token>' demo

# 清空并删除组配置
python3 manager.py remove --count 0 --token '<token>' demo
```

**`remove --count N` 表示最终保留 N 个，不是本次删除 N 个。** 只从末尾移除，不支持范围删除；重复执行不会继续删除。若最终数量使下标位宽改变，保留实例也会注销并重新注册。移除会删除对应实例目录，包括工作目录和日志；共享缓存保留。

### 导入旧 runner

先使用旧安全停止脚本停止该组，然后导入：

```bash
./stop_runners_safe.sh --config xs.json#runner
python3 manager.py import --config xs.json#runner --labels bosc,runner
# 若旧 runner 使用代理，导入时同时传 --proxy-command 'proxychains -q'
python3 manager.py start xs-runner
```

组名取旧配置的 `basename`，不是 JSON key；上例中的实际名称以 `xs.json` 为准。import 检查目录、名称、注册信息和进程，发现运行进程或信息冲突时拒绝。URL 默认从 `.runner` 读取，缺失时可提供 `--url`。导入不注销、不重命名、不启动，标签必须显式提供。导入后不要再用旧脚本操作该组；旧 runner 的自动更新设置不会被 import 改写。

### 持久化与失败恢复

入口目录的 `state/<短hostname>.json` 按组名保存配置，保证同一状态目录内 `(hostname, name)` 唯一。修改命令通过主机锁串行执行；JSON 原子写入，目录通过所有权标记校验。status 可在修改期间读取操作进度。

外部操作前记录目标和阶段，逐实例保存进度。命令中断后重新执行相同操作和目标即可恢复，可以调整 `--timeout`、`--force` 或重新提供 token。未完成操作会阻止该组执行其他修改命令。已经完成的远端操作不会自动回滚。

如果 GitHub 注册成功但本地注册文件不完整，或注销过程中本地文件仅被部分删除，管理器会保留现场并报错。此时先核对 GitHub runner 列表及本地 `.runner` / `.credentials`，修复身份信息后重试；不要盲目删改状态文件或使用 `--replace` 覆盖未知 runner。state、缓存和运行目录应由同一个可信用户管理，不要在运行中手动改名或替换为符号链接。

验收建议：先在临时目录和隔离 tmux socket 中使用伪 config/run 脚本验证重复执行、10↔11 / 100↔101 位宽变化、忙任务等待、超时和中断恢复；再使用临时 GitHub 仓库验证真实注册、重注册及注销，确认没有遗留旧名称。不要直接使用生产 runner 做故障注入。

## 旧 Bash 脚本

已移动至 ./legacy 文件夹。

此文件夹包含一系列用于维护 Self-hosted Runner 的妙妙脚本，能够有效降低维护 runner 的工作强度，提升幸福感。

## 配置

新版本的脚本已支持从 json 文件中读取配置（包括前缀 `-r`、运行目录 `-d` 和数量 `-n`，以及 `RUNNER_LABELS`，其余 RUNNER_FILE 等配置仍通过环境变量配置）

示例 `xs.json`：
```json
{
    "runner": {
        "basename": "runner",
        "directory": "/nfs/home/ci-runner",
        "count": "16",
        "labels": "bosc,runner"
    },
    "builder": {
        "basename": "builder",
        "directory": "/nfs/home/ci-runner",
        "count": "4",
        "labels": "bosc,builder"
    }
}
```

随后通过 `--config <json_path>#<key>` 参数使用，如 `./start_runner.sh --config xs.json#runner` 等效于 `./start_runner.sh -r runner -d /nfs/home/ci-runner -n 16`。

**注意**：`--config` 和其它参数是按顺序解析的，后面的参数会覆盖前面的配置。例如 `./start_runner.sh -n 10 --config xs.json#runner` 会完全使用 `xs.json` 的配置（n=16），而 `./start_runner.sh --config xs.json#runner -n 10` 会使用 `xs.json` 的配置，但 runner 数量被命令行覆盖为n=10。

## 创建 runners
`create_runners.sh` 脚本用于创建 self-hosted runner。需要根据 GitHub 上 Add new self-hosted runner 页面的指示设置环境变量 `RUNNER_URL`、`RUNNER_TOKEN`。需要下载 Runner Package 并将地址设为 `RUNNER_FILE` 环境变量。需要根据需要设置 `RUNNER_LABELS` 环境变量（逗号分隔）。

> 这里使用环境变量而不是参数，是为了让 `config.sh` 脚本统一处理所有脚本的参数。

### 示例
在 Open 服务器上：
```shell
~/xstop \
RUNNER_URL="https://github.com/OpenXiangShan/XiangShan" \
RUNNER_TOKEN="<token_from_github_new_self-hosted_runner_page>" \
RUNNER_LABELS="bosc,open" \
RUNNER_FILE=~/actions-runner-linux-x64-2.333.0.tar.gz \
~/env-scripts/ci-runner/create_runners.sh -r xs -d /local/ci-runner -n 6
```

在 Node 服务器上：
```shell
~/xstop \
RUNNER_URL="https://github.com/OpenXiangShan/XiangShan" \
RUNNER_TOKEN="<token_from_github_new_self-hosted_runner_page>" \
RUNNER_LABELS="bosc,node" \
RUNNER_FILE=~/actions-runner-linux-x64-2.333.0.tar.gz \
~/env-scripts/ci-runner/create_runners.sh -r xs -d /home/cirunner -n 10
```

```shell
~/xstop \
RUNNER_URL="https://github.com/OpenXiangShan/XiangShan" \
RUNNER_TOKEN="<token_from_github_new_self-hosted_runner_page>" \
RUNNER_LABELS="eda,perf,node" \
RUNNER_FILE=~/actions-runner-linux-x64-2.333.0.tar.gz \
~/env-scripts/ci-runner/create_runners.sh -r xs-eda -d $HOME/ci-runner-xs-eda -n 4
```

## 批量启动 runners
`start_runners.sh` 脚本用于批量启动 self-hosted runner，它可以创建 tmux 会话（Session）和一系列窗格（Pane），并在每个窗格中启动一个 Runner 进程。

### 实例
在 Open 服务器上：
```shell
~/xstop ~/env-scripts/ci-runner/start_runners.sh -r xs -d /local/ci-runner -n 6
```
在 Node 服务器上：
```shell
~/xstop ~/env-scripts/ci-runner/start_runners.sh -r xs -d /home/cirunner -n 10
~/xstop ~/env-scripts/ci-runner/start_runners.sh -r xs-eda -d $HOME/ci-runner-xs-eda -n 4
```


## 批量关闭 runners
`stop_runners.sh` 脚本用于批量关闭 self-hosted runner，它可以为指定 Runner 系列的 tmux 窗格逐个发送 `Ctrl-C` 终止 Runner 进程，并关闭对应的 tmux 会话。

### 实例
在 Open 服务器上：
```shell
~/xstop ~/env-scripts/ci-runner/stop_runners.sh -r xs -d /local/ci-runner -n 6
```
在 Node 服务器上：
```shell
~/xstop ~/env-scripts/ci-runner/stop_runners.sh -r xs -d /home/cirunner -n 10
~/xstop ~/env-scripts/ci-runner/stop_runners.sh -r xs-eda -d $HOME/ci-runner-xs-eda -n 4
```

## 批量更新 runners
`update_runners_safe.sh` 脚本用于手动更新 self-hosted runner。需要下载 Runner Package 并将地址设为 `RUNNER_FILE` 环境变量。

不建议直接使用 `update_runners.sh`，其会强制对 runner 做更新，可能会中断正在运行的 CI 任务。`_safe` 版本会首先对 tmux session 进行检查，逐渐将所有处于 idle 状态的 runner 停止，直至所有 runner 都停止后，调用 `update_runners.sh` 进行更新，并自动调用 `start_runners.sh` 重启 runner。

建议配合 tmux 使用 `update_runners_safe.sh`，因为它可能会等待很久才能等到所有 runner 都 idle。

建议不要同时对所有 CI 服务器进行更新，这会导致更新期间可用的 runner 数量过少。

### 实例
在 Open 服务器上：
```shell
tmux create-session -s runner-update
RUNNER_FILE=$HOME/actions-runner-linux-x64-2.333.0.tar.gz \
~/env-scripts/ci-runner/update_runners_safe.sh -r xs -d /local/ci-runner -n 6
```
在 Node 服务器上：
```shell
tmux create-session -s runner-update
RUNNER_FILE=$HOME/actions-runner-linux-x64-2.333.0.tar.gz \
~/env-scripts/ci-runner/update_runners_safe.sh -r xs -d /home/cirunner -n 10
```
