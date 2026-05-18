@echo off
REM Realme C53 (RMX3760) — Flash KernelSU Boot Image
REM Run this from the release folder

echo ============================================
echo Realme C53 KernelSU Flash Tool
echo ============================================
echo.

adb get-state >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo [ERROR] No device detected. Enable USB debugging and connect.
    pause
    exit /b 1
)

echo [1/4] Rebooting to fastboot...
adb reboot bootloader
ping -n 6 127.0.0.1 >nul

echo [2/4] Testing boot image (fastboot boot)...
fastboot boot kernelsu_patched_boot.img
echo.
echo Did the device boot successfully?
echo If YES: Press any key to flash permanently.
echo If NO:  Close this window, the device will reboot normally.
pause

echo [3/4] Flashing to both slots...
fastboot flash boot_a kernelsu_patched_boot.img
fastboot flash boot_b kernelsu_patched_boot.img

echo [4/4] Rebooting...
fastboot reboot

echo.
echo Done!
echo Install APK: adb install KernelSU_Next.apk
pause
