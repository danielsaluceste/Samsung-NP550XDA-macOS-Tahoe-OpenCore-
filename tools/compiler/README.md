# Compilador Metal (Tahoe + Iris Xe)

Este diretório contém o **adapter/bridge** que faz o `MTLCompilerService` do Tahoe conversar com o
plugin Intel antigo (TGL) e com o `libigc`. Sem isso, o Metal até inicializa, mas a compilação de
shaders falha e o WindowServer cai.

## Arquivos

| Arquivo | Função |
|---|---|
| `compiler-adapter.cpp` | exporta `MTLCompilerBuildRequestWithSerializedBitcode`, parseia o bitcode, mapeia a stack e chama o plugin antigo; instala o helper ICB; contém a contenção de crash |
| `llvm-bridge.cpp` | reexporta os símbolos do `GPUCompiler` 32023 usados pelo plugin antigo |
| `plugin-old-patches.json` | patches de bytes no plugin Intel antigo |
| `build-xe2.sh` | monta `xe.bundle` (Apple binaries + bridge + plugin patchado + adapter) |
| `install-xe.sh` | instala no alvo e troca o `adapter.dylib` |

## O que NÃO está aqui

Os binários da Apple (`libigc.dylib`, `libigcHSW.dylib`, `libMTLIGCCompilerPluginOld.dylib`,
`runtime.igc64.bc`, `runtime.gpuencode.split`, etc.) **não são redistribuídos**. Obtenha de uma
instalação do macOS que você possui (ou dos projetos que documentam a extração) e ajuste os
caminhos do `build-xe2.sh`.

## Requisitos de build

- macOS com Xcode (clang).
- `$HOME/wex/ng` — Apple 16.0.32 (NootedGreen): `MacOS/libigc.dylib`, etc.
- `$HOME/wex/tx` — bundle do MTL driver do Tahoe:
  `Library/GPUBundles/AppleIntelTGLGraphicsMTLDriver.bundle/Contents`
- `$HOME/wex/xps/macos/src` — estes dois `.cpp`
- `$HOME/wex/xps/macos/plugin-old-patches.json`

## Build

```bash
export W="$HOME/wex"
mkdir -p "$W/xps/macos/src"
cp compiler-adapter.cpp llvm-bridge.cpp "$W/xps/macos/src/"
cp plugin-old-patches.json "$W/xps/macos/"
bash build-xe2.sh
# gera $W/xe.bundle.tgz
```

## Instalação

```bash
bash install-xe.sh "$HOME/wex/xe.bundle.tgz"
```

O script:

1. faz backup do adapter original do WEX (`adapter-wex.dylib`);
2. extrai o `xe.bundle` em `/System/Library/Caches/xe.bundle`;
3. copia `libMTLIGCCompilerPlugin.dylib` para
   `/Library/GPUBundles/XeCompilerAdapter.bundle/Contents/MacOS/adapter.dylib`;
4. testa o Metal.

## Debug (não use em produção)

O adapter é **release** por padrão: sem dumps e sem `usleep`. Para reativar a instrumentação:

```bash
export XE_ADAPTER_DUMP=1
```

Isso faz o adapter despejar bitcode/entrada/resposta em base64 no log e aplicar **250 ms de espera
por shader** nos 40 primeiros. Em uso normal isso deixa o sistema lento (ver
`docs/PERFORMANCE.md`).

## Armadilhas

- Build **DEBUG** do WhateverXe dá panic; use RELEASE.
- O sandbox do `MTLCompilerService` só lê `/System`; por isso o bundle fica em
  `/System/Library/Caches/xe.bundle` e não em `/Library/GPUBundles`.
- Non-ASCII/acentos nos comentários do `.cpp` podem quebrar o build em alguns toolchains; mantenha
  ASCII nos fontes.
- O `install-xe.sh` usa `sudo` interativo; **nunca** embuta senha em script.
