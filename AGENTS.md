# AGENTS.md — Realme C53 (RMX3760) Unlock & Root Guide for AI

## Device Identity
- **Model**: Realme C53 (RMX3760)
- **SoC**: Unisoc T612 (ums9230)
- **Kernel**: `5.15.178-android13-8` (non-GKI)
- **Android**: 15 (AP3A.240905.015.A2)
- **Build**: `realme/RMX3760/RE58C2:15/AP3A.240905.015.A2/T.R4T2.1773288057:user/release-keys`
- **Arch**: aarch64, ARM Cortex-A55 (6x) + A78 (2x)
- **Slots**: A/B (`boot_a`/`boot_b`, `init_boot_a`/`init_boot_b`)

## Working Directory
```
D:\Realme-C-project\
```

## Key Paths
| Item | Path |
|------|------|
| Backup | `D:\Realme-C-project\backup\` |
| Stock boot | `D:\Realme-C-project\backup\stock_boot.img` (64 MB) |
| Unlock state | `D:\Realme-C-project\backup\unlock_state\` (partition dumps) |
| Unlock tool | `D:\Realme-C-project\unlock_tool\` (CVE-2022-38694) |
| KernelSU files | `D:\Realme-C-project\ksu\` |
| Magisk-patched boot | `D:\Realme-C-project\ksu\magisk_patched_boot.img` |
| SPRD driver | `D:\Realme-C-project\sprd_driver\` |
| Kernel source | `https://github.com/realme-kernel-opensource/realme_C51_C53_Note50_C60_C51_N53-AndroidU-kernel-source` |

## Git Bash Path Mangling Fix
Git Bash converts `/data/local/tmp/` to `C:/Program Files/Git/data/local/tmp/`. Always use:
```bash
export MSYS2_ARG_CONV_EXCL="*"
# Then run adb commands normally
```

## Step 1: Backup Data
```bash
adb shell "mkdir -p /sdcard/backup_media && cp -r /sdcard/DCIM /sdcard/backup_media/ && cp -r /sdcard/Pictures /sdcard/backup_media/ && cp -r /sdcard/Download /sdcard/backup_media/ && cp -r /sdcard/WhatsApp /sdcard/backup_media/" 2>/dev/null
adb pull //sdcard/backup_media/ "D:/Realme-C-project/backup/"
# Enable Google Backup
adb shell "settings put secure backup_enabled 1 && bmgr run"
# Backup WhatsApp manually via app → Chats → Chat backup → Back up
```

## Step 2: Unlock Bootloader (CVE-2022-38694)
**Tool**: `https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader` (release 1.72)

### Prerequisites
- Install SPRD driver (`D:\Realme-C-project\sprd_driver\`)
- Device shows as **SPRD U2S Diag (COM3)** in Device Manager
- `spd_dump.exe` needs `Channel9.dll` and `Channel.ini` in working dir

### Sub-steps
1. **Dump partitions**:
   ```
   spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin
   spd_dump.exe dump 0x00002000 0x00006000 splloader.bin  
   spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin
   ```
2. **Generate patched SPL**: `gen_spl-unlock.exe uboot_a.bin`
3. **Erase + write cboot**:
   ```
   spd_dump.exe erase 0x00002000 0x00006000
   spd_dump.exe write 0x00002000 rmx3762/fdl2-cboot.bin
   ```
4. **Screwdriver+PowerOff**: Hold both vol keys, tap power 1s, release power
5. **Run unlock payload**: `spd_dump.exe write 0x00002000 spl-unlock.bin`
6. **Restore & wipe**:
   ```
   spd_dump.exe write 0x00002000 u-boot-spl-16k-sign.bin
   spd_dump.exe write 0x0000c000 uboot_bak.bin
   spd_dump.exe erase 0x0000e000 0x00002000
   ```
7. **Verify**: `spd_dump.exe dump 0x0000e000 0x00000001 miscdata.bin` → non-zero = unlocked

## Step 3: Dump Stock Boot
```bash
adb shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.bin"
adb pull //data/local/tmp/boot.bin "D:\Realme-C-project\backup\stock_boot.img"
```

## Step 4: Root with Magisk
### Prerequisites
- Download Magisk APK v30.7+ from `https://github.com/topjohnwu/Magisk/releases`
- Extract magiskboot, magiskinit, magisk, magiskpolicy, busybox, init-ld from APK

### Patch Boot Image
```bash
export MSYS2_ARG_CONV_EXCL="*"
# Push stock boot and Magisk files to phone
adb push "D:\Realme-C-project\backup\stock_boot.img" /data/local/tmp/boot.img
adb push files... /data/local/tmp/magisk/
adb shell chmod 755 /data/local/tmp/magisk/*
# Run boot_patch.sh
adb shell /data/local/tmp/magisk/boot_patch.sh /data/local/tmp/boot.img
# Pull patched image
adb pull /data/local/tmp/magisk/new-boot.img "D:\Realme-C-project\ksu\magisk_patched_boot.img"
```

### Flash
```bash
adb reboot bootloader
fastboot flash boot_a "D:\Realme-C-project\ksu\magisk_patched_boot.img"
fastboot flash boot_b "D:\Realme-C-project\ksu\magisk_patched_boot.img"
fastboot reboot
```

### Grant Root Permission
```bash
adb shell su -c id  # Will show "Accessed denied" until granted
```
- Open **Magisk** on phone → **Superuser** tab → Grant **Shell**
- Or: `adb shell /data/local/tmp/magisk/magisk --sqlite "UPDATE policies SET policy=2 WHERE package_name='com.android.shell'"`

## Notes for AI
- Use `export MSYS2_ARG_CONV_EXCL="*"` before ALL adb commands on Git Bash
- `adb pull` from `/sdcard` needs `//sdcard/` prefix (double slash)
- magiskd must be running after boot (check `ps -A | grep magiskd`)
- Stock boot.img has **no ramdisk** (RAMDISK_SZ: 0) — Magisk creates one
- Pre-built KernelSU LKM modules are incompatible (vermagic mismatch: 5.15.202 vs 5.15.178)
- Always flash BOTH boot_a and boot_b for slot safety
- `fastboot flash boot` fails — use `fastboot flash boot_a` / `fastboot flash boot_b`
