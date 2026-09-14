ENV_SCRIPTS_HOME ?= $(CURDIR)

FPGA_BACKEND ?= $(if $(filter uvhs%,$(MAKECMDGOALS)),uvhs,vivado)
SUPPORTED_FPGA_BACKENDS := vivado uvhs
CORE_DIR ?=
RTL_INCLUDE ?=
FPGA_BIT_HOME ?=
FPGA_BIT_ARTIFACT_DIR ?=
WORKLOAD ?=
AXI_WIDTH ?= 64
NO_DIFF ?= 0
XDMA_LINK_WIDTH ?= X4
VIVADO_JOBS ?=
export XDMA_LINK_WIDTH VIVADO_JOBS NO_DIFF
FPGA_RUNTIME ?=
REMOTE_ENV ?= source ~/.bash_profile &&
BIND_UART ?= 1
# Supported CPU parameters:
#   kmh
#   nutshell
#   nanhu
CPU ?=
SUFFIX ?=
ifeq ($(NO_DIFF),1)
ifeq ($(filter nodiff nodiff-%,$(SUFFIX)),)
override SUFFIX := nodiff$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
endif
endif
override PRJ_NAME := fpga_$(FPGA_BACKEND)_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
export PRJ_NAME
FPGA_DISPATCH_TARGETS := project bitstream stage_bitstream write_bitstream halt_soc \
	write_ddr write_flash reset_cpu runtime_status runtime_stop \
	ila_arm ila_upload ila_clear host_env

.PHONY: $(FPGA_DISPATCH_TARGETS) check_project_name pcie_remove pcie_rescan

check_project_name:
	@case "$$PRJ_NAME" in \
		"") echo "ERROR: PRJ_NAME is empty" >&2; exit 2 ;; \
		.|..|*[!A-Za-z0-9_.-]*) \
			echo "ERROR: invalid PRJ_NAME: $$PRJ_NAME" >&2; \
			echo "Use only letters, digits, '.', '_', and '-'." >&2; exit 2 ;; \
	esac

$(FPGA_DISPATCH_TARGETS): check_project_name
	@test -n "$(filter $(FPGA_BACKEND),$(SUPPORTED_FPGA_BACKENDS))" || { \
		echo "ERROR: FPGA_BACKEND must be one of: $(SUPPORTED_FPGA_BACKENDS)" >&2; \
		exit 2; \
	}
	+@$(MAKE) --no-print-directory $(FPGA_BACKEND)_$@

pcie_remove:
	bash "$(CURDIR)/tools/pcie-remove.sh"

pcie_rescan:
	bash "$(CURDIR)/tools/pcie-rescan.sh"

include vivado/vivado.mk
include uvhs/uvhs.mk
