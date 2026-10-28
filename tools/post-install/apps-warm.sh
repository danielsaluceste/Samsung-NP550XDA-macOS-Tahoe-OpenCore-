#!/bin/sh
# Pre-aquece a App Library (RenderBox/IconServices) apos o login.
# Nao ativa a janela (-g) e nao mata processos de GPU.
LOG=/tmp/apps-warm.log
{
    echo "=== inicio $(date) ==="
    /usr/bin/open -g -a /System/Applications/Apps.app
    i=0
    while [ "$i" -lt 24 ]; do
        sleep 5
        i=$((i + 1))
    done
    echo "=== fim $(date) ==="
    /bin/ps -Ao time,comm | /usr/bin/grep MTLCompilerService | /usr/bin/tail -1
} >>"$LOG" 2>&1
exit 0
