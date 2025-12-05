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

synth:
	vivado -mode batch -source ./tools/gen_synth.tcl -tclargs $(PRJ)

bitstream:
	vivado -mode batch -source ./tools/gen_bitstream.tcl -tclargs $(PRJ)

update_core_flist:
	rm -rf $(CORE_DIR)/rtl/verification
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
	sed -i "s/reg \(\[[0-9]*:[0-9]*\]\) ram \[\([4-9][0-9]\{3,\}\|[1-9][0-9]\{4,\}\):0\];/(\* ram_style = \"ultra\" \*)\treg \1 ram \[\2:0\];/g" $(CORE_DIR)/rtl/array_*.v

get_impl_log:
	cat fpga_$(CPU)/fpga_$(CPU).runs/impl_1/runme.log

get_synth_log:
	cat fpga_$(CPU)/fpga_$(CPU).runs/synth_1/runme.log
