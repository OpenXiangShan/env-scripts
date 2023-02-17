
import sys
import os


log_old_path = sys.argv[1]
log_new_path = sys.argv[2]

output_path = sys.argv[3]

print(os.listdir(log_old_path))
print(os.listdir(log_new_path))

old_list = os.listdir(log_old_path)
new_list = os.listdir(log_new_path)

os.system(f"mkdir -p {output_path}")
for test in new_list:
  if test not in old_list:
    print(f"$test is not found in $log_old_path")
    continue
  test_name = test.split(" ")[-1].split(".")[0]
  print(test_name)
  new_test = log_new_path + "/" + test
  old_test = log_old_path + "/" + test

  cmd = f"python3 perf.py \'{old_test}\' \'{new_test}\' -o \'{output_path+test_name}.csv\'"
  #print(cmd)
  os.system(cmd)
