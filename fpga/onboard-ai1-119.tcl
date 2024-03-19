# param
# first : xiangshan's bit
# second : workload's data.txt
set xs_path [lindex $argv 0]
puts "xiangshan path:"
puts $xs_path
set bit_path $xs_path/xs_fpga_top_debug.bit
set ltx_path $xs_path/xs_fpga_top_debug.ltx
puts "bit_path:"
puts $bit_path
puts "ltx_path:"
puts $ltx_path

open_hw_manager
connect_hw_server -url localhost:3121 -allow_non_jtag
current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/00001ce00adf01]
set_property PARAM.FREQUENCY 12000000 [get_hw_targets */xilinx_tcf/Xilinx/00001ce00adf01]
open_hw_target
set_property PROBES.FILE $ltx_path [get_hw_devices xcvu19p_0]
set_property FULL_PROBES.FILE $ltx_path [get_hw_devices xcvu19p_0]
set_property PROGRAM.FILE $bit_path [get_hw_devices xcvu19p_0]
program_hw_devices [get_hw_devices xcvu19p_0]
refresh_hw_device [lindex [get_hw_devices xcvu19p_0] 0]
display_hw_ila_data [ get_hw_ila_data hw_ila_data_1 -of_objects [get_hw_ilas -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"xs_soc_debug/U_JTAG_DDR_SUBSYS/jtag_ddr_subsys_i/jtag_maxi_ila"}]]
display_hw_ila_data [ get_hw_ila_data hw_ila_data_2 -of_objects [get_hw_ilas -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_ila_0"}]]
startgroup
set_property OUTPUT_VALUE 0 [get_hw_probes vio_sw6 -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
commit_hw_vio [get_hw_probes {vio_sw6} -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
endgroup
after 500
# hold 500ms
startgroup
set_property OUTPUT_VALUE 1 [get_hw_probes vio_sw6 -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
commit_hw_vio [get_hw_probes {vio_sw6} -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
endgroup
after 500
startgroup
set_property OUTPUT_VALUE 0 [get_hw_probes vio_sw4 -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
commit_hw_vio [get_hw_probes {vio_sw4} -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
endgroup
after 500
startgroup
set_property OUTPUT_VALUE 1 [get_hw_probes vio_sw4 -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
commit_hw_vio [get_hw_probes {vio_sw4} -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
endgroup
after 500

# source /nfs/home/share/fpga/0210xsmini/xs-4bin/jtagmv.tcl
puts "workload path:"
puts [lindex $argv 1]
set file_name [lindex $argv 1]
proc write_to_ddr {fn} { 
  set fdata [open $fn r]
  while {[eof $fdata] != 1} {
    gets $fdata aline
    set AddrString [lindex $aline 0] 
    gets $fdata dline
    set DataString [lindex $dline 0] 
    create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address $AddrString -data $DataString -len 256 -burst INCR -size 32 -type write
    run_hw_axi wr_txn
    delete_hw_axi_txn wr_txn
  }
  close $fdata
}

if {[catch {[write_to_ddr $file_name]} errmsg]} {
  puts "ErrorMsg: $errmsg"
}
puts "After Error"
# after 5000 
# foreach rline $lines { 
#     set Raddr [string range [lindex $rline 0] 0 7]
#     create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address $Raddr -len 4 -size 32 -type read
#     run_hw_axi rd_txn
#     delete_hw_axi_txn rd_txn
# }

# source reset.tcl
startgroup
set_property OUTPUT_VALUE 0 [get_hw_probes vio_sw5 -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
commit_hw_vio [get_hw_probes {vio_sw5} -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
endgroup
after 500
#hold 500ms
startgroup
set_property OUTPUT_VALUE 1 [get_hw_probes vio_sw5 -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
commit_hw_vio [get_hw_probes {vio_sw5} -of_objects [get_hw_vios -of_objects [get_hw_devices xcvu19p_0] -filter {CELL_NAME=~"u_vio"}]]
endgroup
after 500
