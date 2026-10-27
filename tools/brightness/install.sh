#!/bin/bash
# Instala o BrightnessMenu em /Applications e registra o LaunchAgent.
# Pede sudo interativamente; nao contem senhas.
set -e
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

if [ ! -d "BrightnessMenu.app" ]; then
  echo "rode ./build.sh primeiro" >&2
  exit 1
fi

sudo rm -rf /Applications/BrightnessMenu.app
sudo cp -R BrightnessMenu.app /Applications/
sudo chown -R root:wheel /Applications/BrightnessMenu.app
sudo codesign -f -s - /Applications/BrightnessMenu.app 2>/dev/null || true
sudo xattr -dr com.apple.quarantine /Applications/BrightnessMenu.app 2>/dev/null || true

mkdir -p "$HOME/Library/LaunchAgents"
cp local.brightnessmenu.plist "$HOME/Library/LaunchAgents/"
launchctl bootout gui/$(id -u)/local.brightnessmenu 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/local.brightnessmenu.plist"

sleep 1
pgrep -fl BrightnessMenu || echo "aviso: processo nao iniciou"
echo "instalado. icone ☀ na barra; atalhos ⌃⌥↑ / ⌃⌥↓."
