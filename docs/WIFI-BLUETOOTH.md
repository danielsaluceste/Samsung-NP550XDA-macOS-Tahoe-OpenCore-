# Wi-Fi e Bluetooth (Intel AX201)

## Wi-Fi: por que não é nativo

O AX201 é **CNVi** (`8086:A0F0`, `00:14.3`): o MAC Wi-Fi é integrado no chipset e o módulo M.2 é
CNVi, não PCIe. O `AirportItlwm` precisaria do **`IOSkywalkFamily`**, e no macOS 26.7.1 esse kext é
**codeless**:

```
/System/Library/Extensions/IOSkywalkFamily.kext/Contents/
  Info.plist
  version.plist
  _CodeSignature/
  (sem Contents/MacOS)
```

Consequências:

- `AirportItlwm-Tahoe` 2.4.0 **não carrega** (`library kext com.apple.iokit.IOSkywalkFamily not found`).
- Injetar o `IOSkywalkFamily.kext` antigo pelo OpenCore **trava o boot** em `SMCRTC: Stop`.
- O itlwm oficial mais recente é o **2.3.0 (Sonoma)**; não há `AirportItlwm` oficial para Tahoe.
- Trocar por uma placa Broadcom nativa (BCM94360NG/BCM94352Z, PCIe) provavelmente **não funciona**,
  porque o slot é CNVi.

Ou seja: **menu de Wi-Fi nativo, AirDrop, Handoff e Continuity não são possíveis** neste notebook
com esse build. A alternativa nativa de verdade é **Ethernet** (RTL8111).

## itlwm + HeliPort

O `itlwm` é um driver completo que expõe uma interface Ethernet. Ele **não** é AirPort, por isso o
macOS mostra a interface como “Ethernet” e não há painel de Wi-Fi. O número (`en0`/`en1`) **muda
conforme a ordem de boot** (o RTL8111 também é “Ethernet”); descubra o correto pelo serviço:

```bash
networksetup -listnetworkserviceorder
# (1) Ethernet  -> (Hardware Port: Ethernet, Device: en0)   <- RTL8111
# (2) Wi-Fi     -> (Hardware Port: Ethernet, Device: en1)   <- itlwm
```

- `itlwm.kext` 2.3.0 em `EFI/OC/Kexts` (Enabled)
- HeliPort 1.5.0 em `/Applications` (só para conectar)

### Auto-conectar sem HeliPort

Preencha o `WiFiConfig` no `Info.plist` do `itlwm`:

```xml
<key>WiFiConfig</key>
<dict>
    <key>WiFi_1</key>
    <dict>
        <key>ssid</key><string>SEU_SSID</string>
        <key>password</key><string>SUA_SENHA</string>
    </dict>
</dict>
```

> **Nunca** commite seu SSID/senha. O `itlwm.kext` do repositório vem sem `WiFiConfig`.

### HeliPort: vazamento no WindowServer

O HeliPort 1.5.0 no Tahoe chama `_CGXPackagesSetWindowConstraints: Invalid window` a cada ~2 s. O
WindowServer vaza ~10 MB a cada 30 s (~1,2 GB/hora) e o sistema vai ficando lento.

Solução: **não deixe o HeliPort aberto**. Use o agente one-shot
(`tools/post-install/heliport-oneshot.plist`):

- abre o HeliPort no login;
- descobre o dispositivo do serviço **Wi-Fi** (`networksetup -listnetworkserviceorder`), sem assumir
  `en0`;
- espera até 45 s por IPv4 nesse dispositivo;
- fecha o HeliPort **só se** conseguiu IP;
- se não conseguir, **não fecha** (fallback para conectar manualmente).

O `itlwm` mantém a conexão depois que o HeliPort fecha.

Se abrir o HeliPort para trocar de rede, **feche depois** (⌘Q).

### Verificação

```bash
dev=$(networksetup -listnetworkserviceorder | awk '/^\([0-9]+\) Wi-Fi/{getline; gsub(/\)/,"",$NF); print $NF; exit}')
ifconfig "$dev" | grep -E 'inet |status'
# inet 192.168.x.x ...
# status: active
```

## Bluetooth

O AX201 Bluetooth é USB e funciona com:

```
IntelBluetoothFirmware.kext   2.5.0   Enabled
IntelBTPatcher.kext           2.5.0   Enabled
BlueToolFixup.kext            2.7.2   Enabled, MinKernel 21.0.0, MaxKernel VAZIO
```

O detalhe crítico: o `BlueToolFixup` **2.7.2** é a versão que adicionou patches para o **macOS 26**
(“Added bluetoothd patches for macOS 26”). Se o `MaxKernel` estiver em `23.9.9` (valor comum em
configs antigos), ele **não carrega no Tahoe** e o controlador fica em `v0 c0` / `State: Off`.

Ordem em `Kernel > Add`: `IntelBluetoothFirmware` → `IntelBTPatcher` → `BlueToolFixup`.

### Verificação

```bash
kextstat | grep -E 'BlueTool|IntelBluetooth'
system_profiler SPBluetoothDataType | grep -E 'State|Address|Firmware|Chipset'
```

Esperado:

```
State: On
Address: XX:XX:XX:XX:XX:XX
Firmware Version: v256 c256
Chipset: THIRD_PARTY_DONGLE   (rótulo cosmético)
```

### Dica

Se o scan por CLI falhar com `kIOReturnNotPermitted` (`0xe00002e2`), é **TCC de Bluetooth**, não o
controlador. Pareie pelo **Ajustes do Sistema → Bluetooth**.

## Ethernet

O RTL8111 (`en1`) funciona nativamente, sem kext extra. É a melhor opção quando você precisa de
estabilidade e velocidade.

## Links

- itlwm: https://github.com/OpenIntelWireless/itlwm
- HeliPort: https://github.com/OpenIntelWireless/HeliPort
- IntelBluetoothFirmware: https://github.com/OpenIntelWireless/IntelBluetoothFirmware
- BrcmPatchRAM/BlueToolFixup: https://github.com/acidanthera/BrcmPatchRAM
- FAQ Monterey+: https://openintelwireless.github.io/IntelBluetoothFirmware/FAQ.html
