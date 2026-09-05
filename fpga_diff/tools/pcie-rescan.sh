#!/bin/bash
set -euo pipefail

XDMA_PCI_ID=${XDMA_PCI_ID:-10ee:9048}
XDMA_RESCAN_TIMEOUT=${XDMA_RESCAN_TIMEOUT:-30}
REQUIRED_NODES=(
  /dev/xdma0_h2c_0
  /dev/xdma0_c2h_0
  /dev/xdma0_user
)

[[ $XDMA_RESCAN_TIMEOUT =~ ^[1-9][0-9]*$ ]] || {
  echo "ERROR: XDMA_RESCAN_TIMEOUT must be a positive integer" >&2
  exit 2
}

printf '1\n' | sudo -n tee /sys/bus/pci/rescan >/dev/null

BDF=
for ((elapsed = 0; elapsed < XDMA_RESCAN_TIMEOUT; elapsed++)); do
  BDF=$(lspci -D -d "$XDMA_PCI_ID" | awk 'NR == 1 {print $1}')
  if [[ -n $BDF && -e /sys/bus/pci/devices/$BDF/driver ]]; then
    DRIVER=$(basename "$(readlink /sys/bus/pci/devices/$BDF/driver)")
    nodes_ready=1
    for node in "${REQUIRED_NODES[@]}"; do
      [[ -c $node ]] || nodes_ready=0
    done
    if [[ $DRIVER == xdma-chr && $nodes_ready == 1 ]]; then
      break
    fi
  fi
  BDF=
  sleep 1
done

if [[ -z $BDF ]]; then
  echo "ERROR: XDMA did not become ready within ${XDMA_RESCAN_TIMEOUT}s" >&2
  lspci -Dnnk -d "$XDMA_PCI_ID" >&2 || true
  ls -l /dev/xdma0_* >&2 2>/dev/null || true
  exit 1
fi

echo "XDMA PCI device:"
lspci -Dnnk -s "$BDF"
echo "XDMA device nodes:"
ls -l /dev/xdma0_*

for node in "${REQUIRED_NODES[@]}"; do
  if [[ ! -r $node || ! -w $node ]]; then
    echo "ERROR: $node is not readable and writable by $(id -un); check the XDMA udev rule" >&2
    exit 1
  fi
done

echo "XDMA rescan completed successfully"
