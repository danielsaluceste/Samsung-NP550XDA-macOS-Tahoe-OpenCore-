# Samsung NP550XDA — macOS Tahoe 26.7.1 (OpenCore)

Hackintosh **funcional** no Samsung NP550XDA (Intel Tiger Lake) com **aceleração Metal**, áudio
interno, microfone, brilho, Bluetooth e Wi-Fi via `itlwm`. Documentação, EFI, kexts e ferramentas
usadas para chegar nesse estado.

> **Aviso:** instalar macOS em hardware que não é Apple viola o EULA da Apple e pode anular a
> garantia. Faça backup. Este repositório é educacional, sem garantias. Não inclua seus seriais
> de SMBIOS em repositórios públicos.
>
> macOS e Apple são marcas registradas da Apple Inc. Este projeto **não** é afiliado, patrocinado
> ou endossado pela Apple.

---

## Status

| Item | Estado | Observação |
|---|---|---|
| Boot | ✅ | OpenCore no ESP interno (`disk0s1`) |
| Gráficos / Metal | ✅ | Iris Xe `8086:9A49` com WhateverXe 0.6.1 + Graphics 0.3.2 |
| Painel eDP | ✅ | 1920×1080, interno, 30-bit (ARGB2101010) |
| Áudio | ✅ | ALC256 via SimpleHDA + AppleALC layout **38** |
| Microfone | ✅ | interno |
| Brilho | ✅ | BrightnessMenu (barra + atalhos), backlight real |
| Teclas Fn+F2/F3 | ❌ | firmware/EC; patches ACPI não resolveram |
| Wi-Fi | ⚠️ | `itlwm` + HeliPort (sem menu nativo/AirDrop) |
| Bluetooth | ✅ | AX201 com BlueToolFixup 2.7.2 |
| Ethernet | ✅ | Realtek RTL8111 (nativo) |
| Sleep/Wake | ⚠️ | **sistema não suspende** (trava na entrada); `sleep 0` e `displaysleep 0` (painel pode não voltar no 0.6.1) |
| AirDrop / Handoff | ❌ | depende de Wi-Fi nativo (AWDL) |
| iServices | ⚠️ | depende de SMBIOS/seriais válidos; não coberto |

---

## Hardware

| Componente | Modelo / ID |
|---|---|
| Notebook | Samsung NP550XDA |
| CPU | Intel Core i5-1135G7 (Tiger Lake, 4C/8T, 2.4–4.2 GHz) |
| iGPU | Intel Iris Xe Graphics `8086:9A49` |
| RAM | 16 GB DDR4 |
| SSD | Kingston SNVS500G (NVMe, 500 GB) |
| Wi-Fi | Intel Wi-Fi 6 AX201 `8086:A0F0` (CNVi) |
| Bluetooth | Intel AX201 (USB, mesmo módulo) |
| Áudio | Realtek ALC256 (`10EC:0256`), HDA |
| Ethernet | Realtek RTL8111 |
| Painel | BOE 1920×1080 eDP |
| BIOS | UEFI, sem Secure Boot |

macOS instalado: **Tahoe 26.7.1 (25G241)**.

### Versões dos kexts (estado validado em 2026-10-27)

| Kext | Versão | Observação |
|---|---|---|
| WhateverXe | **0.6.1** | release; `-wexdbg` não usado |
| WhateverXe Graphics | **0.3.2** | `AppleIntelTGLCompat` 0.6.1 + MTL/GL/VA |
| Lilu | 1.7.2 | |
| VirtualSMC + SMCProcessor/SMCSuperIO/SMCLightSensor/SMCBatteryManager | **1.3.8** | todos na mesma versão |
| AppleALC | **1.9.8** | layout 38 |
| SimpleHDA | 1.0.0 | substitui o AppleHDA removido no 26 |
| BlueToolFixup | 2.7.2 | `MaxKernel` **vazio** |
| itlwm | 2.3.0 | + HeliPort one-shot |
| VoodooI2C / VoodooI2CHID | **2.8** / 1.0 | **fixado**: a 2.9.1 não carrega no Tahoe (ver TROUBLESHOOTING) |
| VoodooPS2Controller | 2.3.7 | teclado interno |
| CPUFriend (+DataProvider) | 1.3.0 / 1.0.1 | |
| RestrictEvents | 1.1.6 | nome da CPU |

