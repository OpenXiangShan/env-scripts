#!/bin/bash
set -e

# Find BDF id of first xdma PCIE
BDF=$(lspci -D | grep -i xilinx | awk '{print $1}' | head -n 1)

if [ -z "$BDF" ]; then
  echo "Warning: No Xilinx PCI device found."
  exit 0
fi

# Unbind xdma driver first to avoid kernel oops in remove_one callback
if [ -e "/sys/bus/pci/devices/$BDF/driver" ]; then
  DRIVER=$(basename "$(readlink /sys/bus/pci/devices/$BDF/driver)")
  echo "Unbinding driver '$DRIVER' from $BDF"
  echo "$BDF" | sudo tee /sys/bus/pci/drivers/$DRIVER/unbind >/dev/null
  sleep 1
fi

# Remove PCIE of xdma
echo "PCI device BDF id: $BDF"
echo 1 | sudo tee /sys/bus/pci/devices/$BDF/remove
echo "Removing PCI device at $BDF"
