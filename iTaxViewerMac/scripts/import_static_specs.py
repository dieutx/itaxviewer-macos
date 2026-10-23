#!/usr/bin/env python3
"""Import reviewed factual specs; never import or execute vendor assets."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RES = ROOT / "iTaxViewerMac/Sources/iTaxViewerCore/Resources"
CODES = ("864", "395", "07", "847")


def main():
    spec_path = RES / "form-specs.json"
    registry_path = RES / "form-registry.json"
    specs = json.loads(spec_path.read_text(encoding="utf-8"))
    registry = json.loads(registry_path.read_text(encoding="utf-8"))
    specs = [s for s in specs if s["maTKhai"] not in CODES]
    registry["supported"] = [s for s in registry["supported"] if s["maTKhai"] not in CODES]
    for code in CODES:
        path = ROOT / "docs/reverse-engineering/forms" / code / "spec.json"
        spec = json.loads(path.read_text(encoding="utf-8-sig"))
        assert spec["maTKhai"] == code
        assert spec["sourceEvidence"]["sha256"] and spec["verificationStatus"]
        assert set(spec["versions"]) <= set(registry["codes"][code]["versions"])
        specs.append(spec)
        registry["supported"].append({
            "displayCode": spec["displayCode"], "maTKhai": code, "versions": spec["versions"],
            "spec": code, "orientation": registry["codes"][code]["orientation"], "title": spec["displayCode"],
        })
    spec_path.write_text(json.dumps(specs, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    registry_path.write_text(json.dumps(registry, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"Imported {len(CODES)} reviewed, version-bound static specs; {len(specs)} layouts total")


if __name__ == "__main__":
    main()
