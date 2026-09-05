SHELL := /bin/bash

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
FPGA_SSH ?= ssh
FPGA_HOST ?=
FPGA_RUNTIME ?= $(FPGA_HOST)
FPGA_REMOTE_DIR ?= $(CURDIR)
FPGA_REMOTE_ENV ?= source ~/.bash_profile &&
FPGA_KEEP_RUNTIME ?= 0
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
FPGA_DISPATCH_TARGETS := project bitstream stage_bitstream halt_soc \
	write_ddr write_flash reset_cpu runtime_status runtime_stop \
	ila_arm ila_upload ila_clear ila_host_env

.PHONY: $(FPGA_DISPATCH_TARGETS) check_project_name check_fpga_backend \
	write_bitstream runtime_cleanup bind_uart uart_env

check_project_name:
	@case "$$PRJ_NAME" in \
		"") echo "ERROR: PRJ_NAME is empty" >&2; exit 2 ;; \
		.|..|*[!A-Za-z0-9_.-]*) \
			echo "ERROR: invalid PRJ_NAME: $$PRJ_NAME" >&2; \
			echo "Use only letters, digits, '.', '_', and '-'." >&2; exit 2 ;; \
	esac

check_fpga_backend:
	@test -n "$(filter $(FPGA_BACKEND),$(SUPPORTED_FPGA_BACKENDS))" || { \
		echo "ERROR: FPGA_BACKEND must be one of: $(SUPPORTED_FPGA_BACKENDS)" >&2; \
		exit 2; \
	}

$(FPGA_DISPATCH_TARGETS): check_project_name check_fpga_backend
	+@$(MAKE) --no-print-directory $(FPGA_BACKEND)_$@

# Validate on the runtime before taking the host endpoint down, then always
# rescan after attempting the backend-specific programming operation.
write_bitstream: check_project_name check_fpga_backend
	@test -n "$(FPGA_HOST)" || { echo "ERROR: FPGA_HOST is required" >&2; exit 2; }
	@test -n "$(FPGA_RUNTIME)" || { echo "ERROR: FPGA_RUNTIME is required" >&2; exit 2; }
	@test -n "$(FPGA_REMOTE_DIR)" || { echo "ERROR: FPGA_REMOTE_DIR is required" >&2; exit 2; }
	@$(FPGA_SSH) $(FPGA_RUNTIME) '$(FPGA_REMOTE_ENV) \
		$(MAKE) --no-print-directory -C "$(FPGA_REMOTE_DIR)" \
		$(FPGA_BACKEND)_write_bitstream_preflight \
		PRJ_NAME="$(PRJ_NAME)" CPU="$(CPU)" SUFFIX="$(SUFFIX)" NO_DIFF="$(NO_DIFF)" \
		FPGA_BIT_HOME="$(FPGA_BIT_HOME)"'
	@set -u; \
		refresh=1; \
		[ "$(NO_DIFF)" = 1 ] && refresh=0; \
		remove_started=0; \
		rescan_done=0; \
		rescan_status=0; \
		rescan_xdma() { \
			local result; \
			rescan_done=1; \
			$(FPGA_SSH) $(FPGA_HOST) 'bash -s' \
				< "$(CURDIR)/tools/pcie-rescan.sh"; \
			result=$$?; \
			return $$result; \
		}; \
		cleanup_xdma() { \
			status=$$?; \
			trap - EXIT INT TERM HUP; \
			if ((refresh && remove_started && !rescan_done)); then \
				rescan_xdma || rescan_status=$$?; \
			fi; \
			if ((status != 0)); then exit $$status; fi; \
			exit $$rescan_status; \
		}; \
		trap cleanup_xdma EXIT; \
		trap 'exit 130' INT; \
		trap 'exit 143' TERM; \
		trap 'exit 129' HUP; \
		if ((refresh)); then \
			remove_started=1; \
			$(FPGA_SSH) $(FPGA_HOST) 'bash -s' \
				< "$(CURDIR)/tools/pcie-remove.sh" || exit $$?; \
		fi; \
		runtime_status=0; \
		$(FPGA_SSH) $(FPGA_RUNTIME) '$(FPGA_REMOTE_ENV) \
			$(MAKE) --no-print-directory -C "$(FPGA_REMOTE_DIR)" \
			$(FPGA_BACKEND)_write_bitstream \
			PRJ_NAME="$(PRJ_NAME)" CPU="$(CPU)" SUFFIX="$(SUFFIX)" NO_DIFF="$(NO_DIFF)" \
			FPGA_BIT_HOME="$(FPGA_BIT_HOME)"' || runtime_status=$$?; \
		if ((refresh)); then \
			rescan_xdma || rescan_status=$$?; \
		fi; \
		trap - EXIT INT TERM HUP; \
		if ((runtime_status != 0)); then exit $$runtime_status; fi; \
		exit $$rescan_status

