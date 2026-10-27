# macOS Tahoe 26.7.1 no Samsung NP550XDA (i5-1135G7 / Iris Xe 9A49) — aceleração funcionando

Data: 2026-10-24
Hardware: Samsung NP550XDA, Intel Core i5-1135G7 (Tiger Lake), iGPU 8086:9A49 (Iris Xe 80 EU),
painel BOE NT156FHM-N61 1920x1080 eDP.

## Estado final

- macOS Tahoe 26.7.1 (build 25G241), Metal 2, 1536 MB VRAM, painel interno 1920x1080
  (`Connection Type: Internal`, `Online: Yes`, `Framebuffer Depth: 30-Bit Color`).
- WindowServer estável; Dock/Finder com composição acelerada.
- WhateverXe 0.5.0 (kernel) + WhateverXe Graphics 0.2.0 (pacote) + AMFIPass 1.4.1 **Mod**.

## Cadeia de diagnóstico (o que era o quê)

1. **A eDP nunca foi o problema.** Todos os patches do WEX aplicavam
   (`WEXDBGStart` = surf/nvram/irq/probe/fbinit/dekel/topo/panelpw/edp = 1, hdmi/gmbus = 0).
   O framebuffer fechava modeset com o clock real do painel (148,51 MHz). Os 20 avisos
   `Unsupported DDI` são um único burst no bringup, para as portas HDMI não usadas.

2. **`FB0: Flip called without enabling VBL` era sintoma**, não causa: o WindowServer abria e
   morria em loop por falha de compilação Metal, e cada ciclo religava/desligava o display.

3. **Causa raiz #1 (Metal não compilava): sandbox do MTLCompilerService.**
   O perfil `/System/Library/Sandbox/Profiles/com.apple.mtlcompilerservice.sb` só permite
   `file-read*` em `/System` e `file-map-executable` em `/System/Library`;
   `/Library/GPUBundles` só é liberado quando `system-attribute apple-internal`.
   Por isso o serviço negava `libigc-tgl.dylib` e `runtime.igc64.bc`
   (`Sandbox: deny(1) file-read-data ...`), e o adapter do WEX falhava.
   **Solução:** `/System/Library/Caches` é um firmlink gravável cujo caminho conta como
   `/System/Library` para o sandbox — o stack de compilador vai para lá.

4. **Causa raiz #2 (Core Animation): ABI do plugin de compilador mudou no Tahoe.**
   Mesmo com o Metal "comum" compilando, o pipeline do Core Animation
   (spec `Pl64rXb_TdfgXhf_Isrc`) falhava com
   `COREANIMATION "Xe compiler unsupported bitcode layout"` — o adapter do WEX rejeita o
   bitcode que o CA envia. **Solução:** stack de compilador do projeto
   `JulioNectar/Hackintosh-XPS13Plus-IrisXe-Tahoe` (adapter + LLVM bridge), que faz o parse
   do bitcode com o LLVM do Tahoe (GPUCompiler 32023) e re-serializa no formato antigo (3902)
   antes de entregar ao plugin IGC 16.0.32.

## Configuração aplicada

### EFI / OpenCore
- `boot-args`: `npci=0x2000 keepsyms=1 -amfipassbeta -no_compat_check -allow3d
  -disablegfxfirmware -igfxcdc gfxrst=1 msgbuf=1048576 -v`
- `csr-active-config` = `0x813` (0x803 + bit apple-internal; o bit não é honrado pelo booter,
  mas não atrapalha). O valor recomendado pelo WEX é `0x803`.
- Kexts relevantes em `EFI/OC/Kexts`: Lilu 1.7.2, **AMFIPass 1.4.1 Mod**
  (sha256 `2d36aeca…`), **WhateverXe 0.5.0** (sha256 `b89521d1…`), demais kexts usuais.
- WhateverGreen **desabilitado** (não pode coexistir com o WhateverXe).
- EFI também no ESP interno (`disk0s1`), boot sem pendrive.

### WhateverXe Graphics 0.2.0
- Instalado pelo `.pkg` oficial (`sudo installer -pkg WhateverXe-Graphics-0.2.0.pkg -target /`),
  recibos `org.b00t0x.WhateverXe.Common` + `org.b00t0x.WhateverXe.Tahoe`, AuxKC reconstruída.
- `CoreMedia / AllowOnePassMetalScaling = false` (feito pelo postinstall).

