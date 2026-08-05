@echo off
REM ================================================================
REM  UJI: A15 MODEM + A15 NV FIXNV1 PENUH (tanpa rawdata 0)
REM
REM  Penemuan penting:
REM   - Fase 2 (tanpa `rawdata 0`)  -> l_fixnv1_a tertulis PENUH (ok)
REM   - Script pakai `rawdata 0`    -> l_fixnv1_a SELALU short-write
REM     (unexpected response 0x00a2, hilang ekor 0x50 byte)
REM   Jadi `rawdata 0` MERUSAK protokol NV_Part. HILANGKAN.
REM
REM  Dulu stack A15 dites dgn l_fixnv1_a KOSONG (wof diblacklist)
REM  atau SHORT -> bootloop. Sekarang fixnv1 ditulis PENUH tanpa
REM  rawdata 0 -> ini konfigurasi A15 asli yg terbukti ber-IMEI,
REM  dan sistem tetap A14.
REM
REM  Catatan: gunakan `w` utk fixnv1 (BUKAN wof yg diblacklist).
REM ================================================================
setlocal
set BK=D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=D:\realme-c53-recovery\03_downgrade_a14\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_fixnv1_a ^
  w l_fixnv1_a %BK%\l_fixnv1_a.img ^
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
  read_part l_fixnv1_a 0 2097152 "%VER%\verify_fixnv1_a15full.img"

echo.
echo ================================================================
echo  Cek hash readback l_fixnv1_a (fokus: 0xd5050 vs 0xd5000):
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_fixnv1_a15full.img'; if(Test-Path $v){$sz=(Get-Item $v).Length; $h1=(Get-FileHash $v -Algorithm SHA1).Hash; Write-Output ('ukuran readback: '+$sz); Write-Output ('readback sha1: '+$h1)} else {Write-Output 'readback TIDAK dihasilkan.'}"
echo.
echo  PENTING: periksa di log apakah tertulis
echo  "unexpected response (0x00a2)" pada l_fixnv1_a.
echo  Jika TIDAK ADA error dan written==target -> PENUH, LANJUT boot.
echo  Jika MASIH short (0xd5000) -> laporkan, ada bug lain.
pause
