#!/bin/bash
set -euo pipefail

# xdma_ep.tcl configures PF0 as 10ee:9048 for both supported XDMA IP versions.
XDMA_PCI_ID=${XDMA_PCI_ID:-10ee:9048}

mapfile -t FPGA_HOST_PROCESSES < <(
  ps -eo pid=,comm=,args= | awk \
    '$2 == "fpga-host" || $0 ~ /(^|[[:space:]\/])fpga-host([[:space:]]|$)/'
)
if ((${#FPGA_HOST_PROCESSES[@]} != 0)); then
  echo "ERROR: fpga-host is still running; stop it before removing the XDMA endpoint:" >&2
  printf '  %s\n' "${FPGA_HOST_PROCESSES[@]}" >&2
  exit 1
fi

mapfile -t BDFS < <(lspci -D -d "$XDMA_PCI_ID" | awk '{print $1}')
if ((${#BDFS[@]} == 0)); then
  echo "WARNING: no XDMA PCI device found for $XDMA_PCI_ID"
  exit 0
fi
if ((${#BDFS[@]} != 1)); then
  echo "ERROR: expected one XDMA PCI device for $XDMA_PCI_ID, found ${#BDFS[@]}:" >&2
  printf '  %s\n' "${BDFS[@]}" >&2
  exit 1
fi
BDF=${BDFS[0]}

# Unbind first so the driver does not retain state across FPGA reprogramming.
if [[ -e /sys/bus/pci/devices/$BDF/driver ]]; then
  DRIVER=$(basename "$(readlink /sys/bus/pci/devices/$BDF/driver)")
  echo "Unbinding driver '$DRIVER' from $BDF"
  printf '%s\n' "$BDF" | sudo -n tee "/sys/bus/pci/drivers/$DRIVER/unbind" >/dev/null
  sleep 1
fi

echo "Removing XDMA PCI device $BDF ($XDMA_PCI_ID)"
printf '1\n' | sudo -n tee "/sys/bus/pci/devices/$BDF/remove" >/dev/null
