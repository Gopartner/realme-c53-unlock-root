@echo off
REM ================================================================
REM  TULIS NV KE l_fixnv1_a + l_fixnv2_a via w_force (RAW penuh)
REM  + LOG LENGKAP + VERIFIKASI lewat read_part l_fixnv2_a
REM
REM  STRATEGI:
REM   - w_force menulis file penuh (0xcf498) via REPARTITION+RAW,
REM     BUKAN load_nv_partition (yg short-write 0xcf000).
REM   - l_fixnv2_a ditulis file yg SAMA -> modem membaca partisi
REM     mana pun yg valid; sekaligus jadi vektor verifikasi.
REM   - read_part l_fixnv2_a TIDAK di-remap (hanya nama "nv1" yg
REM     diremap ke "nv2") -> bisa membuktikan w_force menulis penuh.
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=%DIR%\verify
set LOG=%DIR%\wforce_v2.log
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  w_force l_fixnv1_a %DIR%\qogirl6_nvitem_a14_crc.bin ^
  w_force l_fixnv2_a %DIR%\qogirl6_nvitem_a14_crc.bin ^
  read_part l_fixnv2_a 0 849048 "%VER%\verify_wforce_nv2.img" ^
  read_part l_fixnv1_a 0 849048 "%VER%\verify_wforce_nv1.img" ^
  reboot-fastboot > "%LOG%" 2>&1

type "%LOG%"

echo.
echo ================================================================
echo  Verifikasi l_fixnv2_a readback vs template (harus PASS):
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_wforce_nv2.img'; $t='%DIR%\qogirl6_nvitem_a14_crc.bin'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $t -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS - w_force menulis PENUH 0xcf498'}else{'FAIL - written != target'}; Write-Output ('nv2 readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('template    : '+$h2)}} else {Write-Output 'readback TIDAK dihasilkan.'}"
echo.
echo  Cek di log: "Force Write" harus muncul untuk l_fixnv1_a DAN l_fixnv2_a.
echo  Boot normal, cek *#06# + versi baseband.
pause
