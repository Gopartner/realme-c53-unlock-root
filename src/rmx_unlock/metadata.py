from pathlib import Path
from typing import Dict, Optional

from .config import METADATA_FILE
from .exceptions import MetadataError
from .logger import get_logger

log = get_logger()


def parse_metadata(path: Optional[Path] = None) -> Dict[str, str]:
    path = path or METADATA_FILE
    if not path.exists():
        raise MetadataError(f"Metadata file not found: {path}")
    result = {}
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            key, _, value = line.partition("=")
            result[key.strip()] = value.strip()
    return result


def get_checksum(filename: str, metadata: Optional[Dict[str, str]] = None) -> Optional[str]:
    if metadata is None:
        metadata = parse_metadata()
    key = f"SHA256_{filename}"
    return metadata.get(key)


def display_metadata(metadata: Optional[Dict[str, str]] = None):
    if metadata is None:
        metadata = parse_metadata()
    print("\n=== Release Metadata ===")
    for key, value in metadata.items():
        if key.startswith("SHA256_"):
            continue
        print(f"  {key}: {value}")