Kexts **removidos** por não terem hardware/uso: `CtlnaAHCIPort` (sem SATA), `EmeraldSDHC` (sem
leitor SD), `HoRNDIS` (sem tethering USB), `EFICheckDisabler`, `WhateverGreen`, `NootedBlue`,
`DisplayMergeNub`, `XHCI-unsupported`, `USBMap`, `BrightnessKeys`, `AirportItlwm*`,
`AirportBrcmFixup`, `BrcmFirmwareData`, `BrcmPatchRAM3`, `IOSkywalkFamily`,
`IO80211FamilyLegacy` e `IntelBluetoothInjector`.

---

## O que tem neste repositório

```
EFI/                     EFI do OpenCore (sanitizada; veja EFI/README.md)
docs/                    documentação detalhada
  HARDWARE.md            specs, PCI IDs, ACPI e BIOS
  INSTALL.md             passo a passo de instalação
  GRAPHICS.md            WhateverXe + stack de compilador Metal
  AUDIO.md               SimpleHDA + AppleALC layout 38
  BRIGHTNESS.md          BrightnessMenu e backlight
  WIFI-BLUETOOTH.md      itlwm/HeliPort e AX201
  PERFORMANCE.md         correções de lentidão medidas
  TROUBLESHOOTING.md     problemas comuns
  REFERENCES.md          links e créditos
  SOLUTION-TECHNICAL.md  log técnico completo (sanitizado)
tools/
  brightness/            código do BrightnessMenu (Objective-C)
  compiler/              adapter + bridge + scripts do compilador Metal
  diagnostics/           vtcheck, randread, displayinfo, gpu_load, btscan
  post-install/          scripts de pós-instalação (sem senhas)
  efi/                   exporta/sanitiza o EFI da máquina funcionando
screenshots/             espaço para capturas de tela
```

> A `EFI/` incluída foi gerada com `tools/efi/export-efi.sh`, que remove seriais/MLB/UUID/ROM e
> credenciais de Wi-Fi. **Gere seu próprio SMBIOS** antes de usar iServices. Se quiser regenerar:
> `bash tools/efi/export-efi.sh /dev/disk0s1`.

---

## Pré-requisitos

- Um pendrive de 16 GB+ para o instalador.
- macOS Tahoe 26.x (instalador oficial) ou uma máquina para criá-lo.
- Acesso ao BIOS/UEFI.
- OpenCore (incluído em `EFI/` após a exportação; veja `EFI/README.md`).
- Paciência: hackintosh em Tiger Lake exige ajustes de GPU/compilador.

### BIOS (configuração típica)

- **Secure Boot: Disabled**
- **Fast Boot: Disabled**
- **CSM/Legacy: Disabled** (UEFI only)
- **VT-d: Disabled** (ou `DisableIoMapper` no OpenCore)
- **CFG Lock: Disabled** (se a opção existir)
- **DVMT Pre-Allocated: 64 MB** (se a opção existir)
- **SATA/NVMe: AHCI**
- **Network boot: Disabled**

Os nomes variam por BIOS; o importante é boot UEFI, sem Secure Boot e sem CSM.

---

## Instalação (resumo)

O passo a passo completo está em [`docs/INSTALL.md`](docs/INSTALL.md). Resumo:

1. Crie o pendrive com o instalador do macOS (`createinstallmedia` ou `macrecovery`).
2. Copie `EFI/` para a partição EFI do pendrive.
3. **Gere seu SMBIOS** (GenSMBIOS) e preencha `PlatformInfo > Generic` no `config.plist`.
   O `config.plist` do repositório vem com serial/MLB/UUID/ROM **vazios**.
