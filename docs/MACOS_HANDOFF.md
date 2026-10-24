# macOS Handoff

This repository was prepared on a Windows analysis machine. On 2026-10-24 macOS Actions
ran 99 tests (98 passed, one optional skip) on arm64 and Intel, launched the same universal
bundle with all 29 safe fixtures on both architectures, and exported 29 native PDFs / 55
A4 pages per runner. Full-document export also resets an inherited partial-page print job.
See `COMPATIBILITY.md` for exact runs, the visual review and remaining limitations.
Follow this document on a local Mac to repeat checks and finish manual interaction/visual QA.

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

Use the current test count in `COMPATIBILITY.md`. If compilation fails, fix the code, never delete or weaken
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
- Captured notice/voucher revisions and the reviewed new declaration/KHBS revisions have
  dedicated layouts; other codes/versions retain structured data. Consult the current matrix.

## 6. Remaining implementation work (prioritised)

1. **P1** — fix any visual/data mismatches found above.
2. **P3** — add specs for:
   - earlier revisions of `864` and `395` (newest reviewed revisions have dedicated layouts)
   - other revisions of `2002`/`2003`/`2004` (3.0.9 now has reviewed TT89 layouts)
   - other BCTC variants (`701`/`702` 2.3.5 and `1254` 2.9.0 now have reviewed layouts)
   - official `PLuc` appendix layouts
   - remaining notice prose templates (`01/TB-BSTT` is already mapped; `107` is not its notice code)
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
