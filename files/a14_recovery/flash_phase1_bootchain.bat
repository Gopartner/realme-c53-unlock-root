@echo off
REM ================================================================
REM  FASE 1: FLASH BOOTCHAIN KRITIS A14 (vbmeta*, ocdt, trustos,
REM          teecfg, sml, uboot)
REM  Device harus dalam kondisi BROM.
REM
REM  URUTAN MENGIKUTI SKEMA RESMI A14 (ums9230_hulk.xml):
REM   - EraseSPL di awal (untuk "reset" area SPL)
REM   - EraseUBOOTLOG
REM   - vbmeta, ocdt, vbmeta_system/system_ext/vendor/product/odm
REM   - trustos, teecfg, sml, uboot  (ditulis di urutan ini)
REM  SPL TIDAK ditulis di fase ini - ditulis di FASE 4 (paling akhir)
REM  sesuai skema resmi (SPLLoaderEMMC urutan terakhir).
REM
REM  PAKAI fdl2-dl.bin (exploit) karena perlu menulis uboot.
REM  Jika terputus: device tetap masuk BROM -> ulangi.
REM ================================================================
setlocal
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e splloader ^
  e uboot_log ^
  e vbmeta_a ^
  w vbmeta_a %PAC%\vbmeta-sign.img ^
  e ocdt_a ^
  w ocdt_a %PAC%\oppo22724.bin ^
  e vbmeta_system_a ^
  w vbmeta_system_a %PAC%\vbmeta_system.img ^
  e vbmeta_system_ext_a ^
  w vbmeta_system_ext_a %PAC%\vbmeta_system_ext.img ^
  e vbmeta_vendor_a ^
  w vbmeta_vendor_a %PAC%\vbmeta_vendor.img ^
  e vbmeta_product_a ^
  w vbmeta_product_a %PAC%\vbmeta_product.img ^
  e vbmeta_odm_a ^
  w vbmeta_odm_a %PAC%\vbmeta_odm.img ^
  e trustos_a ^
  w trustos_a %PAC%\tos-sign.bin ^
  e teecfg_a ^
  w teecfg_a %PAC%\teecfg-sign.bin ^
  e sml_a ^
  w sml_a %PAC%\sml-sign.bin ^
  e uboot_a ^
  w uboot_a %PAC%\lk-sign.bin

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo FASE 1 SELESAI. Jangan reboot dulu.
  echo Lanjut ke FASE 2 (flash_phase2_modem.bat).
  pause
)
