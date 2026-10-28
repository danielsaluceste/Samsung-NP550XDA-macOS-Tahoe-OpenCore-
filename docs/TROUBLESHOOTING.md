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
- Verifique `WhateverXe.kext` Enabled (o `WhateverGreen` foi removido do repo).
- Veja `docs/GRAPHICS.md`.

## Trackpad / I2C

### Trackpad sumiu depois de atualizar o VoodooI2C

A **2.9.1** (nov/2024) não carrega no Tahoe: o `VoodooGPIO`/`VoodooI2C` novos falham na injeção e
o trackpad não aparece no `hidutil`. Use a **2.8**, que é a versão fixada no repo:

```bash
# confira o que está carregado
kmutil showloaded --list-only | grep -i voodoo

# o esperado (2.8):
# com.alexandred.VoodooI2C (2.8)
# org.coolstar.VoodooGPIO (1.1)
# com.alexandred.VoodooI2CHID (1)
# me.kishorprins.VoodooInput (1.1.6)

# o trackpad deve aparecer como I2C
hidutil list | grep -i -E 'I2C|Touchpad'
```

Para voltar: substitua `EFI/OC/Kexts/VoodooI2C.kext` e `VoodooI2CHID.kext` pela 2.8 (backup
`RECOVERY/EFI-backup-0.5.0.tgz`/`EFI-OLD-0.5.0` do pendrive) e reinicie.

## Tela / display sleep

### A tela não acende ao mexer o mouse (Synergy)

O movimento sintético do Synergy **não** conta como atividade para o `IODisplayWrangler`: o cursor
mexe, mas o display fica em `CurrentPowerState = 1`. O painel acorda normalmente com
`caffeinate -u` (vai para 4), então é só o evento que não “cutuca”.

Solução instalada: `local.cursor-wake` (`/usr/local/bin/cursorwake`) lê **apenas a posição do
cursor** a cada 0,5 s e chama `IOPMAssertionDeclareUserActivity` quando ela muda. Não lê teclado nem
cliques e não impede o display de dormir.

```bash
launchctl list | grep cursor-wake
ps -Ao pid,pcpu,comm | grep cursorwake
pmset displaysleepnow        # tela apaga
# mexa o mouse do Synergy -> deve acender
ioreg -n IODisplayWrangler -r -w0 | grep CurrentPowerState   # 4 = acordado
```

## Apps / ícones

### O app Apps demora para mostrar as prévias/ícones

O app Apps abre a App Library no **Spotlight**, que renderiza pelo **RenderBox** do Tahoe. Como o
`archive.metallib` da Apple não tem código para GPU Intel, os shaders são compilados na hora
(`MTLCompilerService`) e o cache **não** vai para o disco. Medido: ~3 min de CPU na primeira vez
após o boot e ~10 s por abertura depois.

O repo instala `local.apps-warm` (pré-aquece no login, sem roubar foco) e `local.iconwarm` (aquece
os ícones das pastas de aplicativos). Para desligar o warm-up:

```bash
launchctl bootout gui/$(id -u)/local.apps-warm
launchctl bootout gui/$(id -u)/local.iconwarm
```

Não use `killall Spotlight` para “forçar”: com contexto de GPU ativo isso pode reiniciar a GPU e
derrubar o WindowServer.

## Mouse / Synergy

### Mouse lento, principalmente ao abrir apps

1. `local.synergy-priority` (LaunchDaemon) mantém `synergy-service` e `Synergy` com `renice -10` e
   latência alta. Confira:

   ```bash
   ps -Ao pid,nice,pri,comm | grep -i synergy
   # synergy-service / synergy-core devem estar com NI -10 (ou melhor)
   ```

2. Input lag do Tahoe: `defaults write -g NSAutoFillHeuristicControllerEnabled -bool false`
   (relogue para valer em todos os apps).
3. App Nap do Synergy: `defaults write com.symless.synergy NSAppSleepDisabled -bool YES`.
4. Use **Ethernet** para o Synergy quando possível; Wi-Fi (`itlwm`) adiciona latência.
5. O lag também aparece enquanto o RenderBox compila shaders (ver seção Apps). O warm-up no login
   reduz esse período.

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

### A interface do `itlwm` aparece como Ethernet, sem painel de Wi-Fi

Normal: `itlwm` não é AirPort. O número (`en0`/`en1`) pode mudar conforme a ordem de boot; descubra
pelo serviço com `networksetup -listnetworkserviceorder`. Veja `docs/WIFI-BLUETOOTH.md`.

### Wi-Fi lento ou sistema degradando

O HeliPort aberto vaza o WindowServer. Feche o HeliPort (`⌘Q`) ou use o one-shot. Verifique:

```bash
pgrep -x HeliPort
sudo log show --last 1m | grep -c '_CGXPackagesSetWindowConstraints'
```

### Não conecta sozinho no boot

- Preencha `WiFiConfig` no `Info.plist` do `itlwm`, **ou**
- use o agente one-shot do HeliPort. O agente descobre o dispositivo do serviço “Wi-Fi”; se você
  editou o script antigo que checava `en0` fixo, ele pode fechar o HeliPort cedo quando o Ethernet
  está conectado (o `en0` passa a ser o RTL8111). Use a versão atual de
  `tools/post-install/heliport-oneshot.plist`.

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
