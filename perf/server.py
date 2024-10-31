
import os
import sys
import subprocess
import signal
import time
import getpass
import ast
import psutil
import requests
from sshconf import read_ssh_config
import os.path as osp
import random
import numpy as np


class Server(object):
  glance_port = 61208
  def __init__(self, node_name):
    ssh_conf_file = osp.expanduser('~/.ssh/config')
    openssh_config_exist = osp.exists(ssh_conf_file)
    if openssh_config_exist:
      ssh_conf = read_ssh_config(ssh_conf_file)
      host_conf = ssh_conf.host(node_name)
      found_node_name_in_ssh = 'hostname' in host_conf
    else:
      found_node_name_in_ssh = False

    if openssh_config_exist and found_node_name_in_ssh:
      print(host_conf)
      self.ip = host_conf['hostname']
      self.username = getpass.getuser()
      self.remote_cmd = ["ssh", node_name]
    else:
      self.ip = node_name
      self.username = getpass.getuser()
      self.remote_cmd = ["ssh", f"{self.username}@{self.ip}"]

    self.failed_tests = []
    self.success_tests = []
    self.pending_proc = []

  def pending_tests(self):
    self.check_running()
    tests = []
    for proc in self.pending_proc:
      tests.append(proc[0])
    return tests

  def numactl(self, cmd, mem, start, end, num_cores):
    if not self.is_epyc(num_cores):
      return cmd
    return ["numactl", "-m", f"{str(mem)}", "-C", f"{start}-{end}"] + cmd

  def remote_get_free_cores_ssh(self, threads):
    pwd = os.path.dirname(os.path.abspath(__file__))
    cmd = ["python3", f"{pwd}/get_free_core.py", f"{threads}"]
    ssh_cmd_str = " ".join(self.remote_cmd + cmd)
    # print(ssh_cmd_str)
    proc = os.popen(ssh_cmd_str)
    result = proc.read().strip()
    if len(result)==0:
      return "(False, 0, 0, 0, 0)"
    result = ast.literal_eval(result)
    # (free, mem, start, end, server_cores)
    return result

  def remote_get_free_cores_glance(self, threads):
    # curl http://localhost:61208/api/4/core
    # return: {"log": 4, "phys": 2}
    print("url:", f"http://{self.ip}:{Server.glance_port}/api/4/core")
    core_info = requests.get(f"http://{self.ip}:{Server.glance_port}/api/4/core").json()
    num_phys_cores = core_info['phys']
    num_log_cores = core_info['log']
    has_smt = num_phys_cores*2 == num_log_cores

    num_windows = num_phys_cores // threads
    rand_windows = np.random.permutation(num_windows)  # use random windows to avoid unexpected waiting on a free window
    window_usage_thres = 20 * threads

    per_core_info = requests.get(f"http://{self.ip}:{Server.glance_port}/api/4/percpu").json()
    # curl http://localhost:61208/api/4/percpu
    # return:
    # [{"cpu_number": 0,
    #   ....
    #   "idle": 26.2,
    #   ....
    #   "system": 4.4,
    #   "total": 73.8,
    #   "user": 68.0},
    # {"cpu_number": 1,
    #   ....}
    # ]

    for w in rand_windows:
      window_usage = 0
      for i in range(threads):
        core_id = w * threads + i
        window_usage += per_core_info[core_id]['total']
        if has_smt:
          smt_sibling = core_id + num_phys_cores
          window_usage += per_core_info[smt_sibling]['total']
      start = w * threads
      end = w * threads + threads - 1
      if window_usage < window_usage_thres:
        # always assume numa with 2 cpus
        numa_node = int(start >= (num_phys_cores // 2))
        return (True, numa_node, start, end, num_phys_cores)
    return (False, 0, 0, 0, num_phys_cores)

  def remote_get_free_cores(self, threads):
    return self.remote_get_free_cores_ssh(threads)

  def assign(self, test_name, cmd, threads, xs_path, stdout_file, stderr_file, dry_run=False, verbose=True):
    self.check_running()
    (free, mem, start, end, server_cores) = self.remote_get_free_cores(threads)
    # print(free, mem, start, end, server_cores)
    if not free:
      return False
    for running in self.pending_proc:
      pending_cores = running[2]
      if (start, end) == pending_cores:
        return False
    if dry_run:
      cmd = ["hostname;", "sleep", "60"]
    run_cmd = self.numactl(cmd, mem, start, end, server_cores)
    run_cmd = self.remote_cmd + [f"NOOP_HOME={xs_path}"] + run_cmd
    os.system("date")
    if verbose:
      print(f"{' '.join(run_cmd)}")

    with open(stdout_file, "w") as stdout, open(stderr_file, "w") as stderr:
      proc = subprocess.Popen(run_cmd, stdout=stdout, stderr=stderr, preexec_fn=os.setsid)
      if not dry_run:
        time.sleep(1)
    self.pending_proc.append((test_name, proc, (start, end)))
    if (len(self.pending_proc) > (server_cores // threads)):
      print(f"Server {self.ip} has more than {len(self.pending_proc)} proc. Is it OK?")
    return True

  def check_running(self):
    for running in self.pending_proc:
      test = running[0]
      proc = running[1]
      result = proc.poll()
      # print(f"Check {test} {result}")
      if result is not None:
        # finished
        self.pending_proc.remove(running)
        if result != 0:
          print(f"[ERROR] {test} exist with code {proc.returncode}")
          self.failed_tests.append(test)
        else:
          self.success_tests.append(test)

  def is_free(self):
    self.check_running()
    return (len(self.pending_proc) == 0)

  def stop(self):
    # for proc in self.pending_proc:
      # os.killpg(os.getpgid(proc[1].pid), signal.SIGINT)
    # kill emu by ssh kill 'emu.pid'
    pwd = os.path.dirname(os.path.abspath(__file__))
    os.popen(" ".join(self.remote_cmd) + f" python3 {pwd}/stop_emu.py")

  def is_epyc(self, num_cores):
    return num_cores > 16
