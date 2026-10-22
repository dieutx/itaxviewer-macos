#!/usr/bin/env python3
"""Create anonymised test samples from real GNT / tax-authority notices.

Redacts taxpayer identity, tax codes, bank accounts, document IDs, amounts and
signatures while preserving the XML structure needed by the viewer.

    python3 scripts/anonymize_samples.py --input <dir> --output test-data/anonymized

Only anonymised output is meant to be committed. Never commit the input folder.
"""
from __future__ import annotations

import argparse
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

NAME_MAP = {
    "TEN_NNOP": "CÔNG TY MẪU",
    "TEN_NTHAY": "CÔNG TY MẪU",
    "TEN_NHANG_NOP": "NGÂN HÀNG MẪU",
    "TEN_NHANG_UNT": "NGÂN HÀNG MẪU",
    "TEN_TK_THU": "KHO BẠC MẪU",
    "TEN_CQT": "CƠ QUAN THUẾ MẪU",
    "TEN_CQTHU": "CƠ QUAN THUẾ MẪU",
    "TEN_DBHC_THU": "ĐỊA BÀN MẪU",
    "TEN_HUYEN_NNOP": "QUẬN MẪU",
    "TEN_HUYEN_NTHAY": "QUẬN MẪU",
    "TEN_KBAC": "KHO BẠC MẪU",
    "TEN_TINH_KBAC": "TỈNH MẪU",
    "TEN_TINH_NNOP": "TỈNH MẪU",
    "TEN_TINH_NTHAY": "TỈNH MẪU",
    "TEN_XA_NNOP": "PHƯỜNG MẪU",
    "tenNNhan": "CÔNG TY MẪU",
    "tenCQT": "CƠ QUAN THUẾ MẪU",
    "tenDLT": "ĐẠI LÝ THUẾ MẪU",
    "tenLoi": "Nội dung mẫu",
    "tenNhomLoi": "Nhóm lỗi mẫu",
}
ADDRESS_TAGS = {"DIACHI_NNOP", "DIACHI_NTHAY", "diaChiNNhan"}
MST_TAGS = {"MST_NNOP", "MST_NTHAY", "maNNhan"}
ACCOUNT_TAGS = {"STK_NHANG_NOP", "STK_THU", "TK_KNGHI", "SO_TK_TB_QD", "ID_TK_KNGHI"}
AMOUNT_TAGS = {"TIEN_PNOP", "TONG_TIEN", "soTienPNop"}
NOTE_TAGS = {"GHI_CHU", "ghiChu", "huongDanXuLy", "LyDo", "CTietLyDo"}
ID_TAGS = {"SO_GNT", "SO_CTU", "ID_CTU", "ID_CTU_CTIET", "MA_THAMCHIEU", "MAHIEU_CTU",
           "MA_HIEU_KBAC", "VAN_ID", "soTBao", "maGiaoDichDTu", "maDVC", "maDinhDanh"}
CODE_TAGS = {"MA_CHUONG", "MA_CQT", "maCQT", "MA_CQTHU", "MA_DBHC_THU", "MA_HUYEN_NNOP",
             "MA_LOAI_THUE", "MA_NDKT", "MA_NGUYENTE", "MA_TINH_KBAC", "MA_TINH_NNOP",
             "MA_XA_NNOP", "maDLT"}
KEEP_MA = {"maTBao", "maTKhai", "maLoaiTien", "maDVu", "maNhomLoi", "maLoi", "MA_CTU"}


def local(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def register_namespaces(raw: str) -> None:
    for m in re.finditer(r'xmlns(?::([A-Za-z0-9_]+))?="([^"]+)"', raw):
        prefix = m.group(1) or ""
        try:
            ET.register_namespace(prefix, m.group(2))
        except ValueError:
            pass


def remove_signatures(root) -> int:
    parents = {child: parent for parent in root.iter() for child in parent}
    removed = 0
    for el in list(root.iter()):
        if local(el.tag) == "Signature":
            parent = parents.get(el)
            if parent is not None:
                parent.remove(el)
                removed += 1
    return removed


def anonymize(src: Path, dst: Path) -> dict:
    raw = src.read_text(encoding="utf-8")
    register_namespaces(raw)
    tree = ET.parse(src)
    root = tree.getroot()
    removed = remove_signatures(root)

    counter = 0
    changed = set()
    for el in root.iter():
        tag = local(el.tag)
        if el.text is None:
            continue
        value = el.text.strip()
        if not value:
            continue
        if tag in NAME_MAP:
            new = NAME_MAP[tag]
        elif tag in ADDRESS_TAGS:
            new = "Số 1 Đường Mẫu, Phường Mẫu"
        elif tag in MST_TAGS:
            new = "0000000000"
        elif tag in ACCOUNT_TAGS:
            new = "0000000000"
        elif tag in AMOUNT_TAGS:
            new = "1000000"
        elif tag in NOTE_TAGS:
            new = "Nội dung mẫu"
        elif tag in ID_TAGS:
            counter += 1
            new = f"MAU-{counter:06d}"
        elif tag in CODE_TAGS:
            new = "00000"
        elif tag.lower() == "email":
            new = "mau@example.com"
        elif tag.lower() in ("hotline", "dienthoai", "fax"):
            new = "0000000000"
        elif tag.lower() == "duongdan":
            new = "https://example.invalid"
        else:
            continue
        if new != value:
            el.text = (el.text[: len(el.text) - len(el.text.lstrip())]
                                  + new
                                  + el.text[len(el.text.rstrip()):])
            changed.add(tag)

    ET.indent(tree, space="  ")
    dst.parent.mkdir(parents=True, exist_ok=True)
    tree.write(dst, encoding="utf-8", xml_declaration=True)
    return {
        "output": dst.name,
        "root": local(root.tag),
        "signaturesRemoved": removed,
        "redactedTags": sorted(changed),
        "sourceSizeBytes": src.stat().st_size,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True, help="folder with real XML samples")
    ap.add_argument("--output", required=True, help="folder for anonymised output")
    ap.add_argument("--limit", type=int, default=0, help="max files (0 = all)")
    args = ap.parse_args()

    src_dir = Path(args.input)
    out_dir = Path(args.output)
    files = sorted(p for p in src_dir.rglob("*.xml") if p.is_file())
    if args.limit:
        files = files[: args.limit]
    if not files:
        print("No XML files found")
        return 2

    manifest = []
    for src in files:
        dst = out_dir / f"sample-{len(manifest) + 1:02d}.xml"
        info = anonymize(src, dst)
        manifest.append(info)
        print(f"{src.name[:20]}… -> {dst.name} ({info['signaturesRemoved']} signature(s) removed)")

    (out_dir / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(f"\n{len(manifest)} anonymised file(s) in {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

