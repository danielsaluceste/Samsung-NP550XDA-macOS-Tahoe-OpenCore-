/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250807 (32-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of github/EFI/OC/ACPI/SSDT-S3.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000041 (65)
 *     Revision         0x02
 *     Checksum         0xD5
 *     OEM ID           "XPS13"
 *     OEM Table ID     "S3Fix"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20230628 (539166248)
 */
DefinitionBlock ("", "SSDT", 2, "XPS13", "S3Fix", 0x00001000)
{
    External (_SB_.SS3_, IntObj)

    Scope (\_SB)
    {
        Name (SS3, One)
    }
}

