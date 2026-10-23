#!/usr/bin/env python3
"""Classify a directory of real tax XML files without uploading them anywhere.

Usage:
    python3 scripts/validate_directory.py ~/itax-samples
    python3 scripts/validate_directory.py ~/itax-samples --json report.json
    python3 scripts/validate_directory.py ~/itax-samples --show-code

The report prints only file names, document kinds, form codes and counts.
It never prints taxpayer names, tax codes, addresses or field values.

Files containing DOCTYPE/ENTITY are skipped (same policy as the app).
"""
from __future__ import annotations

import argparse
import json
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "Sources" / "iTaxViewerCore" / "Resources"
REGISTRY = json.loads((RES / "form-registry.json").read_text(encoding="utf-8"))
SUPPORTED = {(f["maTKhai"], f["displayCode"]) for f in REGISTRY["supported"]}


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def first(node, name):
    for child in node:
        if local(child.tag) == name:
            return child
    return None


def text(node, name):
    child = first(node, name)
    if child is None or child.text is None:
        return None
    value = child.text.strip()
    return value or None


def descendant(node, name):
    for el in node.iter():
        if local(el.tag) == name:
            return el
    return None


def classify(root):
    tag = local(root.tag)
    if tag == "HSoThueDTu":
        khai = descendant(root, "TKhaiThue")
        if khai is None:
            return "Tờ khai thuế", None, None, None, "invalid: missing TKhaiThue"
        code = text(khai, "maTKhai")
        version = text(khai, "pbanTKhaiXML")
        info = REGISTRY["codes"].get(code or "", {})
        display = info.get("displayCode")
        if code is None or version is None:
            return "Tờ khai thuế", display, code, version, "invalid: missing maTKhai/pbanTKhaiXML"
        supported = (code, display) in SUPPORTED
        # Verified legacy alias: 01/GTGT moved from maTKhai 01 to 842 with the
        # same indicator tags (checked against real 2.1.2 / 2.5.0 files).
        matched = next((f for f in REGISTRY["supported"] if f["maTKhai"] == code), None)
        if not supported and code == "01" and (("842", "01/GTGT") in SUPPORTED):
            supported = True
            matched = next(f for f in REGISTRY["supported"] if f["maTKhai"] == "842")
        if supported and version not in (matched or {}).get("versions", []):
            note = f"supported layout, unverified version {version}"
        elif supported:
            note = "full renderer"
        elif display:
            note = "structured data view"
        else:
            note = "unknown form code"
        return "Tờ khai thuế", display, code, version, note
    if tag == "CHUNGTU":
        code = None
        for name in ("MA_CTU", "MAHIEU_CTU"):
            node = descendant(root, name)
            if node is not None and node.text:
                code = node.text.strip()
                break
        version_node = descendant(root, "PBAN_TLIEU_XML")
        version = version_node.text.strip() if version_node is not None and version_node.text else None
        return "Giấy nộp tiền / chứng từ", "CT-" + (code or "?"), code, version, "structured data view"
    if tag in ("TBaoThueDTu", "THONGBAO", "THONG_BAO", "TBAO_TKHOAN_NH", "TBAO_TKHOAN_NT", "TBAO_NGUNG"):
        mso = descendant(root, "MSo")
        code = descendant(root, "maTBao")
        code_text = code.text.strip() if code is not None and code.text else None
        display = mso.text.strip() if mso is not None and mso.text else (
            f"TB-{code_text}" if code_text else None)
        version = descendant(root, "pbanTBao")
        return ("Thông báo / văn bản của cơ quan thuế", display, code_text,
                version.text.strip() if version is not None and version.text else None,
                "structured data view")
    if tag == "DKyThueDTu":
        return "Đăng ký thuế", None, text(root, "maHSo"), None, "structured data view"
    if tag == "DanhMucDTu":
        return "Danh mục", None, None, None, "structured data view"
    if tag in ("TOKHAI_OBJ", "TOKHAISUA_OBJ") or tag.endswith(":Envelope"):
        return "Hồ sơ hải quan", None, None, None, "structured data view"
    if tag in ("TKhai", "DNghi", "TBao", "BCTHSDBLai", "BLai"):
        return "Tài liệu hóa đơn điện tử", None, None, None, "structured data view"
    return "Không xác định", None, None, None, f"unsupported root {tag}"


def count_leaves(root) -> int:
    return sum(1 for el in root.iter() if len(list(el)) == 0 and (el.text or "").strip())


def has_signature(root) -> bool:
    return any(local(el.tag) == "Signature" for el in root.iter())


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("directory")
    ap.add_argument("--json", help="write machine-readable report to this path")
    ap.add_argument("--show-code", action="store_true", help="show internal maTKhai")
    ap.add_argument("--no-recursive", action="store_true")
    args = ap.parse_args()

    directory = Path(args.directory).expanduser().resolve()
    if not directory.is_dir():
        print(f"Not a directory: {directory}", file=sys.stderr)
        return 2

    pattern = "*.xml" if args.no_recursive else "**/*.xml"
    files = sorted(p for p in directory.glob(pattern) if p.is_file())
    if not files:
        print(f"No XML files in {directory}", file=sys.stderr)
        return 2

    rows, errors, skipped = [], 0, 0
    print(f"Scanning {len(files)} XML file(s) in {directory}\n")
    for path in files:
        raw = path.read_bytes()
        if b"<!DOCTYPE" in raw.upper() or b"<!ENTITY" in raw.upper():
            print(f"SKIP  {path.name}: DOCTYPE/ENTITY rejected")
            skipped += 1
            continue
        try:
            root = ET.fromstring(raw)
        except ET.ParseError as exc:
            print(f"ERROR {path.name}: {exc}")
            errors += 1
            continue

        kind, display, code, version, note = classify(root)
        row = {
            "file": path.name,
            "kind": kind,
            "displayCode": display,
            "maTKhai": code,
            "version": version,
            "signature": has_signature(root),
            "leafFields": count_leaves(root),
            "status": note,
        }
        rows.append(row)
        code_text = f" [{code}]" if args.show_code and code else ""
        print(f"{path.name:<52} {str(display or '—'):<16} {kind:<40} "
              f"v{version or '?':<8} sig={'yes' if row['signature'] else 'no':<3} "
              f"fields={row['leafFields']:<4} {note}{code_text}")

    print(f"\nTotal: {len(rows)} parsed, {skipped} skipped for security, {errors} failed")
    if args.json:
        Path(args.json).write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"Report: {args.json}")
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
