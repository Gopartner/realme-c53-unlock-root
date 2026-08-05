@echo off
REM ================================================================
REM  VERIFIKASI: READBACK partisi yang baru ditulis & banding SHA-256
REM  Device harus dalam kondisi BROM (ulangi 3-kombinasi tombol).
REM
REM  Partisi yang diverifikasi (dibaca sebesar ukuran file PAC:
REM   - uboot_a (lk-sign.bin), teecfg_a, sml_a, vbmeta_a, ocdt_a
REM   - boot_a, dtbo_a, l_modem_a, l_fixnv1_a
REM  super (5.9GB) TIDAK diverifikasi di sini - opsional manual.
REM
REM  Hasil: file dump di 03_downgrade_a14\verify\ , lalu hash
REM  readback dibandingkan otomatis vs hash file PAC.
REM ================================================================
setlocal
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=D:\realme-c53-recovery\03_downgrade_a14\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  read_part uboot_a 0 1626680 "%VER%\verify_uboot_a.img" ^
  read_part teecfg_a 0 124568 "%VER%\verify_teecfg_a.img" ^
  read_part sml_a 0 122760 "%VER%\verify_sml_a.img" ^
  read_part vbmeta_a 0 1048576 "%VER%\verify_vbmeta_a.img" ^
  read_part ocdt_a 0 68 "%VER%\verify_ocdt_a.img" ^
  read_part boot_a 0 67108864 "%VER%\verify_boot_a.img" ^
  read_part dtbo_a 0 8388608 "%VER%\verify_dtbo_a.img" ^
  read_part l_modem_a 0 26214400 "%VER%\verify_modem_a.img" ^
  read_part l_fixnv1_a 0 849048 "%VER%\verify_fixnv1_a.img"

powershell -NoProfile -ExecutionPolicy Bypass -File "D:\realme-c53-recovery\03_downgrade_a14\verify_compare.ps1"

echo.
if errorlevel 1 (
  echo Readback gagal - periksa log spd_dump.
)
pause
