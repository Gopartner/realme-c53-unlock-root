@echo off
REM ================================================================
REM  ROOT via Magisk - TANPA UNLOCK BOOTLOADER (metode bypass UBL)
REM  - boot_a   = magisk_patched_boot.img (sha1 A8BCB42F...)
REM  - vbmeta_a = verify_vbmeta_a_new_pad.img (avbtool flags=2,
REM               VERIFICATION_DISABLED, algorithm NONE)
REM  Flash via BROM/spd_dump, lalu verify read-back + reboot-fastboot
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=%DIR%\verify
set LOG=%DIR%\wforce_root.log
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  w_force boot_a "%DIR%\magisk_patched_boot.img" ^
  w_force vbmeta_a "%VER%\verify_vbmeta_a_new_pad.img" ^
  read_part boot_a 0 67108864 "%VER%\verify_root_boot_a.img" ^
  read_part vbmeta_a 0 1048576 "%VER%\verify_root_vbmeta_a.img" ^
  reboot-fastboot > "%LOG%" 2>&1

type "%LOG%"

echo.
echo ================================================================
echo  Hash hasil:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$a='%VER%\verify_root_boot_a.img'; $b='%VER%\verify_root_vbmeta_a.img'; if(Test-Path $a){(Get-FileHash $a -Algorithm SHA1).Hash; (Get-Item $a).Length} else {'boot MISSING'}; Write-Output ('target boot_a    = A8BCB42FBD2EBFE5B753C0C4021A6BB11D6BA2BD'); if(Test-Path $b){(Get-FileHash $b -Algorithm SHA1).Hash; (Get-Item $b).Length} else {'vbmeta MISSING'}; Write-Output ('target vbmeta_a  = 7C79BBFCF485822582B30DBE45B8B1DDAA6332B4 (flags=2, 1MB pad)')"
pause
