@echo off
REM ================================================================
REM  MASUK FASTBOOT DARI BROM (tanpa menu FDL2 manual)
REM  Device harus dalam kondisi BROM.
REM  Setelah ini, HP masuk fastboot -> pakai fastboot.exe
REM  untuk query OEM / baca IMEI.
REM ================================================================
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"
spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec reboot-fastboot
pause
