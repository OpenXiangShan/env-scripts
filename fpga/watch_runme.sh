# Usage: zsh watch_runme.sh bitgen-path
bs_path=$1
bs_begin_time=$(date)
bs_log=$bs_path/xs_nanhu/xs_nanhu.runs/impl_1/runme.log
end_mw="write_bitstream completed successfully"
error_mw="write_bitstream failed"
exit_mw="Exiting Vivado at"

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
    exit 0
  elif [ -f $bs_log ] && [ $(grep -c $error_mw $bs_log) -eq 1 ]; then
    echo "End   time: $(date)"
    echo $error_mw
    exit 1
  elif [ -f $bs_log ] && [ $(grep -c $exit_mw $bs_log) -eq 1 ]; then
    echo "End   time: $(date)"
    echo $exit_mw
    echo "Vivado exit with unexpected errors, please check $bs_log"
    exit 1
  elif [ -f $bs_log ]; then
    echo -ne "Now   time: $(date) & runme.log exists\r"
    sleep 5
  else
    echo -ne "Now   time: $(date) & runme.log not exists\r"
    sleep 5
  fi
done
