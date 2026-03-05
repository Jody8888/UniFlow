from __future__ import annotations
import json
import os
from typing import Any

def load_config(path: str) -> dict[str, Any]:
    with open(path, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    if "channel" not in cfg:
        cfg["channel"] = os.path.splitext(os.path.basename(path))[0]
    return cfg

def validate_config(cfg: dict[str, Any]) -> None:
    if not isinstance(cfg, dict):
        raise TypeError("config must be a dict")

    for key in ["list", "detail"]:
        if key not in cfg or not isinstance(cfg[key], dict):
            raise ValueError(f"missing or invalid '{key}' section")

    list_cfg = cfg["list"]
    detail_cfg = cfg["detail"]

    for key in ["url", "container_xpath", "link"]:
        if key not in list_cfg:
            raise ValueError(f"missing list.{key}")

    if not isinstance(list_cfg["link"], dict):
        raise ValueError("list.link must be an object")

    if "content_xpath" not in detail_cfg:
        raise ValueError("missing detail.content_xpath")