### Stack de compilador (`/System/Library/Caches/xe.bundle`)
Construído a partir do fonte do repo XPS + binários Apple 16.0.32 do NootedGreen:
- `libMTLIGCCompilerPlugin.dylib` — adapter (compilado de `macos/src/compiler-adapter.cpp`)
- `libMTLIGCCompilerPluginOld.dylib` — plugin Apple 16.0.32, patchado por
  `macos/plugin-old-patches.json` (caminhos → `xe.bundle`, `isPoshEnabled` → false)
- `libLLVMbridge.dylib` — ponte LLVM (compilada de `macos/src/llvm-bridge.cpp`)
- `libigc.dylib`, `libigcHSW.dylib`, `libIGIL-Metal.dylib`, `libISAProfilerDyn.dylib`
- `Resources/runtime.igc64.split`, `runtime.igcHSW64.split`, `runtime.gpuencode.split`
- Tudo `root:wheel`, assinado ad-hoc.

O adapter final é copiado sobre
`/Library/GPUBundles/XeCompilerAdapter.bundle/Contents/MacOS/adapter.dylib`
(sha256 `7f91159b…`); o adapter original do WEX fica guardado como `adapter-wex.dylib`.
O caminho declarado pelo driver já começa com `/Library/GPUBundles/`, o prefixo que o
`MTLCompilerPluginInterface` aceita, então não é preciso patch no MTLDriver.

### Observações
- O LLVM do Tahoe **não existe como arquivo**: `dlopen` do caminho
  `/System/Library/PrivateFrameworks/GPUCompiler.framework/Versions/32023/Libraries/libLLVM.dylib`
  resolve pelo dyld shared cache; o `.tbd` usado no link lista só os símbolos C necessários.
- Assinatura ad-hoc exige `AMFIPass` Mod (ou `amfi_get_out_of_my_way=1`) e SIP sem kext signing.
- Fora do escopo desta entrega: Wi-Fi (AirportItlwm), brilho (SSDT-PNLF), áudio, sleep.

## Áudio no Tahoe 26.7.1 (25G241)

- O codec é **Realtek ALC256 em HDA** (confirmado no Linux live: `snd_hda_intel`,
  pins 0x14 speaker, 0x21 fone, 0x12 mic interno, 0x19 mic jack; subsystem `144d:c195`).
  O `10EC1308` do DSDT pertence ao caminho SST alternativo que esta placa não usa.
- **Causa raiz**: a Apple **removeu o `AppleHDA.kext` no macOS 26** (Tahoe). Sem ele não existe
  `AppleHDAController`, então AppleALC não tem o que patchear — nenhum `layout-id` resolve.
- **Solução sem reinstalar nada**: **SimpleHDA 1.0.0** (laobamac), plugin do Lilu injetado pelo
  OpenCore que restaura o stack do AppleHDA em memória.
  - `SimpleHDA.kext` em `EFI/OC/Kexts`, `Kernel > Add` na ordem **Lilu → AppleALC → SimpleHDA**
    (`MinKernel 25.0.0`, `MaxKernel 25.99.99`).
  - `layout-id` = **38** (Samsung Galaxy Book, ALC256) em `DeviceProperties` do
    `PciRoot(0x0)/Pci(0x1F,0x3)` como **Data** (`JgAAAA==`).
  - `keepsyms=1` já estava nos boot-args ✓.
  - Resultado: `AppleHDAController` anexa, codec `0x10EC0256` detectado,
    `Built-in Output` (default) e `Built-in Microphone` (default).

## Brilho

- O backlight é PWM do iGPU (`intel_backlight`, max **96000** no Linux) e o hardware responde:
  escrever o parâmetro `bklt` via IOKit muda a luminância de fato.
- Porém o **CoreBrightness não considera o display controlável**
  (`DisplayServicesCanChangeBrightness = 0`), porque o serviço expõe apenas `bklt` e não o
  parâmetro `brightness`. Consequências: sem slider no Control Center e teclas de brilho inertes.
- Solução adotada: **BrightnessMenu.app** (barra de menus, código em
  `phase2/work/BrightnessMenu3.m`), que fala direto com o `AppleBacklightDisplay` via
  `IODisplaySetFloatParameter("bklt")`:
  - ícone `☀ NN%` na barra, com 25/50/75/100% e passos finos;
  - atalhos globais **⌃⌥↑ / ⌃⌥↓** (Carbon hotkeys — não exigem permissão);
  - **não** lê o teclado (sem Input Monitoring), para poder ser publicado;
  - inicia no login via `~/Library/LaunchAgents/local.brightnessmenu.plist`.
