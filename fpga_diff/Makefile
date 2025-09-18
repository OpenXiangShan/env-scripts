PRJ ?=

CORE_DIR ?= ""

# Supported CPU parameters:
#   kmh
#   nutshell
CPU ?= ""

.PHONY: bitstream vivado

bitstream:
	vivado -mode batch $(PRJ) -source ./src/tcl/gen_bitstream.tcl

update_core_flist:
	find "$(CORE_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./core_flist.awk > ./src/tcl/cpu_files.tcl

vivado:
	vivado -mode batch -source src/tcl/common/xs_uart.tcl -tclargs --cpu $(CPU) --project_name fpga_$(CPU)

add_sys_option:
	sed -i "s/reg \[63:0\] ram \[6143:0\];/\(\* ram_style = \"ultra\" \*\)\n \treg \[63:0\] ram \[6143:0\];/g" $(CORE_DIR)/array_*.v