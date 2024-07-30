import re
import json
import copy
import os

cpt_fmt="/nfs/home/share/liyanqin/perf-report/cr240523-master-2b16f0c2c/%s_%s_%s/simulator_out.txt"
json_path="/nfs/home/share/liyanqin/spec06_rv64gcb_O3_20m_gcc12.2.0-intFpcOff-jeMalloc/checkpoint-0-0-0/cluster-0-0.json"

data = {}
with open(json_path) as f:
    data = json.load(f)
res = copy.deepcopy(data)
for spec in data:
    for cpt in data[spec]["points"]:
        cpt_path=cpt_fmt%(spec, cpt, data[spec]["points"][cpt])
        res[spec]["points"][cpt]=-1
        finish=False
        if os.path.exists(cpt_path):
            with open(cpt_path) as f:
                for line in f:
                    match = re.search(r'Host time spent: (\d{1,3}(?:,\d{3})*)ms', line)
                    if "EXCEEDING CYCLE/INSTR LIMIT" in line or "GOOD TRAP" in line:
                        finish=True
                    if match is None:
                        match = re.search(r'Host time spent: (\d+)ms', line)
                    if match:
                        time_str = match.group(1)
                        time_num = int(time_str.replace(',',''))
                        res[spec]["points"][cpt]=time_num
        if not finish:
            res[spec]["points"][cpt]=-1
            print("%s_%s_%s ERROR", spec, cpt, data[spec]["points"][cpt])
#the time of checkpoint not finished needs to be manually modified
with open("./cluster-0-0-time.json", "w") as f:
    json.dump(res, f, indent=4)