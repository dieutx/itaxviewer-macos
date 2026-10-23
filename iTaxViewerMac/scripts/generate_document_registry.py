#!/usr/bin/env python3
"""Generate factual routing data, without distributing vendor templates."""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "docs/reverse-engineering/documents/document-registry.csv"
DEST = ROOT / "iTaxViewerMac/Sources/iTaxViewerCore/Resources/document-registry.json"


def generate():
    with SOURCE.open(encoding="utf-8-sig", newline="") as source:
        rows = [
            {key: row[key] for key in ("kind", "registry", "root", "id", "version", "orientation")}
            for row in csv.DictReader(source) if row["kind"] != "declaration"
        ]
    DEST.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Generated {len(rows)} document routing entries")


if __name__ == "__main__":
    generate()
