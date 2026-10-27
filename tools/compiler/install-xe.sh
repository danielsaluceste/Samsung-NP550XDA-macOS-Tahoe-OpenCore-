#!/bin/bash
# Instala o stack do compilador Metal e troca o adapter do XeCompilerAdapter.
# Rode na maquina alvo (macOS). Pede sudo interativamente; nao contem senhas.
set -e
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

B=/Library/GPUBundles/XeCompilerAdapter.bundle/Contents/MacOS
TGZ="${1:-$HOME/xe.bundle.tgz}"

if [ ! -f "$TGZ" ]; then
  echo "uso: $0 /caminho/para/xe.bundle.tgz" >&2
  exit 1
fi

echo "=== backup do adapter original do WEX ==="
sudo cp -n "$B/adapter.dylib" "$B/adapter-wex.dylib" 2>/dev/null || true

echo "=== instalando xe.bundle ==="
sudo rm -rf /System/Library/Caches/xe.bundle
sudo tar -xzf "$TGZ" -C /System/Library/Caches/
sudo chown -R root:wheel /System/Library/Caches/xe.bundle
sudo chmod -R go-w /System/Library/Caches/xe.bundle

echo "=== trocando o adapter ==="
sudo cp /System/Library/Caches/xe.bundle/Contents/MacOS/libMTLIGCCompilerPlugin.dylib "$B/adapter.dylib"
sudo chmod 755 "$B/adapter.dylib"
sudo codesign -f -s - "$B/adapter.dylib" 2>/dev/null || true
shasum -a 256 "$B/adapter.dylib"

echo "=== teste Metal ==="
if [ -x "$HOME/metal_test2" ]; then
  "$HOME/metal_test2" 2>&1 | tail -8
else
  echo "dica: compile tools/diagnostics como metal_test2 para testar"
fi

echo "=== log do adapter ==="
sudo log show --last 2m 2>/dev/null | grep -a -E 'xe-adapter|xe-bridge' | tail -10 || true
