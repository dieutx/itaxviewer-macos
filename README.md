# iTax Viewer for macOS

An independent, native macOS viewer for Vietnamese tax XML documents (hồ sơ thuế XML),
built from black-box reverse engineering of the official Windows **iTax Viewer**.

* Opens `.xml` files from Finder, drag-and-drop, or `⌘O`
* Classifies declarations, notices and payment vouchers using the official registry rules
* Renders four priority forms with their real Vietnamese layout and indicator tables
* Prints with the native macOS print panel and exports multi-page PDF
* Shows digital-signature and certificate metadata without ever claiming an unverified
  document is valid
* Notifies you when a newer release is published (checks once a day; no document data is
  ever sent) and opens the release page
* Fully offline for document processing; no login, telemetry or cloud processing

> This is **not** an official product of the Vietnamese tax authority (Tổng cục Thuế /
> GDT). It is an independent interoperability project. No assets from the original
> application are redistributed.

---

## Supported documents

| Form | Internal code | Verified XML versions | Rendering |
|---|---|---|---|
| **01/GTGT** – VAT declaration | `842` (legacy `01`) | 2.5.1, 2.6.8, 2.7.4, 2.8.3 | Full (27 rows) |
| **05/KK-TNCN** – PIT withholding | `394` (legacy `42`, `864`) | 2.1.6 | Full (16 rows) |
| **05/QTT-TNCN** – PIT finalisation | `953` (legacy `395`) | 2.5.x – 2.9.3 | Full (26 rows) |
| **03/TNDN** – CIT finalisation | `892` (legacy `03`) | 2.5.1 – 2.9.4 | Full (74 rows) |
| **01/GTGT VAT-reduction appendices** | `PL_NQ43_GTGT`, `PL_NQ101_GTGT`, `PL_NQ142_GTGT` | any | Full appendix layout (I/II/III + totals) |
| Notices (`TBaoThueDTu`, `THONGBAO`, …) | — | any | Structured data view |
| Payment vouchers (`CHUNGTU`) | `MA_CTU` | any | Structured data view |
| Registration, catalogs, customs, e-invoice | — | any | Structured data view |
| All other 406 declaration codes | — | any | Structured data view + explicit warning |

The registry shipped with the app contains **410 form codes / 244 display codes** extracted
from the installed `DMucTKhai.xml` (1,150 entries). See
[`docs/reverse-engineering/document-types.md`](docs/reverse-engineering/document-types.md).

**Known coverage gaps:** newer versions that use a different indicator numbering are not yet
mapped to a dedicated layout — notably `864` (05/KK-TNCN under TT 80/2021, indicators
`[16]–[32]`), legacy `395` (05/QTT), and the TT 89/2025 CIT forms (`2002`/`2003`/`2004`).
Those files open in the structured data view with all values and an explicit warning; they
are never mis-labelled as fully rendered.

## Requirements

* macOS **13 Ventura** or later
* Xcode 15+ / Swift 5.9 toolchain (only to build)
* Apple Silicon or Intel (universal build supported)

## Build

```bash
cd iTaxViewerMac
chmod +x scripts/build_app.sh

# development build (ad-hoc signed, not notarized)
scripts/build_app.sh

# universal binary + DMG
scripts/build_app.sh --universal --dmg
```

The bundle is produced at `iTaxViewerMac/build/iTaxViewerMac.app`.

From Windows, use the committed code on a macOS GitHub Actions runner:

```powershell
powershell -File iTaxViewerMac/scripts/Build-MacOS.ps1 -Ref main
```

This downloads a universal ZIP, DMG and SHA-256 manifest into `iTaxViewerMac/build/downloads`.
The helper uploads no local XML. Windows cannot compile AppKit/SwiftUI for macOS locally.
The viewer itself has no network entitlement and does not check for updates.

The new version-bound layouts are `864` (2.9.3), `395` (2.4.2), `07` (2.4.1/2.5.0)
and `847` (2.5.1/2.6.8/2.7.4). Standard TT80 `01/KHBS` and `01-1/KHBS` appendices
also have dedicated layouts for the exact parent versions in the bundled mapping.
These are independently recreated from traceable field facts; Windows visual and
pagination comparison remains pending. Unmapped versions retain the structured view.

Open it with:

```bash
open build/iTaxViewerMac.app
```

Or open `Package.swift` in Xcode and run the `iTaxViewerMac` scheme (the app bundle script
adds `Info.plist`, document types and the resource bundle).

### Code signing and notarization

Signing credentials are **not** included. For distribution:

```bash
scripts/build_app.sh --universal --sign "Developer ID Application: YOUR NAME (TEAMID)"
xcrun notarytool submit build/iTaxViewerMac-unsigned.dmg \
  --apple-id "you@example.com" --team-id TEAMID --password "app-specific-password" --wait
xcrun stapler staple build/iTaxViewerMac.app
```

The default build is unsigned/ad-hoc and will show Gatekeeper warnings.

### Publishing a release (enables the in-app update notice)

The app checks `https://api.github.com/repos/dieutx/itaxviewer-macos/releases/latest`
once per day and shows a banner when the published tag is newer than
`CFBundleShortVersionString` in `scripts/Info.plist`. Only the app version is sent
(`User-Agent`); no document data or identifiers leave the machine. Users can disable the
check under the application menu.

For the notice to appear, publish a **GitHub Release** (a plain tag is not enough):

1. Bump `CFBundleShortVersionString`/`CFBundleVersion` in `iTaxViewerMac/scripts/Info.plist`.
2. Build and sign the app.
3. Create a release with a semver tag such as `v1.0.1` and attach the DMG.

