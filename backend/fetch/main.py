from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from fetch.fetcher import AnnouncementFetcher  # noqa: E402


def main(argv: list[str]) -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:  # noqa: BLE001
        pass

    parser = argparse.ArgumentParser(description="(Dev only) Run a single fetch config.")
    parser.add_argument("--config", required=True, help="Path to a single JSON config file.")
    parser.add_argument("--max-items", type=int, default=None, help="Override config limits.max_items.")
    args = parser.parse_args(argv)

    res = AnnouncementFetcher().fetch(args.config, max_items=args.max_items)
    json.dump(res, sys.stdout, ensure_ascii=False, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
