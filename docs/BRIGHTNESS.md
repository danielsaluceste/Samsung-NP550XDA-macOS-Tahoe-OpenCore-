# Brilho

## Como o backlight funciona aqui

O painel é PWM do iGPU e o hardware responde de verdade: escrever o parâmetro **`bklt`** no
`AppleBacklightDisplay` via IOKit muda a luminância. No Linux, `intel_backlight` tem máximo
**96000**.

O problema é que o **CoreBrightness não considera o display controlável**:

```
DisplayServicesCanChangeBrightness = 0
```

porque o serviço expõe apenas `bklt` e não o parâmetro `brightness`. Consequências:

- não há slider no Control Center;
- as teclas de brilho do sistema ficam inertes;
- `Fn+F2` / `Fn+F3` não mudam nada.

## BrightnessMenu

Solução adotada: um app de barra de menus que fala direto com o `AppleBacklightDisplay`.

- Ícone `☀ NN%` na barra.
- Atalhos globais **⌃⌥↑** (aumentar) e **⌃⌥↓** (diminuir), via Carbon `RegisterEventHotKey`.
- Presets 25/50/75/100%.
- **Não lê o teclado** (sem Input Monitoring/TCC), para poder ser publicado.
- Inicia no login via `~/Library/LaunchAgents/local.brightnessmenu.plist`.

### Código

`tools/brightness/BrightnessMenu.m` (Objective-C, ARC):

```objc
static io_service_t findBacklight(void) {
    io_iterator_t it;
    IOServiceGetMatchingServices(kIOMainPortDefault,
        IOServiceMatching("AppleBacklightDisplay"), &it);
    io_service_t s = IOIteratorNext(it);
    IOObjectRelease(it);
    return s;
}
```

Leitura/escrita:

```objc
IODisplayGetFloatParameter(svc, 0, CFSTR("bklt"), &v);
IODisplaySetFloatParameter(svc, 0, CFSTR("bklt"), v);
```

### Build

```bash
cd tools/brightness
bash build.sh
# gera BrightnessMenu.app
```

O `build.sh` usa `clang -fobjc-arc -framework Cocoa -framework IOKit -framework Carbon`.

### Instalação

```bash
sudo cp -R BrightnessMenu.app /Applications/
sudo chown -R root:wheel /Applications/BrightnessMenu.app
sudo codesign -f -s - /Applications/BrightnessMenu.app
```

LaunchAgent (`tools/post-install/local.brightnessmenu.plist`):

```xml
<key>Label</key><string>local.brightnessmenu</string>
<key>ProgramArguments</key>
<array><string>/Applications/BrightnessMenu.app/Contents/MacOS/BrightnessMenu</string></array>
<key>RunAtLoad</key><true/>
```

```bash
cp local.brightnessmenu.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.brightnessmenu.plist
```

### CLI de teste

`tools/brightness/bright_tool2` (fonte `bright_tool2.c`) imprime o nível atual:

```bash
./bright_tool2
# get bklt -> r=0x0 v=1.000
```

## Teclas Fn+F2/F3

O DSDT usa:

```
_Q63 -> BRTN(0x87)   ; aumentar
_Q64 -> BRTN(0x86)   ; diminuir
```

condicionado a `!GFX0.PDRD()` e a `DIDX`/`DIDY`. Os patches ACPI para forçar a notificação foram
testados e **revertidos**: não produziram mudança de brilho, porque o caminho final continua sendo
o CoreBrightness. Sem efeito prático.

Se quiser tentar de novo, os bytes estão documentados em `docs/SOLUTION-TECHNICAL.md`
(seção “Brilho”), mas não há garantia.

## Limitações

- Sem slider nativo no Control Center.
- Sem OSD de brilho do sistema.
- O app cobre o uso diário (menu + atalhos + presets).
