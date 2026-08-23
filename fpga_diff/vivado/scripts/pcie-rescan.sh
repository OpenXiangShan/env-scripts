#!/bin/bash
set -e
echo 1 | sudo tee /sys/bus/pci/rescan >/dev/null
echo "Rescan PCI device successfully"