#!/usr/bin/env python3
"""Fail CI when public-repository safety rules are violated.

The checker intentionally reports only a category and file path. It never prints
matched values, XML content, or candidate secrets.
"""

from __future__ import annotations

import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SELF = Path(__file__).resolve()

FORBIDDEN_PREFIXES = (
    "_re/",
    "realdata to test/",
    "samples/",
    "external-fixtures/",
    "itax-samples/",
)
FORBIDDEN_NAMES = {
    ".env",
    ".npmrc",
    ".pypirc",
    "credentials",
    "credentials.json",
    "id_rsa",
    "id_ed25519",
}
FORBIDDEN_SUFFIXES = (
    ".local.xml",
    ".pem",
    ".key",
    ".p12",
    ".pfx",
    ".mobileprovision",
)

SECRET_PATTERNS = {
    "private-key": re.compile(rb"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----"),
    "aws-access-key": re.compile(rb"(?:AKIA|ASIA)[0-9A-Z]{16}"),
    "github-token": re.compile(
        rb"(?:github_pat_[0-9A-Za-z_]{50,}|gh[pousr]_[0-9A-Za-z]{30,})"
    ),
    "google-api-key": re.compile(rb"AIza[0-9A-Za-z_-]{30,}"),
    "slack-token": re.compile(rb"xox[baprs]-[0-9A-Za-z-]{10,}"),
    "stripe-live-key": re.compile(rb"sk_live_[0-9A-Za-z]{12,}"),
}

ABSOLUTE_HOME_PATTERNS = (
    re.compile(rb"/Users/[^/\s]+/"),
    re.compile(rb"/home/[^/\s]+/"),
    re.compile(rb"[A-Za-z]:\\Users\\[^\\\s]+\\"),
)

ANONYMIZED_PREFIX = "test-data/anonymized/"
ANON_NAME_TAGS = {
    "TEN_NNOP",
    "TEN_NTHAY",
    "TEN_NHANG_NOP",
    "TEN_NHANG_UNT",
    "TEN_TK_THU",
    "TEN_CQT",
    "TEN_CQTHU",
    "TEN_DBHC_THU",
    "TEN_HUYEN_NNOP",
    "TEN_HUYEN_NTHAY",
    "TEN_KBAC",
    "TEN_TINH_KBAC",
    "TEN_TINH_NNOP",
    "TEN_TINH_NTHAY",
    "TEN_XA_NNOP",
    "tenNNhan",
    "tenCQT",
    "tenDLT",
}
ANON_ADDRESS_TAGS = {"DIACHI_NNOP", "DIACHI_NTHAY", "diaChiNNhan"}
ANON_ZERO_TAGS = {
    "MST_NNOP",
    "MST_NTHAY",
    "maNNhan",
    "STK_NHANG_NOP",
    "STK_THU",
    "TK_KNGHI",
    "SO_TK_TB_QD",
    "ID_TK_KNGHI",
    "hotline",
    "dienThoai",
    "fax",
}
ANON_ID_TAGS = {
    "SO_GNT",
    "SO_CTU",
    "ID_CTU",
    "ID_CTU_CTIET",
    "MA_THAMCHIEU",
    "MAHIEU_CTU",
    "MA_HIEU_KBAC",
    "VAN_ID",
    "soTBao",
    "maGiaoDichDTu",
    "maDVC",
    "maDinhDanh",
}


def tracked_and_new_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        check=True,
        stdout=subprocess.PIPE,
    )
    return sorted(
        item.decode("utf-8", errors="surrogateescape")
        for item in result.stdout.split(b"\0")
        if item
    )


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def is_all_zero(value: str) -> bool:
    compact = re.sub(r"[\s.()-]", "", value)
    return bool(compact) and set(compact) == {"0"}


def audit_anonymized_xml(relative: str, path: Path, findings: list[tuple[str, str]]) -> None:
    try:
        root = ET.parse(path).getroot()
    except (ET.ParseError, OSError):
        findings.append(("anonymized-xml-unreadable", relative))
        return

    for element in root.iter():
        tag = local_name(element.tag)
        value = (element.text or "").strip()
        if not value:
            continue
        if tag == "Signature":
            findings.append(("signature-in-anonymized-fixture", relative))
        elif tag in ANON_NAME_TAGS | ANON_ADDRESS_TAGS and "MẪU" not in value.upper():
            findings.append((f"anonymization-marker-missing:{tag}", relative))
        elif tag in ANON_ZERO_TAGS and not is_all_zero(value):
            findings.append((f"anonymized-identifier-not-zero:{tag}", relative))
        elif tag in ANON_ID_TAGS and not value.startswith("MAU-"):
            findings.append((f"anonymized-id-marker-missing:{tag}", relative))
        elif tag.lower() == "email" and not value.lower().endswith("@example.com"):
            findings.append(("anonymized-email-domain", relative))
        elif tag.lower() == "duongdan" and value != "https://example.invalid":
            findings.append(("anonymized-url-domain", relative))


def main() -> int:
    findings: list[tuple[str, str]] = []
    files = tracked_and_new_files()

    for relative in files:
        normalized = relative.replace("\\", "/")
        path = ROOT / relative
        lower_name = path.name.lower()

        if normalized.startswith(FORBIDDEN_PREFIXES):
            findings.append(("forbidden-local-data-path", relative))
        if lower_name in FORBIDDEN_NAMES or lower_name.startswith(".env."):
            findings.append(("forbidden-credential-filename", relative))
        if lower_name.endswith(FORBIDDEN_SUFFIXES):
            findings.append(("forbidden-sensitive-suffix", relative))
        if not path.is_file():
            continue

        try:
            data = path.read_bytes()
        except OSError:
            findings.append(("unreadable-file", relative))
            continue

        for category, pattern in SECRET_PATTERNS.items():
            if pattern.search(data):
                findings.append((category, relative))

        # Skip user-home checks in binary files. UTF-16 XML is decoded separately
        # by its tests and must not cause binary garbage in CI output.
        if path.resolve() != SELF and b"\0" not in data:
            for pattern in ABSOLUTE_HOME_PATTERNS:
                if pattern.search(data):
                    findings.append(("absolute-user-home-path", relative))
                    break

        if normalized.startswith(ANONYMIZED_PREFIX) and lower_name.endswith(".xml"):
            audit_anonymized_xml(relative, path, findings)

    entitlements = ROOT / "iTaxViewerMac/scripts/iTaxViewerMac.entitlements"
    if entitlements.exists() and b"com.apple.security.network" in entitlements.read_bytes():
        findings.append(("network-entitlement", str(entitlements.relative_to(ROOT))))

    unique_findings = sorted(set(findings))
    if unique_findings:
        print("PUBLIC SAFETY CHECK FAILED")
        for category, relative in unique_findings:
            print(f"- {category}: {relative}")
        print("Matched values are intentionally omitted.")
        return 1

    print(f"PUBLIC SAFETY PASS: scanned {len(files)} tracked/new non-ignored files")
    print("No high-confidence secret, private-key, local-data path or anonymization violation found.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
