# Github 自托管运行器 维护脚本

此文件夹包含一系列用于维护 Self-hosted Runner 的妙妙脚本，能够有效降低维护 runner 的工作强度，提升幸福感。

## 创建 runners
`create_runners.sh` 脚本用于创建 self-hosted runner。需要根据 GitHub 上 Add new self-hosted runner 页面的指示设置环境变量 `RUNNER_URL`、`RUNNER_TOKEN`。需要下载 Runner Package 并将地址设为 `RUNNER_FILE` 环境变量。需要根据需要设置 `RUNNER_LABELS` 环境变量（逗号分隔）。

> 这里使用环境变量而不是参数，是为了让 `config.sh` 脚本统一处理所有脚本的参数。

### 示例
设置环境变量。
```shell
export RUNNER_URL="https://github.com/OpenXiangShan/XiangShan"
export RUNNER_TOKEN="<token_from_github_new_self-hosted_runner_page>"
export RUNNER_LABELS="bosc,open"
export RUNNER_FILE=~/actions-runner-linux-x64-2.329.0.tar.gz
```
在 Open 服务器上：
```shell
~/xstop ~/env-scripts/ci-runner/create_runners.sh -r xs -d /local/ci-runner -n 6
```
在 Node 服务器上：
```shell
~/xstop ~/env-scripts/ci-runner/create_runners.sh -r xs -d /home/cirunner -n 10
~/xstop ~/env-scripts/ci-runner/create_runners.sh -r xs-eda -d $HOME/ci-runner-xs-eda -n 4
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

