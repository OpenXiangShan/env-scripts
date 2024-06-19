
import os
import sys
import subprocess
import signal
import time
import getpass
import ast
import psutil

class Server(object):
  def __init__(self, ip):
    # if not is_epyc():
    #   print(f"Only epyc is supported. {ip} is not epyc")
    #   sys.exit()
    self.ip = ip
    self.username = getpass.getuser()
    self.failed_tests = []
    self.success_tests = []
    self.pending_proc = []
    self.remote_cmd = ["ssh", f"{self.username}@{self.ip}"]

  def pending_tests(self):
    self.check_running()
    tests = []
    for proc in self.pending_proc:
      tests.append(proc[0])
    return tests

  def numactl(self, cmd, mem, start, end):
    if not self.is_epyc():
      return cmd
    return ["numactl", "-m", f"{str(mem)}", "-C", f"{start}-{end}"] + cmd

  def remote_get_free_cores(self, threads):
    pwd = os.path.dirname(os.path.abspath(__file__))
    cmd = ["python3", f"{pwd}/get_free_core.py", f"{threads}"]
    ssh_cmd_str = " ".join(self.remote_cmd + cmd)
    # print(ssh_cmd_str)
    proc = os.popen(ssh_cmd_str)
    result = proc.read().strip()
    result = ast.literal_eval(result)
    return result

  def assign(self, test_name, cmd, threads, xs_path, stdout_file, stderr_file):
    self.check_running()
    (free, mem, start, end, server_cores) = self.remote_get_free_cores(threads)
    # print(free, mem, start, end, server_cores)
    if not free:
      return False
    for running in self.pending_proc:
      pending_cores = running[2]
      if (start, end) == pending_cores:
        return False
    run_cmd = self.numactl(cmd, mem, start, end)
    run_cmd = self.remote_cmd + [f"NOOP_HOME={xs_path}"] + run_cmd
    os.system("date")
    print(f"{' '.join(run_cmd)}")

    with open(stdout_file, "w") as stdout, open(stderr_file, "w") as stderr:
      proc = subprocess.Popen(run_cmd, stdout=stdout, stderr=stderr, preexec_fn=os.setsid)
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

  def is_epyc(self):
    num_core = psutil.cpu_count(logical=False)
    return num_core > 16
