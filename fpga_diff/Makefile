PRJ ?=

CORE_DIR ?= ""
FPGA_BIT_HOME ?=
WORKLOAD ?=
# Supported CPU parameters:
#   kmh
#   nutshell
#   nanhu
CPU ?= ""

.PHONY: bitstream vivado

bitstream:
	vivado -mode batch $(PRJ) -source ./tools/gen_bitstream.tcl

update_core_flist:
    rm -rf $(CORE_DIR)/build/rtl/verification
	find "$(CORE_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./core_flist.awk > ./src/tcl/cpu_files.tcl

vivado:
	vivado -mode batch -source src/tcl/common/xs_uart.tcl -tclargs --cpu $(CPU) --project_name fpga_$(CPU)

write_bitstream:
	sh tools/pcie-remove.sh
	vivado -mode tcl -source tools/write_bitstream.tcl -tclargs $(FPGA_BIT_HOME)
	sh tools/pcie-rescan.sh

write_jtag_ddr:
	vivado -mode tcl -source tools/reset_ddr.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx
	vivado -mode tcl -source tools/jtag_write_ddr.tcl -tclargs $(WORKLOAD)

reset_cpu:
	vivado -mode tcl -source tools/reset_cpu.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

add_sys_option:
	sed -i "s/reg \[63:0\] ram \[6143:0\];/\(\* ram_style = \"ultra\" \*\)\n \treg \[63:0\] ram \[6143:0\];/g" $(CORE_DIR)/array_*.v