# Ensure synthesis first
launch_runs synth_1 -jobs 16
wait_on_run synth_1

# Then run implementation through write_bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 16
wait_on_run impl_1

# Write bitstream
write_bitstream -force