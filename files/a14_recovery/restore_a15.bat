@echo off
REM ================================================================
REM  RESTORE A15 (JARING PENGAMAN)
REM  Kembalikan device ke A15 stock dari backup.
REM  Jalankan jika downgrade A14 gagal/semi-brick.
REM  Device harus dalam kondisi BROM (ulangi 3-kombinasi tombol).
REM
REM  Sumber: D:\porting-custom-rom\backup\20260727_231930\
REM  SPL A15: D:\Realme-C-project\01_unlock_tool\u-boot-spl-16k-sign.bin
REM
REM  URUTAN MIRIP SKEMA RESMI (SPL ditulis paling akhir).
REM  Partisi yang DI-SKIP (tidak ada di backup / tidak perlu):
REM   - userdata, cache, blackbox (di-erase saja)
REM   - oplusreserve/opporeserve/dtb/hypervsior/avbmeta_rs/common_rs
REM     (bukan bagian chain boot kritis; tidak rusak oleh downgrade)
REM  PAKAI fdl2-dl.bin (exploit) karena perlu menulis uboot & SPL.
REM ================================================================
setlocal
set BK=D:\porting-custom-rom\backup\20260727_231930
set SPL=D:\Realme-C-project\01_unlock_tool\u-boot-spl-16k-sign.bin
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e splloader ^
  e uboot_log ^
  e vbmeta_a ^
  w vbmeta_a %BK%\vbmeta_a.img ^
  e ocdt_a ^
  w ocdt_a %BK%\ocdt_a.img ^
  e vbmeta_system_a ^
  w vbmeta_system_a %BK%\vbmeta_system_a.img ^
  e vbmeta_system_ext_a ^
  w vbmeta_system_ext_a %BK%\vbmeta_system_ext_a.img ^
  e vbmeta_vendor_a ^
  w vbmeta_vendor_a %BK%\vbmeta_vendor_a.img ^
  e vbmeta_product_a ^
  w vbmeta_product_a %BK%\vbmeta_product_a.img ^
  e vbmeta_odm_a ^
  w vbmeta_odm_a %BK%\vbmeta_odm_a.img ^
  e l_fixnv1_a ^
  w l_fixnv1_a %BK%\l_fixnv1_a.img ^
  e l_deltanv_a ^
  w l_deltanv_a %BK%\l_deltanv_a.img ^
  e prodnv ^
  w prodnv %BK%\prodnv.img ^
  e l_modem_a ^
  w l_modem_a %BK%\l_modem_a.img ^
  e l_ldsp_a ^
  w l_ldsp_a %BK%\l_ldsp_a.img ^
  e l_gdsp_a ^
  w l_gdsp_a %BK%\l_gdsp_a.img ^
  e l_agdsp_a ^
  w l_agdsp_a %BK%\l_agdsp_a.img ^
  e pm_sys_a ^
  w pm_sys_a %BK%\pm_sys_a.img ^
  e boot_a ^
  w boot_a %BK%\boot_a.img ^
  e vendor_boot_a ^
  w vendor_boot_a %BK%\vendor_boot_a.img ^
  e dtbo_a ^
  w dtbo_a %BK%\dtbo_a.img ^
  e init_boot_a ^
  w init_boot_a %BK%\init_boot_a.img ^
  e super ^
  w super %BK%\super.img ^
  e persist ^
  w persist %BK%\persist.img ^
  e logo ^
  w logo %BK%\logo.img ^
  e fbootlogo ^
  w fbootlogo %BK%\fbootlogo.img ^
  e trustos_a ^
  w trustos_a %BK%\trustos_a.img ^
  e teecfg_a ^
  w teecfg_a %BK%\teecfg_a.img ^
  e sml_a ^
  w sml_a %BK%\sml_a.img ^
  e uboot_a ^
  w uboot_a %BK%\uboot_a_trimmed.img ^
  e miscdata ^
  e misc ^
  e l_runtimenv1 ^
  e sysdumpdb ^
  e metadata ^
  e userdata ^
  e cache ^
  e blackbox ^
  e splloader ^
  w splloader %SPL% ^
  set_active a ^
  reset

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo ================================================================
  echo  RESTORE A15 SELESAI - device reboot ke A15 stock.
  echo  Jika masih tidak boot: kemungkinan besar masalah HARDWARE.
  echo  (Tes daya: charger original berjam-jam, cek HP hangat.)
  echo ================================================================
  pause
)
