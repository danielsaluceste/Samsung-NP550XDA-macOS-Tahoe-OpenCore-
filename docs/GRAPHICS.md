# Gráficos / Metal (Iris Xe no Tahoe)

Este é o ponto mais delicado do projeto. O macOS Tahoe não tem driver para Tiger Lake; o
**WhateverXe** faz o binding da iGPU, mas o **MTLCompilerService** do Tahoe tem uma ABI diferente
da que o plugin Intel antigo exporta, e o sandbox dele só lê `/System`.

## Resumo do que funciona

```
WhateverXe 0.6.1 (RELEASE) + WhateverXe Graphics 0.3.2
MTLCompilerService -> adapter.dylib (oficial 0.3.2) -> GPUCompiler 32023 + libigc-tgl.dylib
```

O `adapter.dylib` oficial do 0.3.2 é **release** (32 KB, sem sleeps de debug nem dump) e usa
`libigc-tgl.dylib` + `runtime.igc64.bc`. Esses dois arquivos são **byte a byte idênticos** aos do
0.2.0, então os symlinks para `/System/Library/Caches/XeCompiler` continuam válidos. O adapter
custom antigo (`adapter-wex.dylib`) e o `xe.bundle` ficam como **fallback** caso uma versão futura
volte a exigir o plugin Intel antigo.

- `Metal Support: Metal 2`
- `Resolution: 1920 x 1080`, `Online: Yes`, `Connection Type: Internal`
- `WindowServer` estável, sem hangs.

## Boot-args

```
npci=0x2000 keepsyms=1 -amfipassbeta -no_compat_check -allow3d -disablegfxfirmware
-igfxcdc gfxrst=1 msgbuf=1048576 -v
```

- `-allow3d` — habilita o acelerador 3D do WEX.
- `-disablegfxfirmware` — evita o firmware GuC/HuC; necessário para estabilidade no TGL.
- `gfxrst=1` — reset de GPU no wake.
- `-igfxcdc` — (herdado do WhateverGreen; o WEX atual não usa, é inofensivo).
- `-wexdbg` **não** deve ser usado em produção (só log; ver `PERFORMANCE.md`).
- `-amfipassbeta` + `AMFIPass.kext` — assinatura/AMFI relaxados no Tahoe.
- `csr-active-config = 0x813` (`EwgAAA==`).

## O problema do sandbox do MTLCompilerService

O perfil `/System/Library/Sandbox/Profiles/com.apple.mtlcompilerservice.sb` permite leitura apenas
sob `/System`. O stack do compilador precisa de `libigc` e `runtime.igc64.bc`; colocá-los em
`/Library/GPUBundles` exige `system-attribute apple-internal` (impossível).

**Solução:** colocar o stack em `/System/Library/Caches/xe.bundle` (firmlink gravável que ainda
conta como `/System` para o sandbox) e criar symlinks no bundle do WEX:

```
/Library/GPUBundles/XeCompilerAdapter.bundle/Contents/MacOS/
  libigc-tgl.dylib    -> /System/Library/Caches/XeCompiler/libigc-tgl.dylib
  runtime.igc64.bc    -> /System/Library/Caches/XeCompiler/runtime.igc64.bc
  adapter.dylib       (oficial 0.3.2; o custom antigo fica em adapter-wex.dylib)
```

## Estrutura do `xe.bundle`

`/System/Library/Caches/xe.bundle/Contents/MacOS/`:

| Arquivo | Origem |
|---|---|
| `libigc.dylib`, `libigcHSW.dylib` | Apple 16.0.32 (IGC) |
| `libIGIL-Metal.dylib`, `libISAProfilerDyn.dylib` | Apple |
| `libMTLIGCCompilerPluginOld.dylib` | plugin Intel antigo, patchado |
| `libLLVMbridge.dylib` | nosso bridge (LLVM 32023) |
| `libMTLIGCCompilerPlugin.dylib` | nosso adapter |
| `runtime.igc64.split`, `runtime.gpuencode.split` | Apple |

`Contents/Resources/` contém `runtime.igc64.split`, `runtime.igcHSW64.split`,
`runtime.gpuencode.split`.

> Os binários da Apple **não** vão neste repositório. Veja `tools/compiler/README.md` para
> obtê-los de uma instalação que você possui e montar o bundle.

## ABI: por que precisa de adapter

O MTLCompiler do Tahoe chama:

```
MTLCompilerBuildRequestWithSerializedBitcode(compiler, input, rdx, flags, bitcode, size, stack...)
```

O plugin antigo (TGL) exporta:

```
MTLCompilerBuildRequestWithOptions(compiler, input, rdx, flags, Module*, stack...)
```

O adapter:

1. parseia o bitcode com `LLVMParseBitcodeInContext2`;
2. mapeia a stack: `r9` antigo = `stack[0x10]` novo; `stack[0x10..0x38]` antigo = `[0x18..0x40]` novo;
3. chama o plugin antigo;
4. devolve o resultado nos ponteiros esperados.

Além disso, o plugin antigo espera um **helper ICB** (`MTLCompilerSetHelper`) que o Tahoe não
chama; o adapter instala um helper que devolve módulo nulo (correto para shaders sem ICB).

O `libLLVMbridge.dylib` reexporta os símbolos do `GPUCompiler.framework` 32023
(`LLVMContextCreate`, `LLVMParseBitcodeInContext2`, etc.) para o plugin antigo.

## Contenção de crash

O `libigc` pode dar sinal em alguns shaders. O adapter instala handlers (`SIGSEGV`, `SIGBUS`,
`SIGILL`, `SIGABRT`, `SIGFPE`) com `sigsetjmp`/`siglongjmp` e uma `altstack`, devolvendo erro em vez
de matar o `MTLCompilerService`. Isso evita que o WindowServer caia junto.

## Build

```bash
# no Mac com Xcode
bash tools/compiler/build-xe2.sh
# instala no alvo
bash tools/compiler/install-xe.sh
```

O `build-xe2.sh` espera:

- `$HOME/wex/ng` — Apple 16.0.32 (NootedGreen)
- `$HOME/wex/tx` — bundle do MTL driver do Tahoe
- `$HOME/wex/xps` — fontes e `plugin-old-patches.json`

Ajuste os caminhos no script.

## Teste

```bash
~/metal_test2
# RENDER pipeline (BGRA8): OK
# RENDER pipeline (RGBA16F+Stencil8): OK
# RENDER pipeline (MSAA4): OK
```

## Armadilhas

- **Build DEBUG do WhateverXe dá panic.** Use RELEASE.
- **Não** coloque o stack em `/Library/GPUBundles` (sandbox).
- **Não** use `XE_ADAPTER_DUMP=1` no adapter custom antigo em produção: 250 ms por shader + dump de
  22 MB no log. O adapter oficial do 0.3.2 não tem esse comportamento.
- **Não** injete `IOSkywalkFamily` (Wi-Fi) esperando resolver gráficos; é outro subsistema e trava
  o boot.
- Se o WindowServer reiniciar em loop, verifique os symlinks e o `adapter.dylib`.
- `-wexdbg` só serve para depurar; em uso normal deixa tudo mais lento.
