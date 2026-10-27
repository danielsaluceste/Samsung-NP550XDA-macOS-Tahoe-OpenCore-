# Referências

## OpenCore / base

- OpenCorePkg — https://github.com/acidanthera/OpenCorePkg
- OpenCore Configuration (PDF) — https://github.com/acidanthera/OpenCorePkg/blob/master/Docs/Configuration.pdf
- Dortania OpenCore Install Guide — https://dortania.github.io/OpenCore-Install-Guide/
- Dortania Troubleshooting — https://dortania.github.io/OpenCore-Install-Guide/troubleshooting/troubleshooting.html
- GenSMBIOS — https://github.com/corpnewt/GenSMBIOS
- ProperTree — https://github.com/corpnewt/ProperTree
- USBToolBox — https://github.com/USBToolBox/tool
- SSDTTime — https://github.com/corpnewt/SSDTTime

## Kexts

- Lilu — https://github.com/acidanthera/Lilu
- VirtualSMC — https://github.com/acidanthera/VirtualSMC
- AppleALC — https://github.com/acidanthera/AppleALC
- WhateverXe — https://github.com/b00t0x/WhateverXe
- RestrictEvents — https://github.com/acidanthera/RestrictEvents
- AMFIPass — https://github.com/acidanthera/AMFIPass
- CPUFriend — https://github.com/acidanthera/CPUFriend
- NVMeFix — https://github.com/acidanthera/NVMeFix
- HibernationFixup — https://github.com/acidanthera/HibernationFixup
- RTCMemoryFixup — https://github.com/acidanthera/RTCMemoryFixup
- USBWakeFixup — https://github.com/acidanthera/USBWakeFixup
- FeatureUnlock — https://github.com/acidanthera/FeatureUnlock
- VoodooPS2 — https://github.com/acidanthera/VoodooPS2
- VoodooI2C — https://github.com/VoodooI2C/VoodooI2C
- ECEnabler — https://github.com/1Revenger1/ECEnabler
- SimpleHDA — https://github.com/laobamac/SimpleHDA
- CtlnaAHCIPort — https://github.com/acidanthera/CtlnaAHCIPort
- EmeraldSDHC — https://github.com/acidanthera/EmeraldSDHC
- HoRNDIS — https://github.com/jwise/HoRNDIS
- ForgedInvariant — https://github.com/ChefKissInc/ForgedInvariant
- NoTouchID — https://github.com/al3xtjames/NoTouchID
- SystemProfilerMemoryFixup — https://github.com/acidanthera/SystemProfilerMemoryFixup
- EFICheckDisabler — https://github.com/acidanthera/EFICheckDisabler
- BrcmPatchRAM / BlueToolFixup — https://github.com/acidanthera/BrcmPatchRAM

## Wi-Fi / Bluetooth Intel

- itlwm — https://github.com/OpenIntelWireless/itlwm
- HeliPort — https://github.com/OpenIntelWireless/HeliPort
- IntelBluetoothFirmware — https://github.com/OpenIntelWireless/IntelBluetoothFirmware
- OpenIntelWireless docs — https://openintelwireless.github.io/
- FAQ Monterey+ (BlueToolFixup/IntelBTPatcher) — https://openintelwireless.github.io/IntelBluetoothFirmware/FAQ.html

## Gráficos / Metal

- WhateverXe — https://github.com/b00t0x/WhateverXe
- WhateverGreen — https://github.com/acidanthera/WhateverGreen
- MTLCompilerService sandbox profile (local):
  `/System/Library/Sandbox/Profiles/com.apple.mtlcompilerservice.sb`
- Metal — https://developer.apple.com/metal/
- VideoToolbox — https://developer.apple.com/documentation/videotoolbox

## Áudio

- AppleALC layouts — https://github.com/acidanthera/AppleALC/wiki/Supported-codecs
- ALC256 layout 38 (Samsung Galaxy Book)
- HDA pin configuration — https://github.com/acidanthera/AppleALC/wiki

## Ferramentas e diagnóstico

- `vtcheck` — testa decode por hardware (H.264/HEVC/VP9/AV1)
- `randread` — IOPS 4K aleatório
- `displayinfo` — modos/refresh do display
- `gpu_load` — carga de compute Metal
- `btscan` — scan Bluetooth (precisa de TCC)
- `powermetrics`, `pmset`, `vmmap`, `footprint`, `log show`, `kextstat`, `ioreg`

## Comunidade

- r/hackintosh — https://www.reddit.com/r/hackintosh/
- InsanelyMac — https://www.insanelymac.com/
- Olarila — https://olarila.com/
- Hackintosh Discord (Dortania) — https://discord.gg/u8V7N5C

## Créditos

- **Acidanthera** — OpenCore, Lilu, VirtualSMC, AppleALC, RestrictEvents, BrcmPatchRAM,
  VoodooPS2, e tantos outros.
- **b00t0x** — WhateverXe, que tornou o Iris Xe possível.
- **OpenIntelWireless** — itlwm, HeliPort, IntelBluetoothFirmware.
- **laobamac** — SimpleHDA, que resolveu o áudio no Tahoe.
- **VoodooI2C** — trackpad I2C.
- **Comunidade hackintosh** — pelos relatos, testes e correções.

Se você usar este material, mantenha os créditos e as licenças originais.
