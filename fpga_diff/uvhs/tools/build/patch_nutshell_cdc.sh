#!/usr/bin/env bash
set -euo pipefail

core_dir=${1:-}
if [[ -z "$core_dir" || ! -d "$core_dir" ]]; then
  exit 0
fi

rtl_dir="$core_dir/build/rtl"
if [[ ! -d "$rtl_dir" ]]; then
  rtl_dir="$core_dir/rtl"
fi
if [[ ! -d "$rtl_dir" ]]; then
  exit 0
fi

patched=0
while IFS= read -r -d '' file; do
  before=$(sha256sum "$file" | awk '{print $1}')
  perl -0pi -e '
    s/(?:\(\*\s*ASYNC_REG="TRUE"\s*\*\)\s*)+reg\s+(\[[^\]]+\]\s+(?:wrPtrGraySync|rdPtrGraySync)(?:_REG)?\s*;)/(* ASYNC_REG="TRUE" *) reg  $1/g;
    s/(^|\n)([ \t]*)(reg\s+\[[^\]]+\]\s+(?:wrPtrGraySync|rdPtrGraySync)(?:_REG)?\s*;)/$1$2(* ASYNC_REG="TRUE" *) $3/g;
  ' "$file"
  after=$(sha256sum "$file" | awk '{print $1}')
  if [[ "$before" != "$after" ]]; then
    echo "INFO: patched AsyncClockFIFO CDC synchronizer attributes: $file"
    patched=1
  fi
done < <(find "$rtl_dir" -maxdepth 1 -type f \( -name 'AsyncClockFIFO.sv' -o -name 'AsyncClockFIFO_*.sv' \) -print0)

while IFS= read -r -d '' file; do
  before=$(sha256sum "$file" | awk '{print $1}')
  perl -0pi -e '
    s/(?:\(\*\s*ASYNC_REG="TRUE"\s*\*\)\s*)+reg(\s+)enableSync_REG\s*;/(* ASYNC_REG="TRUE" *) reg$1enableSync_REG;/g;
    s/(?:\(\*\s*ASYNC_REG="TRUE"\s*\*\)\s*)+reg(\s+)enableSync\s*;/(* ASYNC_REG="TRUE" *) reg$1enableSync;/g;
    s/(^|\n)([ \t]*)(reg(\s+)enableSync_REG\s*;)/$1$2(* ASYNC_REG="TRUE" *) $3/g;
    s/(^|\n)([ \t]*)(reg(\s+)enableSync\s*;)/$1$2(* ASYNC_REG="TRUE" *) $3/g;
  ' "$file"
  after=$(sha256sum "$file" | awk '{print $1}')
  if [[ "$before" != "$after" ]]; then
    echo "INFO: patched H2CAXIs2Mem enable synchronizer attributes: $file"
    patched=1
  fi
done < <(find "$rtl_dir" -maxdepth 1 -type f \( -name 'H2CAXIs2Mem.sv' -o -name 'H2CAXIs2Mem_*.sv' \) -print0)

if [[ "$patched" == 0 ]]; then
  echo "INFO: NutShell CDC synchronizer attributes already patched or no matching RTL found"
fi
