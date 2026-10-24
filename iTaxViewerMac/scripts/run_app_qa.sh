#!/bin/bash
# Run from iTaxViewerMac. Only bundled synthetic/anonymised fixtures are opened.
set -euo pipefail
APP="$PWD/build/iTaxViewerMac.app"
APP_PID=""
trap 'if [[ -n "$APP_PID" ]]; then kill "$APP_PID" 2>/dev/null || true; fi' EXIT
mkdir -p "$PWD/build/native-qa"
OPEN_REPORT="$PWD/build/native-qa/app-open-report.json"
open -n "$APP" --args --qa-open-report "$OPEN_REPORT"
for attempt in {1..10}; do
  for candidate in $(pgrep -x iTaxViewerMac || true); do
    if [[ "$(ps -p "$candidate" -o comm=)" == "$APP/Contents/MacOS/iTaxViewerMac" ]]; then
      APP_PID="$candidate"
      break
    fi
  done
  [[ -n "$APP_PID" ]] && break
  sleep 1
done
[[ -n "$APP_PID" ]] || { echo "App process did not launch" >&2; exit 1; }
sleep 3
kill -0 "$APP_PID"
for fixture in "$PWD"/Tests/iTaxViewerCoreTests/Fixtures/*.xml; do
  name="$(basename "$fixture")"
  [[ "$name" == "xxe_attack.xml" ]] && continue
  open -a "$APP" "$fixture"
  python3 scripts/check_app_open.py "$OPEN_REPORT" "$name"
done
echo "Native app bundle loaded every safe fixture; Finder gestures and drag/drop remain manual checks."
