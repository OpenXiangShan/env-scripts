import sys
import glob

def get_ipc(filename, instrCnt = 100000000):
    ipc = -1
    with open(filename, "r") as f:
        for line in f.readlines():
            if "IPC" in line:
                words = line.split(" ")
                icount = int(words[2].replace(",", ""))
                if abs(icount - instrCnt) > (0.05 * instrCnt):
                    print(f"{filename} instrCnt mismatch: [{icount}<->{instrCnt}]")
                    break
                ipc = float(words[-1])
                break
    return ipc

def get_ipc_map(base_dir):
    files = [f for f in glob.glob(base_dir + "/**/simulator_out.txt", recursive=True)]
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
    for (k, v) in new_map.items():
        if k in ref_map:
            ref_v = ref_map[k]
            inc = ((v - ref_v) / ref_v) * 100
            inc_lst.append(inc)
            print(f"{k}: {v} {ref_map[k]} {inc}%")
    avg_inc = sum(inc_lst) / len(inc_lst)
    print(f"avg_inc: {avg_inc}%")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"usage: {sys.argv[0]} new_result_dir ref_result_dir")
        sys.exit(-1)
    diff(sys.argv[1], sys.argv[2])
