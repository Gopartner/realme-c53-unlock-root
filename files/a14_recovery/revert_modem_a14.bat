@echo off
REM ================================================================
REM  FALLBACK: REVERT MODEM KE A14 PAC, PERTAHANKAN NV A15 (IMEI)
REM
REM  Dipakai JIKA restore_fixnv1_retry.bat masih bootloop
REM  (artinya stack modem A15 tidak cocok dgn sistem A14).
REM
REM  Yang dilakukan:
REM   - l_fixnv1_a <- NV A15 asli (full, via w + rawdata 0)
REM   - l_fixnv2_a <- mirror NV A15
REM   - l_modem_a, l_deltanv_a, l_ldsp_a, l_gdsp_a, l_agdsp_a,
REM     pm_sys_a  <- stack modem A14 PAC (versi sistem A14)
REM   - prodnv     <- TIDAK disentuh (sudah A15, berisi IMEI)
REM
REM  Hasil = A14 system + A14 modem + NV A15 LENGKAP.
REM  Ini menguji apakah A14 modem mau baca NV A15 yg UTUH
REM  (sebelumnya fixnv1 cuma short-write 0xd5000 -> Unknown).
REM ================================================================
setlocal
set PAC=D:\downloader-firmware\results\pac-bootchain
set BK=D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=D:\realme-c53-recovery\03_downgrade_a14\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  rawdata 0 ^
  e l_fixnv1_a ^
  w l_fixnv1_a %BK%\l_fixnv1_a.img ^
  e l_fixnv2_a ^
  w l_fixnv2_a %BK%\l_fixnv1_a.img ^
  e l_modem_a ^
  w l_modem_a %PAC%\SC9600_qogirl6_pubcp_SPA_modem.bin ^
  e l_deltanv_a ^
  w l_deltanv_a %PAC%\qogirl6_pubcp_SPA_deltanv.bin ^
  e l_ldsp_a ^
  w l_ldsp_a %PAC%\qogirl6_pubcp_SPA_LTEA_DSP.bin ^
  e l_gdsp_a ^
  w l_gdsp_a %PAC%\qogirl6_pubcp_SPA_DM_DSP.bin ^
  e l_agdsp_a ^
  w l_agdsp_a %PAC%\QogirL6_AUDCP_DSP_lit_dm.bin ^
  e pm_sys_a ^
  w pm_sys_a %PAC%\qogirl6_cm4.bin ^
  read_part l_fixnv1_a 0 2097152 "%VER%\verify_fixnv1_a14modem.img"

echo.
echo ================================================================
echo  Cek hash readback l_fixnv1_a vs sumber backup A15:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_fixnv1_a14modem.img'; $b='%BK%\l_fixnv1_a.img'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $b -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS'}else{'FAIL'}; Write-Output ('readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('sumber : '+$h2); Write-Output ('ukuran readback: '+(Get-Item $v).Length)}} else {Write-Output 'readback TIDAK dihasilkan.'}"
echo.
echo  Lepas USB, nyalakan normal. Cek *#06# + Versi baseband.
pause
