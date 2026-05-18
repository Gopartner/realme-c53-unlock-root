import sys
import os
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "src"))

from rmx_unlock import config
from rmx_unlock import exceptions
from rmx_unlock import validation
from rmx_unlock import metadata


def test_config_paths():
    assert config.REPO_ROOT.exists()
    assert config.TOOLS.exists()
    assert config.UNLOCK_DIR.exists()
    assert config.DRIVER_DIR.exists()
    assert "RMX3760" in config.DEVICE_MODEL


def test_config_apk_paths():
    assert config.MAGISK_APK is not None
    assert config.KERNELSU_APK is not None
    assert "magisk_patched_boot.img" in str(config.RUNTIME_IMAGES["magisk"])
    assert "kernelsu_patched_boot.img" in str(config.RUNTIME_IMAGES["kernelsu"])


def test_config_slots():
    assert "boot_a" in config.DEVICE_SLOTS
    assert "boot_b" in config.DEVICE_SLOTS


def test_exception_hierarchy():
    assert issubclass(exceptions.DeviceNotDetected, exceptions.RmxError)
    assert issubclass(exceptions.UnsupportedDevice, exceptions.RmxError)
    assert issubclass(exceptions.BinaryMissing, exceptions.RmxError)
    assert issubclass(exceptions.ReleaseFileMissing, exceptions.RmxError)
    assert issubclass(exceptions.ChecksumMismatch, exceptions.RmxError)
    assert issubclass(exceptions.FlashError, exceptions.RmxError)
    assert issubclass(exceptions.MetadataError, exceptions.RmxError)


def test_sha256():
    with tempfile.NamedTemporaryFile(delete=False) as f:
        f.write(b"test data")
        tmppath = f.name
    try:
        h = validation.sha256(tmppath)
        assert len(h) == 64
        assert h == "916f0027a575074ce72a331777c3478d6513f786a591bd892da1a577bf2335f9"
    finally:
        os.unlink(tmppath)


def test_verify_release_file_missing():
    result = validation.verify_release_file("/nonexistent/path.img")
    assert result is False


def test_verify_release_file_exists():
    with tempfile.NamedTemporaryFile(suffix=".img", delete=False) as f:
        tmppath = f.name
    try:
        result = validation.verify_release_file(tmppath)
        assert result is True
    finally:
        os.unlink(tmppath)


def test_check_binary():
    assert validation.check_binary("python") is True
    assert validation.check_binary("nonexistent_binary_xyz") is False


def test_metadata_parse_empty():
    with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
        f.write("# comment\nDEVICE=RMX3760\nKERNEL=5.15\n\n")
        tmppath = f.name
    try:
        m = metadata.parse_metadata(Path(tmppath))
        assert m["DEVICE"] == "RMX3760"
        assert m["KERNEL"] == "5.15"
        assert "comment" not in str(m)
    finally:
        os.unlink(tmppath)


def test_metadata_parse_with_checksums():
    content = """# Release
DEVICE=RMX3760
SHA256_test.img=aabbccdd
SIZE_test.img=1234
"""
    with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
        f.write(content)
        tmppath = f.name
    try:
        m = metadata.parse_metadata(Path(tmppath))
        assert m["SHA256_test.img"] == "aabbccdd"
        assert m["SIZE_test.img"] == "1234"
        chk = metadata.get_checksum("test.img", m)
        assert chk == "aabbccdd"
    finally:
        os.unlink(tmppath)


def test_version():
    from rmx_unlock import __version__
    assert __version__ == "2.0.0"
