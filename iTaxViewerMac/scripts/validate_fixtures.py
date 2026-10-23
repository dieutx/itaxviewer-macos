#!/usr/bin/env python3
"""Reproducible field-mapping validation for iTax Viewer for macOS.

This harness mirrors the Swift core's registry resolution and XPath field mapping
(see Sources/iTaxViewerCore). It does not build Swift; it validates that the
shipped form specs map the fixtures to the expected official indicators and that
numeric formatting matches the original application's JavaScript formatter.

Run:  python3 scripts/validate_fixtures.py
Exit: 0 on success, 1 on any mismatch.
"""
from __future__ import annotations

import json
import math
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
RES = ROOT / "Sources" / "iTaxViewerCore" / "Resources"
FIX = ROOT / "Tests" / "iTaxViewerCoreTests" / "Fixtures"


def format_number(raw: str | None) -> str:
    """Port of ihtkk:formatNumber from common.xsl (msxsl JavaScript)."""
    if raw is None:
        return ""
    value = raw.strip()
    if not value:
        return ""
    negative = False
    if value.startswith("-"):
        negative = True
        value = value[1:]
    integer_part, _, fraction = value.partition(".")
    try:
        numeric = float(integer_part)
    except ValueError:
        return raw.strip()
    rounded_hundredths = math.floor(numeric * 100 + 0.50000000001)
    rounded_integer = math.floor(rounded_hundredths / 100)
    digits = f"{int(rounded_integer)}"
    groups = []
    while digits:
        groups.append(digits[-3:])
        digits = digits[:-3]
    grouped = ".".join(reversed(groups))
    if fraction:
        grouped += "," + fraction
    if negative and grouped != "0":
        grouped = f"({grouped})"
    return grouped