- Teclas **Fn+F2/F3**: o DSDT usa `_Q63/_Q64 → BRTN(0x87/0x86)` condicionado a
  `!GFX0.PDRD()` e a `DIDX/DIDY`; patches ACPI para forçar a notificação foram testados e
  **revertidos** (não produziram mudança de brilho, pois o caminho final continua sendo o
  CoreBrightness). Sem efeito prático.

## Desempenho (2026-10-26)

Sintoma: "às vezes é meio lento para carregar algo". Diagnóstico medido, não chute.

**Causa raiz nº 1 — o adapter do compilador estava em modo debug.**
O `compiler-adapter.cpp` usado para fechar a ABI do Tahoe tinha, por instrumentação:

```c
if (seq) usleep(250000);              // 250 ms por shader, nos 40 primeiros
xe_dump("bc", seq, bc, bcSize);       // bitcode inteiro em base64 no log
xe_dump("reply", seq, rp, rn);        // resposta inteira em base64 no log
```

Medição antes (16 min de uptime): **29.114 linhas `xe-dump` / 22,4 MB** no log unificado e
**978 compilações Metal**. Cada `MTLCompilerService` pagava até 40 × 250 ms = **10 s** de
espera artificial, mais o custo de escrever 22 MB no disco.

Correção: dump virou opt-in (`XE_ADAPTER_DUMP=1`) e o `usleep` foi removido; a contenção de
crash do `libigc` e o helper de ICB continuam. Build novo:
`xe.bundle.tgz` sha256 `bf6240f8db4dafe867ad2527f0149e1b6dd8116e607d028d20928da7492e4a99`.
Depois do boot: **0 linhas `xe-dump`**.

**Causa raiz nº 2 — `-wexdbg`.** O WhateverXe em build RELEASE não precisa dele; gerava
~2.700 linhas de log a cada 16 min. Removido dos `boot-args`.

**Causa raiz nº 3 — vazamento do WindowServer causado pelo HeliPort 1.5.0.**
Sintoma medido: o RSS do `WindowServer` subia ~10 MB a cada 30 s (**~20 MB/min, 1,2 GB/hora**) e
chegou a **1,4 GB**. `vmmap`/`footprint` mostraram `MALLOC_LARGE` de 1,0 GB em 13.478 regiões.
O log repetia, a cada 2 s:

```
WindowServer[...] _CGXPackagesSetWindowConstraints: Invalid window
```

A causa é o **HeliPort 1.5.0** (última versão, de 2024): ele chama `SetWindowConstraints` numa
janela inválida a cada ~2 s, e o WindowServer aloca e não libera. Teste isolado: fechar o HeliPort
fez os erros caírem de **15/30 s para 0** e o RSS parar de crescer na hora (1299 → 1299 MB).

Correção adotada (sem perder o Wi-Fi): o `itlwm` mantém a associação sozinho; o HeliPort só é
necessário para conectar. Removido dos login items e substituído por um agente one-shot:

`~/Library/LaunchAgents/local.heliport-oneshot.plist` → abre o HeliPort no login, espera até 30 s
por IPv4 em `en0`, e então **fecha** o HeliPort. Se não conseguir IP, **não fecha** (fallback para
o usuário conectar manualmente). A memória já vazada só é devolvida com reboot/logout.

> Observação para publicar: o vazamento é do HeliPort no Tahoe, não do `itlwm`. Alternativa
> definitiva é gravar SSID/senha em `WiFiConfig` no `Info.plist` do `itlwm` e não usar HeliPort.

Validação pós-reboot (com o agente one-shot):
`ws=194 → 271 → 357 → 436 → 483 → 633 → 687 → 687 → 687 → 687 → 688 → 704 MB`
em ~6 min — ou seja, **platô em ~690 MB**, sem crescimento linear; `_CGXPackagesSetWindowConstraints`
= **0/60 s** na janela final. Antes, sem o one-shot, crescia ~10 MB/30 s indefinidamente.

**Outras limpezas aplicadas**

- `BrightnessKeys.kext` desabilitado (`Kernel > Add` índice 42): não é mais usado (as teclas Fn
  não funcionam) e era um kext ligado a input.