The banner opens the release page; it never downloads or executes code automatically.

## Tests

### Swift unit tests (run on macOS)

```bash
cd iTaxViewerMac
swift test
```

Covers: secure parsing (UTF-8/UTF-16, XXE rejection), registry resolution, classification,
HTML rendering, number/date formatting, signature metadata, CSP/script absence.

### Cross-platform field-mapping harness (runs anywhere)

```bash
python3 iTaxViewerMac/scripts/validate_fixtures.py
```

This mirrors the Swift registry lookup and XPath field mapping and asserts the exact
official indicator values for every fixture. It passes for all four priority forms, the
payment voucher and the notice fixture.

The Swift suite was executed on macOS 15 (Xcode 16.1 / Swift 6.0.2): **45 tests, 44 passed,
1 skipped** (the optional external-fixture test). See
[`COMPATIBILITY.md`](COMPATIBILITY.md) for the executed UI/print results.

### Bundled test data

`test-data/` contains:

* four synthetic declarations (01/GTGT, 05/KK-TNCN, 05/QTT-TNCN, 03/TNDN);
* three **anonymised** real-structure payment vouchers;
* two **anonymised** real-structure tax-authority notices.

See [`test-data/README.md`](test-data/README.md) for exactly what was redacted. The source
files were never committed.

```bash
python3 iTaxViewerMac/scripts/validate_directory.py test-data
ITAX_FIXTURE_DIR=test-data swift test --filter ExternalFixturesTests
```

### Testing a whole folder of real files without uploading them

```bash
# keep real samples outside the repo, e.g. ~/itax-samples
python3 iTaxViewerMac/scripts/validate_directory.py ~/itax-samples
ITAX_FIXTURE_DIR=~/itax-samples swift test --filter ExternalFixturesTests
```

Only file names, form codes and field counts are printed — never taxpayer names, tax codes,
addresses or values. Real samples must never be committed; `samples/`, `itax-samples/` and
`*.local.xml` are gitignored.

### Reverse-engineering other document types

The remaining layouts (notices, payment vouchers, registration, catalogs, e-invoices,
customs and the rest of the declarations/appendices) have a staged Windows RE plan:

- prompt index: [`docs/PROMPTS/WINDOWS_DOCUMENT_RE.md`](docs/PROMPTS/WINDOWS_DOCUMENT_RE.md)
- stages/types: [`docs/PROMPTS/document-re/`](docs/PROMPTS/document-re/)
- appendices sub-kit: [`docs/PROMPTS/appendix-re/`](docs/PROMPTS/appendix-re/)
- live progress/results:
  [`docs/reverse-engineering/documents/PROGRESS.md`](docs/reverse-engineering/documents/PROGRESS.md)
  and `progress.json`

## Using the app

| Action | Shortcut |
|---|---|
| Open XML | `⌘O` |
| Print | `⌘P` |
| Export PDF | `⌘S` |
| Zoom in / out | `⌘+` / `⌘−` |
| Actual size | `⌘0` |
| Document information | `⌘I` |
| Signature details | `⇧⌘Y` |

Drag one or more `.xml` files onto the window. Recent files are listed in the sidebar;
only their paths are stored locally.

## Architecture

```
iTaxViewerMac/
├── Package.swift
├── Sources/
│   ├── iTaxViewerCore/                 (platform-agnostic document logic)
│   │   ├── Model/                      XML tree, TaxDocument, metadata
│   │   ├── XMLParser/                  hardened Foundation XMLParser loader
│   │   ├── DocumentClassifier/         registry + root/code classification
│   │   ├── Rendering/                  form specs, HTML/CSS, Vietnamese formats
│   │   ├── SignatureVerification/      XMLDSig metadata + X.509 facts
│   │   └── Resources/
│   │       ├── form-registry.json      410 codes, 4 verified specs
│   │       └── form-specs.json         official indicators + labels + XPath
│   └── iTaxViewerMac/                  (SwiftUI/AppKit app)
│       ├── App/                        app entry, model, commands
│       └── Features/                   sidebar, viewer, print/export, signatures
├── Tests/                              XCTest + anonymised fixtures
├── scripts/                            build_app.sh, Info.plist, validation harness
└── docs/
```

Design decisions and recovered behaviour:
[`docs/reverse-engineering/`](docs/reverse-engineering/).

## Security

* DOCTYPE/ENTITY is rejected before parsing; external entities are disabled; size/depth/node
  limits are enforced.
* WKWebView JavaScript is disabled, navigation is blocked, the data store is non-persistent,
  and the generated HTML has a `default-src 'none'` CSP with no remote URLs.
* Documents are never uploaded or logged; recent-file storage contains paths only.
* XML signatures are **not cryptographically verified**. The UI always shows
  “Chưa xác minh (Not verified)” and explains why. See
  [`docs/reverse-engineering/signature-verification.md`](docs/reverse-engineering/signature-verification.md).

## Licence / assets

The application source in this repository is original work. The official Windows
application ships without a licence file, so **no XSLT, CSS, font, image or icon from it is
bundled here**. Form specs contain factual field identifiers and official Vietnamese form
labels recovered for interoperability. Tax form layouts themselves are official government
forms.

## Acknowledgements

Reverse engineering was performed with CFR 0.152 on the installed JAR, static analysis of
2,163 XSLT templates, XML registry parsing and live reference captures of the Windows
application (see `docs/reverse-engineering/evidence/`).
