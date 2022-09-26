# Usage: zsh watch_runme.sh bitgen-path
bs_path=$1
bs_begin_time=$(date)
bs_log=$bs_path/xs_nanhu/xs_nanhu.runs/impl_1/runme.log
end_mw="write_bitstream completed successfully"

if [ ! -d $bs_path/xs_nanhu ]; then
  echo "error bitgen path"
  exit
fi

echo "watch log: $bs_log"
echo "Begin time: $bs_begin_time"

while true
do
  if [ -f $bs_log ] && [ $(grep -c $end_mw $bs_log) -eq 1 ]; then
    echo "End   time: $(date)"
    echo $end_mw
    break
  else
    echo -ne "Now   time: $(date)\r"
    sleep 1
  fi
done
