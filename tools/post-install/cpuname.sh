#!/bin/bash
# Ajusta o nome do processador em "Sobre Este Mac" via RestrictEvents.
# Uso: bash cpuname.sh [/dev/disk0s1]
# Pede sudo interativamente; nao contem senhas.
set -e
ESP="${1:-/dev/disk0s1}"
MNT=/Volumes/EFI
G=4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102
CPUNAME="Intel Core i5-1135G7"

sudo mkdir -p "$MNT"
sudo mount -t msdos "$ESP" "$MNT" 2>/dev/null || true
CFG="$MNT/EFI/OC/config.plist"
if [ ! -f "$CFG" ]; then
  echo "config.plist nao encontrado em $CFG" >&2
  exit 1
fi

sudo cp "$CFG" "$CFG.bak-cpuname"

if ! sudo /usr/libexec/PlistBuddy -c "Print :NVRAM:Add:$G" "$CFG" >/dev/null 2>&1; then
  sudo /usr/libexec/PlistBuddy -c "Add :NVRAM:Add:$G dict" "$CFG"
fi

for key in revcpu revcpuname revpatch; do
  if ! sudo /usr/libexec/PlistBuddy -c "Print :NVRAM:Add:$G:$key" "$CFG" >/dev/null 2>&1; then
    sudo /usr/libexec/PlistBuddy -c "Add :NVRAM:Add:$G:$key string" "$CFG"
  fi
done

sudo plutil -replace "NVRAM.Add.$G.revcpu"     -string "1" "$CFG"
sudo plutil -replace "NVRAM.Add.$G.revcpuname" -string "$CPUNAME" "$CFG"
sudo plutil -replace "NVRAM.Add.$G.revpatch"   -string "sbvmm,cpuname" "$CFG"

echo "--- resultado ---"
sudo /usr/libexec/PlistBuddy -c "Print :NVRAM:Add:$G" "$CFG"
sudo plutil -lint "$CFG"
sudo umount "$MNT" 2>/dev/null || true
echo "ok. Reinicie para o RestrictEvents aplicar."
