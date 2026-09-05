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
REMOTE ?=
REMOTE_UART_PORT ?= /dev/ttyUSB0
REMOTE_UART_BAUD ?= 115200
FPGA_UART_PORT ?= /tmp/fpga-remote-uart
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
PRJ_NAME ?= fpga_$(FPGA_BACKEND)_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
export PRJ_NAME
FPGA_DISPATCH_TARGETS := project bitstream stage_bitstream write_bitstream halt_soc \
	write_ddr write_flash reset_cpu runtime_status runtime_stop \
	ila_arm ila_upload ila_clear ila_host_env

.PHONY: $(FPGA_DISPATCH_TARGETS) check_project_name bind_uart uart_env

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

# Print the environment assignment consumed by fpga-host.
uart_env:
	@printf 'export FPGA_UART_PORT=%s\n' '$(FPGA_UART_PORT)'

# Bridge REMOTE_UART_PORT through SSH to a local PTY for fpga-host.
# Start an interactive shell with FPGA_UART_PORT exported after the bridge starts.
bind_uart:
	@test -n "$(REMOTE)" || { echo "REMOTE is required (for example: REMOTE=<user@fpga-runtime>)" >&2; exit 2; }
	@command -v socat >/dev/null || { echo "socat is required on the local host" >&2; exit 2; }
	@set -e; \
	socat -d -d pty,link="$(FPGA_UART_PORT)",rawer,echo=0,waitslave \
		EXEC:"ssh -T $(REMOTE) 'exec socat - $(REMOTE_UART_PORT),rawer,b$(REMOTE_UART_BAUD)'",nofork & \
	bridge_pid=$$!; \
	trap 'kill $$bridge_pid 2>/dev/null || true; wait $$bridge_pid 2>/dev/null || true' 0 INT TERM; \
	export FPGA_UART_PORT="$(FPGA_UART_PORT)"; \
	printf 'FPGA_UART_PORT=%s\n' "$$FPGA_UART_PORT"; \
	$(SHELL) -i

include vivado/vivado.mk
include uvhs/uvhs.mk
