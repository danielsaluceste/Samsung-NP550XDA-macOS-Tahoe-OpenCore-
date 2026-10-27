# Troubleshooting

## Boot

### Boot para em `SMCRTC: Stop`

Você injetou `IOSkywalkFamily.kext` (ou outro kext de Wi-Fi) tentando habilitar Wi-Fi nativo.
Remova a entrada em `Kernel > Add` e desabilite o kext. O boot volta.

### Picker do OpenCore não aparece

- Confirme `EFI/BOOT/BOOTx64.efi` e `EFI/OC/OpenCore.efi`.
- BIOS: UEFI only, Secure Boot off, CSM off.
- Pendrive em FAT32 com `EFI/` na raiz.

### Kernel panic no WhateverXe

Use build **RELEASE**. Builds DEBUG do WEX dão panic. Confirme também os boot-args
(`-allow3d -disablegfxfirmware`).

## Sleep / tela preta ao dormir

Sintoma: ao entrar em suspensão, a tela apaga e o sistema **congela** (LED aceso, sem resposta).
No próximo boot, `pmset -g log` mostra:

```
Failure during sleep: 0x0000001F : EFI/Bootrom Failure after last point of entry to sleep
```

Causa: a transição S3/S4 não completa. O README do WhateverXe declara **sleep/wake não
verificado** no Tiger Lake. Testados e descartados: `hibernatemode 0`, `hibernatemode 25`,
remoção do `SSDT-S3`, Bluetooth desligado, patches USB (`SSDT-RHUB`, `SSDT-USBW`,
`USBWakeFixup`) e o par `SSDT-GPRW`/`GPRW→XPRW`. Restam WEX/GPU e `itlwm`.

Workaround (padrão do repo):

```bash
sudo pmset -a sleep 0
sudo pmset -a standby 0
sudo pmset -a autopoweroff 0
sudo pmset -a hibernatemode 0
```

O **display sleep** continua funcionando (`displaysleep 2/10`). Use desligar/reiniciar em vez de
dormir.

## Gráficos

### Tela preta / WindowServer reiniciando em loop

1. Confirme que `/System/Library/Caches/xe.bundle` existe e tem os dylibs.
2. Confirme os symlinks:

```bash
ls -l /Library/GPUBundles/XeCompilerAdapter.bundle/Contents/MacOS/
# libigc-tgl.dylib -> /System/Library/Caches/XeCompiler/libigc-tgl.dylib
# runtime.igc64.bc -> /System/Library/Caches/XeCompiler/runtime.igc64.bc
```

3. Confirme o `adapter.dylib` (sha) e o backup `adapter-wex.dylib`.
4. Teste `~/metal_test2`.

### “Metal: unsupported” / sem aceleração

- Verifique `-allow3d` e `-disablegfxfirmware`.
- Verifique `WhateverXe.kext` Enabled e `WhateverGreen.kext` **Disabled**.
- Veja `docs/GRAPHICS.md`.

## Áudio

### Sem saída/entrada

- `SimpleHDA.kext` Enabled, `MinKernel 25.0.0`.
- Ordem Lilu → AppleALC → SimpleHDA.
- `layout-id` = `Data` `JgAAAA==` (38).
- `system_profiler SPAudioDataType`.

### Áudio sai no HDMI em vez do interno

Remova/ajuste as entradas de áudio HDMI no `DeviceProperties` ou selecione “Built-in Output” em
Ajustes → Som.

## Brilho

### Slider do Control Center não existe

Normal neste build (`DisplayServicesCanChangeBrightness = 0`). Use o **BrightnessMenu**.

### BrightnessMenu não abre

```bash
pkill -x BrightnessMenu
open -a /Applications/BrightnessMenu.app
```

Se crashar, confira se foi compilado com `-fobjc-arc` (o `g_item` precisa de ARC).

### Fn+F2/F3 não fazem nada

Limitação de firmware/EC. Veja `docs/BRIGHTNESS.md`.

## Wi-Fi

### `en0` aparece como Ethernet, sem painel de Wi-Fi

Normal: `itlwm` não é AirPort. Veja `docs/WIFI-BLUETOOTH.md`.

### Wi-Fi lento ou sistema degradando

O HeliPort aberto vaza o WindowServer. Feche o HeliPort (`⌘Q`) ou use o one-shot. Verifique:

```bash
pgrep -x HeliPort
sudo log show --last 1m | grep -c '_CGXPackagesSetWindowConstraints'
```

### Não conecta sozinho no boot

- Preencha `WiFiConfig` no `Info.plist` do `itlwm`, **ou**
- use o agente one-shot do HeliPort.

## Bluetooth

### `State: Off`, `Firmware v0 c0`

`BlueToolFixup` não carregou. Confirme:

```bash
kextstat | grep BlueTool
```

Se vazio, o `MaxKernel` está limitando. Deixe **vazio** (ou `25.99.99`).

### Pareia mas não conecta

- Remova o dispositivo e pareie de novo.
- Verifique `BlueToolFixup` 2.7.2 e `IntelBluetoothFirmware` 2.5.0.
- Teste com outro dispositivo (fone/mouse).

## Apps.app vazio

Você desativou `duetexpertd`/`spotlightknowledged`. Reative:

```bash
launchctl enable gui/$(id -u)/com.apple.duetexpertd
launchctl enable gui/$(id -u)/com.apple.spotlightknowledged
launchctl enable gui/$(id -u)/com.apple.spotlightknowledged.updater
launchctl enable gui/$(id -u)/com.apple.spotlightknowledged.importer
launchctl enable gui/$(id -u)/com.apple.knowledge-agent
launchctl enable gui/$(id -u)/com.apple.knowledgeconstructiond
rm -rf ~/Library/Caches/com.apple.duetexpertd
launchctl kickstart -k gui/$(id -u)/com.apple.duetexpertd
killall Dock
```

## Lentidão

Ordene a investigação:

1. `-wexdbg` nos boot-args? Remova.
2. `XE_ADAPTER_DUMP=1` no ambiente? Remova.
3. HeliPort aberto? Feche.
4. `disksleep` > 0? `sudo pmset -a disksleep 0`.
5. `hibernatemode 3`? `sudo pmset -a hibernatemode 0`.
6. `mediaanalysisd`/`photoanalysisd` rodando? Desative.
7. `sudo log show --last 5m | grep -c xe-dump` deve ser 0.

## Instalador / USB

- `hdiutil attach` por SSH trava; instale DMG pela interface gráfica.
- `screencapture` por SSH falha; valide pela tela.
- `createinstallmedia` exige o instalador completo em `/Applications`.

## Comandos úteis

```bash
# EFI
diskutil list
sudo diskutil mount disk0s1

# GPU
system_profiler SPDisplaysDataType | grep -E 'Chipset|Metal|Resolution|Online'

# Áudio
system_profiler SPAudioDataType | grep -E 'Built-in (Output|Microphone)'

# Bluetooth
system_profiler SPBluetoothDataType | grep -E 'State|Address|Firmware'

# Wi-Fi
ifconfig en0 | grep -E 'inet |status'

# CPU
sysctl -n machdep.cpu.brand_string

# Logs
sudo log show --last 5m --style compact | grep -i -E 'xe-adapter|WindowServer|BlueTool'
```
