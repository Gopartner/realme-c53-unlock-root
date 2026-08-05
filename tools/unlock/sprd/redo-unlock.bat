@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set SPD=spd_dump.exe
set FDL1=fdl1-dl.bin
set FDL2=fdl2-dl.bin
set CB00T=fdl2-cboot.bin
set SPLUN=spl-unlock.bin
set PATCHED=u-boot-spl-16k-sign.bin
set UBOOTBK=uboot_bak.bin
set MISSWIPE=misc-wipe.bin
set MBIN=m.bin
set BASE=--wait 300 exec_addr 0x65015f08 fdl %FDL1% 0x65000800 fdl %FDL2% 0x9efffe00 exec

rem ============================================================
rem REDO UNLOCK — mengikuti unlock_autopatch_9230.bat resmi CVE.
rem PENTING: pakai fdl1-dl.bin + fdl2-dl.bin (FDL PATCHED CVE,
rem signature-check OFF). JANGAN pakai fdl1-sign.bin/lk-fdl2-sign.bin
rem (FDL stock A14, signature-check ON -> write cboot ditolak).
rem
rem Kunci urutan:
rem   1. erase splloader            (mode BROM)
rem   2. w uboot fdl2-cboot.bin     (mode BROM; dgn FDL patched LOLOS)
rem   3. payload spl-unlock.bin     (mode CBOOT — JANGAN cabut kabel!)
rem   4. verify miscdata
rem   5. restore splloader+uboot+misc
rem ============================================================

if not exist %SPD% (
  echo spd_dump.exe tidak ditemukan di folder ini.
  pause
  exit /b 1
)

echo ===== REDO UNLOCK (CVE-2022-38694) A14 =====
echo.
echo FDL1 = %FDL1%   FDL2 = %FDL2%   (patched CVE, sig-check OFF)
echo.
echo CARA MASUK BROM: power off, tahan Vol Up+Down, colok USB, lepas tombol
echo saat "SPRD U2S Diag (COM...)" muncul di Device Manager.
echo.
echo Mulai: CABUT kabel USB sekarang, lalu tekan Enter.
pause

echo.
echo ============ STEP 1: erase splloader (mode BROM) ============
echo CABUT kabel, PASANG ulang tahan Vol sampai COM muncul, tekan Enter.
pause
%SPD% %BASE% e splloader reset < nul > log-01-erase.txt 2>&1
type log-01-erase.txt
echo.
echo Cek: harus ada "Erase Part Done: splloader".
echo (Kalau "partition not found: splloader_bak" TIDAK muncul karena batch
echo  ini hanya erase splloader. Kalau "find port failed", ulangi langkah ini.)
pause

echo.
echo ============ STEP 2: write cboot uboot (mode BROM) ============
echo CABUT kabel, PASANG ulang tahan Vol sampai COM muncul, tekan Enter.
pause
%SPD% %BASE% w uboot %CB00T% reset < nul > log-02-cboot.txt 2>&1
type log-02-cboot.txt
echo.
echo Cek: harus ada "Write Part Done: uboot".
echo KALAU MUNCUL "signature verification of uboot_a failed" -> FDL masih
echo stock; pastikan fdl1-dl.bin/fdl2-dl.bin yang dipakai, lalu ulangi.
echo KALAU SUKSES: device reset otomatis ke mode CBOOT (download).
echo JANGAN cabut kabel sekarang — lanjut ke STEP 3.
pause

echo.
echo Menunggu 8 detik device re-enumerate di mode cboot...
TIMEOUT /T 8 /NOBREAK > nul

echo.
echo ============ STEP 3: payload spl-unlock (mode CBOOT, max 3x) ============
echo JANGAN CABUT KABEL. Payload dijalankan terhadap cboot yang sedang jalan.
for /L %%i in (1,1,3) do (
  echo.
  echo [Payload %%i/3] menekan Enter untuk menjalankan...
  pause > nul
  %SPD% --wait 30 exec_addr 0x65015f08 fdl %SPLUN% 0x65000800 < nul > log-03-payload.txt 2>&1
  type log-03-payload.txt
  echo.
  echo Cek: payload biasanya butuh 2x (lihat output spd_dump). Jika masih
  echo "find port failed", ulangi via Enter. (Jangan cabut kecuali diinstruksikan.)
)

echo.
echo ============ STEP 4: verify miscdata (mode CBOOT) ============
echo JANGAN CABUT KABEL. Tekan Enter untuk baca miscdata.
pause > nul
%SPD% --wait 30 exec_addr 0x65015f08 fdl %FDL1% 0x65000800 fdl %FDL2% 0x9efffe00 exec verbose 2 read_part miscdata 8192 64 %MBIN% reset < nul > log-04-verify.txt 2>&1
type log-04-verify.txt
echo.

for /f %%v in ('powershell -NoProfile -Command "$b=[IO.File]::ReadAllBytes('!MBIN!'); @($b|Where-Object{$_ -ne 0}).Count"') do set NONZERO=%%v
echo Nonzero byte di miscdata: %NONZERO%
if not defined NONZERO (
  echo GAGAL baca m.bin. Cek apakah file tertulis.
) else if %NONZERO% GTR 0 (
  echo.
  echo ##############################
  echo #  RESULT: UNLOCKED!
  echo ##############################
  echo.
) else (
  echo.
  echo RESULT: miscdata masih 0 (LOCKED). Payload belum efektif.
  echo.
)

echo.
echo ============ STEP 5: restore splloader + uboot + wipe misc ============
echo JANGAN CABUT KABEL. Tekan Enter untuk restore (agar device boot normal).
echo Jika "find port failed" di sini, cabut-pasang (tahan Vol) lalu jalankan
echo ulang batch ini dari STEP 4, atau pakai restore-boot.bat.
pause > nul
%SPD% --wait 30 exec_addr 0x65015f08 fdl %FDL1% 0x65000800 fdl %FDL2% 0x9efffe00 exec r boot w splloader %PATCHED% w uboot %UBOOTBK% w misc %MISSWIPE% reset < nul > log-05-restore.txt 2>&1
type log-05-restore.txt
echo.
echo Cek: harus ada "Write Part Done: splloader", "Write Part Done: uboot",
echo dan "Write Part Done: misc". Kalau splloader tidak tertulis device tidak
echo boot -> jalankan restore-boot.bat.
echo.
echo ===== SELESAI =====
echo Device reboot. Kalau RESULT di atas UNLOCKED, masuk fastboot lalu:
echo   fastboot flash boot_a output\backup\magisk_patched_boot_a14.img
echo   fastboot flash boot_b output\backup\magisk_patched_boot_a14.img
echo Log tiap langkah tersimpan: log-01..log-05.
pause