4. Boot pelo pendrive, formate o SSD em APFS e instale.
5. Copie a EFI para o ESP interno (`disk0s1`), monte com `diskutil` e ajuste a ordem de boot.
6. Aplique o pós-instalação (áudio, brilho, Bluetooth, Wi-Fi, performance).

Boot-args usados:

```
npci=0x2000 keepsyms=1 -amfipassbeta -no_compat_check -allow3d -disablegfxfirmware
-igfxcdc gfxrst=1 msgbuf=1048576 -v
```

> `-wexdbg` **não** é usado: em build RELEASE ele só gera log e deixa o sistema mais lento.

---

## Pós-instalação

### Áudio (ALC256)

A Apple **removeu o `AppleHDA.kext` no macOS 26**. A solução é o **SimpleHDA 1.0.0** (plugin do
Lilu) + AppleALC:

- `SimpleHDA.kext` em `EFI/OC/Kexts`
- Ordem em `Kernel > Add`: **Lilu → AppleALC → SimpleHDA**
- `layout-id` = **38** (`Data`, base64 `JgAAAA==`) em
  `DeviceProperties > PciRoot(0x0)/Pci(0x1F,0x3)`

Verificação:

```bash
system_profiler SPAudioDataType | grep -E 'Built-in (Output|Microphone)'
```

Detalhes: [`docs/AUDIO.md`](docs/AUDIO.md).

### Brilho

O painel responde ao parâmetro `bklt` do `AppleBacklightDisplay`, mas o CoreBrightness não o
considera controlável (`DisplayServicesCanChangeBrightness = 0`). Por isso o **BrightnessMenu**:

- ícone `☀ NN%` na barra de menus;
- atalhos **⌃⌥↑ / ⌃⌥↓** (Carbon, sem ler o teclado);
- 25/50/75/100%;
- inicia no login via LaunchAgent.

Código e build em [`tools/brightness`](tools/brightness). Detalhes: [`docs/BRIGHTNESS.md`](docs/BRIGHTNESS.md).

### Nome do processador

Para aparecer **Intel Core i5-1135G7** em “Sobre Este Mac” (em vez de um nome genérico), use o
RestrictEvents:

```
NVRAM > Add > 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102
  revcpu     = 1
  revcpuname = Intel Core i5-1135G7
  revpatch   = sbvmm,cpuname
```

O `ProcessorType = 1537 (0x601)` está correto para CPUs de 4 núcleos; não mude.

### Bluetooth (AX201)

O `BlueToolFixup.kext` **2.7.2** é o que tem patches para o macOS 26. No `config.plist` ele precisa
estar **sem `MaxKernel`** (ou `25.99.99`), senão não carrega:

```
IntelBluetoothFirmware.kext   (Enabled)
IntelBTPatcher.kext           (Enabled)
BlueToolFixup.kext            (Enabled, MinKernel 21.0.0, MaxKernel vazio)
```

Verificação:

```bash
kextstat | grep -E 'BlueTool|IntelBluetooth'
system_profiler SPBluetoothDataType | grep -E 'State|Address|Firmware'
```

### Wi-Fi (itlwm)

Wi-Fi **nativo** (menu do macOS) não é possível neste build: o `IOSkywalkFamily.kext` do
26.7.1 é **codeless** e o `AirportItlwm` depende dele; injetar o kext antigo trava o boot em
`SMCRTC: Stop`. A solução é `itlwm` + HeliPort.

- `itlwm.kext` 2.3.0 em `EFI/OC/Kexts`
- HeliPort 1.5.0 em `/Applications`
- **HeliPort só conecta**: o `itlwm` mantém a conexão. O HeliPort 1.5.0 tem um vazamento de
  memória no WindowServer no Tahoe (`_CGXPackagesSetWindowConstraints: Invalid window` a cada 2 s).
  Use o agente `tools/post-install/heliport-oneshot.plist` para abrir, conectar e **fechar** o HeliPort.
