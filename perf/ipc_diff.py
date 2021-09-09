import sys
import glob

def get_ipc(filename, instrCnt = 20000000):
    clock_cycle = -2
    icount = -2
    ipc = -1
    with open(filename, "r") as f:
        for line in f.readlines():
            if "ctrlBlock.roq: clock_cycle" in line:
                if clock_cycle == -2:
                    clock_cycle = -1
                else:
                    clock_cycle = int(line.split(' ')[-1])
            if "ctrlBlock.roq: commitInstr," in line:
                if icount == -2:
                    icount = -1
                else:
                    icount = int(line.split(' ')[-1])
                    if abs(icount - instrCnt) > (instrCnt * 0.01):
                        print(f"{filename}: instrCnt mismatch [{icount} <-> {instrCnt}]")
                        icount = -2
    if icount > 0 and clock_cycle > 0:
        ipc = icount * 1.0 / clock_cycle
    return ipc

def get_ipc_map(base_dir):
    files = [f for f in glob.glob(base_dir + "/**/simulator_err.txt", recursive=True)] + [f for f in glob.glob(base_dir + "/**/main_err.txt", recursive=True)]
    imap = {}
    for f in files:
        path_split = f.split("/")
        k = path_split[-3] + "_" + path_split[-2]
        v = get_ipc(f)
        if v != -1:
            imap[k] = v
    return imap

def diff(new_base_dir, ref_base_dir):
    new_map = get_ipc_map(new_base_dir)
    ref_map = get_ipc_map(ref_base_dir)
    inc_lst = []
    print(f"{'worloads':<32}: {'diff_ipc':>8} {'ref_ipc':>8} {'inc_rate':>9}")
    for (k, v) in new_map.items():
        if k in ref_map:
            ref_v = ref_map[k]
            inc = ((v - ref_v) / ref_v) * 100
            inc_lst.append(inc)
            print(f"{k:<32}: {v:>8.4f} {ref_map[k]:>8.4f} {inc:>8.4f}%")
    avg_inc = sum(inc_lst) / len(inc_lst)
    print(f"{len(inc_lst)} points in total, avg_inc: {avg_inc}%")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"usage: {sys.argv[0]} new_result_dir ref_result_dir")
        sys.exit(-1)
    diff(sys.argv[1], sys.argv[2])
