# Board AXI widths are independent of CPU XLEN.
set cpu_axi_data_width 256
set cpu_axi_addr_width 40
if {$cpu in {nutshell boom}} {
  set cpu_axi_data_width 64
  set cpu_axi_addr_width 33
}
set cpu_axi_defines [list \
  CPU_AXI_DATA_WIDTH=$cpu_axi_data_width \
  CPU_AXI_ADDR_WIDTH=$cpu_axi_addr_width]
