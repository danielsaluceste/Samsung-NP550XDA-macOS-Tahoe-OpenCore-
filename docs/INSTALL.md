# Instalação

Este guia assume que você já tem o instalador do **macOS Tahoe 26.x** e um pendrive de 16 GB+.
O alvo é o **Samsung NP550XDA** (i5-1135G7 / Iris Xe). Outros Tiger Lake podem funcionar com ajustes.

> **Faça backup.** O processo apaga o disco de destino.

## 1. Criar o pendrive

### Opção A — `createinstallmedia` (a partir de um Mac)

```bash
diskutil list
# identifique o pendrive, ex.: /dev/disk2
sudo /Applications/Install\ macOS\ Tahoe.app/Contents/Resources/createinstallmedia \
  --volume /Volumes/MyUSB --nointeraction
```

### Opção B — `macrecovery` (sem Mac)

```bash
python3 macrecovery.py -b Mac-42FD25EABCABB274 -m 00000000000000000 download
# copie BaseSystem.dmg + BaseSystem.chunklist para a raiz do pendrive FAT32
```

O pendrive precisa ser **FAT32** (ou GPT + FAT32) com a pasta `EFI/` na raiz.

## 2. Copiar a EFI

Copie o conteúdo de `EFI/` deste repositório para a partição EFI do pendrive:

```
EFI/
├── BOOT/
│   └── BOOTx64.efi
└── OC/
    ├── OpenCore.efi
    ├── config.plist
    ├── ACPI/
    ├── Drivers/
    ├── Kexts/
    └── Resources/
```

## 3. Gerar seu SMBIOS (obrigatório)

O `config.plist` do repositório vem com **serial, MLB, UUID e ROM vazios**. Gere os seus com
[GenSMBIOS](https://github.com/corpnewt/GenSMBIOS):

- Modelo sugerido: **MacBookAir9,1** (Ice Lake, 4 núcleos) ou **MacBookPro16,2**.
- Preencha em `PlatformInfo > Generic`:
  - `SystemSerialNumber`
  - `MLB`
  - `SystemUUID`
  - `ROM` (MAC da Ethernet em formato `Data`, ou 6 bytes aleatórios)
- **Nunca** publique seus seriais. Não use os seriais de outra pessoa.

Se você não usa iServices (iMessage/FaceTime/App Store), pode deixar vazio para o primeiro boot.

## 4. BIOS

- Secure Boot: **Disabled**
- Fast Boot: **Disabled**
- CSM/Legacy: **Disabled**
- VT-d: **Disabled** (ou use `DisableIoMapper` no OpenCore)
- CFG Lock: **Disabled** (se existir)
- DVMT Pre-Allocated: **64 MB** (se existir)
- SATA/NVMe: **AHCI**
- Boot UEFI: **Enabled**

## 5. Boot e instalação

1. Boot pelo pendrive (tecla de boot do Samsung, geralmente `F10`/`F12`/`Esc`).
2. No picker do OpenCore, escolha o instalador.
3. Abra o **Utilitário de Disco**, formate o SSD em **APFS** (GUID).
4. Instale o macOS. O sistema reinicia algumas vezes; sempre boot pelo pendrive/EFI.
5. Depois de instalar, finalize o assistente (pode pular iCloud).

## 6. Pós-instalação (ESP interna)

Monte a EFI interna e copie a EFI:

```bash
diskutil list
sudo diskutil mount disk0s1
# copie EFI/ para /Volumes/EFI/
sudo diskutil unmount disk0s1
```

Ajuste a ordem de boot na BIOS para o **disco interno** primeiro.

### Áudio

- `SimpleHDA.kext` em `EFI/OC/Kexts`
- `Kernel > Add`: Lilu → AppleALC → SimpleHDA
- `DeviceProperties > PciRoot(0x0)/Pci(0x1F,0x3)`:
  - `layout-id` = `Data` `JgAAAA==` (layout 38)

### Brilho

Instale o **BrightnessMenu** (veja `docs/BRIGHTNESS.md` e `tools/brightness/`). Ele cria o ícone
`☀` e os atalhos `⌃⌥↑` / `⌃⌥↓`. As teclas Fn+F2/F3 não funcionam neste firmware.

### Bluetooth

- `IntelBluetoothFirmware.kext` — Enabled
- `IntelBTPatcher.kext` — Enabled
- `BlueToolFixup.kext` 2.7.2 — Enabled, **MaxKernel vazio**

### Wi-Fi

- `itlwm.kext` 2.3.0 — Enabled
- HeliPort 1.5.0 em `/Applications` (só para conectar; veja o one-shot)
- Wi-Fi nativo (menu do macOS) **não é possível** neste build — veja `docs/WIFI-BLUETOOTH.md`.

### Performance

Aplique o `tools/post-install/perf-tweaks.sh` (ou manualmente):

```bash
sudo pmset -a disksleep 0
sudo pmset -a hibernatemode 0
sudo pmset -a powernap 0
sudo pmset -a womp 0
sudo rm -f /var/vm/sleepimage
```

E **não** use `-wexdbg` nos boot-args.

## 7. Verificação rápida

```bash
# GPU
system_profiler SPDisplaysDataType | grep -E 'Chipset|Metal|Resolution|Online'
# Áudio
system_profiler SPAudioDataType | grep -E 'Built-in (Output|Microphone)'
# Bluetooth
system_profiler SPBluetoothDataType | grep -E 'State|Address|Firmware'
# Wi-Fi
ifconfig en0 | grep 'inet '
# CPU
sysctl -n machdep.cpu.brand_string
```

## 8. Se algo der errado

- Boot parado em `SMCRTC: Stop`: remova qualquer `IOSkywalkFamily.kext` injetado.
- Tela preta/WindowServer reiniciando: revise a stack do compilador (`docs/GRAPHICS.md`).
- Sem áudio: confira a ordem dos kexts e o `layout-id`.
- Sem Bluetooth: confira `BlueToolFixup` sem `MaxKernel`.
- Sem Wi-Fi: confira `itlwm` carregado e o HeliPort.

Mais em `docs/TROUBLESHOOTING.md`.
