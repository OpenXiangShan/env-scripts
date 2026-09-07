"""Load local robot configuration from JSON."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Optional, Union


DEFAULT_CONFIG_PATH = Path(__file__).with_name("config.json")


class ConfigError(RuntimeError):
    """Raised when the robot configuration is missing or invalid."""


def load_config(path: Optional[Union[str, Path]] = None) -> Dict[str, Any]:
    config_path = Path(path) if path else DEFAULT_CONFIG_PATH
    try:
        with config_path.open(encoding="utf-8") as config_file:
            config = json.load(config_file)
    except FileNotFoundError as exc:
        raise ConfigError(
            f"Configuration file not found: {config_path}. "
            "Copy config.example.json to config.json first."
        ) from exc
    except json.JSONDecodeError as exc:
        raise ConfigError(
            f"Invalid JSON in {config_path}: line {exc.lineno}, column {exc.colno}"
        ) from exc

    if not isinstance(config, dict):
        raise ConfigError(f"Configuration root must be an object: {config_path}")
    return config


def require_string(config: Dict[str, Any], section: str, key: str) -> str:
    section_value = config.get(section)
    if not isinstance(section_value, dict):
        raise ConfigError(f"Missing configuration object: {section}")
    value = section_value.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ConfigError(f"Missing configuration value: {section}.{key}")
    return value.strip()