- Para auto-conectar sem HeliPort, preencha `WiFiConfig` no `Info.plist` do `itlwm` com seu
  SSID/senha (veja [`docs/WIFI-BLUETOOTH.md`](docs/WIFI-BLUETOOTH.md)).

### Performance

Correções aplicadas (medidas, veja [`docs/PERFORMANCE.md`](docs/PERFORMANCE.md)):

- adapter do compilador **oficial do Graphics 0.3.2** (release, sem `usleep(250ms)` por shader e sem
  dump no log); o adapter custom antigo continua em `adapter-wex.dylib` como fallback;
- `-wexdbg` removido;
- **warm-up no login** (`local.apps-warm` + `local.iconwarm`): o Tahoe compila os shaders do
  RenderBox/App Library no `MTLCompilerService` porque não há código para GPU Intel; o pré-aquece
  evita pagar ~3 min na primeira abertura do Apps (custo: carga alta por alguns minutos no login);
- **Synergy**: `local.synergy-priority` (`renice -10` + latência alta), App Nap desligado e
  `NSAutoFillHeuristicControllerEnabled=false` (input lag do Tahoe);
- **wake do display**: `local.cursor-wake` declara atividade quando o cursor muda — o movimento
  sintético do Synergy sozinho não acorda o `IODisplayWrangler`;
- HeliPort sem ficar aberto (vazamento do WindowServer);
- `disksleep 0` e `hibernatemode 0` (SSD sem DRAM);
- `displaysleep 0`: o painel pode apagar e não voltar no stack 0.6.1/Compat 0.6.1 (link eDP);
  com `sleep 0`, o notebook fica ligado até você desligar/reiniciar;
- `mediaanalysisd`/`photoanalysisd` desativados;
- **não** desativar `duetexpertd`/`spotlightknowledged`: o app **Apps** (App Library do Tahoe)
  depende deles, senão a lista fica vazia.

---

## Limitações conhecidas

- **Wi-Fi nativo/AirDrop/Handoff/Continuity**: não. `itlwm` não é AirPort.
- **Teclas Fn+F2/F3 de brilho**: o DSDT/EC só notifica o EC; patches ACPI não mudaram nada.
- **VP9/AV1 por hardware**: o Tiger Lake não decodifica; YouTube no Chrome usa CPU. Use Safari ou
  force H.264.
- **App Library (app Apps)**: o RenderBox do Tahoe não tem shaders pré-compilados para GPU Intel;
  a primeira abertura após o boot paga ~3 min de CPU e as seguintes ~10 s (o cache não vai para o
  disco). O `local.apps-warm` pré-aquece no login para reduzir isso.
- **Input lag do Tahoe**: corrigido com `NSAutoFillHeuristicControllerEnabled=false`; o Synergy
  ainda pode ficar lento enquanto o WindowServer está ocupado compilando shaders.
- **Sleep do sistema**: trava na entrada (`Failure 0x1F`, EFI/Bootrom). Testados e descartados: `hibernatemode 0`, `hibernatemode 25`, remoção do `SSDT-S3`, Bluetooth desligado, patches USB (`SSDT-RHUB`, `SSDT-USBW`, `USBWakeFixup`) e o par `SSDT-GPRW`/`GPRW→XPRW`. Todos travam na entrada. Restam WEX/GPU (sleep/wake **não verificado** no TGL; `AppleIntelFramebuffer` slow no log) e `itlwm`. Use `sleep 0` (padrão do repo) e desligue/reinicie; o **display sleep** funciona.
- **VoodooI2C 2.9.1**: não carrega no Tahoe (`VoodooGPIO`/`VoodooI2C` novos falham na injeção e o
  trackpad some). O repo fixa a **2.8**, que funciona.
- **iServices**: exigem SMBIOS/seriais válidos e únicos; não distribua os seus.
- **Painel 30-bit**: o EDID declara 10-bit; não há opção segura para forçar 24-bit.

