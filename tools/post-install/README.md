# Pós-instalação

Scripts idempotentes (em geral) para aplicar os ajustes deste projeto. **Nenhum contém senha**;
todos pedem `sudo` interativamente.

## Ordem sugerida

```bash
bash perf-tweaks.sh
bash cpuname.sh /dev/disk0s1
bash bt-fix.sh /dev/disk0s1
bash disable-mediaanalysisd.sh
```

### `perf-tweaks.sh`

`disksleep 0`, `hibernatemode 0`, `powernap 0`, `womp 0`, remove `/var/vm/sleepimage`.
Reverter no final do script.

### `cpuname.sh`

Adiciona ao NVRAM do OpenCore:

```
revcpu=1
revcpuname=Intel Core i5-1135G7
revpatch=sbvmm,cpuname
```

Faz backup (`config.plist.bak-cpuname`). Reinicie.

### `bt-fix.sh`

Encontra o `BlueToolFixup.kext` em `Kernel > Add`, marca `Enabled=true`, `MinKernel=21.0.0` e
**limpa o `MaxKernel`**. Sem isso o BlueToolFixup 2.7.2 não carrega no macOS 26 e o Bluetooth fica
`State: Off` / `Firmware v0 c0`. Backup `config.plist.bak-bt`.

### `disable-mediaanalysisd.sh`

Desativa `mediaanalysisd` e `photoanalysisd` (análise automática de Fotos). Reverter:

```bash
launchctl enable gui/$(id -u)/com.apple.mediaanalysisd
launchctl enable gui/$(id -u)/com.apple.photoanalysisd
```

## HeliPort one-shot

```bash
cp heliport-oneshot.plist ~/Library/LaunchAgents/local.heliport-oneshot.plist
launchctl bootout  gui/$(id -u)/local.heliport-oneshot 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.heliport-oneshot.plist
```

Ele abre o HeliPort no login, espera o IPv4 em `en0`, e fecha. O `itlwm` mantém a conexão. Se não
conseguir IP, deixa o HeliPort aberto para você conectar manualmente.

## BrightnessMenu

O LaunchAgent está em `tools/brightness/local.brightnessmenu.plist` (instalado pelo
`tools/brightness/install.sh`).

## Não desative

`duetexpertd`, `spotlightknowledged` (+ `.updater`/`.importer`), `knowledge-agent`,
`knowledgeconstructiond`: o app **Apps** do Tahoe depende deles. Veja `docs/PERFORMANCE.md`.
