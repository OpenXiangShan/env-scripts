include Makefile.nanhu

PRJ ?=

.PHONY: bitstream

bitstream:
	vivado -mode batch $(PRJ) -source ./src/tcl/gen_bitstream.tcl
