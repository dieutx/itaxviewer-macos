#!/usr/bin/env python3
"""Trich cau truc bieu mau tu XSLT cua iTax Viewer (Windows) -> JSON bang chung.

Chi trich DSu kien (ma mau, tieu de cot, STT, nhan, ma chi tieu, duong dan gia tri),
khong copy asset cua vendor (khong XSLT/CSS/font vao repo). Moi entry giu
`sourceTemplate` + `sourceVersion` de truy nguoc.

Dung:
    python3 extract_xslt_specs.py --xslt-root "C:/Program Files (x86)/iTax Viewer/data/xslt" \
        --out docs/reverse-engineering/xslt-specs

    # kiem chung voi spec da viet tay
    python3 extract_xslt_specs.py --xslt-root ... --out ... \
        --verify iTaxViewerMac/Sources/iTaxViewerCore/Resources/form-specs.json
"""

from __future__ import annotations

import argparse
import html
import hashlib
import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

XSL = "http://www.w3.org/1999/XSL/Transform"
VERSION_DIR = re.compile(r"^XSLT\s+(\d+(?:\.\d+)*)$", re.IGNORECASE)
INDICATOR = re.compile(r"^\[\s*(\d{1,3}(?:\.\d{1,3})?[a-zA-Z]?)\s*\]$")
INLINE_INDICATOR = re.compile(r"\[\s*([A-Za-z]?\d{1,3}(?:\.\d{1,3})?[a-zA-Z]?)\s*\]")
FORMULA_CELL = re.compile(r"^\[[^]]+\]\s*=")
# hang tieu de cot chi tieu kieu "(3)", "(4)": khong phai dong du lieu
INDICATOR_HEADER = re.compile(r"^\(\s*\d{1,3}(?:\.\d{1,3})?[a-zA-Z]?\s*\)$")
STT = re.compile(r"^(?:[A-Za-z]{1,3}|[IVX]{1,4}|\d{1,2}(?:\.\d{1,2})?[a-z]?)$")
# cot "Ma chi tieu" (khong co ngoac vuong), vd 03/TNDN in ra A1, B13
CODE = re.compile(r"^[A-Za-z]{1,3}\d{0,3}[a-z]?$")
INDICATOR_COLUMN_TITLES = ("mã chỉ tiêu", "mã ct", "mã số")
SPACE = re.compile(r"\s+")
ENTITY = re.compile(r"&([a-zA-Z][a-zA-Z0-9]*);")
DOCTYPE = re.compile(rb"<!(?:DOCTYPE|ENTITY)[^>]*>", re.IGNORECASE)
# entity HTML pho bien trong XSLT khong co DTD di kem
NAMED = {"nbsp": 160, "amp": 38, "lt": 60, "gt": 62, "quot": 34, "apos": 39}


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def read_text(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        text = raw.decode("utf-16", errors="replace")
    elif raw.startswith(b"\xef\xbb\xbf"):
        text = raw[3:].decode("utf-8", errors="replace")
    else:
        text = raw.decode("utf-8", errors="replace")
    return text


def parse(path: Path) -> ET.Element:
    text = read_text(path)
    # bo DOCTYPE/ENTITY khai bao ngoai, giu nguyen noi dung
    text = DOCTYPE.sub(b"", text.encode("utf-8", errors="replace")).decode(
        "utf-8", errors="replace"
    )

    def entity(match: re.Match) -> str:
        name = match.group(1)
        if name in NAMED:
            return f"&#{NAMED[name]};"
        return match.group(0)

    text = ENTITY.sub(entity, text)
    return ET.fromstring(text)


def text_of(element: ET.Element) -> str:
    """Ghep text, coi <br/> va khoi con la ranh gioi tu (tranh dinh chu)."""
    parts: list[str] = []

    def walk(node: ET.Element) -> None:
        if node.text:
            parts.append(node.text)
        for child in node:
            name = local(child.tag)
            if name in ("br", "p", "div", "tr", "li"):
                parts.append(" ")
            walk(child)
            if name in ("br", "p", "div", "tr", "li"):
                parts.append(" ")
            if child.tail:
                parts.append(child.tail)

    walk(element)
    return SPACE.sub(" ", "".join(parts)).strip()


RELATIVE = re.compile(r"^[A-Za-z_][\w.\-]*(?:/[A-Za-z_][\w.\-]*)*$")


def selects_of(element: ET.Element) -> list[tuple[str, str]]:
    """value-of select -> (root, path).

    Giu ca duong dan tuong doi (select="maHSo") vi bang danh sach cua vendor dung
    <xsl:for-each> + duong dan tuong doi; root khi do la chuoi rong.
    """
    out = []
    for node in element.iter():
        if local(node.tag) != "value-of":
            continue
        select = (node.get("select") or "").strip()
        # Keep the selected field inside the known numeric formatter. Do not
        # infer paths from sum(), predicates or arbitrary function expressions.
        numeric = re.fullmatch(r"(?:[\w.-]+:)?formatNumber\(\s*([^(),]+)\s*\)", select)
        if numeric:
            select = numeric.group(1).strip()
        if select.startswith("$") and "/" in select:
            root, _, path = select[1:].partition("/")
            root, path = root.strip(), path.strip().strip("/")
            if path and not any(ch in path for ch in "[]()'\" "):
                out.append((root, path))
        elif RELATIVE.match(select):
            out.append(("", select))
    return out


def has_branch(element: ET.Element) -> bool:
    return any(local(n.tag) in ("if", "choose", "when") for n in element.iter())


def label_prefix(element: ET.Element) -> str:
    """Literal label before a value/conditional, excluding placeholder branches."""
    parts = []
    def walk(node):
        if node.tag.startswith("{" + XSL + "}"):
            return False
        if node.text:
            parts.append(node.text)
        for child in node:
            if not walk(child):
                return False
            if child.tail:
                parts.append(child.tail)
        return True
    walk(element)
    return SPACE.sub(" ", "".join(parts)).strip()


def display_codes(root: ET.Element) -> list[str]:
    codes: list[str] = []
    for node in root.iter():
        if local(node.tag) != "with-param" or (node.get("name") or "") != "mauTKhai":
            continue
        select = (node.get("select") or "").strip()
        if select.startswith("'") and select.endswith("'") and len(select) > 2:
            value = select[1:-1].strip()
            if value and value not in codes:
                codes.append(value)
    return codes


def table_of(tr: ET.Element, parents: dict) -> int:
    node = parents.get(id(tr))
    while node is not None and local(node.tag) != "table":
        node = parents.get(id(node))
    return id(node) if node is not None else 0


def inside_for_each(tr: ET.Element, parents: dict) -> bool:
    node = parents.get(id(tr))
    while node is not None:
        if local(node.tag) == "for-each":
            return True
        node = parents.get(id(node))
    return False


def extract(path: Path) -> dict:
    root = parse(path)
    parents = {id(child): parent for parent in root.iter() for child in parent}
    source_order = {id(node): index for index, node in enumerate(root.iter())}
    columns: list[str] = []
    spec_tables: set[int] = set()
    indicator_column: int | None = None
    header_rows: set[int] = set()
    # 1) moi bang co tieu de STT deu la bang noi dung (bieu mau nhieu phan), giu thu tu
    for tr in (n for n in root.iter() if local(n.tag) == "tr"):
        cells = [c for c in tr if local(c.tag) == "td"]
        texts = [text_of(c) for c in cells]
        if not any(t.upper() == "STT" for t in texts):
            continue
        header_rows.add(id(tr))
        spec_tables.add(table_of(tr, parents))
        if not columns:
            columns = [t for t in texts if t]
            for index, text in enumerate(texts):
                lowered = text.lower()
                if any(title in lowered for title in INDICATOR_COLUMN_TITLES):
                    indicator_column = index
                    break
    rows: list[dict] = []
    for tr in (n for n in root.iter() if local(n.tag) == "tr"):
        cells = [c for c in tr if local(c.tag) == "td"]
        if not cells or id(tr) in header_rows:
            continue
        if spec_tables and table_of(tr, parents) not in spec_tables:
            continue
        texts = [text_of(c) for c in cells]
        filled = [t for t in texts if t]
        if filled and all(INDICATOR_HEADER.match(t) for t in filled):
            continue
        indicator = ""
        if indicator_column is not None and indicator_column < len(texts):
            candidate = texts[indicator_column]
            if candidate and (CODE.match(candidate) or re.fullmatch(r"\d{1,4}[a-z]?", candidate) or INDICATOR.match(candidate)):
                match = INDICATOR.match(candidate)
                indicator = match.group(1) if match else candidate
        for text in texts:
            if indicator:
                break
            match = INDICATOR.match(text)
            if match:
                indicator = match.group(1)
                break
        if not indicator:
            for text in texts:
                match = INLINE_INDICATOR.match(text)
                if FORMULA_CELL.match(text) and match:
                    indicator = match.group(1)
                    break
        values: list[dict] = []
        for cell in cells:
            for root_name, value_path in selects_of(cell):
                item = {"root": root_name, "path": value_path}
                if item not in values:
                    values.append(item)
        stt = ""
        for text in texts:
            if INDICATOR.match(text) or not text:
                continue
            if STT.match(text):
                stt = text
                break
        label = ""
        left_cells = [
            text
            for cell, text in zip(cells, texts)
            if text
            and not INDICATOR.match(text)
            and not (STT.match(text) and len(text) <= 3)
            and not (INDICATOR_HEADER.match(text))
        ]
        aligned = [
            text_of(cell)
            for cell, text in zip(cells, texts)
            if text and "align-l" in (cell.get("class") or "")
        ]
        candidates = [t for t in aligned if t] + left_cells
        # A formula printed in a code cell is not the row's descriptive label.
        # In particular, it must not replace the official label "Tổng".
        descriptive = [t for t in candidates if not FORMULA_CELL.match(t)]
        for text in descriptive or candidates:
            if len(text) > len(label):
                label = text
        if not (indicator or label or values or stt):
            continue
        if indicator:
            kind = "checkbox" if has_branch(tr) and not values else "row"
        elif values:
            kind = "listrow" if not label and inside_for_each(tr, parents) else "row"
        else:
            kind = "section"
        rows.append(
            {
                "stt": stt,
                "label": label,
                "indicator": indicator,
                "codes": [indicator] if indicator else [],
                "values": values,
                "kind": kind,
                "sourceOrder": source_order[id(tr)],
            }
        )
    # Official totals can sit in div/p elements after the table (04/GTGT).
    # Extract only the innermost standalone blocks, never enclosing whole forms
    # or fields already represented by a table row.
    for block in root.iter():
        if local(block.tag) not in ("div", "p") or table_of(block, parents):
            continue
        if any(node is not block and local(node.tag) in ("div", "p", "table") for node in block.iter()):
            continue
        label = label_prefix(block)
        match = INLINE_INDICATOR.search(label)
        values = [{"root": name, "path": value_path} for name, value_path in selects_of(block)]
        if match is None or not values:
            continue
        rows.append({"stt": "", "label": label, "indicator": match.group(1),
                     "codes": [match.group(1)], "values": values, "kind": "row",
                     "origin": "outside-table", "sourceOrder": source_order[id(block)]})
    rows.sort(key=lambda row: row["sourceOrder"])
    title = ""
    for node in root.iter():
        if local(node.tag) != "variable" or (node.get("name") or "") != "moTaBieuMau":
            continue
        select = (node.get("select") or "").strip()
        if select.startswith("'") and select.endswith("'"):
            title = html.unescape(select[1:-1]).strip()
        break
    return {
        "displayCodes": display_codes(root),
        "title": title,
        "columns": columns,
        "rows": rows,
        "layout": "spec-tables" if spec_tables else "no-stt-header",
    }


def version_key(path: Path, root: Path) -> tuple:
    parts = path.relative_to(root).parts
    for part in parts:
        match = VERSION_DIR.match(part)
        if match:
            numbers = tuple(int(p) for p in match.group(1).split("."))
            return (1,) + numbers
    return (0,)


def version_label(path: Path, root: Path) -> str:
    for part in path.relative_to(root).parts:
        match = VERSION_DIR.match(part)
        if match:
            return match.group(1)
    return ""


def collect(root: Path) -> dict[str, dict]:
    chosen: dict[str, dict] = {}
    for path in sorted(root.rglob("*.xslt")):
        key = path.name.lower()
        candidate = {"path": path, "version": version_label(path, root)}
        if key in chosen:
            current = chosen[key]
            if version_key(candidate["path"], root) <= version_key(current["path"], root):
                current.setdefault("versions", set()).add(candidate["version"])
                continue
        versions = chosen.get(key, {}).get("versions", set())
        versions.add(candidate["version"])
        candidate["versions"] = versions
        chosen[key] = candidate
    return chosen


def merge_by_code(extracted: list[dict]) -> dict:
    """Gop cac version cua cung mot ma hien thi (giu version moi nhat lam chinh)."""
    grouped: dict[str, dict] = {}
    for entry in extracted:
        code = (entry.get("displayCodes") or [""])[0]
        if not code:
            continue
        grouped.setdefault(code, {"displayCode": code, "templates": []})["templates"].append(entry)
    for value in grouped.values():
        value["templates"].sort(key=lambda e: tuple(int(p) for p in (e["sourceVersion"].split(".") or ["0"]) if p.isdigit()), reverse=True)
    return grouped


def verify(extracted: list[dict], spec_path: Path, xslt_root: Path | None = None) -> int:
    specs = json.loads(spec_path.read_text(encoding="utf-8"))
    by_template: dict[str, list[dict]] = {}
    for entry in extracted:
        by_template.setdefault(entry["sourceTemplate"], []).append(entry)
    failures = 0
    for spec in specs:
        template = spec.get("sourceTemplate")
        candidates = by_template.get(template) or []
        evidence = spec.get("sourceEvidence") or {}
        if xslt_root is not None and evidence.get("path"):
            relative = evidence["path"].replace("\\", "/")
            if relative.lower().startswith("data/xslt/"):
                relative = relative[len("data/xslt/"):]
            source = (xslt_root / relative).resolve()
            if not source.is_relative_to(xslt_root.resolve()) or not source.is_file():
                print(f"MISS  {spec['maTKhai']}: exact source evidence path unavailable")
                failures += 1
                continue
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            if evidence.get("sha256", "").lower() != digest:
                print(f"DIFF  {spec['maTKhai']}: source evidence SHA-256 mismatch")
                failures += 1
                continue
            candidates = [extract(source)]
        if not candidates:
            print(f"MISS  {spec['displayCode']:<12} {template}: khong tim thay XSLT")
            failures += 1
            continue
        got = candidates[0]
        expected = [(r.get("label", ""), r.get("indicator", "")) for r in spec["rows"]]
        actual = [(r["label"], r["indicator"]) for r in got["rows"]]
        col_ok = spec["columns"] == got["columns"]
        # Bản trích là nguồn gốc: spec tay phải là *dãy con* đúng thứ tự của bản trích.
        # Dòng thừa trong bản trích là thông tin bổ sung (ghi nhận), không phải lỗi.
        cursor = 0
        missing: list[tuple] = []
        indicator_mismatch: list[tuple] = []
        for label, indicator in expected:
            while cursor < len(actual) and actual[cursor][0] != label:
                cursor += 1
            if cursor == len(actual):
                missing.append((label, indicator))
                continue
            if indicator and actual[cursor][1] != indicator:
                indicator_mismatch.append((label, indicator, actual[cursor][1]))
            cursor += 1
        extra = len(actual) - (len(expected) - len(missing))
        status = "OK" if (col_ok and not missing and not indicator_mismatch) else "DIFF"
        print(
            f"{status:<5} {spec['displayCode']:<12} {template}: "
            f"spec {len(expected)} dòng · trích {len(actual)} dòng · "
            f"cột {'khớp' if col_ok else 'lệch'} · thiếu {len(missing)} · "
            f"lệch chỉ tiêu {len(indicator_mismatch)} · thừa {extra}"
        )
        if status == "DIFF":
            failures += 1
            for row in missing[:12]:
                print(f"      thiếu trong bản trích: label={row[0][:70]!r} indicator={row[1]!r}")
            for row in indicator_mismatch[:6]:
                print(f"      chỉ tiêu lệch: label={row[0][:50]!r} spec={row[1]!r} trích={row[2]!r}")
    print(f"kết quả: {len(specs) - failures} khớp / {len(specs)} spec đã viết tay")
    return failures


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--xslt-root", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--verify", type=Path)
    parser.add_argument("--limit", type=int, default=0)
    args = parser.parse_args()

    if not args.xslt_root.is_dir():
        print(f"không thấy thư mục XSLT: {args.xslt_root}")
        return 2

    chosen = collect(args.xslt_root)
    names = sorted(chosen)
    if args.limit:
        names = names[: args.limit]
    extracted: list[dict] = []
    errors: list[tuple[str, str]] = []
    for name in names:
        item = chosen[name]
        try:
            data = extract(item["path"])
        except Exception as exc:  # ghi lại để báo cáo khoảng trống, không nuốt lỗi
            errors.append((name, f"{type(exc).__name__}: {exc}"))
            continue
        extracted.append(
            {
                "sourceTemplate": item["path"].name,
                "sourceVersion": item["version"],
                "sourceVersions": sorted(v for v in item["versions"] if v),
                "sourcePath": str(item["path"]),
                "sourceSHA256": hashlib.sha256(item["path"].read_bytes()).hexdigest(),
                "displayCodes": data["displayCodes"],
                "title": data["title"],
                "columns": data["columns"],
                "layout": data["layout"],
                "rows": data["rows"],
            }
        )

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "xslt-specs.json").write_text(
        json.dumps(extracted, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )

    codes = [e for e in extracted if e["displayCodes"]]
    rows = [
        {
            "template": e["sourceTemplate"],
            "version": e["sourceVersion"],
            "versions": ";".join(e["sourceVersions"]),
            "displayCode": ";".join(e["displayCodes"]),
            "title": e["title"],
            "columns": len(e["columns"]),
            "layout": e["layout"],
            "rows": len(e["rows"]),
            "indicators": sum(1 for r in e["rows"] if r["indicator"]),
            "sections": sum(1 for r in e["rows"] if r["kind"] == "section"),
            "values": sum(len(r["values"]) for r in e["rows"]),
        }
        for e in codes
    ]
    rows.sort(key=lambda r: (r["displayCode"], r["template"]))
    fields = ["displayCode", "template", "version", "versions", "layout", "columns", "rows", "indicators", "sections", "values", "title"]
    lines = [",".join(fields)]
    for row in rows:
        values = {k: str(row[k]).replace('"', "'") for k in fields}
        lines.append(
            "{displayCode},{template},{version},{versions},{layout},{columns},{rows},"
            "{indicators},{sections},{values},\"{title}\"".format(**values)
        )
    (args.out / "xslt-specs-index.csv").write_text("\n".join(lines) + "\n", encoding="utf-8")

    summary = {
        "templatesParsed": len(extracted),
        "templatesWithDisplayCode": len(codes),
        "distinctDisplayCodes": len({c for e in codes for c in e["displayCodes"]}),
        "rows": sum(len(e["rows"]) for e in extracted),
        "indicators": sum(1 for e in extracted for r in e["rows"] if r["indicator"]),
        "parseErrors": len(errors),
        "kinds": dict(Counter(r["kind"] for e in extracted for r in e["rows"])),
    }
    (args.out / "xslt-specs-summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print("tổng hợp:", json.dumps(summary, ensure_ascii=False))
    if errors:
        print(f"lỗi parse: {len(errors)}")
        for name, message in errors[:10]:
            print(f"  {name}: {message}")

    failures = 0
    if args.verify:
        failures = verify(extracted, args.verify, args.xslt_root)
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
