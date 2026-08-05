@echo off
REM ================================================================
REM  RESTORE NV ASLI DEVICE (backup A15 fresh, format VN wrapper)
REM  ke l_fixnv1_a + l_fixnv2_a via w_force + LOG + VERIFIKASI
REM
REM  TEMUAN:
REM   - Backup A15 fresh l_fixnv1_a.img (2MB) = NV ASLI device,
REM     format "VN" wrapper (header @0x0, struktur NV @0x200),
REM     berisi IMEI device. Struktur item identik dgn template A14.
REM   - Sebelumnya kita menulis template A14 MENTAH (tanpa wrapper
REM     VN) -> modem mungkin menolak format -> baseband Unknown.
REM
REM  LANGKAH:
REM   1) w_force l_fixnv1_a <- backup A15 fresh (2MB penuh)
REM   2) w_force l_fixnv2_a <- backup A15 fresh (2MB penuh)
REM   3) read_part l_fixnv2_a (TIDAK di-remap) -> verifikasi hash
REM   4) reboot-fastboot
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=%DIR%\verify
set LOG=%DIR%\wforce_v3_restore.log
set NV=%DIR%\backup_a15_fresh\l_fixnv1_a.img
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  w_force l_fixnv1_a "%NV%" ^
  w_force l_fixnv2_a "%NV%" ^
  read_part l_fixnv2_a 0 2097152 "%VER%\verify_nv_restore.img" ^
  reboot-fastboot > "%LOG%" 2>&1

type "%LOG%"

echo.
echo ================================================================
echo  Verifikasi readback l_fixnv2_a vs backup A15 fresh (PASS?):
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_nv_restore.img'; $t='%NV%'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $t -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS - NV ASLI UTUH (2MB)'}else{'FAIL - beda'}; Write-Output ('readback : {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('backup   : '+$h2)}} else {Write-Output 'readback TIDAK dihasilkan.'}"
echo.
echo  Boot normal. Cek *#06# (IMEI) + versi baseband.
pause