- `~/Library/LaunchAgents/com.wex.mtlcompiler.plist` removido: declarava um MachService
  `com.apple.MTLCompilerService` duplicado no domínio do usuário, sem instância ativa
  (`active count = 0`). Era sobra de tentativa antiga; o serviço real é o do sistema.
- `pmset -a powernap 0` e `womp 0`: menos wakes de fundo (wake on LAN não faz sentido com itlwm).
- Backup do EFI: `config.plist.bak-perf`.

**O que NÃO é gargalo (medido)**

- CPU: 560–1900 MHz sob carga leve, pacote ~3,2 W, `CPU_Speed_Limit 100`, sem throttle.
  `plugin-type = 1`, `X86PlatformPlugin` ativo. HWP funcionando.
- Disco: Kingston SNVS500G, TRIM ativo, SMART verificado; leitura de 200 MB em ~0,03–0,10 s.
- Memória: 16 GB, 84% livre, swap 0.
- Abertura de app: `open` de Calculadora/TextEdit em **0,07–0,10 s**.
- Vídeo: **H.264 e HEVC com decode por hardware**; VP9/AV1 não (limite do Tiger Lake).
  No Chrome, YouTube cai em VP9 → decode por software (CPU alta). Usar Safari, ou forçar
  H.264 no Chrome, resolve a sensação de lentidão em vídeo.

**Ruído de boot (normal, mas visível)**

O load average chega a ~180 no primeiro minuto e assenta em ~3 em 8 min. Vem de
Spotlight (primeira indexação), `mediaanalysisd`, `siriactionsd`/`dasd` (Duet) e restauração
dos apps (Chrome/Discord/VS Code). Não é defeito do hackintosh.

- `mediaanalysisd` crashava em ciclo (`EXC_BAD_ACCESS` em 0x8, a cada ~5 min, 20 relatórios) e
  era relançado — cada volta gerava relatório e I/O. **Desativado**:
  `launchctl disable gui/$(id -u)/com.apple.mediaanalysisd` + `bootout` + `pkill`.
  Confirmado: 150 s sem crash e sem processo. Para reverter:
  `launchctl enable gui/$(id -u)/com.apple.mediaanalysisd`.
  Efeito colateral: Photos perde a análise automática (busca por objetos/cenas).
- `Synergy` (`synergy-core`) lê **todo** o teclado/mouse e injeta latência de input; se não for
  usado para compartilhar teclado com outro Mac, remover.

## Siri / Apple Intelligence / análise de Fotos desativados

Objetivo: cortar ~25 daemons de fundo sem utilidade num hackintosh sem ANE (economia de ~140 MB e
menos trabalho periódico).

**Preferências (Siri desligada e sem ícone na barra):**

```bash
defaults write com.apple.assistant.support "Assistant Enabled" -bool false
defaults write com.apple.Siri StatusMenuVisible -bool false
defaults write com.apple.Siri SiriPrefStashedStatusMenuVisible -bool false
defaults write com.apple.Siri VoiceTriggerUserEnabled -bool false
```

**`launchctl disable gui/501/<label>`** para:

```
com.apple.assistantd                      com.apple.assistant_service
com.apple.assistant_cdmd                  com.apple.AddressBook.AssistantService
com.apple.siriactionsd                    com.apple.siriinferenced
com.apple.siriknowledged                  com.apple.sirittsd
com.apple.siri.context.service            com.apple.SiriTTSTrainingAgent
com.apple.callintelligenced               com.apple.intelligenceflowd
com.apple.intelligencecontextd            com.apple.intelligenceplatformd
com.apple.intelligencetasksd              com.apple.ModelCatalogAgent
com.apple.photoanalysisd
```

**System domain:** `sudo launchctl disable system/com.apple.modelcatalogd` e
`sudo launchctl disable system/com.apple.modelmanagerd`.

> **NÃO desativar** `com.apple.duetexpertd`, `com.apple.spotlightknowledged` (+ `.updater` /
> `.importer`), `com.apple.knowledge-agent` e `com.apple.knowledgeconstructiond`.
> O app **Apps** novo do Tahoe (`/System/Applications/Apps.app`, `com.apple.apps.launcher`, o ícone
> ao lado do Finder) monta a lista com o **ATX App Directory** do `duetexpertd` + CoreSpotlight.
> Sem eles a lista fica **vazia**. Sintoma nos logs:
> `ATXAppDirectoryResponse: getting hidden apps from cache failed` e
> `failed lookup: name = com.apple.spotlightknowledged, requestor = corespotlightd`.
>
> Conserto (se acontecer): limpar o cache do ATX e reiniciar o `duetexpertd`:
> `rm -rf ~/Library/Caches/com.apple.duetexpertd`, `launchctl kickstart -k gui/$(id -u)/com.apple.duetexpertd`,
> `killall Dock`. Ele reconstrói as categorias
> (`ATXAppDirectoryOrderingProvider: Read from disk succeeded, got 6 categories`).