# Run this target on FPGA_HOST after fpga-host exits. The backend owns the
# cleanup policy; FPGA_RUNTIME selects local execution or the remote runtime.
runtime_cleanup: check_project_name check_fpga_backend
	@test -n "$(FPGA_HOST)" || { echo "ERROR: FPGA_HOST is required" >&2; exit 2; }
	@test -n "$(FPGA_RUNTIME)" || { echo "ERROR: FPGA_RUNTIME is required" >&2; exit 2; }
	@case "$(FPGA_KEEP_RUNTIME)" in \
		0|1) ;; \
		*) echo "ERROR: FPGA_KEEP_RUNTIME must be 0 or 1" >&2; exit 2 ;; \
	esac
	@if [ "$(FPGA_RUNTIME)" = "$(FPGA_HOST)" ]; then \
		$(MAKE) --no-print-directory $(FPGA_BACKEND)_runtime_cleanup \
			PRJ_NAME="$(PRJ_NAME)" CPU="$(CPU)" SUFFIX="$(SUFFIX)" \
			FPGA_BIT_HOME="$(FPGA_BIT_HOME)" FPGA_KEEP_RUNTIME="$(FPGA_KEEP_RUNTIME)"; \
	else \
		$(FPGA_SSH) $(FPGA_RUNTIME) '$(FPGA_REMOTE_ENV) \
			$(MAKE) --no-print-directory -C "$(FPGA_REMOTE_DIR)" \
			$(FPGA_BACKEND)_runtime_cleanup \
			PRJ_NAME="$(PRJ_NAME)" CPU="$(CPU)" SUFFIX="$(SUFFIX)" \
			FPGA_BIT_HOME="$(FPGA_BIT_HOME)" FPGA_KEEP_RUNTIME="$(FPGA_KEEP_RUNTIME)"'; \
	fi

# Print the environment assignment consumed by fpga-host.
uart_env:
	@printf 'export FPGA_UART_PORT=%s\n' '$(FPGA_UART_PORT)'

# Bridge REMOTE_UART_PORT through SSH to a local PTY for fpga-host.
# Start an interactive shell with FPGA_UART_PORT exported after the bridge starts.
bind_uart:
	@test -n "$(FPGA_RUNTIME)" || { \
		echo "FPGA_RUNTIME is required (for example: FPGA_RUNTIME=<user@fpga-runtime>)" >&2; \
		exit 2; \
	}
	@command -v socat >/dev/null || { echo "socat is required on the local host" >&2; exit 2; }
	@set -e; \
	socat -d -d pty,link="$(FPGA_UART_PORT)",rawer,echo=0,waitslave \
		EXEC:"ssh -T $(FPGA_RUNTIME) 'exec socat - $(REMOTE_UART_PORT),rawer,b$(REMOTE_UART_BAUD)'",nofork & \
	bridge_pid=$$!; \
	trap 'kill $$bridge_pid 2>/dev/null || true; wait $$bridge_pid 2>/dev/null || true' 0 INT TERM; \
	export FPGA_UART_PORT="$(FPGA_UART_PORT)"; \
	printf 'FPGA_UART_PORT=%s\n' "$$FPGA_UART_PORT"; \
	$(SHELL) -i

include vivado/vivado.mk
include uvhs/uvhs.mk
