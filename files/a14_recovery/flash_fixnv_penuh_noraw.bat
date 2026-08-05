@echo off
REM ================================================================
REM  UJI: fixnv1/2 PENUH TANPA rawdata 0 (modem A14 + prodnv A15)
REM
REM  Penemuan dari log:
REM   - Fase 2 (tanpa `rawdata 0`): l_fixnv1_a tertulis PENUH
REM   - Semua script dgn `rawdata 0`: l_fixnv1_a SELALU short-write
REM     (unexpected response 0x00a2, written < target)
REM   -> `rawdata 0` MERUSAK protokol NV_Part. DIBUANG.
REM
REM  Kondisi perangkat saat ini (dari flash_a14_modem_keep_a15_prodnv):
REM   - modem/dsp/pm_sys/deltanv A14  (terpasang)
REM   - prodnv A15 (berisi IMEI, tidak disentuh)
REM   - l_fixnv1_a A14 template SHORT (0xcf000/0xcf498) <- MASALAH
REM   - l_fixnv2_a A14 template PENUH
REM
REM  Yang dilakukan: tulis ulang fixnv1+fixnv2 (template A14) TANPA
REM  rawdata 0 agar fixnv1 PENUH. Modem A14 + prodnv A15 tetap.
REM  Kemudian cek baseband/IMEI.
REM ================================================================
setlocal
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=D:\realme-c53-recovery\03_downgrade_a14\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_fixnv1_a ^
  w l_fixnv1_a %PAC%\qogirl6_pubcp_SPA_nvitem.bin ^
  e l_fixnv2_a ^
  w l_fixnv2_a %PAC%\qogirl6_pubcp_SPA_nvitem.bin ^
  read_part l_fixnv1_a 0 2097152 "%VER%\verify_fixnv1_noraw.img"

echo.
echo ================================================================
echo  Cek ukuran & hash readback l_fixnv1_a:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_fixnv1_noraw.img'; $t='%PAC%\qogirl6_pubcp_SPA_nvitem.bin'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $t -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS - fixnv1 UTUH (sama dgn template)'}else{'FAIL'}; Write-Output ('readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('template: '+$h2)}} else {Write-Output 'readback TIDAK dihasilkan.'}"
echo.
echo  PENTING: periksa log, apakah masih ada "unexpected response
echo  (0x00a2)" saat tulis l_fixnv1_a. Tanpa rawdata 0 seharusnya
echo  written == target (PENUH).
echo  Lepas USB, nyalakan normal. Cek *#06# + Versi baseband.
pause
