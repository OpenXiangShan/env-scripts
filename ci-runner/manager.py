#!/usr/bin/env python3
from pathlib import Path

from modules.cli import main

if __name__ == "__main__":
    raise SystemExit(main(Path(__file__).resolve().parent))
