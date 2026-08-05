@echo off
REM ================================================================
REM  FASE 2: FLASH NV + MODEM + DSP + DFS A14
REM  Device harus dalam kondisi BROM (ulangi 3-kombinasi tombol).
REM
REM  URUTAN MENGIKUTI SKEMA RESMI A14:
REM   - l_fixnv1_a  <- qogirl6_pubcp_SPA_nvitem.bin
REM   - prodnv      <- prodnv.img
REM   - l_modem_a   <- SC9600_qogirl6_pubcp_SPA_modem.bin
REM   - l_deltanv_a <- qogirl6_pubcp_SPA_deltanv.bin
REM   - l_ldsp_a    <- qogirl6_pubcp_SPA_LTEA_DSP.bin
REM   - l_gdsp_a    <- qogirl6_pubcp_SPA_DM_DSP.bin
REM   - l_agdsp_a   <- QogirL6_AUDCP_DSP_lit_dm.bin
REM   - pm_sys_a    <- qogirl6_cm4.bin
REM ================================================================
setlocal
set PAC=D:\downloader-firmware\results\pac-bootchain
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_fixnv1_a ^
  w l_fixnv1_a %PAC%\qogirl6_pubcp_SPA_nvitem.bin ^
  e prodnv ^
  w prodnv %PAC%\prodnv.img ^
  e l_modem_a ^
  w l_modem_a %PAC%\SC9600_qogirl6_pubcp_SPA_modem.bin ^
  e l_deltanv_a ^
  w l_deltanv_a %PAC%\qogirl6_pubcp_SPA_deltanv.bin ^
  e l_ldsp_a ^
  w l_ldsp_a %PAC%\qogirl6_pubcp_SPA_LTEA_DSP.bin ^
  e l_gdsp_a ^
  w l_gdsp_a %PAC%\qogirl6_pubcp_SPA_DM_DSP.bin ^
  e l_agdsp_a ^
  w l_agdsp_a %PAC%\QogirL6_AUDCP_DSP_lit_dm.bin ^
  e pm_sys_a ^
  w pm_sys_a %PAC%\qogirl6_cm4.bin

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo FASE 2 SELESAI. Jangan reboot dulu.
  echo Lanjut ke FASE 3 (flash_phase3_system.bat).
  pause
)
