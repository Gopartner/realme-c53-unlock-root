@echo off
REM ================================================================
REM  TULIS l_fixnv1_a PENUH via w_force (jalur RAW, bukan NV_Part)
REM
REM  MASALAH (dari analisis source spd_dump):
REM   - `w l_fixnv1_a` selalu lewat load_nv_partition (nama "fixnv1")
REM     yg mengirim chunk parsial 0x498 terakhir -> ditolak (0x00a2)
REM     -> written 0xcf000, NV primer invalid -> baseband Unknown.
REM   - `read_part l_fixnv1_a` DI-REMAP ke l_fixnv2_a (dump_partition)
REM     -> isi asli l_fixnv1_a tak pernah terbaca/verifikasi.
REM
REM  SOLUSI:
REM   - w_force l_fixnv1_a FILE  -> load_partition_force (common.c:1364)
REM     REPARTITION partisi tsb jadi nama "w_force", tulis RAW PENUH
REM     (file size 0xcf498, bukan struktur NV), kembalikan nama.
REM   - read_flash 0x7700000 ... -> dump_flash (BSL_CMD_READ_FLASH,
REM     alamat fisik) -> TIDAK di-remap -> verifikasi isi sebenarnya.
REM   - CRC internal NV dipatch jadi 0x0EE4 (persis yg ditulis
REM     load_nv_partition) -> modem validasi CRC.
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=%DIR%\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

REM 1) Backup isi asli l_fixnv1_a (0x7700000) sebelum menimpa
REM 2) w_force tulis RAW penuh (crc-patched template A14)
REM 3) read_flash verifikasi isi sebenarnya (tanpa remap)
spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  read_flash 0x7700000 0 0xcf498 "%VER%\before_l_fixnv1_a.img" ^
  w_force l_fixnv1_a %DIR%\qogirl6_nvitem_a14_crc.bin ^
  read_flash 0x7700000 0 0xcf498 "%VER%\verify_l_fixnv1_wforce.img" ^
  reboot-fastboot

echo.
echo ================================================================
echo  Cek: written harus 0xcf498 (BUKAN 0xcf000), tanpa 0x00a2
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_l_fixnv1_wforce.img'; $t='%DIR%\qogirl6_nvitem_a14_crc.bin'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $t -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS - l_fixnv1_a UTUH & SAMA DGN TEMPLATE'}else{'FAIL'}; Write-Output ('readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('template: '+$h2)}} else {Write-Output 'readback TIDAK dihasilkan.'}"
echo.
echo  PENTING: jika log menunjukkan "Force Write l_fixnv1_a Done"
echo  dan written == 0xcf498 -> NV PRIMER SEKARANG UTUH.
echo  Lepas USB, nyalakan normal. Cek *#06# + Versi baseband.
pause
