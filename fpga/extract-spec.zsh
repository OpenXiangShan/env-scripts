log_tag=$1
python3 extract_spec.py /nfs/home/share/fpga/minicom-output/$log_tag* | tee $log_tag.csv | wc -l
