#!/usr/bin/env python3
"""
Entry point: `python cli.py` or `python -m src.rmx_unlock`

This is a thin wrapper. All logic lives in src/rmx_unlock/.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / "src"))

from rmx_unlock.cli import main

main()
