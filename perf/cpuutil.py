import psutil

def get_free_cores(n):
  # SMT is not allowed
  num_core = psutil.cpu_count(logical=False)
  core_usage = psutil.cpu_percent(interval=5, percpu=True)
  # print("Core Usage: ",core_uage)
  num_window = num_core // n
  for i in range(num_window):
    window_usage = core_usage[i * n : i * n + n]
    # print(f"Window{i} Usage: ", window_usage)
    # 5950x only allow 1 emu
    free = sum(window_usage) < 30 * n and True not in map(lambda x: x > 80, window_usage if is_epyc() else core_usage)
    if free:
      # return (Success?, memory node, start_core, end_core)
      return (True, ((i * n) % 128)// 64, i * n, i * n + n - 1)
  return (False, 0, 0, 0)
  # print(f"No free {n} cores found. CPU usage: {core_usage}\n")

def is_epyc():
  # has 128 core? equal to is_epyc now.
  num_core = psutil.cpu_count(logical=False)
  return (num_core == 128)
