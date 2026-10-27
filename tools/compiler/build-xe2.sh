#!/bin/bash
set -e
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
W="$HOME/wex"
NG="$W/ng"
SRC="$W/xps/macos/src"
MTL="$W/tx/Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents"
OUT="$W/xe-out"
DEST=/System/Library/Caches/xe.bundle/Contents/MacOS
B="$OUT/xe.bundle/Contents"

rm -rf "$OUT"; mkdir -p "$B/MacOS" "$B/Resources"

echo "== 1. Apple 16.0.32 (NootedGreen) =="
for f in libigc.dylib libigcHSW.dylib libIGIL-Metal.dylib libISAProfilerDyn.dylib; do cp "$NG/MacOS/$f" "$B/MacOS/"; done
cp "$NG/Resources/"* "$B/Resources/"
cp "$MTL/Resources/runtime.gpuencode.split" "$B/Resources/"
ls -l "$B/MacOS" "$B/Resources"

echo "== 2. tbd =="
cat > /tmp/libLLVM32023.tbd <<'EOF'
--- !tapi-tbd
tbd-version: 4
targets: [ x86_64-macos ]
install-name: '/System/Library/PrivateFrameworks/GPUCompiler.framework/Versions/32023/Libraries/libLLVM.dylib'
current-version: 1
exports:
  - targets: [ x86_64-macos ]
    symbols: [ '_LLVMContextCreate', '_LLVMCreateMemoryBufferWithMemoryRange', '_LLVMParseBitcodeInContext2', '_LLVMWriteBitcodeToMemoryBuffer', '_LLVMGetBufferStart', '_LLVMGetBufferSize', '_LLVMDisposeMemoryBuffer', '_LLVMGetModuleContext', '_LLVMModuleCreateWithNameInContext' ]
...
EOF

echo "== 3. bridge =="
clang++ -arch x86_64 -dynamiclib -std=c++17 -O2 -mmacosx-version-min=15.0 \
  -install_name "$DEST/libLLVMbridge.dylib" -compatibility_version 1.0.0 -current_version 3902.30.1 \
  "$SRC/llvm-bridge.cpp" -Wl,-reexport_library,/tmp/libLLVM32023.tbd -o "$B/MacOS/libLLVMbridge.dylib" 2>&1 | grep -v warning || true
ls -l "$B/MacOS/libLLVMbridge.dylib"

echo "== 4. plugin antigo patchado =="
P="$B/MacOS/libMTLIGCCompilerPluginOld.dylib"
cp "$NG/MacOS/libMTLIGCCompilerPlugin.dylib" "$P"
codesign --remove-signature "$P" 2>/dev/null || true
install_name_tool -id "$DEST/libMTLIGCCompilerPluginOld.dylib" "$P"
install_name_tool -change /System/Library/PrivateFrameworks/GPUCompiler.framework/Versions/3902/Libraries/libLLVM.dylib "$DEST/libLLVMbridge.dylib" "$P" 2>/dev/null || echo "(sem dep libLLVM3902)"
python3 - "$P" "$W/xps/macos/plugin-old-patches.json" <<'PY'
import json, sys
p = sys.argv[1]; b = bytearray(open(p,'rb').read())
for x in json.load(open(sys.argv[2])):
    o, old, new = x['off'], bytes.fromhex(x['old']), bytes.fromhex(x['new'])
    if b[o:o+len(old)] != old: sys.exit('bytes em 0x%x nao conferem' % o)
    b[o:o+len(new)] = new
open(p,'wb').write(b); print("plugin antigo patchado OK")
PY

echo "== 5. adapter =="
clang++ -arch x86_64 -dynamiclib -std=c++17 -O2 -mmacosx-version-min=15.0 \
  -install_name "$DEST/libMTLIGCCompilerPlugin.dylib" \
  "$SRC/compiler-adapter.cpp" /tmp/libLLVM32023.tbd -Wl,-reexport_library,"$P" \
  -o "$B/MacOS/libMTLIGCCompilerPlugin.dylib" 2>&1 | grep -v warning || true
ls -l "$B/MacOS/libMTLIGCCompilerPlugin.dylib"

echo "== 6. assinaturas =="
for f in "$B/MacOS/"*.dylib; do codesign -f -s - "$f"; done
echo "== 7. resultado =="
ls -l "$B/MacOS"
otool -L "$B/MacOS/libMTLIGCCompilerPlugin.dylib" | head -8
tar -czf "$W/xe.bundle.tgz" -C "$OUT" xe.bundle
ls -l "$W/xe.bundle.tgz"; shasum -a 256 "$W/xe.bundle.tgz"
