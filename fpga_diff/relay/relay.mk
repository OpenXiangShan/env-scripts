XDMA_RELAY_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: relay_host_env
relay_host_env:
	@test -n "$(XDMA_RELAY_BOARD)" || { \
		echo "ERROR: XDMA_RELAY_BOARD is required for relay_host_env" >&2; exit 2; \
	}
	@XDMA_RELAY_BOARD="$(XDMA_RELAY_BOARD)" \
		XDMA_RELAY_DAEMON="$(XDMA_RELAY_DAEMON)" \
		XDMA_RELAY_LISTEN="$(XDMA_RELAY_LISTEN)" \
		XDMA_RELAY_PORT="$(XDMA_RELAY_PORT)" \
		XDMA_RELAY_ZSTD="$(or $(XDMA_RELAY_ZSTD),0)" \
		DIFFTEST_HOSTIF="$(DIFFTEST_HOSTIF)" \
		bash "$(XDMA_RELAY_DIR)/host_env.sh" \
		$(MAKE) --no-print-directory host_env
