# Param:
# First: bin path (dir)
# Second: data path (dir)

import sys
import os

bin_dir = sys.argv[1]
data_dir = sys.argv[2]

spec_list = os.listdir(bin_dir)
print(spec_list)

os.system(f"mkdir -p {data_dir}")
for spec_bin in spec_list:
  spec_name = spec_bin[:-4]
  md = f"mkdir -p {data_dir}/{spec_name}"
  tran = f"/nfs/home/share/fpga/bin2fpgadata/bin2fpgadata -i {bin_dir}/{spec_bin} -o {data_dir}/{spec_name}/data.txt"
  cmd = md + " && " + tran
  print(cmd)
  os.system(f"{cmd}")
