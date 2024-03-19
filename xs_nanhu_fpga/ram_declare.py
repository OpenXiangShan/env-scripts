#! /usr/bin/python3
import re
import sys

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("ERROR: ram_declare.py need a build path as input!")
        sys.exit(1)

    build_path = sys.argv[1]
    #change_list:     ram file              ram name             desired resource
    change_list = [["array_22_ext.v", "reg [63:0] ram [6143:0];", "ultra"]]
    for change in change_list:
        with open(build_path + "/" + change[0], "r") as f:
            lines = f.read()
            lines = lines.replace(change[1], '(* ram_style = "ultra" *)\n' + "\t" +  change[1])

        with open(build_path + "/" + change[0], "w") as f:
            f.write(lines)

