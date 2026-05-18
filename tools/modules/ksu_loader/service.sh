#!/system/bin/sh
# Load KernelSU kernel module at late boot stage
sleep 15
if [ -x /data/adb/ksu/bin/ksud ]; then
    /data/adb/ksu/bin/ksud late-load 2>/dev/null
fi
if ! lsmod | grep -q kernelsu && [ -f /data/adb/ksu/module/kernelsu.ko ]; then
    insmod /data/adb/ksu/module/kernelsu.ko 2>/dev/null
fi
