#!/bin/bash
# Compila o BrightnessMenu.app (Objective-C, ARC, sem ler teclado).
set -e
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
OUT="BrightnessMenu.app"

rm -rf "$OUT"
mkdir -p "$OUT/Contents/MacOS"

cat > "$OUT/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>BrightnessMenu</string>
    <key>CFBundleIdentifier</key><string>local.brightnessmenu</string>
    <key>CFBundleVersion</key><string>1.4</string>
    <key>CFBundleShortVersionString</key><string>1.4</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>BrightnessMenu</string>
    <key>LSUIElement</key><true/>
    <key>LSMinimumSystemVersion</key><string>11.0</string>
</dict>
</plist>
EOF

clang -arch x86_64 -mmacosx-version-min=11.0 -fobjc-arc \
  -framework Cocoa -framework IOKit -framework Carbon \
  -o "$OUT/Contents/MacOS/BrightnessMenu" BrightnessMenu.m

codesign -f -s - "$OUT" 2>/dev/null || true
echo "ok: $OUT"
file "$OUT/Contents/MacOS/BrightnessMenu"