def localname(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def first(node: ET.Element, name: str) -> ET.Element | None:
    for child in node:
        if localname(child.tag) == name:
            return child
    return None


def descendants(node: ET.Element, name: str):
    for el in node.iter():
        if localname(el.tag) == name:
            yield el


def node_at(root: ET.Element | None, path: str) -> ET.Element | None:
    current = root
    for part in path.split("/"):
        if current is None:
            return None
        current = first(current, part)
    return current


class Fixture:
    def __init__(self, path: Path):
        self.path = path
        self.tree = ET.parse(path)
        self.root = self.tree.getroot()

    def text(self, path: str) -> str | None:
        node = node_at(self.root, path)
        return None if node is None or node.text is None else node.text.strip()


def resolve(fixture: Fixture, row: dict) -> str:
    ctx = {
        "tkchinh": node_at(fixture.root, "HSoKhaiThue/CTieuTKhaiChinh"),
        "ktru": node_at(fixture.root, "HSoKhaiThue/CTieuTKhaiChinh/NVuKhauTruThue"),
        "qtoan": node_at(fixture.root, "HSoKhaiThue/CTieuTKhaiChinh/NVuQToanThay"),
        "ttkthue": node_at(fixture.root, "HSoKhaiThue/TTinChung/TTinTKhaiThue"),
    }
    result = []
    for value in row["values"]:
        base = ctx.get(value["root"])
        node = node_at(base, value["path"]) if base is not None else None
        result.append("" if node is None or node.text is None else node.text.strip())
    return result


EXPECTED = {
    "correction_tt80": {"kind": "Tờ khai thuế", "display": "01/GTGT", "code": "842"},
    "gtgt_842_return": {
        "kind": "Tờ khai thuế",
        "display": "01/GTGT",
        "code": "842",
        "indicators": {
            "23": "1000000000", "24": "80000000", "23a": "200000000", "24a": "20000000",
            "25": "80000000", "27": "2000000000", "28": "160000000", "30": "0",
            "32": "2000000000", "33": "160000000", "34": "2000000000", "35": "160000000",
            "36": "80000000", "40a": "80000000", "40": "80000000", "43": "0",
        },
        "formatted": {"23": "1.000.000.000", "24": "80.000.000", "43": "0"},
    },
    "gtgt_842_nq142": {
        "kind": "Tờ khai thuế",
        "display": "01/GTGT",
        "code": "842",
        "indicators": {
            "23": "1000000000", "24": "80000000", "23a": "200000000",
            "24a": "20000000", "25": "80000000", "27": "2000000000",
            "28": "160000000", "30": "0", "32": "2000000000",
            "33": "160000000", "34": "2000000000", "35": "160000000",
            "36": "80000000", "40a": "80000000", "40": "80000000", "43": "0",
        },
        "formatted": {"23": "1.000.000.000", "24": "80.000.000", "43": "0"},
    },
    "tncn_394_05kk_tt92": {
        "kind": "Tờ khai thuế",
        "display": "05/KK-TNCN",
        "code": "394",
        "indicators": {"21": "20", "23": "2", "26": "1200000", "32": "5000", "36": "0"},
        "formatted": {"26": "1.200.000", "32": "5.000"},
    },
    "tncn_953_05qtt": {
        "kind": "Tờ khai thuế",
        "display": "05/QTT-TNCN",
        "code": "953",
        "indicators": {"16": "25", "23": "1500000000", "31": "95000000", "38": "95000000", "41": "0"},
        "formatted": {"23": "1.500.000.000", "31": "95.000.000"},
    },
    "tndn_892_03tndn_v2.9.4": {
        "kind": "Tờ khai thuế",
        "display": "03/TNDN",
        "code": "892",
        "indicators": {"A1": "-1000", "B1": "250", "B4": "250", "C1": "-750", "E": "10.5"},
        "formatted": {"A1": "(1.000)", "B1": "250", "E": "10,5"},
    },
    "gnt_chungtu": {"kind": "Giấy nộp tiền / chứng từ", "display": "CT-01", "code": "01"},
    "voucher_ct01": {"kind": "Giấy nộp tiền / chứng từ", "display": "CT-01", "code": "01"},
    "tbao_107_bstt": {"kind": "Thông báo / văn bản của cơ quan thuế", "display": "01/TB-BSTT", "code": "107"},
    "notice_843": {"kind": "Thông báo / văn bản của cơ quan thuế", "display": None, "code": "843"},
    "notice_843_rejected": {"kind": "Thông báo / văn bản của cơ quan thuế", "display": None, "code": "843"},
    "notice_844": {"kind": "Thông báo / văn bản của cơ quan thuế", "display": None, "code": "844"},
    "notice_01_tb_bstt": {"kind": "Thông báo / văn bản của cơ quan thuế", "display": "01/TB-BSTT", "code": None},
    "gtgt_01_legacy_212": {
        "kind": "Tờ khai thuế",
        "display": "01/GTGT",
        "code": "01",
        "indicators": {
            "22": "5000000", "23": "1000000000", "24": "80000000",
            "25": "80000000", "36": "-115000000", "41": "115000000", "43": "115000000",
        },
        "formatted": {"23": "1.000.000.000", "36": "(115.000.000)"},
    },
}

REGISTRY = json.loads((RES / "form-registry.json").read_text(encoding="utf-8"))
SPECS = {s["maTKhai"]: s for s in json.loads((RES / "form-specs.json").read_text(encoding="utf-8"))}

for _code, _indicators in {
    "864": {"16": "1", "21": "1000006", "25.1": "1000011", "32": "1000018"},
    "395": {"21": "1", "28": "1000008", "34": "1000014", "46": "1000026"},
    "07": {"21": "1000001", "32": "1000012", "33": "1000013"},
    "847": {"21": "1000001", "31": "1000011"},
}.items():
    EXPECTED[f"declaration_{_code}_static"] = {
        "kind": "Tờ khai thuế", "display": SPECS[_code]["displayCode"], "code": _code,
        "indicators": _indicators,
    }


def classify(fixture: Fixture) -> tuple[str, str | None, str | None]:
    root = localname(fixture.root.tag)
    if root == "HSoThueDTu":
        khai = next(descendants(fixture.root, "TKhaiThue"), None)
        if khai is None:
            raise AssertionError("missing TKhaiThue")
        code = fixture.text("HSoKhaiThue/TTinChung/TTinTKhaiThue/TKhaiThue/maTKhai")
        info = REGISTRY["codes"].get(code or "")
        display = (info or {}).get("displayCode")
        return "Tờ khai thuế", display.strip() if display else None, code
    if root == "CHUNGTU":
        return "Giấy nộp tiền / chứng từ", "CT-01", "01"
    if root in ("TBaoThueDTu", "THONGBAO", "THONG_BAO", "TBao"):
        mso = next(descendants(fixture.root, "MSo"), None)
        code = next(descendants(fixture.root, "maTBao"), None)
        return ("Thông báo / văn bản của cơ quan thuế",
                (mso.text.strip() if mso is not None and mso.text else None),
                (code.text.strip() if code is not None and code.text else None))
    raise AssertionError(f"unsupported root {root}")


def main() -> int:
    failures: list[str] = []
    print(f"{'fixture':<30}{'display':<14}{'kind':<40}result")
    print("-" * 96)

    for fixture_path in sorted(FIX.glob("*.xml")):
        name = fixture_path.stem
        if name in ("xxe_attack", "signed_demo", "gtgt_842_return_utf16"):
            continue
        fixture = Fixture(fixture_path)
        expected = EXPECTED[name]
        kind, display, code = classify(fixture)
        ok = kind == expected["kind"] and display == expected["display"] and code == expected["code"]
        if not ok:
            failures.append(f"{name}: classification {kind}/{display}/{code} != "
                            f"{expected['kind']}/{expected['display']}/{expected['code']}")
        print(f"{name:<30}{str(display):<14}{kind:<40}{'PASS' if ok else 'FAIL'}")

        if "indicators" in expected:
            spec = SPECS["842" if code == "01" else code]
            found: dict[str, list[str]] = {}
            for row in spec["rows"]:
                if not row["values"]:
                    continue
                values = resolve(fixture, row)
                for idx, indicator in enumerate(row["codes"]):
                    if idx < len(values):
                        found[indicator] = values[idx]
                if len(row["codes"]) == 1 and values:
                    found[row["codes"][0]] = values[0]
            for indicator, want in expected["indicators"].items():
                got = found.get(indicator)
                if got != want:
                    failures.append(f"{name}: [{indicator}] mapping mismatch")
            for indicator, want in expected.get("formatted", {}).items():
                got = format_number(found.get(indicator))
                if got != want:
                    failures.append(f"{name}: format([{indicator}]) mismatch")

    # Spec coverage: every supported form must have a spec with rows.
    for form in REGISTRY["supported"]:
        spec = SPECS.get(form["maTKhai"])
        if not spec or not spec["rows"]:
            failures.append(f"missing spec for {form['displayCode']}")
        else:
            print(f"spec {form['displayCode']:<12} rows={len(spec['rows']):<4} "
                  f"mapped={sum(1 for r in spec['rows'] if r['values'])}")

    # Formatting corpus (matches Swift FormatterTests).
    corpus = {
        "1000000000": "1.000.000.000", "80000000": "80.000.000", "0": "0",
        "250": "250", "-1000": "(1.000)", "-1": "(1)", "1234.56": "1.234,56",
    }
    for raw, want in corpus.items():
        got = format_number(raw)
        if got != want:
            failures.append(f"format_number({raw!r}) = {got!r}, expected {want!r}")

    print("-" * 96)
    if failures:
        print(f"FAILED ({len(failures)})")
        for failure in failures:
            print(" -", failure)
        return 1
    print("ALL CHECKS PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
