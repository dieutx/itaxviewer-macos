#!/usr/bin/env python3
"""Bound the complete macOS QA process tree, including Swift's child process."""
import os
import signal
import subprocess
import sys

if sys.platform != "darwin":
    raise SystemExit("Native QA requires macOS")

process = subprocess.Popen(["swift", "run", "iTaxViewerQA"], start_new_session=True)
try:
    raise SystemExit(process.wait(timeout=180))
except subprocess.TimeoutExpired:
    print("FAIL native-qa process timeout", flush=True)
    os.killpg(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
    raise SystemExit(1)
