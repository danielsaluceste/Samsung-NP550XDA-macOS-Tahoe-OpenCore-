# BrightnessMenu

App de barra de menus para controlar o backlight real do painel via IOKit
(`AppleBacklightDisplay` / parâmetro `bklt`), sem ler o teclado e sem permissões de
Input Monitoring.

## Por que existe

Neste build o CoreBrightness reporta `DisplayServicesCanChangeBrightness = 0` (o serviço expõe
`bklt`, não `brightness`). Resultado: sem slider no Control Center e teclas Fn inertes. O
BrightnessMenu fala direto com o `AppleBacklightDisplay`.

## Build

```bash
bash build.sh
# gera BrightnessMenu.app
```

Requisitos: Xcode/CLT (clang), ARC.

## Instalar

```bash
bash install.sh
```

O script copia para `/Applications`, assina ad-hoc, e registra
`~/Library/LaunchAgents/local.brightnessmenu.plist`.

## Usar

- Ícone `☀ NN%` na barra de menus.
- Clique: presets 25/50/75/100% e “Sair”.
- Atalhos globais: **⌃⌥↑** aumenta, **⌃⌥↓** diminui.

## CLI de teste

```bash
clang -O2 -framework IOKit -framework CoreFoundation -o bright_tool2 bright_tool2.c
./bright_tool2
# get bklt -> r=0x0 v=1.000
```

## Notas

- A versão 1.4 **não** tem código de HID/teclado (a v1.2/v1.3 tentou ler eventos e exigia
  Monitoramento de Entrada; foi descartada).
- Compile com `-fobjc-arc`: sem ARC o `g_item` vira dangling e o app crasha.
- As teclas `Fn+F2/F3` não funcionam neste firmware; veja `docs/BRIGHTNESS.md`.
