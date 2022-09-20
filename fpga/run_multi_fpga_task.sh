# python3 fpga-autorun-v2.py -F "116 117" -L gcc-list.txt -B vnh-0917 -S xsbins50m-9-md5

python3 fpga-autorun-v2.py -F "116 117 120 122" -L error-list.txt -B vnh0919 -S xsbins50m-bk-md5 -M oldspec-1 -C
python3 fpga-autorun-v2.py -F "116 117 120 122" -L error-list.txt -B vnh0919 -S xsbins50m-9-md5 -M newspec-1 -C
python3 fpga-autorun-v2.py -F "116 117 120 122" -L error-list.txt -B vnh0919 -S xsbins50m-bk-md5 -M oldspec-2 -C
python3 fpga-autorun-v2.py -F "116 117 120 122" -L error-list.txt -B vnh0919 -S xsbins50m-9-md5 -M newspec-2 -C
python3 fpga-autorun-v2.py -F "116 117 120 122" -L error-list.txt -B vnh0919 -S xsbins50m-bk-md5 -M oldspec-3 -C
python3 fpga-autorun-v2.py -F "116 117 120 122" -L error-list.txt -B vnh0919 -S xsbins50m-9-md5 -M newspec-3 -C
