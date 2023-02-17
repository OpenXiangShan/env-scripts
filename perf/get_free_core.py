from cpuutil import get_free_cores
import sys

if __name__ == "__main__":
  print(get_free_cores(int(sys.argv[1])))