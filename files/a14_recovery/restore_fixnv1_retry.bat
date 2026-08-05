@echo off
REM ================================================================
REM  RETRY: TULIS l_fixnv1_a (SEBELUMNYA BLACKLISTED OLEH wof)
REM
REM  Hasil restore_modem_a15.bat:
REM   - l_modem_a/deltanv/DSP/pm_sys/prodnv/l_fixnv2_a  = SUKSES (A15)
REM   - l_fixnv1_a  = ERASE OK tapi `wof` di-blacklist target
REM     -> partisi KOSONG sekarang (NV utama tidak ada)
REM
REM  Strategi: pakai `w` (jalur NV_Part yang bekerja, partial
REM   ke 0xd5000) + rawdata 0 agar protokol NV tidak terganggu.
REM  Setelah write, baca ulang penuh 2MB lalu bandingkan hash.
REM ================================================================
setlocal
set BK=D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
set VER=D:\realme-c53-recovery\03_downgrade_a14\verify
if not exist "%VER%" mkdir "%VER%"
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  rawdata 0 ^
  e l_fixnv1_a ^
  w l_fixnv1_a %BK%\l_fixnv1_a.img ^
  read_part l_fixnv1_a 0 2097152 "%VER%\verify_fixnv1_a_retry.img"

echo.
echo ================================================================
echo  Cek hash readback l_fixnv1_a vs sumber backup:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_fixnv1_a_retry.img'; $b='%BK%\l_fixnv1_a.img'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $b -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS'}else{'FAIL'}; Write-Output ('readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('sumber : '+$h2); Write-Output ('ukuran readback: '+(Get-Item $v).Length)}} else {Write-Output 'readback TIDAK dihasilkan (mungkin timeout saat baca).'}"
echo.
echo  Lepas USB, nyalakan normal. Cek *#06# + Versi baseband.
pause