`mediaanalysisd` já estava desativado; `photoanalysisd` entrou na mesma leva (análise automática de
Fotos desligada).

**O que NÃO foi desativado de propósito:**

- `com.apple.cmio.*`, `VDCAssistant`, `UVCAssistant` — são da **câmera**, apesar do "assistant".
- `com.apple.texttospeech.SiriAUSP` — é **TTS/acessibilidade** (iniciado por `axassetsd`), não o
  assistente; desligar quebraria VoiceOver/Fala.
- `com.apple.intelligenceplatform.IntelligencePlatformComputeService` — é chamado pelo
  **BiomeAgent** (dados de uso), não pelo Siri.
- `coreduetd`, `contextstored`, `ContextStoreAgent` — usados por vários recursos do sistema.
- O **Spotlight core (`mds`) continua funcionando** (`mdfind` OK); só sugestões/conhecimento caíram.

**Reverter:**

```bash
for L in assistantd assistant_service assistant_cdmd siriactionsd siriinferenced \
         siriknowledged sirittsd siri.context.service SiriTTSTrainingAgent \
         callintelligenced intelligenceflowd intelligencecontextd intelligenceplatformd \
         intelligencetasksd ModelCatalogAgent photoanalysisd AddressBook.AssistantService; do
  launchctl enable gui/$(id -u)/com.apple.$L
done
# Estes ficam SEMPRE habilitados: o app Apps depende deles
for L in duetexpertd spotlightknowledged spotlightknowledged.updater \
         spotlightknowledged.importer knowledge-agent knowledgeconstructiond; do
  launchctl enable gui/$(id -u)/com.apple.$L
done
sudo launchctl enable system/com.apple.modelcatalogd
sudo launchctl enable system/com.apple.modelmanagerd
defaults write com.apple.assistant.support "Assistant Enabled" -bool true
```

Efeitos colaterais esperados: **Siri e Ditado** param; **Fotos** perde análise automática;
**Visual Look Up** pode não funcionar. As sugestões do Spotlight e a **App Library do app Apps**
continuam funcionando porque `duetexpertd` e o CoreSpotlight knowledge foram mantidos.

## Nome do processador em "Sobre Este Mac"

Aparecia **`3.00GHz Intel Core i3 Dual-Core`**. O `PlatformInfo > Generic > ProcessorType = 1537`
(`0x601`) estava **correto** — é o identificador Apple para CPUs de 1/2/4/6 núcleos. O problema era
a string do RestrictEvents no NVRAM:

- `NVRAM > Add > 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102`
  - `revcpu` = `1`
  - `revcpuname` = **`Intel Core i5-1135G7`** (antes: `3.00GHz Intel Core i3 Dual-Core`)
  - `revpatch` = `sbvmm,cpuname`
- Backup: `config.plist.bak-cpuname`.

Resultado verificado:

```
Processor Name: Intel Core i5-1135G7
Processor Speed: 2,42 GHz
Total Number of Cores: 4
Hyper-Threading Technology: Enabled
```

O `Model Name` continua `MacBook Air` / `MacBookAir9,1`: é o SMBIOS que o macOS aceita (não existe
Mac com esse i5-1135G7). Trocar o texto do modelo não é suportado; trocar o SMBIOS por outro Mac
mexe em USB/GPU/energia e não traz ganho.

## Bluetooth (Intel AX201)

Sintoma: `State: Off`, `Address: NULL`, `Firmware Version: v0 c0`, `Chipset: BCM_4350C2`.

