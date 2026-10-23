#!/usr/bin/env python3
"""Kiem ke ban cai iTax Viewer (Windows) thanh du lieu may doc: hash, co, PE, JRE, certstore.

Chi doc ban cai va ghi vao workspace phan tich `_re/` (da gitignore) + mot JSON tom tat.
Khong copy asset cua vendor vao repo.

Dung:
    python3 inventory_install.py --install "C:/Program Files (x86)/iTax Viewer" \
        --out _re/inventory
"""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

SKIP_HASH_DIRS = {"jre"}  # JRE cua vendor: chi dem, khong hash tung file
HASH_LIMIT = 8 * 1024 * 1024


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def pe_info(path: Path) -> dict:
    data = path.read_bytes()[:4096]
    if data[:2] != b"MZ":
        return {"format": "not-pe", "magic": data[:2].hex()}
    offset = struct.unpack_from("<I", data, 0x3C)[0]
    if data[offset : offset + 4] != b"PE\x00\x00":
        return {"format": "mz-only", "peOffset": offset}
    machine = struct.unpack_from("<H", data, offset + 4)[0]
    subsystems = struct.unpack_from("<H", data, offset + 4 + 24 + 68)[0]
    return {
        "format": "pe",
        "machine": hex(machine),
        "machineName": {0x14C: "i386", 0x8664: "x86_64", 0xAA64: "arm64"}.get(machine, "unknown"),
        "subsystem": subsystems,
        "peOffset": offset,
    }


def ascii_strings(path: Path, minimum: int = 6, limit: int = 60) -> list[str]:
    data = path.read_bytes()
    found, current = [], bytearray()
    for byte in data:
        if 32 <= byte < 127:
            current.append(byte)
        else:
            if len(current) >= minimum:
                found.append(current.decode("ascii"))
                if len(found) >= limit:
                    break
            current.clear()
    return found


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--install", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    root: Path = args.install
    if not root.is_dir():
        print(f"không thấy bản cài: {root}")
        return 2
    args.out.mkdir(parents=True, exist_ok=True)

    rows: list[dict] = []
    per_dir: Counter = Counter()
    per_ext: Counter = Counter()
    sizes: defaultdict[str, int] = defaultdict(int)
    for path in sorted(root.rglob("*")):
        if not path.is_file():
            continue
        relative = path.relative_to(root)
        top = relative.parts[0]
        per_dir[top] += 1
        per_ext[path.suffix.lower() or "(none)"] += 1
        sizes[top] += path.stat().st_size
        hashed = ""
        if top not in SKIP_HASH_DIRS and path.stat().st_size <= HASH_LIMIT:
            hashed = sha256(path)
        rows.append(
            {
                "path": str(relative).replace("\\", "/"),
                "size": path.stat().st_size,
                "sha256": hashed,
            }
        )
    with (args.out / "files.csv").open("w", encoding="utf-8", newline="") as handle:
        handle.write("path,size,sha256\n")
        for row in rows:
            handle.write(f"{row['path']},{row['size']},{row['sha256']}\n")

    exe = root / "iTaxViewer.exe"
    jre_release = root / "jre" / "release"
    jre = {}
    if jre_release.is_file():
        for line in jre_release.read_text(encoding="utf-8", errors="replace").splitlines():
            if "=" in line:
                key, _, value = line.partition("=")
                jre[key.strip()] = value.strip().strip('"')
    summary = {
        "installRoot": str(root),
        "totalFiles": len(rows),
        "totalBytes": sum(sizes.values()),
        "bytesByDir": dict(sorted(sizes.items(), key=lambda kv: -kv[1])),
        "filesByDir": dict(sorted(per_dir.items(), key=lambda kv: -kv[1])),
        "filesByExtension": dict(per_ext.most_common(20)),
        "jre": {k: jre.get(k) for k in ("JAVA_VERSION", "OS_ARCH")},
        "certstore": {
            group: len(list((root / "certstore" / group).glob("*")))
            for group in ("root", "trust", "trust_bk")
            if (root / "certstore" / group).is_dir()
        },
        "exe": pe_info(exe) if exe.is_file() else None,
        "exeStrings": ascii_strings(exe, limit=40) if exe.is_file() else [],
        "keyHashes": {
            row["path"]: row["sha256"]
            for row in rows
            if row["path"]
            in {
                "iTaxViewer.exe",
                "itaxviewer.jar",
                "data/js/common.js",
                "data/css/ihtkk.css",
                "data/css/ihtkk_ntdt.css",
                "update/latest.xml",
                "update/updater.jar",
            }
        },
    }
    (args.out / "summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(json.dumps({k: summary[k] for k in ("totalFiles", "totalBytes", "jre", "certstore", "exe")}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
