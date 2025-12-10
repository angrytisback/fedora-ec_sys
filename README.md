
# Fedora ec_sys Module Installer

**This utility automates the process of enabling the `ec_sys` kernel module with write support on Fedora**

## Prerequisites

### Secure Boot Warning

If Secure Boot is enabled in the BIOS/UEFI, this module will fail to load because it is not signed by a trusted authority (Fedora/Microsoft)

You have two options:

1. Disable Secure Boot in the BIOS.
2. Sign the Module manually using a Machine Owner Key (MOK).

Please refer to [`SIGNING.md`](https://github.com/angrytisback/fedora-ec_sys/blob/main/SIGNING.md) for detailed instructions.

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/angrytisback/fedora-ec_sys.git
   cd fedora-ec-sys
   ```
2. **Execute the installer:**
   ```bash
   chmod +x install.sh
   sudo ./install.sh
   cd fedora-ec_sys
   ```
   The script attempts to load the module immediately. A reboot may be required if the module fails to load.

## Verification

To confirm the module is active and has write access, insert the EC debug interface:

```bash
 sudo hexdump -C /sys/kernel/debug/ec/ec0/io
```

The output should look like this:

```text
00000000 00 80 00 00 00 00 00 00 00 00 00 00 00 00 00 00 |................|
00000010 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 |................|
00000020 00 00 00 00 00 00 00 00 0a 05 00 00 08 24 0b 4b |.............$.K|
00000030 03 09 00 0d 00 00 52 81 d2 11 88 2c c8 01 e0 00 |......R....,....|
00000040 00 00 64 00 78 11 00 00 78 11 96 32 b7 0b 00 00 |..d.x...x..2....|
00000050 00 00 00 00 00 01 00 00 00 00 00 00 00 00 00 00 |................|
00000060 00 00 00 00 00 00 00 00 37 00 25 40 49 4c 52 58 |........7.%@ILRX|
00000070 64 2b 00 2b 30 36 3c 4b 55 64 08 03 03 03 03 03 |d+.+06<KUd......|
00000080 00 00 37 3d 43 49 4f 53 63 00 00 2b 30 36 3c 4b |..7=CIOSc..+06<K|
00000090 55 64 08 03 03 03 03 02 06 0f 7d 06 0a 78 36 00 |Ud........}..x6.|
000000a0 31 35 38 35 45 4d 53 31 2e 31 31 35 30 38 32 32 |1585EMS1.1150822|
000000b0 32 30 32 34 31 33 3a 33 36 3a 31 36 00 00 00 08 |202413:36:16....|
000000c0 00 00 07 22 00 00 12 00 00 bc 00 00 00 00 00 00 |..."............|
000000d0 00 00 c1 83 8d 00 05 e4 00 05 00 00 00 0b 00 00 |................|
000000e0 e2 00 00 78 11 00 00 c1 00 00 00 00 00 c2 00 00 |...x............|
000000f0 40 00 70 00 00 64 00 00 64 00 00 00 00 01 00 00 |@.p..d..d.......|
00000100
```

