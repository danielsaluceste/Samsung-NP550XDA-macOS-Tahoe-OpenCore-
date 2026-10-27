#!/bin/bash
# Desativa a analise automatica de Fotos (mediaanalysisd/photoanalysisd).
# Reverter: launchctl enable gui/$(id -u)/com.apple.mediaanalysisd
#           launchctl enable gui/$(id -u)/com.apple.photoanalysisd
set -e
U=$(id -u)

for L in com.apple.mediaanalysisd com.apple.photoanalysisd; do
  launchctl disable "gui/$U/$L" 2>/dev/null || true
  launchctl bootout  "gui/$U/$L" 2>/dev/null || true
done

pkill -x mediaanalysisd 2>/dev/null || true
pkill -x photoanalysisd 2>/dev/null || true

echo "desativados: mediaanalysisd, photoanalysisd"
echo "efeito: Fotos perde a analise automatica (busca por objetos/cenas)."
