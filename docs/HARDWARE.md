# Hardware

## Samsung NP550XDA

| Component | Detail | ID / note |
|---|---|---|
| CPU | Intel Core i5-1135G7 | Tiger Lake, 4C/8T, 2.4 GHz base, 4.2 GHz single-core turbo |
| iGPU | Intel Iris Xe Graphics | `8086:9A49` |
| Chipset | Tiger Lake-LP | |
| RAM | 16 GB DDR4 | 2 × 8 GB |
| SSD | Kingston SNVS500G | NVMe, 500 GB, DRAM-less |
| Wi-Fi | Intel Wi-Fi 6 AX201 | `8086:A0F0`, CNVi |
| Bluetooth | Intel AX201 | USB, same module |
| Audio | Realtek ALC256 | `10EC:0256`, HDA |
| Ethernet | Realtek RTL8111 | `10EC:8168` |
| Panel | BOE 1920×1080 | eDP, 30-bit (ARGB2101010) |
| Battery | 3-cell | reports ~68% health after years of use |
| BIOS | UEFI | no Secure Boot |

## PCI / USB topology (relevant)

```
00:02.0  VGA compatible controller  Intel Iris Xe  [8086:9a49]
00:14.3  Network controller         Intel AX201     [8086:a0f0]  (CNVi Wi-Fi)
00:1f.3  Audio device               Intel TGL HD Audio [8086:a0c8]
00:1d.0  PCI bridge                 NVMe root port
          NVMe SSD                  Kingston SNVS500G
00:1f.6  Ethernet controller        Realtek RTL8111 [10ec:8168]
USB      Bluetooth USB Host Controller (AX201 BT)
USB      VGA camera (internal)
```

The AX201 is a **CNVi** module: the Wi-Fi MAC is integrated in the chipset and the M.2 slot is
CNVi, not a standard PCIe Wi-Fi slot. This matters for hardware swaps — a Broadcom BCM94360NG
(PCIe) is unlikely to be recognized.

## ACPI

The DSDT exposes the usual Tiger Lake devices:

- `\_SB.PCI0.GFX0` — iGPU
- `\_SB.PCI0.HDAS` — HD Audio (ALC256)
- `\_SB.PCI0.RP05` / NVMe
- `\_SB.PCI0.XHC` — USB
- `\_SB.PCI0.LPCB.EC` — embedded controller
- `\_SB.PCI0.LPCB.H_EC` — keyboard/trackpad EC

Brightness-related EC methods: `_Q63`/`_Q64` → `BRTN(0x87/0x86)`, gated by `!GFX0.PDRD()` and
`DIDX`/`DIDY`. The panel backlight is PWM via the iGPU (`intel_backlight` max 96000 on Linux).

## Audio codec

ALC256 pins (from Linux `snd_hda_intel`):

| Pin | Function |
|---|---|
| `0x14` | speaker |
| `0x21` | headphone |
| `0x12` | internal microphone |
| `0x19` | microphone jack |

Subsystem: `144d:c195` (Samsung).

## Storage

- APFS on the internal NVMe (`disk0`), EFI on `disk0s1`.
- Measured: ~32–35k random 4K read IOPS, ~3.1 GB/s sequential read (PCIe 3.0 x4).
- TRIM enabled.

## Display

- 1920×1080 internal eDP, `Connection Type: Internal`.
- Framebuffer depth reported as **30-bit Color (ARGB2101010)**.
- `CGDisplayModeGetRefreshRate()` returns `0.00` on this driver; the panel runs at 60 Hz.

## Power

- `pmset`: `disksleep 0`, `hibernatemode 0`, `powernap 0`, `womp 0` (tuned for responsiveness;
  see `PERFORMANCE.md`).
- CPU power management: `plugin-type = 1`, `X86PlatformPlugin` loaded, HWP active,
  `CPUFriendDataProvider` for the i5-1135G7 (4.2 GHz single / 3.8 GHz all-core).
