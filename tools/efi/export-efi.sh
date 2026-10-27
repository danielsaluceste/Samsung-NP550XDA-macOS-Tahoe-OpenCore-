#!/bin/bash
# Exporta uma EFI SANITIZADA da maquina funcionando.
# - remove seriais/MLB/UUID/ROM do SMBIOS
# - remove WiFiConfig (SSID/senha) do itlwm
# - copia apenas kexts habilitados
# - mantem ACPI, Drivers, OpenCore.efi, BOOTx64.efi e Resources (se OpenCanopy)
#
# Uso: bash export-efi.sh [/dev/disk0s1]
# Requer: sudo (interativo) e python3 (Command Line Tools) para o plist.
set -e
ESP="${1:-/dev/disk0s1}"
MNT=/Volumes/EFI
OUT="$HOME/EFI-sanitized"
TGZ="$HOME/EFI-sanitized.tar.gz"
OC="$MNT/EFI/OC"

command -v python3 >/dev/null || { echo "precisa de python3 (xcode-select --install)" >&2; exit 1; }

echo "=== montando $ESP ==="
sudo mkdir -p "$MNT"
sudo mount -t msdos "$ESP" "$MNT" 2>/dev/null || true
[ -f "$OC/config.plist" ] || { echo "config.plist nao encontrado" >&2; exit 1; }

echo "=== preparando staging ==="
rm -rf "$OUT" "$TGZ"
mkdir -p "$OUT/EFI/OC"
sudo cp -R "$MNT/EFI/BOOT" "$OUT/EFI/" 2>/dev/null || true
sudo cp "$OC/OpenCore.efi" "$OUT/EFI/OC/" 2>/dev/null || true
sudo cp "$OC/config.plist" "$OUT/EFI/OC/config.plist"
sudo cp -R "$OC/ACPI" "$OUT/EFI/OC/" 2>/dev/null || true
sudo cp -R "$OC/Drivers" "$OUT/EFI/OC/" 2>/dev/null || true

PICKER=$(sudo plutil -extract Misc.Boot.PickerMode raw -o - "$OC/config.plist" 2>/dev/null || echo "")
if [ "$PICKER" = "External" ]; then
  echo "OpenCanopy (External): copiando Resources"
  sudo cp -R "$OC/Resources" "$OUT/EFI/OC/" 2>/dev/null || true
fi

echo "=== copiando kexts habilitados ==="
sudo python3 - "$OC/config.plist" "$OC/Kexts" "$OUT/EFI/OC/Kexts" <<'PY'
import json, os, shutil, subprocess, sys

cfg, src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.loads(subprocess.check_output(["plutil", "-extract", "Kernel.Add", "json", "-o", "-", cfg]))
os.makedirs(dst, exist_ok=True)
copied = set()
for k in data:
    if not k.get("Enabled"):
        continue
    bp = k.get("BundlePath", "")
    if not bp.endswith(".kext"):
        continue
    top = bp.split("/")[0]
    if top in copied:
        continue
    s = os.path.join(src, top)
    d = os.path.join(dst, top)
    if os.path.isdir(s):
        shutil.copytree(s, d, dirs_exist_ok=True)
        copied.add(top)
        print("  ", top)
    else:
        print("  FALTA:", top)
print("total:", len(copied))
PY

echo "=== sanitizando config.plist ==="
sudo python3 - "$OUT/EFI/OC/config.plist" <<'PY'
import plistlib, sys
p = sys.argv[1]
d = plistlib.load(open(p, 'rb'))

g = d.setdefault('PlatformInfo', {}).setdefault('Generic', {})
for k in ('SystemSerialNumber', 'MLB', 'SystemUUID', 'ROM'):
    g[k] = b'' if k == 'ROM' else ''
    print(f"  {k} = (vazio)")

# remove apenas entradas de Kernel>Add desabilitadas (mantem as habilitadas)
add = d.get('Kernel', {}).get('Add', [])
d['Kernel']['Add'] = [k for k in add if k.get('Enabled')]
print(f"  Kernel>Add: {len(add)} -> {len(d['Kernel']['Add'])}")

with open(p, 'wb') as f:
    plistlib.dump(d, f, fmt=plistlib.FMT_XML)
PY

echo "=== removendo WiFiConfig do itlwm ==="
if [ -f "$OUT/EFI/OC/Kexts/itlwm.kext/Contents/Info.plist" ]; then
  sudo python3 - "$OUT/EFI/OC/Kexts/itlwm.kext/Contents/Info.plist" <<'PY'
import plistlib, sys
p = sys.argv[1]
d = plistlib.load(open(p, 'rb'))
n = 0
for k, v in d.get('IOKitPersonalities', {}).items():
    if isinstance(v, dict) and 'WiFiConfig' in v:
        del v['WiFiConfig']; n += 1
with open(p, 'wb') as f:
    plistlib.dump(d, f, fmt=plistlib.FMT_XML)
print(f"  WiFiConfig removido de {n} personality(s)")
PY
fi

echo "=== checagem de dados sensiveis ==="
for pat in 'l5g8d6da' '192\.168\.' 'SystemSerialNumber</key><string>[A-Z0-9]' 'MLB</key><string>[A-Z0-9]'; do
  if grep -R -a -E -q "$pat" "$OUT" 2>/dev/null; then
    echo "  AVISO: padrao encontrado: $pat"
  fi
done
if grep -R -a -q 'WiFiConfig' "$OUT/EFI/OC/Kexts/itlwm.kext" 2>/dev/null; then
  echo "  AVISO: ainda existe WiFiConfig"
fi
echo "  ok"

echo "=== empacotando ==="
tar -czf "$TGZ" -C "$OUT" EFI
ls -lh "$TGZ"
shasum -a 256 "$TGZ"

sudo umount "$MNT" 2>/dev/null || true
echo
echo "Pronto: $TGZ"
echo "Confira manualmente antes de publicar (seriais, SSID, MACs, UUID)."
