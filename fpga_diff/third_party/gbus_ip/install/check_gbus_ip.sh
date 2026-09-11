#!/usr/bin/env bash
set -euo pipefail
root=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
declare -A hashes=(
  ["uvw_general_bus/uvw_general_bus.dcp"]="8acb76af84c6ab6c010d16c7dcccf06f3370576ca39dba1a0b1d5f3060bd82ce"
  ["uvw_general_bus/uvw_general_bus_Stub.v"]="585082f0fe646b50f1b9ad64751caecad2253f409378d73101fbe2a9fe0a3c36"
  ["generalBD/generalBD.dcp"]="ce46fdc91cc7267916ace4bf84bbfb5d1b718d20f63810e35eb522f5f7653748"
  ["generalBD/generalBD_Stub.v"]="71c2adf493c5ae36a039032e7c316e77784dd450421fdd6ec91bdd9690317d1f"
)
for rel in "${!hashes[@]}"; do
  file="$root/$rel"
  test -s "$file" || { echo "missing GBus IP asset: $file" >&2; exit 1; }
  actual=$(sha256sum "$file" | cut -d' ' -f1)
  test "$actual" = "${hashes[$rel]}" || {
    echo "Gbus IP SHA-256 mismatch: $file ($actual != ${hashes[$rel]})" >&2
    exit 1
  }
done
printf 'GBUS_IP_ROOT=%s\n' "$root"
printf 'GBus IP assets verified (%d files)\n' "${#hashes[@]}"
