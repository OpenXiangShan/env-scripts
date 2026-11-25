CXX ?= c++
CXXFLAGS ?= -O2 -g
CXXFLAGS += -std=c++17 -Wall -Wextra -Werror -Iinclude
BUILD_DIR ?= build

TESTS := address_mapping_test fixed_fifo_test virtual_ram_test
TEST_BINS := $(addprefix $(BUILD_DIR)/,$(TESTS))

.PHONY: all test clean

all: $(TEST_BINS)

test: $(TEST_BINS)
	@set -e; for test_bin in $(TEST_BINS); do ./$$test_bin; done

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/address_mapping_test: tests/address_mapping_test.cpp src/dfi/address_mapping.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@

$(BUILD_DIR)/fixed_fifo_test: tests/fixed_fifo_test.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@

$(BUILD_DIR)/virtual_ram_test: tests/virtual_ram_test.cpp src/dfi/virtual_ram.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@

clean:
	rm -rf $(BUILD_DIR)
