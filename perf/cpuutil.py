import psutil
import os

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

  for proc in psutil.process_iter(['pid', 'name', 'cpu_affinity']):
    try:
      affinity = proc.info['cpu_affinity']
      #two methods to judge
      #but there are lots of stuck emu processes, `judge1` may miss the real free cores 
      # judge1 = affinity and max(affinity) < cpu_count and "emu" in proc.info['name']
      judge2 = affinity and max(affinity) < cpu_count and sum(core_usage[i] for i in affinity) > percpu_use_thres * len(affinity)
      if judge2:
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
      tuple[bool, int, int, int]: is success, memory node, start_core, end_core
  """
  # SMT is not allowed
  num_core = psutil.cpu_count(logical=False)
  core_usage = psutil.cpu_percent(interval=5, percpu=True)
  unset_cores = get_unset_cores(num_core, core_usage)
  # print(f"Core Count: {num_core}\nCore Usage: {core_usage}\nUnset Cores: {unset_cores}")
  num_window = num_core // n
  numa_node = numa_count() # default 2
  for i in range(num_window):
    window_usage = core_usage[i * n : i * n + n]
    # print(f"Window{i} Usage: ", window_usage)
    # 5950x only allow 1 emu
    cond1 = sum(window_usage) < percpu_use_thres * n
    cond2 = True not in map(lambda x: x > 80, window_usage if is_epyc() else core_usage)
    cond3 = set(window_usage).issubset(unset_cores)
    if cond1 and cond2 and cond3:
      # return (Success?, memory node, start_core, end_core)
      return (True, ((i * n) % num_core)// (num_core//numa_node), i * n, i * n + n - 1, num_core)
  return (False, 0, 0, 0, num_core)
  # print(f"No free {n} cores found. CPU usage: {core_usage}\n")

def is_epyc():
  num_core = psutil.cpu_count(logical=False)
  return num_core > 16
