@echo off
REM ================================================================
REM  FASE 4: FINALIZE - ERASE + SPL + SET ACTIVE + REBOOT
REM  Device harus dalam kondisi BROM (ulangi 3-kombinasi tombol).
REM
REM  URUTAN MENGIKUTI SKEMA RESMI A14:
REM   - erase l_runtimenv1 (FLASH_LTE)
REM   - erase misc (EraseMisc)
REM   - erase sysdumpdb (EraseSysdumpdb)
REM   - erase metadata (EraseMetadata)
REM   - erase miscdata (PhaseCheck - dikosongkan agar device tidak
REM     menganggap fase flash belum selesai)
REM   - erase userdata (data A15 yang terenkripsi, tidak terpakai)
REM   - WRITE SPL PALING AKHIR (SPLLoaderEMMC) <- u-boot-spl-16k-emmc
REM   - set_active a
REM   - reset (reboot)
REM
REM  PERHATIAN: setelah reset, device mencoba boot A14. Jika gagal,
REM  masuk BROM lagi (3-kombinasi) dan jalankan restore_a15.bat.
REM ================================================================
setlocal
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_runtimenv1 ^
  e misc ^
  e sysdumpdb ^
  e metadata ^
  e miscdata ^
  e userdata ^
  e splloader ^
  w splloader %PAC%\u-boot-spl-16k-emmc-sign.bin ^
  set_active a ^
  reset

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo ================================================================
  echo  FASE 4 SELESAI - device reboot ke A14.
  echo  Pantau layar. Jika boot ke Android: SELAMAT, downgrade sukses.
  echo  Jika hang/kaki/loop: masuk BROM lagi lalu jalankan
  echo  restore_a15.bat untuk kembali ke A15.
  echo ================================================================
  pause
)
