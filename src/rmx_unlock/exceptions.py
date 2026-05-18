class RmxError(Exception):
    """Base exception for all RMX unlock tool errors."""


class DeviceNotDetected(RmxError):
    """Device not found via ADB."""


class UnsupportedDevice(RmxError):
    """Detected device does not match RMX3760."""


class BinaryMissing(RmxError):
    """Required host binary (adb/fastboot) not found."""


class ReleaseFileMissing(RmxError):
    """Required release artifact not found."""


class ChecksumMismatch(RmxError):
    """Checksum verification failed."""


class FlashError(RmxError):
    """Flashing operation failed."""


class MetadataError(RmxError):
    """Release metadata missing or corrupted."""
