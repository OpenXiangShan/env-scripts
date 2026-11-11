XDMA_RELAY_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: relay_host_env
relay_host_env:
	@bash "$(XDMA_RELAY_DIR)/host_env.sh" \
		$(MAKE) --no-print-directory host_env
