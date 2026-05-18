import sys
from datetime import datetime

from .config import LOG_DIR


class Logger:
    def __init__(self):
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        self._log_file = LOG_DIR / f"session_{datetime.now().strftime('%Y%m%d')}.log"

    def _write(self, level: str, message: str):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{timestamp}] [{level}] {message}"
        with open(self._log_file, "a", encoding="utf-8") as f:
            f.write(line + "\n")

    def info(self, message: str):
        self._write("INFO", message)

    def warn(self, message: str):
        self._write("WARN", message)

    def error(self, message: str):
        self._write("ERROR", message)

    def cmd(self, command: str):
        self._write("CMD", command)


_logger: Logger | None = None


def get_logger() -> Logger:
    global _logger
    if _logger is None:
        _logger = Logger()
    return _logger
