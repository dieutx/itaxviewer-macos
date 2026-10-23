#!/usr/bin/env python3
"""Generate the Windows-RE coverage inventory.

Reads the extracted registry (`document-registry.csv`), the shipped form
registry and the document progress tracker, then writes one CSV per document
kind. The CSVs are the machine-readable source for
`docs/reverse-engineering/COVERAGE-REVIEW.md` and the Windows prompts.

Run from the repository root:
    python3 docs/reverse-engineering/tools/generate_coverage.py
"""
from __future__ import annotations

import csv
import json
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
REGISTRY_CSV = ROOT / "docs/reverse-engineering/documents/document-registry.csv"
FORM_REGISTRY = ROOT / "iTaxViewerMac/Sources/iTaxViewerCore/Resources/form-registry.json"
OUT = ROOT / "docs/reverse-engineering/inventory"

# Codes with a recreated macOS renderer today.
FULL_DECLARATIONS = {"842", "01", "394", "953", "892"}
P0_DECLARATIONS = {
    "07", "847",           # 04/GTGT (real data in the local corpus)
    "864",                 # 05/KK-TNCN under TT 80/2021
    "395",                 # legacy 05/QTT-TNCN
    "2002", "2003", "2004",  # CIT forms under TT 89/2025
    "386", "473", "1240", "1266",  # 01/CNKD household business
    "701", "1254", "702",  # B01/B05 financial statements
}
P1_DISPLAY = {
    "02/GTGT", "03/GTGT", "05/GTGT", "01/TĐ-GTGT",
    "02/KK-TNCN", "02/QTT-TNCN", "06/TNCN", "04/NNG-TNCN",
    "02/TNDN", "04/TNDN",
    "01/TTS", "01/TAIN", "01/TAIN-DK", "02/TAIN", "03/TĐ-TAIN",
    "01/NTNN", "02/NTNN", "03/NTNN", "04/NTNN",
    "01/TBVMT", "01/HKNN", "01/TBH", "01/XSBHĐC",
    "02/KK-XS", "02/KK-BH", "01/ĐNHT", "01/MBAI", "01/VTNN",
}
IMPLEMENTED_APPENDICES = {"PL_NQ43_GTGT", "PL_NQ101_GTGT", "PL_NQ142_GTGT"}
CAPTURED_NOTICES = {"843", "844", "01/TB-BSTT"}


def read_rows() -> list[dict]:
    with REGISTRY_CSV.open(encoding="utf-8-sig", newline="") as fh:
        return list(csv.DictReader(fh))


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)



def declaration_family(display: str | None) -> str:
    """Group the 237 display codes into reviewable tax families."""
    if not display:
        return "Không mã hiển thị / nội bộ"
    d = display.upper().strip()
    if "GTGT" in d:
        return "GTGT"
    if "TNCN" in d:
        return "TNCN"
    if "TNDN" in d:
        return "TNDN"
    if "TTĐB" in d or "TTS" in d:
        return "TTĐB / TTS"
    if "BVMT" in d or "PBVMT" in d:
        return "Bảo vệ môi trường"
    if "TAIN" in d:
        return "Tài nguyên"
    if "NTNN" in d or "NCCNN" in d:
        return "Nhà thầu nước ngoài"
    if "CNKD" in d or "HKD" in d:
        return "Hộ kinh doanh"
    if any(k in d for k in ("XSBH", "KK-XS", "KK-BH", "LNCL-XS")):
        return "Xổ số / Bảo hiểm"
    if (d.startswith("B0") or d.startswith("B 0") or d.startswith("B-0")
            or d.startswith("MẪU SỐ B0") or "BCTC" in d or d.startswith("BC")
            or d.startswith("TB0") or d.startswith("BK0") or "CTCK" in d
            or "DNNKLT" in d or "DNSN" in d or "DNSS" in d or "HTX" in d
            or "CTQ" in d or "TCTD" in d or "DNN" in d):
        return "BCTC & thuyết minh"
    if "TEM" in d or "CTT24" in d:
        return "Tem điện tử"
    if any(k in d for k in ("PHLP", "PHLPNG")) or d in ("01/PH", "02/PH", "01/LP"):
        return "Phí / lệ phí"
    if "MBAI" in d or "LPMB" in d:
        return "Thuế môn bài"
    if "VTNN" in d:
        return "Vận tải"
    if "HTQT" in d:
        return "Hiệp định thuế / HTQT"
    return "Đăng ký, khai lần đầu & chuyên ngành"

