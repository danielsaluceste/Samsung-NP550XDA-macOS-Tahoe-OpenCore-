# Third-party components

This repository bundles or references third-party software. Each component keeps its original
license and copyright. The table below is a guide — **always confirm the license in the upstream
repository** before redistributing or using commercially.

| Component | Version used | Upstream | License (check upstream) |
|---|---|---|---|
| OpenCorePkg | see `EFI/OC/OpenCore.efi` | https://github.com/acidanthera/OpenCorePkg | BSD-3-Clause |
| Lilu | latest | https://github.com/acidanthera/Lilu | BSD-3-Clause |
| VirtualSMC (+ SMCProcessor, SMCSuperIO, SMCLightSensor, SMCBatteryManager) | latest | https://github.com/acidanthera/VirtualSMC | BSD-3-Clause |
| AppleALC | latest | https://github.com/acidanthera/AppleALC | BSD-3-Clause |
| WhateverXe | 0.5.0 | https://github.com/b00t0x/WhateverXe | BSD-3-Clause (see upstream) |
| WhateverXe Graphics | 0.2.0 | https://github.com/b00t0x/WhateverXe | see upstream |
| itlwm | 2.3.0 | https://github.com/OpenIntelWireless/itlwm | GPL-2.0 |
| HeliPort | 1.5.0 | https://github.com/OpenIntelWireless/HeliPort | GPL-3.0 (see upstream) |
| IntelBluetoothFirmware | 2.5.0 | https://github.com/OpenIntelWireless/IntelBluetoothFirmware | GPL-2.0 |
| IntelBTPatcher | 2.5.0 | https://github.com/OpenIntelWireless/IntelBluetoothFirmware | GPL-2.0 |
| BlueToolFixup (BrcmPatchRAM) | 2.7.2 | https://github.com/acidanthera/BrcmPatchRAM | see upstream |
| RestrictEvents | latest | https://github.com/acidanthera/RestrictEvents | BSD-3-Clause |
| AMFIPass | latest | https://github.com/acidanthera/AMFIPass | BSD-3-Clause |
| CPUFriend / CPUFriendDataProvider | latest | https://github.com/acidanthera/CPUFriend | see upstream |
| NVMeFix | latest | https://github.com/acidanthera/NVMeFix | BSD-3-Clause |
| HibernationFixup | latest | https://github.com/acidanthera/HibernationFixup | BSD-3-Clause |
| RTCMemoryFixup | latest | https://github.com/acidanthera/RTCMemoryFixup | BSD-3-Clause |
| USBWakeFixup | latest | https://github.com/acidanthera/USBWakeFixup | BSD-3-Clause |
| FeatureUnlock | latest | https://github.com/acidanthera/FeatureUnlock | BSD-3-Clause |
| VoodooPS2 | latest | https://github.com/acidanthera/VoodooPS2 | BSD-3-Clause |
| VoodooI2C (+ VoodooGPIO, VoodooI2CServices, VoodooInput) | latest | https://github.com/VoodooI2C/VoodooI2C | GPL-2.1 |
| RealtekRTL8111 | latest | https://github.com/Mieze/RTL8111_driver_for_OS_X | GPL-2.0 |
| ECEnabler | latest | https://github.com/1Revenger1/ECEnabler | MIT (see upstream) |
| SimpleHDA | 1.0.0 | https://github.com/laobamac/SimpleHDA | see upstream |
| CtlnaAHCIPort | latest | https://github.com/acidanthera/CtlnaAHCIPort | see upstream |
| EmeraldSDHC | latest | https://github.com/acidanthera/EmeraldSDHC | see upstream |
| HoRNDIS | latest | https://github.com/jwise/HoRNDIS | GPL-2.0 |
| ForgedInvariant | 1.5.0 | https://github.com/ChefKissInc/ForgedInvariant | see upstream |
| HWPEnabler | 1.2 | search GitHub for `good.win.HWPEnabler` | see upstream |
| NoTouchID | latest | https://github.com/al3xtjames/NoTouchID | see upstream |
| SystemProfilerMemoryFixup | latest | https://github.com/acidanthera/SystemProfilerMemoryFixup | see upstream |
| EFICheckDisabler | latest | https://github.com/acidanthera/EFICheckDisabler | see upstream |
| USBToolBox | 1.2.0 (tool only) | https://github.com/USBToolBox/tool | see upstream |
| GenSMBIOS | tool | https://github.com/corpnewt/GenSMBIOS | see upstream |

## Apple binaries NOT included

The Metal compiler stack needs Apple binaries (`libigc.dylib`, `libigcHSW.dylib`,
`libMTLIGCCompilerPluginOld.dylib`, `runtime.igc64.bc`, `runtime.gpuencode.split`, etc.). They are
**not** redistributed here. Obtain them from a macOS installation you own (or from the upstream
projects that document the extraction) and build the bundle with `tools/compiler/build-xe2.sh`.

## Our code

`BrightnessMenu`, `compiler-adapter.cpp`, `llvm-bridge.cpp`, diagnostics, scripts and docs are
MIT-licensed (see `LICENSE`), except where a file says otherwise.
