@echo off
REM ================================================================
REM  UJI: A14 MODEM + A15 NV LENGKAP (fixnv1+fixnv2+deltanv A15)
REM
REM  Penemuan penting dari log:
REM   - Fase 2 (tanpa `rawdata 0`): l_fixnv1_a tertulis PENUH
REM   - Semua script dgn `rawdata 0`: l_fixnv1_a SELALU short-write
REM     (unexpected response 0x00a2, written < target)
REM   -> `rawdata 0` MERUSAK protokol NV_Part. DIBUANG.
REM
REM  Dulu restore_nv_asli.bat: fixnv1 SHORT (0xd5000/0xd5050),
REM  deltanv tidak disentuh (masih A14) -> baseband Unknown.
REM  Sekarang: fixnv1+fixnv2 PENUH (tanpa rawdata 0) + deltanv A15,
REM  modem/dsp/pm_sys tetap A14 (sudah terpasang).
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
  read_part l_fixnv1_a 0 2097152 "%VER%\verify_fixnv1_noraw.img"

echo.
echo ================================================================
echo  Cek hash readback l_fixnv1_a vs sumber backup A15:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$v='%VER%\verify_fixnv1_noraw.img'; $b='%BK%\l_fixnv1_a.img'; if(Test-Path $v){$h1=(Get-FileHash $v -Algorithm SHA1).Hash; $h2=(Get-FileHash $b -Algorithm SHA1).Hash; $r= if($h1 -eq $h2){'PASS - fixnv1 UTUH'}else{'FAIL'}; Write-Output ('readback: {0}  {1}' -f $r,$h1); if($r -eq 'FAIL'){Write-Output ('sumber : '+$h2)}} else {Write-Output 'readback TIDAK dihasilkan (timeout baca).'}"
echo.
echo  PENTING: periksa log, apakah "unexpected response (0x00a2)"
echo  masih muncul saat tulis l_fixnv1_a. Tanpa rawdata 0
echo  seharusnya PENUH (target == written).
echo  Lepas USB, nyalakan normal. Cek *#06# + Versi baseband.
pause
