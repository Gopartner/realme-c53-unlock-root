@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set SPD=spd_dump.exe
set FDL1=fdl1-sign.bin
set FDL2=lk-fdl2-sign.bin
set UBOOTBK=uboot_bak.bin
set PATCHED=u-boot-spl-16k-sign.bin
set BASE=--wait 300 exec_addr 0x65015f08 fdl %FDL1% 0x65000800 fdl %FDL2% 0x9efffe00 exec

if not exist %SPD% ( echo spd_dump.exe tidak ditemukan. & pause & exit /b 1 )

echo ===== RECOVERY BOOT: restore uboot yang terbukti boot =====
echo.
echo Kondisi sekarang (bootloop) harusnya tetap bisa masuk BROM:
echo tahan Vol Up+Down, colok USB, lepas saat "SPRD U2S Diag" muncul.
echo.
echo STEP 1: restore uboot_a = uboot_bak.bin (62F02A2A, proven boot)
echo          + splloader  = u-boot-spl-16k-sign.bin (patched spl)
echo.
echo CABUT kabel sekarang, lalu tekan Enter.
pause
echo PASANG ulang tahan Vol sampai COM muncul, lalu tekan Enter.
pause
%SPD% %BASE% w splloader %PATCHED% w uboot %UBOOTBK% reset < nul
echo.
echo Cek: harus ada "Write Part Done: splloader" dan "Write Part Done: uboot".
echo Kalau sukses, device reset dan harusnya boot ke Android.
echo.
echo Jika ingin pakai uboot stock penuh (94EFC4C2, full 3MB), jalankan ulang
echo dengan perintah:  w uboot uboot_a_stock_full.img
pause