Causa: o `BlueToolFixup.kext` (versão **2.7.2**, cujo changelog diz "Added `bluetoothd` patches for
macOS 26") estava no EFI com `MaxKernel = 23.9.9`, então **não carregava no Tahoe**. O
`IntelBluetoothFirmware` e o `IntelBTPatcher` carregavam, mas sem o BlueToolFixup o upload de
firmware é bloqueado e o controlador fica no placeholder.

Correção: em `Kernel > Add` (índice 31), `MaxKernel` vazio. Backup: `config.plist.bak-bt`.
Ordem mantida: `IntelBluetoothFirmware` (29) → `IntelBTPatcher` (30) → `BlueToolFixup` (31).

Resultado verificado:

```
kextstat: as.acidanthera.BlueToolFixup (2.7.2)  [carregado]
State: On
Address: XX:XX:XX:XX:XX:XX
Firmware Version: v256 c256
Chipset: THIRD_PARTY_DONGLE   (rótulo cosmético do macOS para BT não-Apple)
Transport: USB
```

Observação: scan por ferramenta CLI via SSH retorna `0xe00002e2` (`kIOReturnNotPermitted`) por causa
do **TCC de Bluetooth**, não por falha do controlador. Validar pareando pelo
**Ajustes do Sistema → Bluetooth**.

## Wi-Fi no Tahoe 26.7.1 (25G241)

- `AirportItlwm-Tahoe` 2.4.0 **não carrega**: declara dependência de
  `com.apple.iokit.IOSkywalkFamily`, e nesse build o bundle em
  `/System/Library/Extensions/IOSkywalkFamily.kext` é **codeless** (só Info.plist, sem executável);
  o kernel responde `library kext com.apple.iokit.IOSkywalkFamily not found`.
- Injetar o `IOSkywalkFamily.kext` (1.0) pelo OpenCore **trava o boot** (para em `SMCRTC: Stop`).
- Solução adotada: **`itlwm` 2.3.0 + HeliPort 1.5.0** (`/Applications/HeliPort.app`), com
  `AirportItlwm*`/`IOSkywalkFamily` desabilitados no `Kernel > Add`.
- Alternativa sem app: gravar SSID/senha no `Info.plist` do `itlwm` (chave `WiFiConfig`).

**Por que não dá Wi-Fi nativo neste notebook/build:**

- `IOSkywalkFamily.kext` em 26.7.1 é **codeless** (só `Info.plist`, sem `Contents/MacOS`). O
  `AirportItlwm-Tahoe` 2.4.0 depende dele; injetar o kext antigo trava o boot em `SMCRTC: Stop`.
- O itlwm oficial mais recente é o **2.3.0** (Sonoma); não existe `AirportItlwm` oficial para Tahoe.
- O AX201 é **CNVi** (Wi-Fi no chipset, `00:14.3`, `8086:a0f0`); o slot M.2 é CNVi, então uma placa
  Broadcom nativa (BCM94360NG/BCM94352Z, PCIe) provavelmente **não** seria reconhecida.
- `en0` é o `itlwm` e aparece como **Ethernet** no macOS — por isso não há painel de Wi-Fi nativo.
- Alternativa nativa de verdade: **Ethernet** (`en1`, Realtek RTL8111, funciona sem kext extra).
- Com itlwm não há **AirDrop/Handoff/Continuity** (AWDL). O Bluetooth nativo já funciona.

## Armadilhas encontradas (para não repetir)

- `hdiutil attach` por SSH trava (precisa da sessão gráfica) — instalar DMG pela interface.
- Editar `config.plist` com PlistBuddy `Set` em chave `<data>` grava **texto ASCII**;
  para `csr-active-config` o certo é regravar o base64 (`EwgAAA==` = 0x813) ou usar `perl`.
- `screencapture` por SSH falha mesmo com o WindowServer de pé; validar pela tela do usuário.
- O boot que travou foi recuperado bootando o **pendrive** (EFI antigo): as correções de Metal
  ficam no volume de dados e continuam valendo com o WEX antigo.

## Artefatos
- `phase2/payloads/xe.bundle.tgz` — stack de compilador pronto (sha256 `bf6240f8…`, build
  **release**, sem dumps; `XE_ADAPTER_DUMP=1` reativa a instrumentação).
- `phase2/work/xps-src/compiler-adapter.cpp` — fonte do adapter já sem `usleep`/dump.
- `phase2/work/vtcheck.c` — testa decode por hardware (H.264/HEVC/VP9/AV1).
- `phase2/work/perf-baseline*.sh`, `verify-after.sh`, `metrics-after.sh` — diagnósticos usados.
- `phase2/work/build-xe2.sh` — script de build (Mac, x86_64).
- `phase2/work/install-xe.sh` — instalação no alvo.
- `phase2/payloads/wex050.tgz` — WhateverXe 0.5.0 (build oficial).
