#!/usr/bin/env python3
"""Doi chieu duong dan trong registry (DMuc*.xml) voi tep that trong ban cai.

Muc dich: tra loi "registry tro toi bao nhieu template/XSD, va bao nhieu tep
thuc su ton tai". Day la bang chung cho cac tuyen bo ve do phu: neu mot entry
tro vao tep khong co thi renderer khong the coi entry do la "da ho tro".

Chi doc registry + liet ke ten tep; khong copy noi dung vendor vao repo.

Dung:
    python3 resolve_registry_refs.py \
        --install "C:/Program Files (x86)/iTax Viewer" \
        --out docs/reverse-engineering/evidence/registry-refs.json

Ket qua: exit 0 luon (day la cong cu do luong, khong phai test), nhung in
bang tom tat va ghi JSON de doi chieu sau nay.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import xml.etree.ElementTree as ET
from collections import Counter, defaultdict
from pathlib import Path

REF_TAGS = ("XSLT", "PLucXSLT", "XMLSchema", "ExcelTemplate", "PLucExcelTemplate")
FILE_SUFFIXES = (".xslt", ".xsl", ".xsd", ".xls", ".xlsx")


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def normalise(reference: str) -> str:
    """`data\\xslt\\XSLT 2.9.4\\...` -> `xslt/xslt 2.9.4/...` (tuong doi voi data/)."""
    rel = reference.strip().replace("\\", "/").lstrip("/")
    if rel.lower().startswith("data/"):
        rel = rel[5:]
    return rel


def index_files(data_dir: Path) -> dict[str, str]:
    """Duong dan tuong doi (lowercase, '/') -> duong dan that."""
    index: dict[str, str] = {}
    for root, _dirs, files in os.walk(data_dir):
        for name in files:
            full = Path(root, name)
            rel = full.relative_to(data_dir).as_posix().lower()
            index[rel] = "data/" + full.relative_to(data_dir).as_posix()
    return index


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--install", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()

    data_dir = args.install / "data"
    if not data_dir.is_dir():
        print(f"khong thay {data_dir}")
        return 2
    index = index_files(data_dir)

    per_tag: dict[str, Counter] = defaultdict(Counter)
    missing: dict[str, set[str]] = defaultdict(set)
    per_registry: dict[str, Counter] = defaultdict(Counter)
    refs_total = 0

    for path in sorted(data_dir.glob("*.xml")):
        if not path.name.lower().startswith("dmuc"):
            continue
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as exc:
            per_registry[path.name]["parseError"] += 1
            print(f"PARSE FAIL {path.name}: {exc}")
            continue
        for element in root.iter():
            tag = local(element.tag)
            if tag not in REF_TAGS or not element.text or not element.text.strip():
                continue
            rel = normalise(element.text)
            if not rel.lower().endswith(FILE_SUFFIXES):
                continue
            refs_total += 1
            per_tag[tag]["refs"] += 1
            per_registry[path.name]["refs"] += 1
            if rel.lower() in index:
                per_tag[tag]["resolved"] += 1
                per_registry[path.name]["resolved"] += 1
            else:
                per_tag[tag]["missing"] += 1
                per_registry[path.name]["missing"] += 1
                missing[tag].add(rel)

    summary = {
        "install": str(args.install),
        "refsTotal": refs_total,
        "perTag": {
            tag: {
                "refs": per_tag[tag]["refs"],
                "resolved": per_tag[tag]["resolved"],
                "missing": per_tag[tag]["missing"],
                "distinctMissing": len(missing[tag]),
            }
            for tag in REF_TAGS
        },
        "perRegistry": {
            name: {
                "refs": counts["refs"],
                "resolved": counts["resolved"],
                "missing": counts["missing"],
            }
            for name, counts in sorted(per_registry.items())
        },
        "missingPaths": {tag: sorted(paths) for tag, paths in sorted(missing.items())},
    }

    out: Path = args.out
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(f"{'tag':<18}{'refs':>7}{'resolved':>10}{'missing':>9}{'distinct':>10}")
    for tag in REF_TAGS:
        row = summary["perTag"][tag]
        print(
            f"{tag:<18}{row['refs']:>7}{row['resolved']:>10}"
            f"{row['missing']:>9}{row['distinctMissing']:>10}"
        )
    print(f"\ntotal refs: {refs_total}")
    print(f"wrote {out} ({out.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
