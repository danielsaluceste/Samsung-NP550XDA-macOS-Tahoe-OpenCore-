# Áudio (ALC256)

## O problema

O macOS 26 **removeu o `AppleHDA.kext`**. Sem ele não existe `AppleHDAController`, e o AppleALC
não tem o que patchear. Nenhum `layout-id` funciona sozinho no Tahoe.

O codec desta máquina é **Realtek ALC256 em HDA** (`10EC:0256`), confirmado no Linux live:

- `0x14` speaker
- `0x21` headphone
- `0x12` microfone interno
- `0x19` mic jack
- subsystem `144d:c195`

O `10EC1308` que aparece no DSDT pertence ao caminho SST alternativo, que esta placa não usa.

## A solução: SimpleHDA

**SimpleHDA 1.0.0** (laobamac) é um plugin do Lilu injetado pelo OpenCore que **restaura o stack do
AppleHDA em memória**. Com ele, o AppleALC volta a funcionar.

### Kexts

```
EFI/OC/Kexts/
  Lilu.kext
  AppleALC.kext
  SimpleHDA.kext
```

Ordem em `Kernel > Add` (importante):

```
0   Lilu.kext
10  AppleALC.kext
60  SimpleHDA.kext      MinKernel 25.0.0  MaxKernel 25.99.99
```

### DeviceProperties

`PciRoot(0x0)/Pci(0x1F,0x3)`:

| Chave | Tipo | Valor |
|---|---|---|
| `layout-id` | Data | `JgAAAA==` (38) |

Layout **38** = Samsung Galaxy Book / ALC256.

### Verificação

```bash
system_profiler SPAudioDataType | grep -E 'Built-in (Output|Microphone)'
```

Saída esperada:

```
Built-in Microphone:
Built-in Output:
```

O codec deve aparecer como `0x10EC0256`:

```bash
sudo log show --last 2m | grep -i 10EC0256
# ou
ioreg -r -c AppleHDACodec | grep -i 0256
```

### Teste audível

```bash
afplay /System/Library/Sounds/Glass.aiff
```

Se o volume estiver mudo:

```bash
osascript -e 'set volume output volume 70'
osascript -e 'set volume output muted false'
```

## Se não funcionar

1. Confirme que `SimpleHDA` está **habilitado** e com `MinKernel 25.0.0`.
2. Confirme a ordem Lilu → AppleALC → SimpleHDA.
3. Confirme que `layout-id` é **Data** (não string/number). PlistBuddy pode gravar texto em
   `<data>`; use `plutil -replace ... -data JgAAAA==` ou edite no ProperTree.
4. Teste outros layouts do ALC256 no AppleALC (ex.: 13, 21, 28, 38, 56, 97) — mas 38 é o validado
   nesta máquina.
5. Verifique se `AppleHDAController` anexou:

```bash
kextstat | grep -i AppleHDA
ioreg -r -c AppleHDAController | head
```

## Links

- SimpleHDA: https://github.com/laobamac/SimpleHDA
- AppleALC: https://github.com/acidanthera/AppleALC
- Lilu: https://github.com/acidanthera/Lilu
