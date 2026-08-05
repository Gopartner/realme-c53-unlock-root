@echo off
REM ================================================================
REM  RESTORE STACK MODEM A15 LENGKAP (PEMULIHAN BASEBAND + IMEI)
REM
REM  DIAGNOSIS BASEBAND MASIH UNKNOWN:
REM   Setelah restore_nv_asli.bat, perangkat punya:
REM    - NV A15 (l_fixnv1_a short, l_fixnv2_a penuh, prodnv penuh)
REM    - TAPI modem/deltanv/DSP/pm_sys MASIH A14 PAC (dari fase 2)
REM   Modem A14 (SC9600_qogirl6_pubcp_SPA_modem.bin, E6014C44)
REM   TIDAK kompatibel dengan NV A15 (22B_W25.07.2_SPA_P21)
REM   -> baseband gagal init -> Versi baseband: Unknown.
REM
REM  SOLUSI: flash stack modem A15 LENGKAP dari backup_a15_fresh
REM   (kondisi A15 yang BUKTI bekerja dengan IMEI), sambil
REM   mempertahankan sistem A14 yang sudah boot.
REM
REM  SUMBER (verifikasi SHA-1):
REM   - l_fixnv1_a.img  = B40FEA4A88F6F55224B292A5FE6C353239CCCECD (NV A15 asli)
REM   - l_modem_a.img   = E2A33C0D765E3F7C77C87B4BCA1133A6E9247C38 (modem A15)
REM   - l_deltanv_a.img = 7FC0992C9E157905ED5DF5F732BFDCBF3737B21A (deltanv A15)
REM   - prodnv.img      = 5856DF4C3047ABE378FFF7331288EA6BD136409E (prodnv A15)
REM   - l_ldsp_a / l_gdsp_a / l_agdsp_a / pm_sys_a = versi A15 fresh
REM
REM  CATATAN l_fixnv1_a: jalur `w` (NV_Part) SELALU short-write
REM   (unexpected response 0x00a2, target 0xd5050 written 0xd5000).
REM   Dipakai `wof` (write-at-offset 0) = raw write penuh 2MB.
REM
REM  Device harus dalam kondisi BROM (ulangi 3-kombinasi tombol:
REM  Volume UP + Volume DOWN + Power, tahan lalu colok USB).
REM ================================================================
setlocal
set BK=D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=D:\realme-c53-recovery\03_downgrade_a14\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_fixnv1_a ^
  wof l_fixnv1_a 0 %BK%\l_fixnv1_a.img ^
  e l_fixnv2_a ^
  w l_fixnv2_a %BK%\l_fixnv1_a.img ^
  e l_deltanv_a ^
  w l_deltanv_a %BK%\l_deltanv_a.img ^
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
  e prodnv ^
  w prodnv %BK%\prodnv.img ^
  read_part l_fixnv1_a 0 2097152 "%VER%\verify_fixnv1_a_full.img" ^
  read_part l_modem_a 0 26214400 "%VER%\verify_modem_a_a15.img"

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo ================================================================
  echo  FLASH SELESAI. Verifikasi hash readback:
  echo ================================================================
  powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$v='%VER%'; $b='%BK%'; foreach($p in @(@('verify_fixnv1_a_full','l_fixnv1_a.img'),@('verify_modem_a_a15','l_modem_a.img'))){ $h1=(Get-FileHash (Join-Path $v ($p[0]+'.img')) -Algorithm SHA1).Hash; $h2=(Get-FileHash (Join-Path $b $p[1]) -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS'}else{'FAIL'}; Write-Output ('{0,-24} {1}  {2}' -f $p[0],$r,$h1); if($r -eq 'FAIL'){Write-Output ('  sumber: '+$h2)} }"
  echo.
  echo  Lepas USB, nyalakan HP normal (jangan ke BROM lagi).
  echo  Cek: Pengaturan - Tentang perangkat - Versi baseband,
  echo  lalu *#06# untuk IMEI.
  pause
)
