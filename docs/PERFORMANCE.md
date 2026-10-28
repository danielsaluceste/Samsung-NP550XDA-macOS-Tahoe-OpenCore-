# Performance

Sintoma original: “às vezes é meio lento para carregar algo”. O diagnóstico foi feito com medições,
não com achismo. As três causas reais estão abaixo.

> **Atualização 2026-10-27:** com o **Graphics 0.3.2**, o `adapter.dylib` oficial passou a ser
> usado e já é release (32 KB, sem `usleep`, sem dump). O adapter custom descrito abaixo e o
> `xe.bundle` continuam só como fallback. As medições abaixo são o histórico do problema.

## 1. O adapter do compilador estava em modo debug

O `compiler-adapter.cpp` usado para fechar a ABI do Tahoe tinha, por instrumentação:

```c
if (seq) usleep(250000);              // 250 ms por shader, nos 40 primeiros
xe_dump("bc", seq, bc, bcSize);       // bitcode inteiro em base64
xe_dump("reply", seq, rp, rn);        // resposta inteira em base64
```

Medição (16 min de uptime):

- **29.114 linhas `xe-dump`**
- **22,4 MB** de log
- **978 compilações Metal**
- cada `MTLCompilerService` pagava até **40 × 250 ms = 10 s** de espera artificial

Correção (build release):

- dump virou opt-in: `XE_ADAPTER_DUMP=1` (nunca em produção);
- `usleep` removido;
- mantida a contenção de crash (`sigsetjmp`) e o helper ICB;
- logs por compilação removidos.

Resultado: **0 linhas `xe-dump`** após o boot.

Novo `xe.bundle.tgz` sha256:
`bf6240f8db4dafe867ad2527f0149e1b6dd8116e607d028d20928da7492e4a99`.

## 2. `-wexdbg`

O WhateverXe em build **RELEASE** não precisa dele. Gerava ~2.700 linhas de log a cada 16 min.
Removido dos `boot-args`.

## 3. HeliPort vazando o WindowServer

O HeliPort 1.5.0 no Tahoe chama, a cada ~2 s:

```
WindowServer: _CGXPackagesSetWindowConstraints: Invalid window
```

O `WindowServer` cresce ~10 MB a cada 30 s (**~20 MB/min, 1,2 GB/hora**). `vmmap`/`footprint`
mostraram `MALLOC_LARGE` de 1,0 GB em 13.478 regiões. Em ~18 min chegou a **1,4 GB**.

Prova isolada: fechar o HeliPort fez os erros caírem de **15/30 s para 0** e o RSS parar de crescer
na hora (1299 → 1299 MB).

Correção:

- HeliPort fora dos login items;
- agente one-shot (`tools/post-install/heliport-oneshot.plist`) que abre, conecta e fecha;
- reboot para devolver a memória já vazada.

Depois do reboot:

```
ws=194 → 271 → 357 → 436 → 483 → 633 → 687 → 687 → 687 → 687 → 688 → 704 MB
```

ou seja, **platô em ~690 MB**, sem crescimento linear.

## 4. Disco e sono

- `sudo pmset -a disksleep 0` — o SSD não dorme após 10 min (a primeira leitura depois de ocioso
  travava).
- `sudo pmset -a hibernatemode 0` — não grava a RAM inteira no SSD a cada sleep (num SSD sem DRAM
  isso dói).
- `sudo rm -f /var/vm/sleepimage`
- `sudo pmset -a powernap 0`, `womp 0` — menos wakes de fundo.

> O `pmset` avisa “Disk sleep should be non-zero whenever system sleep is non-zero”. É só um aviso;
> com `disksleep 0` o disco fica acordado enquanto o sistema está acordado.

> **Sleep do sistema desativado**: `sudo pmset -a sleep 0` + `standby 0` (o S3/S4 trava na
> entrada com `Failure 0x1F`; ver `TROUBLESHOOTING.md`). O **display sleep** funciona; use
> desligar/reiniciar em vez de dormir.

## 5. `mediaanalysisd` / `photoanalysisd`

O `mediaanalysisd` crashava em ciclo (`EXC_BAD_ACCESS` em `0x8`, a cada ~5 min), gerava relatório e
era relançado. Desativado:

```bash
launchctl disable gui/$(id -u)/com.apple.mediaanalysisd
launchctl bootout  gui/$(id -u)/com.apple.mediaanalysisd
launchctl disable gui/$(id -u)/com.apple.photoanalysisd
launchctl bootout  gui/$(id -u)/com.apple.photoanalysisd
```

Efeito colateral: Fotos perde a análise automática. Reverter com `launchctl enable ...`.

## 6. Siri / Apple Intelligence (opcional)

Desativar `assistantd`, `siriactionsd`, `intelligenceplatformd`, etc. economiza ~140 MB e alguns
daemons. **Mas não desative** `duetexpertd`, `spotlightknowledged` (+ `.updater`/`.importer`),
`knowledge-agent` ou `knowledgeconstructiond`: o app **Apps** do Tahoe (o ícone ao lado do Finder)
monta a lista com o **ATX App Directory** do `duetexpertd` + CoreSpotlight. Sem eles a lista fica
vazia.

Sintoma:

```
ATXAppDirectoryResponse: getting hidden apps from cache failed
failed lookup: name = com.apple.spotlightknowledged, requestor = corespotlightd
```

Conserto:

```bash
rm -rf ~/Library/Caches/com.apple.duetexpertd
launchctl kickstart -k gui/$(id -u)/com.apple.duetexpertd
killall Dock
```

