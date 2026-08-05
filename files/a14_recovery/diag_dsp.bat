@echo off
REM ================================================================
REM  DIAGNOSA: baca partisi modem-related utk cek versi yg terpasang
REM  (l_gdsp_a, l_ldsp_a, l_agdsp_a, l_deltanv_a, l_fixnv1/2_a)
REM  Lalu bandingkan hash dgn PAC A14 vs backup A15.
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=%DIR%\verify
set LOG=%DIR%\diag_dsp.log
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  read_part l_gdsp_a 0 10485760 "%VER%\now_l_gdsp_a.img" ^
  read_part l_ldsp_a 0 20971520 "%VER%\now_l_ldsp_a.img" ^
  read_part l_agdsp_a 0 6291456 "%VER%\now_l_agdsp_a.img" ^
  read_part l_deltanv_a 0 1048576 "%VER%\now_l_deltanv_a.img" ^
  read_part l_fixnv1_a 0 2097152 "%VER%\now_l_fixnv1_a.img" ^
  read_part l_fixnv2_a 0 2097152 "%VER%\now_l_fixnv2_a.img" ^
  reboot-fastboot > "%LOG%" 2>&1

type "%LOG%"

echo.
echo ================================================================
echo  Hash partisi SEKARANG vs PAC A14 vs backup A15:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$files=@('now_l_gdsp_a','now_l_ldsp_a','now_l_agdsp_a','now_l_deltanv_a','now_l_fixnv1_a','now_l_fixnv2_a'); $pac=@{'now_l_gdsp_a'='D:\downloader-firmware\results\pac-bootchain\qogirl6_pubcp_SPA_DM_DSP.bin';'now_l_ldsp_a'='D:\downloader-firmware\results\pac-bootchain\qogirl6_pubcp_SPA_LTEA_DSP.bin';'now_l_agdsp_a'='D:\downloader-firmware\results\pac-bootchain\QogirL6_AUDCP_DSP_lit_dm.bin';'now_l_deltanv_a'='D:\downloader-firmware\results\pac-bootchain\qogirl6_pubcp_SPA_deltanv.bin';'now_l_fixnv1_a'='D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh\l_fixnv1_a.img';'now_l_fixnv2_a'='D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh\l_fixnv1_a.img'}; $b15='D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh\'; foreach($n in $files){ $p='%VER%\'+$n+'.img'; $hp= if(Test-Path $p){(Get-FileHash $p -Algorithm SHA1).Hash}else{'MISSING'}; $ppac= if(Test-Path $pac[$n]){(Get-FileHash $pac[$n] -Algorithm SHA1).Hash}else{'-'}; $pb15= if(Test-Path ($b15+$n+'.img')){(Get-FileHash ($b15+$n+'.img') -Algorithm SHA1).Hash}else{'-'}; Write-Output ('{0}`n  NOW : {1}`n  PAC : {2}`n  A15 : {3}`n' -f $n,$hp,$ppac,$pb15) }"
pause
