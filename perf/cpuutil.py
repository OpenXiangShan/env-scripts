import psutil
import os
import numpy as np

percpu_use_thres = 30

def numa_count():
  node_dir = "/sys/devices/system/node/"
  nodes = [node for node in os.listdir(node_dir) if node.startswith("node")]
  return len(nodes)

def get_unset_cores(cpu_count=None, core_usage=None) -> list[int]:
  """get unset cores.
  Parameters are passed in to reduce fetch time.

  Args:
      cpu_count (int, optional): the number of physical cores. Defaults to None.
      core_usage (list[float], optional): the usage of cores. Defaults to None.

  Returns:
      list[int]: the list of unset cores
  """
  #FIXME: SMT is not considered temporaryly
  if cpu_count is None:
    cpu_count = psutil.cpu_count(logical=False)
  if core_usage is None:
    core_usage = psutil.cpu_percent(interval=5, percpu=True)

  cpu_affinity_count = {i: 0 for i in range(cpu_count)}
  valid_list = ['running', 'disk-sleep', 'waking', 'waiting']
  for proc in psutil.process_iter(['pid', 'name', 'cpu_affinity', 'status']):
    try:
      affinity = proc.info['cpu_affinity']
      valid = proc.info['status'] in valid_list
      if affinity and max(affinity) < cpu_count and len(affinity) > 1 and valid:
        for cpu in affinity:
          cpu_affinity_count[cpu] += 1
    except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
      pass

  unset_cores = [cpu for cpu, count in cpu_affinity_count.items() if count == 0]
  return unset_cores

def get_free_cores(n):
  """get n consecutive free cores

  Args:
      n (int): threads you need

  Returns:
      tuple[bool, int, int, int, int]: is success, memory node, start_core, end_core, physical cores number
  """
  # SMT is not allowed
  num_core = psutil.cpu_count(logical=False)
  core_usage = psutil.cpu_percent(interval=5, percpu=True)
  unset_cores = get_unset_cores(num_core, core_usage)
  # print(f"Core Count: {num_core}\nCore Usage: {core_usage}\nUnset Cores: {unset_cores}")
  num_window = num_core // n
  numa_node = numa_count() # default 2
  # use random windows to avoid unexpected waiting on a free window
  rand_windows = np.random.permutation(num_window)
  for i in rand_windows:
    window_cores = range(i*n, i*n+n)
    window_usage = core_usage[i * n : i * n + n]
    # print(f"Window{i} Usage: ", window_usage)
    # 5950x only allow 1 emu

    #average unsage of window_cores less than percpu_use_thres
    cond1 = sum(window_usage) < percpu_use_thres * n
    #less than 1 core has high usage in window_cores
    cond2 = sum(map(lambda x: x > 80, window_usage if is_epyc() else core_usage)) < 1
    #window_cores is unset
    cond3 = set(window_cores).issubset(unset_cores)
    if cond1 and cond2 and cond3:
      # return (Success?, memory node, start_core, end_core)
      return (True, (int)(((i * n) % num_core)// (num_core//numa_node)), (int)(i * n), (int)(i * n + n - 1), num_core)
  return (False, 0, 0, 0, num_core)
  # print(f"No free {n} cores found. CPU usage: {core_usage}\n")

def is_epyc():
  num_core = psutil.cpu_count(logical=False)
  return num_core > 16
