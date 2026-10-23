#!/usr/bin/env python3
"""Dump *day du* (lossless) moi registry XML cua iTax Viewer + bang phang de doi chieu.

`documents/document-registry.csv` truoc day chi giu 1.512 dong, trong khi chi rieng
`DMucTKhai.xml` da co 1.149 entry va `DMucHquan*.xml` ~517. Script nay giu tat ca de khong
mat du lieu, va sinh bang phang de biet dong nao chua duoc dua vao CSV cu.

Dung:
    python3 extract_registries.py --data "C:/.../iTax Viewer/data" \
        --out _re/registry --csv docs/reverse-engineering/registry-tables/all-entries.csv
"""

from __future__ import annotations

import argparse
import csv
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

KIND_BY_ROOT = {
    "DMucTKhai": "declaration",
    "DMucTBao": "notice",
    "DMucTBaoNtdt": "notice",
    "DMucTBaoNtdt22": "notice",
    "DMucBKeKDTT": "notice",
    "DMucBKeTDTT": "notice",  # root tag vendor viết thiếu chữ K
    "DMucCTu": "voucher",
    "DMucHSoDKy": "registration",
    "DMucDMuc": "catalog",
    "DMucHquan": "customs",
    "DMucXNhanCTuNtdt": "notice",
    "DmucBtruNtdt": "notice",
    "DmucTSoatNtdt": "notice",
}
ENTRY_TAGS = {"TKhai", "TBao", "BKe", "CTu", "DKyThueDTu", "DMuc", "TBaoHquan", "XNhanCTu", "Btru", "TSoat"}
FIELDS = ("maTKhai", "pbanTKhai", "viewMethod", "loaiTKhai", "kieuKyKKhai", "orientation", "maTBao", "pbanTBao")


def strip(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def flatten(element: ET.Element) -> dict:
    out: dict[str, str] = {}
    for key, value in element.attrib.items():
        out[strip(key)] = value
    for child in element:
        name = strip(child.tag)
        text = (child.text or "").strip()
        if len(child):
            text = text or ";".join(
                (grand.text or "").strip() for grand in child if (grand.text or "").strip()
            )
        if text:
            out.setdefault(name, text)
    return out


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--csv", required=True, type=Path)
    args = parser.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)
    files = sorted(set(args.data.glob("DMuc*.xml")) | set(args.data.glob("Dmuc*.xml")))
    rows: list[dict] = []
    per_file: dict[str, dict] = {}
    for path in files:
        try:
            root = ET.parse(path).getroot()
        except Exception as exc:
            per_file[path.name] = {"error": f"{type(exc).__name__}: {exc}"}
            continue
        root_name = strip(root.tag)
        kind = KIND_BY_ROOT.get(root_name, "unknown")
        entries = [child for child in root if strip(child.tag) in ENTRY_TAGS]
        dumped = [{"tag": strip(entry.tag), "fields": flatten(entry)} for entry in entries]
        (args.out / f"{path.stem}.json").write_text(
            json.dumps({"root": root_name, "kind": kind, "entries": dumped}, ensure_ascii=False),
            encoding="utf-8",
        )
        per_file[path.name] = {"root": root_name, "kind": kind, "entries": len(dumped)}
        for entry in dumped:
            values = entry["fields"]
            rows.append(
                {
                    "registry": path.name,
                    "kind": kind,
                    "tag": entry["tag"],
                    **{field: values.get(field, "") for field in FIELDS},
                    "xslt": values.get("XSLT", ""),
                    "xsd": values.get("XMLSchema", ""),
                    "plucCount": str(len([p for p in values.get("DSachPLuc", "").split(";") if p.strip()])),
                }
            )

    args.csv.parent.mkdir(parents=True, exist_ok=True)
    columns = ["registry", "kind", "tag", *FIELDS, "xslt", "xsd", "plucCount"]
    with args.csv.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns)
        writer.writeheader()
        for row in rows:
            writer.writerow({key: row.get(key, "") for key in columns})

    summary = {
        "registries": len(files),
        "entriesTotal": len(rows),
        "perRegistry": dict(sorted(per_file.items())),
        "entriesWithXslt": sum(1 for row in rows if row["xslt"]),
        "distinctIds": len({(row["registry"], row["maTKhai"] or row["maTBao"]) for row in rows}),
    }
    (args.out / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(json.dumps({k: summary[k] for k in ("registries", "entriesTotal", "entriesWithXslt", "distinctIds")}, ensure_ascii=False))
    for name, info in summary["perRegistry"].items():
        print(f"  {name}: {info}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
