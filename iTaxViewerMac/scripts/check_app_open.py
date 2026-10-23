#!/usr/bin/env python3
"""Check the opt-in app event report, without printing document data."""
import json
import sys
import time
from pathlib import Path

report = Path(sys.argv[1])
fixture = sys.argv[2]
for _ in range(150):
    try:
        events = json.loads(report.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        events = []
    stages = {event["stage"] for event in events if event["file"] == fixture}
    if stages & {"open-failed", "webview-failed"}:
        raise SystemExit("FAIL app file-open or WebKit load")
    if {"opened", "webview-loaded"} <= stages:
        print("PASS LaunchServices file-open and app WebKit load")
        raise SystemExit(0)
    time.sleep(0.1)
raise SystemExit("FAIL app file-open report timed out")
