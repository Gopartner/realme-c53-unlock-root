@echo off
REM ================================================================
REM  FASE 3: FLASH PARTISI ANDROID A14
REM  Device harus dalam kondisi BROM (ulangi 3-kombinasi tombol).
REM
REM  URUTAN MENGIKUTI SKEMA RESMI A14:
REM   - boot_a       <- boot.img
REM   - vendor_boot_a<- vendor_boot.img
REM   - dtbo_a       <- dtbo.img
REM   - my_preload   <- my_preload.img
REM   - super        <- super.img (5.9GB, butuh beberapa menit)
REM   - cache        <- cache.img
REM   - blackbox     <- blackbox.img
REM   - logo         <- logo.bin
REM   - persist      <- persist.img
REM   - userdata     <- DI-ERASE (file PAC adalah sparse image,
REM                      tidak bisa ditulis mentah; data tak penting)
REM ================================================================
setlocal
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e boot_a ^
  w boot_a %PAC%\boot.img ^
  e vendor_boot_a ^
  w vendor_boot_a %PAC%\vendor_boot.img ^
  e dtbo_a ^
  w dtbo_a %PAC%\dtbo.img ^
  e my_preload ^
  w my_preload %PAC%\my_preload.img ^
  e super ^
  w super %PAC%\super.img ^
  e cache ^
  w cache %PAC%\cache.img ^
  e blackbox ^
  w blackbox %PAC%\blackbox.img ^
  e logo ^
  w logo %PAC%\logo.bin ^
  e persist ^
  w persist %PAC%\persist.img ^
  e userdata

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo FASE 3 SELESAI. Jangan reboot dulu.
  echo Lanjut ke FASE 4 (flash_phase4_finalize.bat).
  pause
)
