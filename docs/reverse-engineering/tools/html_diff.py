#!/usr/bin/env python3
"""Compare local HTML cell text, reporting positions/counts without taxpayer values.

This checks text only. It does not establish visual or PDF pagination parity.
"""
import argparse
import json
from html.parser import HTMLParser
from pathlib import Path


def read_html(path):
    data = Path(path).read_bytes()
    return data.decode("utf-16" if data.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig")


class Cells(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.cells = []
        self.active = []

    def handle_starttag(self, tag, attrs):
        if tag in ("td", "th"):
            self.cells.append("")
            self.active.append(len(self.cells) - 1)
        elif tag == "br":
            self.handle_data(" ")

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.active:
            self.active.pop()

    def handle_data(self, data):
        for index in self.active:
            self.cells[index] += data

    def normalized(self):
        return [" ".join(value.split()) for value in self.cells]


def cells(text):
    parser = Cells()
    parser.feed(text)
    return parser.normalized()


def main():
    args = argparse.ArgumentParser(description=__doc__)
    args.add_argument("reference", type=Path)
    args.add_argument("candidate", type=Path)
    options = args.parse_args()
    reference = cells(read_html(options.reference))
    candidate = cells(read_html(options.candidate))
    mismatches = [index for index in range(max(len(reference), len(candidate)))
                  if index >= len(reference) or index >= len(candidate) or reference[index] != candidate[index]]
    print(json.dumps({"referenceCells": len(reference), "candidateCells": len(candidate),
                      "mismatchCount": len(mismatches), "firstMismatchPositions": mismatches[:30]}))
    return int(bool(mismatches))


if __name__ == "__main__":
    raise SystemExit(main())
