import os
import subprocess
import time

from .exceptions import DeviceNotDetected
from .logger import get_logger

log = get_logger()


def _env():
    env = os.environ.copy()
    env["MSYS2_ARG_CONV_EXCL"] = "*"
    return env


def adb(cmd: str, timeout: int = 60) -> str:
    full = f"adb {cmd}"
    log.cmd(full)
    result = subprocess.run(
        full,
        shell=True,
        text=True,
        capture_output=True,
        timeout=timeout,
        env=_env(),
    )
    return (result.stdout + result.stderr).strip()


def fastboot(cmd: str, timeout: int = 60) -> str:
    full = f"fastboot {cmd}"
    log.cmd(full)
    result = subprocess.run(
        full,
        shell=True,
        text=True,
        capture_output=True,
        timeout=timeout,
    )
    return (result.stdout + result.stderr).strip()


def wait_for_device(timeout: int = 30) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        output = adb("get-state")
        if "device" in output:
            return True
        time.sleep(1)
    return False


def wait_for_fastboot(timeout: int = 30) -> bool:
    deadline = time.time() + timeout
    while time.time() < deadline:
        output = fastboot("devices")
        if "fastboot" in output:
            return True
        time.sleep(1)
    return False


def device_model() -> str:
    return adb("shell getprop ro.product.model")


def reboot_bootloader():
    adb("reboot bootloader")
    time.sleep(5)


def reboot():
    fastboot("reboot")
