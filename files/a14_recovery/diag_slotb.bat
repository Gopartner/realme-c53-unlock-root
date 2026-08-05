@echo off
REM ================================================================
REM  DIAGNOSA SLOT B + PENANDA SLOT BOOT
REM  Baca l_modem_b, l_gdsp_b, l_fixnv2_b, l_deltanv_b, misc, miscdata
REM  untuk menentukan slot aktif dan versi modem/NV di slot B.
REM ================================================================
setlocal
set DIR=D:\realme-c53-recovery\03_downgrade_a14
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=%DIR%\verify
set LOG=%DIR%\diag_slotb.log
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  read_part misc 0 1048576 "%VER%\now_misc.img" ^
  read_part miscdata 0 1048576 "%VER%\now_miscdata.img" ^
  read_part l_modem_b 0 26214400 "%VER%\now_l_modem_b.img" ^
  read_part l_gdsp_b 0 10485760 "%VER%\now_l_gdsp_b.img" ^
  read_part l_fixnv2_b 0 2097152 "%VER%\now_l_fixnv2_b.img" ^
  read_part l_deltanv_b 0 1048576 "%VER%\now_l_deltanv_b.img" ^
  reboot-fastboot > "%LOG%" 2>&1

type "%LOG%"

echo.
echo ================================================================
echo  Hash partisi slot B vs PAC A14 vs backup A15:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$files=@('now_l_modem_b','now_l_gdsp_b','now_l_fixnv2_b','now_l_deltanv_b'); $pac=@{'now_l_modem_b'='D:\downloader-firmware\results\pac-bootchain\SC9600_qogirl6_pubcp_SPA_modem.bin';'now_l_gdsp_b'='D:\downloader-firmware\results\pac-bootchain\qogirl6_pubcp_SPA_DM_DSP.bin';'now_l_fixnv2_b'='D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh\l_fixnv1_a.img';'now_l_deltanv_b'='D:\downloader-firmware\results\pac-bootchain\qogirl6_pubcp_SPA_deltanv.bin'}; foreach($n in $files){ $p='%VER%\'+$n+'.img'; $hp= if(Test-Path $p){(Get-FileHash $p -Algorithm SHA1).Hash}else{'MISSING'}; $ppac= if(Test-Path $pac[$n]){(Get-FileHash $pac[$n] -Algorithm SHA1).Hash}else{'-'}; Write-Output ('{0}`n  NOW : {1}`n  PAC : {2}`n' -f $n,$hp,$ppac) }"
pause
