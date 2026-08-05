@echo off
REM ================================================================
REM  TULIS l_fixnv1_a PENUH via PADDING KE KELIPATAN PAGE
REM
REM  DIAGNOSIS (dari analisis dump):
REM   l_fixnv1_a SELALU short-write di semua percobaan (termasuk
REM   fase 2 asli downgrade):
REM    - A14 template: target 0xcf498, written 0xcf000 (kurang
REM      0x498 = 1176 byte, termasuk trailer NV di 0xCF497)
REM    - A15 NV: target 0xd5050, written 0xd5000
REM   Pola: SELALU halaman 0x1000 terakhir yg gagal (jalur NV_Part).
REM   NV primer invalid -> modem gagal init -> baseband Unknown.
REM
REM  SOLUSI: pad file NV ke kelipatan page (0xd0000) agar tidak ada
REM  halaman parsial. File: qogirl6_nvitem_pad0xd0000.bin (851968B).
REM  Setelah write, baca ulang 0xcf498 byte dan bandingkan dgn
REM  template asli -> harus PASS.
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=%DIR%\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_fixnv1_a ^
  w l_fixnv1_a %DIR%\qogirl6_nvitem_pad0xd0000.bin ^
  read_part l_fixnv1_a 0 849048 "%VER%\verify_fixnv1_padded.img"

echo.
echo ================================================================
echo  Cek readback 849048 byte vs template A14 (harus PASS):
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_fixnv1_padded.img'; $t='%PAC%\qogirl6_pubcp_SPA_nvitem.bin'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $t -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS - l_fixnv1_a UTUH'}else{'FAIL'}; Write-Output ('readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('template: '+$h2)}} else {Write-Output 'readback TIDAK dihasilkan.'}"
echo.
echo  PENTING: cek log, apakah "written" == target (0xd0000)
echo  TANPA "unexpected response (0x00a2)".
echo  Lepas USB, nyalakan normal. Cek *#06# + Versi baseband.
pause