Ele reconstrói as categorias (`ATXAppDirectoryOrderingProvider: Read from disk succeeded, got 6
categories`).

## 7. Tahoe: App Library, RenderBox e input lag (2026-10-28)

Medições novas, depois da atualização para WEX 0.6.1/Graphics 0.3.2:

- O app **Apps** (App Library) não é renderizado pelo app em si: ele aciona o **Spotlight**, que
  usa o **RenderBox** do Tahoe. O `archive.metallib` do RenderBox só tem slices de GPU Apple
  (`applegpu_g13g/g14g/g15g…`), então na Iris Xe (TGL) os shaders são **compilados de código-fonte**
  pelo `MTLCompilerService`.
- Primeira abertura depois do boot: **~3 min de CPU** no `MTLCompilerService` (dois processos,
  ~2 min + ~1 min) + categorização do `duetexpertd` (~26 s de CPU, picos de 200%). Load average
  chegou a **7,3** num 4C/8T.
- Aberturas seguintes: **~10 s de CPU por abertura**. O cache **não é gravado em disco** para esse
  caminho (`com.apple.Spotlight/com.apple.metal` ficou em 2,9 MB), então fecha/reabre = recompila.
- O GPU restart/WindowServer watchdog observado em teste foi causado por **`killall Spotlight`**
  com contexto de GPU ativo — não repetir.

Mitigações aplicadas (todas reversíveis):

- `local.apps-warm` — 45 s após o login, abre a App Library com `open -g` (sem roubar foco) e deixa
  a compilação/categorização acontecer em segundo plano. Custo: carga alta por alguns minutos no
  login; ganho: a primeira abertura “de verdade” deixa de pagar os ~3 min.
- `local.iconwarm` + `/usr/local/bin/iconwarm` — desenha os ícones de `/Applications` e
  `/System/Applications` (79 ícones; 3,1 s a frio, 97 ms quente) para aquecer IconServices/RenderBox.
- `local.synergy-priority` — a cada 10 s, `renice -n -10` + `taskpolicy -B -l 1` em
  `synergy-service` e `Synergy`; verificado com `ps` (`NI -10`/`-20`).
- `defaults write -g NSAutoFillHeuristicControllerEnabled -bool false` — correção conhecida do
  Tahoe para input lag que acumula com o uptime.
- `defaults write com.symless.synergy NSAppSleepDisabled -bool YES` — tira o App Nap do Synergy.
- Rede: Synergy via **Ethernet** (en0) é mais estável que Wi-Fi (`itlwm`); o roteamento atual já
  usa en0 quando o cabo está conectado.
- Não usar `killall Spotlight`/`killall WindowServer` para “limpar” o lag: pode reiniciar a GPU.

## 8. Wake do display com o mouse do Synergy (2026-10-28)

Sintoma: depois do display sleep, mexer o mouse do Synergy move o cursor mas a tela não acende.
Medido: `IODisplayWrangler` fica em `CurrentPowerState = 1`; `caffeinate -u` acorda (vai para 4),
então o painel/GPU acordam normalmente — o que falta é o evento sintético contar como atividade.

Solução: `local.cursor-wake` (LaunchAgent, `/usr/local/bin/cursorwake`) lê **apenas a posição do
cursor** a cada 0,5 s (não lê teclado nem cliques) e, quando ela muda, chama
`IOPMAssertionDeclareUserActivity(kIOPMUserActiveLocal)` por 2 s. Não impede o display de dormir:
sem movimento, não há atividade.

Verificação:

```bash
ps -Ao pid,pcpu,comm | grep cursorwake          # 0,0% CPU
pmset displaysleepnow
# mexa o mouse; depois:
ioreg -n IODisplayWrangler -r -w0 | grep CurrentPowerState   # deve ir para 4
```

> **Aviso (2026-10-28):** no stack 0.6.1/Compat 0.6.1 o painel pode apagar e **não voltar** (o
> `IODisplayWrangler` fica em 4 e `bklt=1.0`, mas o link eDP não reativa; só reboot resolve). Por
> isso o repo fixa `displaysleep 0`. O `cursor-wake` só ajuda quando o wake normal funciona.

## O que NÃO é gargalo (medido)

| Item | Medição |
|---|---|
| CPU | 4,17 GHz single-core, 3,83 GHz all-core, sem throttle |
| CPU (idle) | 430–470 MHz, pacote ~3 W |
| SSD | 32–35k IOPS 4K aleatório, ~3,1 GB/s sequencial |
| RAM | 16 GB, ~83–84% livre, swap 0 |
| Rede | ping 10 ms, apple.com 0,14 s, DNS 0,08 s |
| GPU | compute 220 dispatches/s, Metal 2, 0 hangs |
| Abertura de app | `open` Calculadora/TextEdit 0,07–0,10 s |

O que ainda custa tempo é inerente: compilação de shader (~400 ms na primeira abertura de cada
app), apps Electron (Chrome/Discord/VS Code) e YouTube em **VP9**, que o Tiger Lake não decodifica
por hardware (H.264 e HEVC decodificam).

## Verificação

```bash
uptime
kextstat | grep -E 'WhateverXe|SimpleHDA'
sudo log show --last 5m | grep -c 'xe-dump'        # 0
ps -o rss= -p $(pgrep -x WindowServer)             # estável
pmset -g custom | grep -E 'disksleep|hibernatemode|powernap'
```
