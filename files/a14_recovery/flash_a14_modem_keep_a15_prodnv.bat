@echo off
REM ================================================================
REM  TEST KOMBINASI BARU: A14 MODEM + A14 NV TEMPLATE + A15 PRODNV
REM
REM  Kenapa kombinasi ini:
REM   - A15 modem + sistem A14  = BOOTLOOP (sudah terbukti)
REM   - A14 modem + NV A15      = boot tapi baseband Unknown (sudah dites)
REM   - A14 modem + NV A14      = format benar utk modem A14,
REM                               tapi template NV-nya KOSONG (tanpa IMEI)
REM   - prodnv A15  = berisi IMEI asli (terenkripsi kunci perangkat),
REM                    TIDAK boleh tertimpa template A14 yg kosong!
REM
REM  Yang ditulis (SEMUA versi A14 PAC, kecuali prodnv):
REM   - l_fixnv1_a, l_fixnv2_a  <- qogirl6_pubcp_SPA_nvitem.bin (template A14)
REM   - l_deltanv_a             <- qogirl6_pubcp_SPA_deltanv.bin
REM   - l_modem_a               <- SC9600_qogirl6_pubcp_SPA_modem.bin
REM   - l_ldsp_a / l_gdsp_a / l_agdsp_a / pm_sys_a <- A14 PAC
REM   - prodnv                  <- TIDAK disentuh (tetap A15, berisi IMEI)
REM
REM  Catatan: fixnv1 A15 yang lama memang akan tertimpa template,
REM  tapi backup lengkap masih ada di backup_a15_fresh untuk dikembalikan.
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
  w l_fixnv1_a %PAC%\qogirl6_pubcp_SPA_nvitem.bin ^
  e l_fixnv2_a ^
  w l_fixnv2_a %PAC%\qogirl6_pubcp_SPA_nvitem.bin ^
  e l_deltanv_a ^
  w l_deltanv_a %PAC%\qogirl6_pubcp_SPA_deltanv.bin ^
  e l_modem_a ^
  w l_modem_a %PAC%\SC9600_qogirl6_pubcp_SPA_modem.bin ^
  e l_ldsp_a ^
  w l_ldsp_a %PAC%\qogirl6_pubcp_SPA_LTEA_DSP.bin ^
  e l_gdsp_a ^
  w l_gdsp_a %PAC%\qogirl6_pubcp_SPA_DM_DSP.bin ^
  e l_agdsp_a ^
  w l_agdsp_a %PAC%\QogirL6_AUDCP_DSP_lit_dm.bin ^
  e pm_sys_a ^
  w pm_sys_a %PAC%\qogirl6_cm4.bin ^
  read_part prodnv 0 67108864 "%VER%\verify_prodnv_keep.img"

echo.
echo ================================================================
echo  Cek hash readback prodnv vs backup A15 (harus SAMA, IMEI utuh):
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_prodnv_keep.img'; $b='%BK%\prodnv.img'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $b -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS - IMEI/prodnv A15 utuh'}else{'FAIL'}; Write-Output ('readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('sumber : '+$h2)}} else {Write-Output 'readback prodnv TIDAK dihasilkan.'}"
echo.
echo  Lepas USB, nyalakan normal. Cek *#06# + Versi baseband.
echo  (Jika baseband muncul = SOLUSI DITEMUKAN)
pause