def declaration_wave(code: str, display: str | None) -> str:
    if code in FULL_DECLARATIONS:
        return "done"
    if code in P0_DECLARATIONS:
        return "P0"
    if display in P1_DISPLAY:
        return "P1"
    if display:
        return "P2"
    return "P3"


def appendix_wave(name: str, parents: int) -> str:
    if name in IMPLEMENTED_APPENDICES:
        return "done"
    if name in {"PL01_KHBS", "PL01_1_KHBS"}:
        return "P0"
    upper = name.upper()
    if any(k in upper for k in ("GTGT", "TNDN", "TNCN", "CNKD", "DK_TCT", "TTDB",
                                "TAIN", "NTNN", "TTS", "KHBS", "QTT", "GTGT")):
        return "P1"
    if parents >= 3:
        return "P1"
    return "P2"


def notice_wave(registry: str, notice_id: str) -> str:
    if notice_id in CAPTURED_NOTICES:
        return "done"
    if notice_id in {"01/CCTT-TB", "01/TB-BSTT-NNT", "01/TB-NSD", "01/TB-SSĐT",
                     "01/TB-TNĐT", "01/TB-ĐKĐT", "448", "450", "451", "801",
                     "818", "960", "998"}:
        return "P0"
    if registry.lower().startswith("dmuctbao.xml") or registry.lower() == "dmuctbao.xml":
        return "P1"
    return "P2"


