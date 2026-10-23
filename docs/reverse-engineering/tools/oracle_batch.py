#!/usr/bin/env python3
"""Run Windows MSXML against registry-selected templates and bundled fixtures.

Vendor HTML remains in gitignored _re/oracle. Only counts/hashes/status are
reported. No taxpayer values or raw transform errors are printed or uploaded.
The oracle is pre-run.html .number postprocessing, not a Windows PDF capture.
"""
import argparse
import csv
import hashlib
import json
import re
import subprocess
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path

from html_diff import cells, read_html

ROOT = Path(__file__).resolve().parents[3]
FIXTURES = ROOT / "iTaxViewerMac/Tests/iTaxViewerCoreTests/Fixtures"
RES = ROOT / "iTaxViewerMac/Sources/iTaxViewerCore/Resources"


def local(tag):
    return tag.rsplit("}", 1)[-1]


def find(root, name):
    return next((node for node in root.iter() if local(node.tag) == name), None)


def text(root, name):
    node = find(root, name)
    return node.text.strip() if node is not None and node.text else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--install", type=Path, default=Path("C:/Program Files (x86)/iTax Viewer"))
    parser.add_argument("--fixture", action="append", help="Bundled fixture basename, repeatable")
    options = parser.parse_args()
    install = options.install.resolve()
    output = ROOT / "_re/oracle/batch"
    output.mkdir(parents=True, exist_ok=True)
    registry = list(csv.DictReader((ROOT / "docs/reverse-engineering/documents/document-registry.csv").open(encoding="utf-8-sig", newline="")))
    specs = {spec["maTKhai"]: spec for spec in json.loads((RES / "form-specs.json").read_text(encoding="utf-8"))}
    results = []
    for source in sorted(FIXTURES.glob("*.xml")):
        if options.fixture and source.name not in options.fixture:
            continue
        result = {"fixture": source.name}
        results.append(result)
        raw = source.read_bytes()
        decoded = raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")
        if re.search(r"<!\s*(?:DOCTYPE|ENTITY)\b", decoded, re.I):
            result["status"] = "rejected-dtd"
            continue
        try:
            root = ET.fromstring(decoded)
        except ET.ParseError:
            result["status"] = "invalid-xml"
            continue
        name = local(root.tag)
        if name == "HSoThueDTu":
            code, version, kind = text(root, "maTKhai"), text(root, "pbanTKhaiXML"), "declaration"
        elif name == "CHUNGTU":
            code, version, kind = text(root, "MA_CTU"), text(root, "PBAN_TLIEU_XML"), "paymentVoucher"
        elif name == "TBaoThueDTu":
            code, version, kind = text(root, "maTBao"), text(root, "pbanTBao"), "notice"
        elif name == "TBao":
            code, version, kind = text(root, "MSo"), text(root, "PBan"), "notice"
        else:
            result["status"] = "unmapped-root"
            continue
        result.update({"code": code, "version": version})
        # DMucTbao's inventory groups these registry rows under TBaoThueDTu,
        # but HSoThueFactory dispatches the MSo family through TBaoHDDT.
        registry_root = "TBaoThueDTu" if name == "TBao" else name
        matches = [row for row in registry if row["kind"] == kind and row["root"] == registry_root and row["id"] == code and row["version"] == version]
        templates = sorted({row["xslt"] for row in matches if row["xslt"]})
        if len(templates) != 1:
            result["status"] = "missing-or-ambiguous-template"
            continue
        relative = templates[0].replace("\\", "/")
        template = (install / relative).resolve()
        result["template"] = relative
        if not template.is_relative_to(install) or not template.is_file():
            result["status"] = "template-unavailable"
            continue
        result["templateSHA256"] = hashlib.sha256(template.read_bytes()).hexdigest()
        # The original strips the known default namespace before transforming.
        # Preserve prefixes/attributes and do not modify the fixture on disk.
        normalized = re.sub(r'\s+xmlns\s*=\s*([\'"])[^\'"]*\1', "", decoded)
        normalized = re.sub(r'(<\?xml\b[^>]*\bencoding\s*=\s*)([\'"])[^\'"]+\2', r'\1"utf-8"', normalized, flags=re.I)
        input_path = output / (source.stem + ".input.xml")
        html_path = output / (source.stem + ".html")
        input_path.write_text(normalized, encoding="utf-8")
        try:
            process = subprocess.run(["cscript.exe", "//nologo", str(ROOT / "docs/reverse-engineering/tools/msxml_oracle.js"),
                                      str(input_path), str(template), str(html_path)], capture_output=True, timeout=30)
        except (OSError, subprocess.TimeoutExpired):
            result["status"] = "oracle-process-failed"
            continue
        result["exitCode"] = process.returncode
        if process.returncode != 0:
            result["status"] = "transform-failed"
            continue
        html = read_html(html_path)
        rendered_cells = cells(html)
        result.update({"status": "rendered", "bytes": html_path.stat().st_size, "chars": len(html),
                       "tables": len(re.findall(r"<table\b", html, re.I)), "rows": len(re.findall(r"<tr\b", html, re.I)),
                       "cells": len(rendered_cells), "sha256": hashlib.sha256(html_path.read_bytes()).hexdigest()})
        spec = specs.get(code)
        if spec is not None and version in spec["versions"]:
            # Distinct synthetic marker amounts (>999) avoid false matches on
            # row numbering. This checks presence, not cell position/parity.
            main = find(root, "CTieuTKhaiChinh")
            values = set()
            for row in spec["rows"]:
                for value in row["values"]:
                    base = {"ktru": find(root, "NVuKhauTruThue"), "qtoan": find(root, "NVuQToanThay"),
                            "ttkthue": find(root, "TTinTKhaiThue")}.get(value.get("root"), main)
                    node = base
                    for part in value["path"].split("/"):
                        node = next((child for child in node if local(child.tag) == part), None) if node is not None else None
                    if node is not None and node.text and re.fullmatch(r"-?\d{4,}", node.text.strip()):
                        values.add(node.text.strip())
            numeric_text = " ".join(rendered_cells).replace(".", "").replace("(", "-").replace(")", "")
            all_text = re.sub(r"<[^>]*>", " ", html).replace(".", "").replace("(", "-").replace(")", "")
            result["uniqueMappedAmounts"] = len(values)
            result["mappedAmountsInCells"] = sum(value in numeric_text for value in values)
            result["mappedAmountsPresent"] = sum(value in all_text for value in values)
    (output / "index.json").write_text(json.dumps(results, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(dict(Counter(result["status"] for result in results)), sort_keys=True))
    for result in results:
        print(f"{result['fixture']}: {result['status']}")
    return int(any(result["status"] in ("transform-failed", "oracle-process-failed", "invalid-xml") for result in results))


if __name__ == "__main__":
    raise SystemExit(main())
