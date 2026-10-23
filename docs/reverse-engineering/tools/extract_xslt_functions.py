#!/usr/bin/env python3
"""Kiem ke cac ham JScript nam trong <msxsl:script> cua XSLT iTax Viewer.

iTax Viewer dinh dang so/ky/chu bang JScript nhung trong XSLT (`common.xsl`...), khong
phai bang Java. Muon clone dung thi phai biet day du cac ham nay va version nao dung ban nao.

Script chi ghi *ten ham + chu ky + hash + noi dung* ra workspace phan tich `_re/`
(da gitignore). Trong repo chi ghi danh muc (ten, so tham so, so version, hash).

Dung:
    python3 extract_xslt_functions.py --xslt-root "C:/.../data/xslt" \
        --out docs/reverse-engineering/render-semantics \
        --bodies _re/js-functions
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

FUNCTION = re.compile(r"function\s+([A-Za-z_$][\w$]*)\s*\(([^)]*)\)\s*\{")
MSXSL = re.compile(r"<msxsl:script[^>]*>(.*?)</msxsl:script>", re.DOTALL | re.IGNORECASE)
ENTITY = re.compile(r"&(?:#(\d+)|#x([0-9a-fA-F]+)|([a-zA-Z]+));")


def unescape(text: str) -> str:
    named = {"amp": "&", "lt": "<", "gt": ">", "quot": '"', "apos": "'", "nbsp": " "}

    def repl(match: re.Match) -> str:
        if match.group(1):
            return chr(int(match.group(1)))
        if match.group(2):
            return chr(int(match.group(2), 16))
        return named.get(match.group(3), match.group(0))

    return ENTITY.sub(repl, text)


def body_at(text: str, start: int) -> str:
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return text[start : index + 1]
    return text[start:]


def read(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16", errors="replace")
    return raw.decode("utf-8", errors="replace")


def version_of(path: Path, root: Path) -> str:
    for part in path.relative_to(root).parts:
        match = re.match(r"^XSLT\s+(\d+(?:\.\d+)*)$", part, re.IGNORECASE)
        if match:
            return match.group(1)
    return "default"


def main() -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    parser = argparse.ArgumentParser()
    parser.add_argument("--xslt-root", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--bodies", required=True, type=Path)
    args = parser.parse_args()

    files_with_scripts = 0
    variants: dict[tuple[str, str], set[str]] = defaultdict(set)  # (name, hash) -> versions
    bodies: dict[str, str] = {}
    signatures: dict[str, tuple[str, int]] = {}
    scripts_per_file: dict[str, int] = {}
    for path in sorted(args.xslt_root.rglob("*.xsl*")):
        text = unescape(read(path))
        blocks = MSXSL.findall(text)
        if not blocks:
            continue
        files_with_scripts += 1
        script = "\n".join(blocks)
        found = 0
        for match in FUNCTION.finditer(script):
            name, params = match.group(1), match.group(2)
            body = body_at(script, match.end() - 1)
            digest = hashlib.sha256(body.encode("utf-8")).hexdigest()[:16]
            found += 1
            variants[(name, digest)].add(version_of(path, args.xslt_root))
            signatures.setdefault(name, (params.strip(), len(params.split(",")) if params.strip() else 0))
            bodies.setdefault(digest, f"// {name} ({params.strip()})\n{body}\n")
        if found:
            scripts_per_file[str(path.relative_to(args.xslt_root))] = found

    args.bodies.mkdir(parents=True, exist_ok=True)
    for digest, body in bodies.items():
        (args.bodies / f"{digest}.js").write_text(body, encoding="utf-8")

    functions: dict[str, dict] = {}
    for (name, digest), versions in variants.items():
        functions.setdefault(name, {"name": name, "signature": signatures[name][0], "arity": signatures[name][1], "variants": []})
        functions[name]["variants"].append(
            {"hash": digest, "versions": sorted(v for v in versions), "versionCount": len(versions)}
        )
    for value in functions.values():
        value["variants"].sort(key=lambda v: -v["versionCount"])

    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "functions.json").write_text(
        json.dumps(sorted(functions.values(), key=lambda f: f["name"]), ensure_ascii=False, indent=1),
        encoding="utf-8",
    )
    summary = {
        "xsltFilesScanned": len(list(args.xslt_root.rglob("*.xsl*"))),
        "filesWithMsxslScript": files_with_scripts,
        "distinctFunctionNames": len(functions),
        "distinctBodies": len(bodies),
        "functions": {
            name: {"arity": value["arity"], "variants": len(value["variants"])}
            for name, value in sorted(functions.items())
        },
    }
    (args.out / "functions-summary.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=1), encoding="utf-8"
    )
    print(json.dumps({k: v for k, v in summary.items() if k != "functions"}, ensure_ascii=False))
    for name, info in summary["functions"].items():
        print(f"  {name}({info['arity']} tham số) — {info['variants']} biến thể")
    print(f"nội dung JS: {args.bodies} ({len(bodies)} file)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
