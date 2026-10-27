#!/bin/bash
# Corrige o BlueToolFixup para carregar no macOS 26 (MaxKernel vazio).
# Uso: bash bt-fix.sh [/dev/disk0s1]
# Pede sudo interativamente; nao contem senhas.
set -e
ESP="${1:-/dev/disk0s1}"
MNT=/Volumes/EFI
sudo mkdir -p "$MNT"
sudo mount -t msdos "$ESP" "$MNT" 2>/dev/null || true
CFG="$MNT/EFI/OC/config.plist"
if [ ! -f "$CFG" ]; then
  echo "config.plist nao encontrado em $CFG" >&2
  exit 1
fi

sudo cp "$CFG" "$CFG.bak-bt"

N=$(sudo /usr/libexec/PlistBuddy -c 'Print :Kernel:Add' "$CFG" 2>/dev/null | grep -c 'Dict {')
IDX=-1
for ((i=0;i<N;i++)); do
  B=$(sudo /usr/libexec/PlistBuddy -c "Print :Kernel:Add:$i:BundlePath" "$CFG" 2>/dev/null || true)
  if [ "$B" = "BlueToolFixup.kext" ]; then IDX=$i; break; fi
done

if [ "$IDX" -lt 0 ]; then
  echo "BlueToolFixup.kext nao encontrado em Kernel > Add" >&2
  exit 1
fi

echo "BlueToolFixup no indice $IDX"
sudo /usr/libexec/PlistBuddy -c "Set :Kernel:Add:$IDX:Enabled true" "$CFG"
sudo /usr/libexec/PlistBuddy -c "Set :Kernel:Add:$IDX:MinKernel 21.0.0" "$CFG"
sudo /usr/libexec/PlistBuddy -c "Set :Kernel:Add:$IDX:MaxKernel " "$CFG"

echo "--- depois ---"
sudo /usr/libexec/PlistBuddy -c "Print :Kernel:Add:$IDX" "$CFG" | grep -E 'BundlePath|Enabled|MinKernel|MaxKernel'
sudo plutil -lint "$CFG"
sudo umount "$MNT" 2>/dev/null || true
echo "ok. Reinicie. Verifique: kextstat | grep BlueTool"
