#!/bin/bash
# Ajustes de disco/sono que ajudam neste SSD sem DRAM.
# Pede sudo interativamente; nao contem senhas.
set -e

sudo pmset -a disksleep 0
sudo pmset -a hibernatemode 0
sudo pmset -a powernap 0
sudo pmset -a womp 0
sudo pmset -a sleep 0
# 0.6.1/Compat 0.6.1: o painel pode apagar e nao voltar (link eDP). Mantem ligado.
sudo pmset -a displaysleep 0
sudo rm -f /var/vm/sleepimage

echo "--- estado ---"
pmset -g custom | grep -E 'disksleep|hibernatemode|powernap|womp|displaysleep|^ sleep'
echo
echo "Obs.: o pmset pode avisar 'Disk sleep should be non-zero whenever system sleep is non-zero'."
echo "E apenas um aviso; disksleep 0 mantem o disco acordado enquanto o sistema esta acordado."
echo "Reverter: sudo pmset -a disksleep 10 hibernatemode 3 powernap 1 womp 1 displaysleep 10 sleep 1"
