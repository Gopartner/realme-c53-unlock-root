@echo off
REM ================================================================
REM  EKSPERIMEN: kombinasi format NV yang benar menurut source
REM  l_fixnv1_a = struktur mentah (template A14 crc)   [load_nv_partition tidak skip]
REM  l_fixnv2_a = VN wrapper (backup A15, berisi IMEI) [format 56 4E...]
REM  Verify via read_part l_fixnv2_a (tidak di-remap)
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set PAC=D:\downloader-firmware\results\pac-bootchain
set VER=%DIR%\verify
set LOG=%DIR%\wforce_v4_mix.log
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  w_force l_fixnv1_a "%DIR%\qogirl6_nvitem_a14_crc.bin" ^
  w_force l_fixnv2_a "%DIR%\backup_a15_fresh\l_fixnv1_a.img" ^
  read_part l_fixnv2_a 0 2097152 "%VER%\verify_v4_nv2.img" ^
  reboot-fastboot > "%LOG%" 2>&1

type "%LOG%"

echo.
echo ================================================================
echo  Hash:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$f='%VER%\verify_v4_nv2.img'; if(Test-Path $f){(Get-FileHash $f -Algorithm SHA1).Hash; (Get-Item $f).Length} else {'MISSING'}; Write-Output ('target l_fixnv2_a = backup A15 VN wrapper (2MB, B40FEA4A88F6F55224B292A5FE6C353239CCCECD)')"
pause
