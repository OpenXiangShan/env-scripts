import json
import os
import psutil
import subprocess
import signal
import sys
import time
from numa import info
from pathlib import Path
from multiprocessing import Process, Queue
from tqdm import tqdm

################################################################################
# Note: all subprocess will be killed if the main process were inturrpted
################################################################################

################################################################################
# please set your configurations here
# total threads will be used = workers * emu_threads
# the last char of 'output_dir' and 'checkpoint_base_dir' must be '/'
################################################################################

config = {
  "workers" : 12, # how many emu you want run in parallel
  "start_cpu_id" : 128, # start cpu id which will be used in numactl
  "emu" : "./emu", # path to emu
  "emu_threads" : 8, # num of emu threads
  "emu_args" : ["-I", "100000000", "-W", "50000000"], # extra emu args
  "output_dir" : "./output/",
  "checkpoint_config" : "./simpoints06.json",
  "checkpoint_base_dir" : "/home53/zyy/expri_results/nemu_take_simpoint_cpt_06/"
}

################################################################################
# do not modify the following code
################################################################################

def get_numa_node(startId, endId):
  nodes = info.numa_hardware_info()['node_cpu_info']
  ret = -1
  cpu_set = set([x for x in range(startId, endId)])
  for (nodeId, cpus) in nodes.items():
    if cpu_set.issubset(set(cpus)):
      ret = nodeId
      break
  return ret

def check_numa():
  assert(info.numa_available())
  numa_nodes = info.numa_hardware_info()['node_cpu_info']
  start_cpu_id = config['start_cpu_id']
  num_workers = config['workers']
  emu_threads = config['emu_threads']
  for i in range(0, num_workers):
    start = start_cpu_id + i * emu_threads
    end = start + emu_threads
    node = get_numa_node(start, end)
    assert node > -1, (f"cpus [{start}-{end}] can't be allocated in one numa node!")

def check_configuration():
  assert(config['output_dir'][-1] == '/')
  assert(config['checkpoint_base_dir'][-1] == '/')
  check_numa()

class Checkpoint:
  def __init__(self, cpt_dir, basename, instrnum, weight, gzname = ""):
    self.cpt_dir = cpt_dir
    self.basename = basename
    self.instrnum = instrnum
    self.weight = weight
    self.gzname = gzname

  def get_dir(self):
    return self.cpt_dir + self.basename + "_" + self.instrnum + "_" + str(self.weight) + "/0"

  def get_path(self):
    return self.get_dir() + "/" + self.gzname

  def output_dir(self, prefix = ""):
    return prefix + self.basename + "/" + self.instrnum

  def __str__(self):
    return self.get_path()

class Worker(Process):
  def __init__(self, workerId, tasks, threads, output_dir, emu, emu_args, queue):
    super(Worker, self).__init__()
    self.workerId = workerId
    self.tasks = tasks
    start_cpu_id = config["start_cpu_id"]
    self.start_cpu_id = start_cpu_id + workerId * threads
    self.end_cpu_id = self.start_cpu_id + threads - 1
    self.output_dir = output_dir
    self.emu = emu
    self.emu_args = emu_args
    self.queue = queue

  def run(self):
    for task in self.tasks:
      task_output_dir = task.output_dir(self.output_dir)
      Path(task_output_dir).mkdir(parents = True, exist_ok = False)
      out = open(task_output_dir + "/simulator_out.txt", "w+")
      err = open(task_output_dir + "/simulator_err.txt", "w+")
      # 'end + 1' because [start, end)
      numa_node = get_numa_node(self.start_cpu_id, self.end_cpu_id + 1)
      arglist = "numactl -m {0} -C {1}-{2} {3} -i {4}".format(
        numa_node, self.start_cpu_id, self.end_cpu_id, self.emu, task.get_path()
      ).split(" ")
      arglist += self.emu_args
      subprocess.run(["echo"] + arglist, stdout = out)
      retcode = subprocess.run(arglist, stdout = out, stderr = err).returncode
      if retcode != 0:
        subprocess.run(["touch", task_output_dir + "/aborted"])
      else:
        subprocess.run(["touch", task_output_dir + "/completed"])
      self.queue.put(str(task))

def get_checkpoints(name, cfg):
  checkpoints = []
  checkpoint_base_dir = config["checkpoint_base_dir"]
  for k,v in cfg.items():
    cpt = Checkpoint(checkpoint_base_dir, name, k, v)
    checkpoint_dir = cpt.get_dir()
    files = os.listdir(checkpoint_dir)
    assert(len(files) == 1)
    cpt.gzname = files[0]
    checkpoints.append(cpt)
  return checkpoints

def kill_child_process(parent_pid, sig=signal.SIGTERM):
  try:
    parent = psutil.Process(parent_pid)
  except psutil.NoSuchProcess:
    return
  children = parent.children(recursive = True)
  for process in children:
    process.send_signal(sig)

def run():
  # kill subprocess if inturrpted
  pid = os.getpid()
  def stop_signal_handler(signum, frame):
    if(os.getpid() == pid):
        print("Killing proc {0} and its children...".format(pid))
        kill_child_process(pid)
    exit(signum)
  signal.signal(signal.SIGTERM, stop_signal_handler)
  signal.signal(signal.SIGINT, stop_signal_handler)
  # load checkpoints
  checkpoint_config = {}
  checkpoint_config_path = config["checkpoint_config"]
  with open(checkpoint_config_path) as f:
    checkpoint_config = json.load(f)
  checkpoints = []
  for k,v in checkpoint_config.items():
    checkpoints += get_checkpoints(k, v)
  # create workers
  num_workers = config["workers"]
  tasks_list = [checkpoints[i::num_workers] for i in range(num_workers)]
  emu_threads = config["emu_threads"]
  output_dir = config["output_dir"]
  emu_path = config["emu"]
  emu_args = config["emu_args"]
  workers = []
  queue = Queue()
  for i in range(num_workers):
    worker = Worker(i, tasks_list[i], emu_threads, output_dir, emu_path, emu_args, queue)
    workers.append(worker)
    worker.start()

  pbar = tqdm(total = len(checkpoints))
  cnt = 0
  while cnt < len(checkpoints):
    t = queue.get()
    cnt += 1
    pbar.update(1)

  for worker in workers:
    worker.join()

if __name__ == '__main__':
  check_configuration()
  run()
