# EFI

Esta pasta contém a **EFI sanitizada** do OpenCore usada no notebook (**31 kexts**,
`Kernel > Add` com **36 entradas habilitadas**). Por segurança, ela **não** inclui SMBIOS
(serial/MLB/UUID/ROM) nem credenciais de Wi-Fi.

> **Gere seu próprio SMBIOS** com GenSMBIOS antes de usar iServices. O `config.plist` está com
> `SystemSerialNumber`, `MLB`, `SystemUUID` e `ROM` **vazios**.

## Como gerar

Na máquina que está funcionando:

```bash
bash tools/efi/export-efi.sh /dev/disk0s1
# gera ~/EFI-sanitized.tar.gz
```

Extraia o conteúdo aqui:

```bash
tar -xzf EFI-sanitized.tar.gz -C .
```

O script:

- remove `SystemSerialNumber`, `MLB`, `SystemUUID` e `ROM` do `PlatformInfo`;
- remove `WiFiConfig` (SSID/senha) do `itlwm.kext`;
- copia apenas kexts com `Enabled=true`;
- mantém `BOOT/`, `OC/OpenCore.efi`, `config.plist`, `ACPI/`, `Drivers/` e `Resources/`
  (se `PickerMode = External`);
- avisa se encontrar padrões sensíveis.

**Revise manualmente** antes de publicar: seriais, SSID, MACs, UUID, caminhos pessoais.

## Estrutura esperada

```
EFI/
├── BOOT/
│   └── BOOTx64.efi
└── OC/
    ├── OpenCore.efi
    ├── config.plist
    ├── ACPI/
    │   ├── SSDT-*.aml
    ├── Drivers/
    │   ├── OpenRuntime.efi
    │   ├── HfsPlus.efi
    │   └── ...
    ├── Kexts/
    │   ├── Lilu.kext
    │   ├── VirtualSMC.kext
    │   ├── WhateverXe.kext
    │   ├── AppleALC.kext
    │   ├── SimpleHDA.kext
    │   ├── itlwm.kext
    │   ├── IntelBluetoothFirmware.kext
    │   ├── IntelBTPatcher.kext
    │   ├── BlueToolFixup.kext
    │   └── ...
    └── Resources/
```

## Config (pontos que importam)

- `boot-args`: `npci=0x2000 keepsyms=1 -amfipassbeta -no_compat_check -allow3d
  -disablegfxfirmware -igfxcdc gfxrst=1 msgbuf=1048576 -v`
- `csr-active-config`: `0x813` (`EwgAAA==`)
- `PlatformInfo > Generic`: `SystemProductName = MacBookAir9,1`, serial/MLB/UUID/ROM **vazios**
- `Kernel > Add`:
  - Lilu primeiro
  - AppleALC antes de SimpleHDA
  - `IntelBluetoothFirmware` → `IntelBTPatcher` → `BlueToolFixup` (MaxKernel vazio)
  - `itlwm` é o único Wi-Fi; `AirportItlwm*`, `IOSkywalkFamily` e `IO80211FamilyLegacy` foram
    **removidos**
  - `VoodooI2C` **2.8** (a 2.9.1 não carrega no Tahoe); `BrightnessKeys` foi **removido**
- `DeviceProperties > PciRoot(0x0)/Pci(0x1F,0x3)`: `layout-id` = `Data` `JgAAAA==` (38)
- `NVRAM > Add > 4D1FDA02-...`: `revcpu=1`, `revcpuname=Intel Core i5-1135G7`,
  `revpatch=sbvmm,cpuname`

## Importante

- **Gere seu próprio SMBIOS** com GenSMBIOS. O config do repositório vem sem seriais.
- Não use a EFI de outra pessoa com os seriais dela.
- O `xe.bundle` do compilador **não** vai na EFI; ele fica em
  `/System/Library/Caches/xe.bundle` (ver `docs/GRAPHICS.md`).
- O `adapter.dylib` do compilador fica em
  `/Library/GPUBundles/XeCompilerAdapter.bundle/Contents/MacOS/` (não na EFI).