def main() -> None:
    rows = read_rows()
    form_registry = json.loads(FORM_REGISTRY.read_text(encoding="utf-8"))
    codes = form_registry["codes"]

    # ---- declarations, one row per maTKhai (410) ----
    decl = defaultdict(list)
    for row in rows:
        if row["kind"] == "declaration":
            decl[row["id"]].append(row)
    decl_rows = []
    for code, entries in sorted(decl.items(), key=lambda kv: kv[0]):
        info = codes.get(code, {})
        display = info.get("displayCode")
        versions = sorted({e["version"] for e in entries})
        decl_rows.append({
            "maTKhai": code,
            "displayCode": display or "",
            "versions": ";".join(versions),
            "versionCount": len(versions),
            "orientation": entries[0]["orientation"],
            "template": entries[0]["xslt"],
            "status": "full" if code in FULL_DECLARATIONS else "structured-only",
            "family": declaration_family(display),
            "wave": declaration_wave(code, display),
            "prompt": "01-DECLARATIONS.md",
        })
    write_csv(OUT / "declarations.csv",
              ["maTKhai", "displayCode", "family", "versions", "versionCount", "orientation",
               "template", "status", "wave", "prompt"],
              decl_rows)

    # ---- declaration families (navigation aid) ----
    families = defaultdict(lambda: {"displays": set(), "codes": set(),
                                    "versions": 0, "templates": set()})
    for row in decl_rows:
        family = families[row["family"]]
        family["displays"].add(row["displayCode"] or "(không mã)")
        family["codes"].add(row["maTKhai"])
        family["versions"] += int(row["versionCount"])
        family["templates"].add(row["template"])
    family_rows = [{
        "family": name,
        "displayCodes": len(value["displays"]),
        "maTKhaiCodes": len(value["codes"]),
        "versions": value["versions"],
        "templates": len(value["templates"]),
    } for name, value in sorted(families.items(),
                                key=lambda kv: -len(kv[1]["displays"]))]
    write_csv(OUT / "declaration-families.csv",
              ["family", "displayCodes", "maTKhaiCodes", "versions", "templates"],
              family_rows)

    # ---- notices, one row per (registry, id) ----
    notices = defaultdict(list)
    for row in rows:
        if row["kind"] == "notice":
            notices[(row["registry"], row["id"])].append(row)
    notice_rows = []
    for (registry, notice_id), entries in sorted(notices.items()):
        notice_rows.append({
            "registry": registry,
            "id": notice_id or "(blank)",
            "versions": ";".join(sorted({e["version"] for e in entries})),
            "root": entries[0]["root"],
            "template": entries[0]["xslt"],
            "status": "captured" if notice_id in CAPTURED_NOTICES else "structured-only",
            "wave": notice_wave(registry, notice_id),
            "prompt": "02-NOTICES.md",
        })
    write_csv(OUT / "notices.csv",
              ["registry", "id", "versions", "root", "template", "status", "wave", "prompt"],
              notice_rows)

    # ---- appendices, unique ids ----
    appendix_parents = defaultdict(set)
    for row in rows:
        for name in (row["plucIds"] or "").split(";"):
            name = name.strip()
            if name:
                appendix_parents[name].add(row["id"])
    appendix_rows = []
    for name, parents in sorted(appendix_parents.items()):
        appendix_rows.append({
            "id": name,
            "parentCount": len(parents),
            "parentCodes": ";".join(sorted(parents)),
            "status": "implemented" if name in IMPLEMENTED_APPENDICES else "structured-only",
            "wave": appendix_wave(name, len(parents)),
            "prompt": "03-APPENDICES.md",
        })
    write_csv(OUT / "appendices.csv",
              ["id", "parentCount", "parentCodes", "status", "wave", "prompt"],
              appendix_rows)

    # ---- vouchers ----
    voucher_rows = [{
        "maCTu": row["id"],
        "version": row["version"],
        "root": row["root"],
        "template": row["xslt"],
        "status": "implemented" if (row["id"], row["version"]) == ("01", "4.0.1") else "structured-only",
        "wave": "done" if (row["id"], row["version"]) == ("01", "4.0.1") else "P0",
        "prompt": "04-VOUCHERS.md",
    } for row in rows if row["kind"] == "paymentVoucher"]
    write_csv(OUT / "vouchers.csv",
              ["maCTu", "version", "root", "template", "status", "wave", "prompt"],
              voucher_rows)

    # ---- registration / catalog / customs ----
    other_rows = []
    for row in rows:
        if row["kind"] in ("registration", "catalog"):
            other_rows.append({
                "kind": row["kind"],
                "id": row["id"],
                "version": row["version"],
                "root": row["root"],
                "template": row["xslt"],
                "status": "structured-only",
                "wave": "P2",
                "prompt": "06-OTHER-KINDS.md",
            })
    write_csv(OUT / "registration-catalog.csv",
              ["kind", "id", "version", "root", "template", "status", "wave", "prompt"],
              other_rows)

    customs = [r for r in rows if r["kind"] == "customs"]
    summary = {
        "generatedFrom": str(REGISTRY_CSV.relative_to(ROOT)),
        "declarations": {
            "codes": len(decl_rows),
            "displayCodes": len({r["displayCode"] for r in decl_rows if r["displayCode"]}),
            "full": sum(1 for r in decl_rows if r["status"] == "full"),
            "structuredOnly": sum(1 for r in decl_rows if r["status"] != "full"),
            "byWave": dict(Counter(r["wave"] for r in decl_rows)),
            "families": len(family_rows),
        },
        "notices": {
            "uniqueIds": len({r["id"] for r in notice_rows}),
            "registryRows": len(notice_rows),
            "captured": sum(1 for r in notice_rows if r["status"] == "captured"),
            "structuredOnly": sum(1 for r in notice_rows if r["status"] != "captured"),
            "byWave": dict(Counter(r["wave"] for r in notice_rows)),
        },
        "appendices": {
            "uniqueIds": len(appendix_rows),
            "implemented": sum(1 for r in appendix_rows if r["status"] == "implemented"),
            "structuredOnly": sum(1 for r in appendix_rows if r["status"] != "implemented"),
            "byWave": dict(Counter(r["wave"] for r in appendix_rows)),
        },
        "vouchers": {
            "rows": len(voucher_rows),
            "implemented": sum(1 for r in voucher_rows if r["status"] == "implemented"),
        },
        "registrationCatalog": len(other_rows),
        "customs": {"rows": len(customs), "uniqueIds": len({r["id"] for r in customs})},
    }
    (OUT / "coverage-summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
