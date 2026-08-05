@echo off
REM ================================================================
REM  BACKUP ULANG A15 (OPSIONAL - TITIK REVERT SEGAR)
REM  Ambil ulang partisi kritis A15 ke folder 03_downgrade_a14\backup\
REM  sebelum flash downgrade. Backup lama (20260727_231930) tetap
REM  menjadi sumber utama restore_a15.bat.
REM  Device harus dalam kondisi BROM.
REM ================================================================
setlocal
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set BK=D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh
if not exist "%BK%" mkdir "%BK%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  read_part splloader 0 1048576 "%BK%\splloader.img" ^
  read_part uboot_a 0 3145728 "%BK%\uboot_a.img" ^
  read_part teecfg_a 0 1048576 "%BK%\teecfg_a.img" ^
  read_part sml_a 0 1048576 "%BK%\sml_a.img" ^
  read_part trustos_a 0 6291456 "%BK%\trustos_a.img" ^
  read_part vbmeta_a 0 1048576 "%BK%\vbmeta_a.img" ^
  read_part ocdt_a 0 8388608 "%BK%\ocdt_a.img" ^
  read_part vbmeta_system_a 0 1048576 "%BK%\vbmeta_system_a.img" ^
  read_part vbmeta_system_ext_a 0 1048576 "%BK%\vbmeta_system_ext_a.img" ^
  read_part vbmeta_vendor_a 0 1048576 "%BK%\vbmeta_vendor_a.img" ^
  read_part vbmeta_product_a 0 1048576 "%BK%\vbmeta_product_a.img" ^
  read_part vbmeta_odm_a 0 1048576 "%BK%\vbmeta_odm_a.img" ^
  read_part l_fixnv1_a 0 2097152 "%BK%\l_fixnv1_a.img" ^
  read_part l_deltanv_a 0 1048576 "%BK%\l_deltanv_a.img" ^
  read_part prodnv 0 67108864 "%BK%\prodnv.img" ^
  read_part l_modem_a 0 26214400 "%BK%\l_modem_a.img" ^
  read_part l_ldsp_a 0 20971520 "%BK%\l_ldsp_a.img" ^
  read_part l_gdsp_a 0 10485760 "%BK%\l_gdsp_a.img" ^
  read_part l_agdsp_a 0 6291456 "%BK%\l_agdsp_a.img" ^
  read_part pm_sys_a 0 1048576 "%BK%\pm_sys_a.img" ^
  read_part boot_a 0 67108864 "%BK%\boot_a.img" ^
  read_part vendor_boot_a 0 104857600 "%BK%\vendor_boot_a.img" ^
  read_part dtbo_a 0 8388608 "%BK%\dtbo_a.img" ^
  read_part init_boot_a 0 8388608 "%BK%\init_boot_a.img" ^
  read_part super 0 8388608000 "%BK%\super.img"

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo BACKUP SELESAI. File tersimpan di:
  echo %BK%
  pause
)
