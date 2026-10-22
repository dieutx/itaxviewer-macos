# macOS Handoff

This repository was prepared on a Windows analysis machine. The Windows iTax Viewer was
decompiled and captured; the Swift app was written but **not compiled**. Follow this document
on macOS to turn the source into a tested `.app`.

## 1. Prerequisites

- macOS 13+ (Ventura/Sonoma/Sequoia)
- Xcode 15 or later (full Xcode, not only Command Line Tools)
- Swift 5.9+
- Python 3.10+ (validation harness)

Verify:

```bash
xcodebuild -version
swift --version
python3 --version
```

If `xcode-select -p` does not point at `/Applications/Xcode.app/Contents/Developer`:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## 2. First build and tests

```bash
cd iTaxViewerMac
swift test 2>&1 | tee /tmp/itax-tests.log
```

Expected: 33 XCTest methods pass. If compilation fails, fix the code, never delete or weaken
assertions. Likely hotspots are listed in `AGENTS.md`.

Then:

```bash
python3 scripts/validate_fixtures.py
```

Expected:

```
01/GTGT      PASS
05/KK-TNCN   PASS
05/QTT-TNCN  PASS
03/TNDN      PASS
ALL CHECKS PASSED
```

## 3. Build the app

```bash
chmod +x scripts/build_app.sh
scripts/build_app.sh --universal
open build/iTaxViewerMac.app
```

The bundle contains:

```
iTaxViewerMac.app/Contents/MacOS/iTaxViewerMac
iTaxViewerMac.app/Contents/Info.plist
iTaxViewerMac.app/Contents/Resources/iTaxViewerMac_iTaxViewerCore.bundle
```

If the app launches with an empty document list and no resources, verify the resource bundle
name and that `Bundle.module` resolves from `Contents/Resources`.

## 4. Functional checks

1. `⌘O` → open every fixture in `Tests/iTaxViewerCoreTests/Fixtures/`.
2. Drag a fixture onto the window.
3. Double-click a fixture in Finder after “Open With → iTax Viewer for macOS → Always”.
4. Check: form code, title, taxpayer name/MST, period, filing type, all indicator values.
5. Zoom `⌘+` / `⌘−` / `⌘0`.
6. `⌘P` → print panel; save as PDF.
7. `⌘S` → export PDF; verify all values and no clipped pages.
8. `⌘I` → document info; `⇧⌘Y` → signature sheet (must say “Chưa xác minh”).

## 4b. Testing with a folder of real/local tax files

Do **not** commit real taxpayer XML. Keep the folder outside the repo, for example
`~/itax-samples/`, and run:

```bash
cd iTaxViewerMac

# classification report for every file in the folder (no taxpayer values printed)
python3 scripts/validate_directory.py ~/itax-samples

# optional machine-readable report
python3 scripts/validate_directory.py ~/itax-samples --json ~/itax-report.json

# integration test through the real Swift core
ITAX_FIXTURE_DIR=~/itax-samples swift test --filter ExternalFixturesTests
```

Then open files from that folder directly in the app (`⌘O` or drag-and-drop).
If a file fails, add only an **anonymised** minimal reproduction to
`Tests/iTaxViewerCoreTests/Fixtures/` (MST `0000000000`, fictitious names, signature removed)
and reference it in `COMPATIBILITY.md`.

The directory scanner skips any file containing `DOCTYPE`/`ENTITY` (same policy as the app).

## 5. Visual comparison against the original

Reference captures (Windows iTax Viewer, same fixtures):

```
docs/reverse-engineering/evidence/reference-gtgt.png
docs/reverse-engineering/evidence/reference-tncn-05kk.png
docs/reverse-engineering/evidence/reference-tncn-05qtt.png
docs/reverse-engineering/evidence/reference-tndn-03.png
```

Compare:

- national header, form-code box, title, scope note;
- per-form header numbering (documented in `HTMLRenderer.headerFields` and
  `docs/reverse-engineering/template-engine.md`);
- table columns, section rows, bold/indentation;
- number formats (`1.000.000.000`, `(1.000)`, `10,5`);
- page breaks and A4 orientation.

Record discrepancies in `COMPATIBILITY.md` with a screenshot and a root-cause note.

### Known intentional differences

- Original uppercases with XSLT `translate()`, corrupting some Vietnamese diacritics; this app
  uses correct Unicode.
- Original crashes on an unmapped `<PLuc>` appendix; this app renders the data.
- Footer page numbers are not implemented (WebKit limitation).
- 01/GTGT `[11a]–[11c]` render on three stacked rows instead of one three-column row.
- Notices, vouchers, BCTC, registration, customs and the other 406 codes use a structured
  data view, not the official layout.

## 6. Remaining implementation work (prioritised)

1. **P1** — fix any visual/data mismatches found above.
2. **P3** — add specs for:
   - `864` 05/KK-TNCN under TT 80/2021 (indicators `[16]–[32]`)
   - `395` legacy 05/QTT
   - `2002`/`2003`/`2004` TT 89/2025 CIT layouts
   - `701`/`1254` B01/BCTC, `702` B05/BCTC
   - official `PLuc` appendix layouts
   - notice prose templates (e.g. `107` / 01/TB-BSTT)
3. **P4** — real XMLDSig verification:
   - XML C14N 1.0/1.1 over the referenced subtree;
   - digest check (SHA-1/256/512);
   - `SecKeyVerifySignature` over `SignedInfo`;
   - chain evaluation with `SecTrust`, explicit offline revocation status;
   - only then introduce a “valid” state.
4. **P5** — App Sandbox + hardened runtime + Developer ID signing + notarization + DMG.

## 7. Signing and notarization

```bash
# add sandbox/read-only entitlement when distributing
codesign --force --options runtime \
  --entitlements scripts/iTaxViewerMac.entitlements \
  --sign "Developer ID Application: NAME (TEAMID)" \
  build/iTaxViewerMac.app

ditto -c -k --keepParent build/iTaxViewerMac.app /tmp/iTaxViewerMac.zip
xcrun notarytool submit /tmp/iTaxViewerMac.zip \
  --apple-id "you@example.com" --team-id TEAMID \
  --password "app-specific-password" --wait
xcrun stapler staple build/iTaxViewerMac.app
```

The current build is ad-hoc signed and not notarized. Do not claim otherwise.

## 8. Updating the compatibility matrix

Edit `COMPATIBILITY.md` only with executed evidence:

- run `swift test` and paste the real result;
- run each fixture through the app and record visual/mapping results;
- attach new screenshots under `docs/reverse-engineering/evidence/`;
- replace “PENDING” with the actual command/date/result;
- keep unresolved gaps explicit.

## 9. What not to commit

- `_re/` (decompiled vendor code, extracted templates)
- `iTaxViewerMac/build/`, `.build/`
- real taxpayer XML or PDFs
- certificates/private keys
