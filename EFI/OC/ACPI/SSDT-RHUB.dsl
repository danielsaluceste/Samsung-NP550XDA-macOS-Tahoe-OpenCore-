/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250807 (32-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of github/EFI/OC/ACPI/SSDT-RHUB.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000306 (774)
 *     Revision         0x02
 *     Checksum         0x5A
 *     OEM ID           "GLUCH"
 *     OEM Table ID     "RhubOff"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200925 (538970405)
 */
DefinitionBlock ("", "SSDT", 2, "GLUCH", "RhubOff", 0x00001000)
{
    External (_SB_.PC00.RP05, DeviceObj)
    External (_SB_.PC00.XHC1.RHUB, DeviceObj)
    External (_SB_.PC00.XHC_.RHUB, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB, DeviceObj)
    External (_SB_.PCI0.RP05, DeviceObj)
    External (_SB_.PCI0.XHC1.RHUB, DeviceObj)
    External (_SB_.PCI0.XHC_.RHUB, DeviceObj)
    External (_SB_.PCI0.XHCI.RHUB, DeviceObj)

    If (CondRefOf (\_SB.PCI0.XHC.RHUB))
    {
        Scope (_SB.PCI0.XHC.RHUB)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }

    If (CondRefOf (\_SB.PCI0.XHCI.RHUB))
    {
        Scope (_SB.PCI0.XHCI.RHUB)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }

    If (CondRefOf (\_SB.PCI0.XHC1.RHUB))
    {
        Scope (_SB.PCI0.XHC1.RHUB)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHC.RHUB))
    {
        Scope (_SB.PC00.XHC.RHUB)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHCI.RHUB))
    {
        Scope (_SB.PC00.XHCI.RHUB)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }

    If (CondRefOf (\_SB.PC00.XHC1.RHUB))
    {
        Scope (_SB.PC00.XHC1.RHUB)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }

    If (CondRefOf (\_SB.PC00.RP05))
    {
        Scope (_SB.PC00.RP05)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }

    If (CondRefOf (\_SB.PCI0.RP05))
    {
        Scope (_SB.PCI0.RP05)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
    }
}