---

## Solução de problemas (resumo)

| Sintoma | Verifique |
|---|---|
| Tela preta / WindowServer reiniciando | stack `xe.bundle`, symlinks `libigc-tgl.dylib`/`runtime.igc64.bc`, adapter |
| Trackpad sumiu após atualizar kext | `VoodooI2C` 2.9.1 não carrega no Tahoe; volte para **2.8** |
| Apps demora a mostrar ícones | RenderBox sem shader Intel; use o `local.apps-warm` (login) |
| Tela não acende com o mouse do Synergy | `local.cursor-wake` (declara atividade ao mover o cursor) |
| Mouse lento com Synergy | veja prioridade/App Nap/autofill em `docs/TROUBLESHOOTING.md` |
| Boot para em `SMCRTC: Stop` | você injetou `IOSkywalkFamily`; remova |
| Sem áudio | ordem Lilu→AppleALC→SimpleHDA e `layout-id` 38 |
| Sem brilho | `bklt` via BrightnessMenu; `DisplayServicesCanChangeBrightness` é 0 |
| Sem Bluetooth | `BlueToolFixup` sem `MaxKernel`; `IntelBluetoothFirmware` carregado |
| Wi-Fi cai/lento | HeliPort aberto? vazamento; use o one-shot |
| Apps.app vazio | `duetexpertd`/`spotlightknowledged` desativados; reative e limpe o cache ATX |
| Sistema lento | `XE_ADAPTER_DUMP`, `-wexdbg`, HeliPort aberto, `disksleep` |

Detalhes: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

---

## Referências

- [OpenCorePkg](https://github.com/acidanthera/OpenCorePkg)
- [Dortania — OpenCore Install Guide](https://dortania.github.io/OpenCore-Install-Guide/)
- [WhateverXe](https://github.com/b00t0x/WhateverXe)
- [itlwm / HeliPort](https://github.com/OpenIntelWireless/itlwm) · [HeliPort](https://github.com/OpenIntelWireless/HeliPort)
- [IntelBluetoothFirmware](https://github.com/OpenIntelWireless/IntelBluetoothFirmware)
- [BrcmPatchRAM (BlueToolFixup)](https://github.com/acidanthera/BrcmPatchRAM)
- [RestrictEvents](https://github.com/acidanthera/RestrictEvents)
- [Lilu](https://github.com/acidanthera/Lilu) · [VirtualSMC](https://github.com/acidanthera/VirtualSMC) · [AppleALC](https://github.com/acidanthera/AppleALC)
- [SimpleHDA](https://github.com/laobamac/SimpleHDA)
- [VoodooI2C](https://github.com/VoodooI2C/VoodooI2C) · [VoodooPS2](https://github.com/acidanthera/VoodooPS2)
- [USBToolBox](https://github.com/USBToolBox/tool) · [GenSMBIOS](https://github.com/corpnewt/GenSMBIOS)
- [OpenIntelWireless docs](https://openintelwireless.github.io/)

Lista completa e créditos: [`docs/REFERENCES.md`](docs/REFERENCES.md).

---

## Licença

O código próprio deste repositório (scripts, BrightnessMenu, adapter/bridge, documentação) está
sob **MIT** — veja [`LICENSE`](LICENSE). Kexts, OpenCore e binários de terceiros mantêm suas
licenças originais; veja [`THIRD-PARTY.md`](THIRD-PARTY.md).

## Créditos

- Acidanthera (OpenCore, Lilu, VirtualSMC, AppleALC, RestrictEvents, BrcmPatchRAM, VoodooPS2)
- b00t0x / WhateverXe
- OpenIntelWireless (itlwm, HeliPort, IntelBluetoothFirmware)
- laobamac (SimpleHDA)
- VoodooI2C
- Toda a comunidade hackintosh

Se este repositório te ajudou, deixe uma ⭐.
