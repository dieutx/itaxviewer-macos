# AGENTS.md — instructions for the macOS continuation agent

You are continuing an existing reverse-engineering + native macOS implementation project.
Read this file first, then `docs/MACOS_HANDOFF.md`, `README.md` and `COMPATIBILITY.md`.

## Repository purpose

An independent macOS viewer for Vietnamese tax XML (iTax Viewer compatible behaviour).
The Windows application has already been reverse engineered; the recovered facts are in
`docs/reverse-engineering/`. The Swift/SwiftUI implementation is complete in source form but
**has never been compiled or run**, because the previous environment was Windows without
Xcode/Swift.

## Your first job (in order)

1. `cd iTaxViewerMac && swift test`
2. Fix every compile error and failing test. Do not weaken tests to make them pass.
3. `scripts/build_app.sh` and launch the app.
4. Open every fixture in `Tests/iTaxViewerCoreTests/Fixtures/` and visually compare with
   `docs/reverse-engineering/evidence/reference-*.png`.
5. Print and export PDF for each priority form; check page count and that all values appear.
6. Update `COMPATIBILITY.md` with actual executed results (replace every PENDING).
7. Commit and push with clear messages.

Do not stop at “it builds”. The acceptance criterion is a real macOS user double-clicking a
supported tax XML and getting the correct form, print and PDF.

## Absolute rules

- **Never claim a result you did not execute.** If a Windows comparison is unavailable,
  write “pending”, not “verified”.
- **Never claim a signature is valid.** `SignatureInspector` must keep returning
  `.notVerified` until a real XML C14N + digest + SignatureValue verification exists.
- **Do not copy vendor assets** (XSLT, CSS, fonts, images, icons) from the iTax Viewer
  installation. No licence file accompanies the original. Form specs contain factual
  official field identifiers/labels only.
- **Do not invent field mappings.** Every indicator/label must be traceable to
  `form-specs.json` and `docs/reverse-engineering/document-types.md`.
- **Offline only.** No document upload, telemetry, analytics or network fetch. Do not add a
  network entitlement.
- **Security is non-negotiable:** keep DOCTYPE/ENTITY rejection, external entity disabling,
  size/depth limits, JavaScript disabled in WKWebView, CSP `default-src 'none'`, navigation
  blocking and non-persistent data store.
- **No taxpayer data in logs.** Never print XML content or field values.

## Architecture map

```
iTaxViewerMac/
  Package.swift
  Sources/iTaxViewerCore/
    Model/XMLNode.swift, TaxDocument.swift
    XMLParser/SecureXMLParser.swift
    DocumentClassifier/FormRegistry.swift, DocumentClassifier.swift
    Rendering/VietnameseFormat.swift, HTMLRenderer.swift
    SignatureVerification/SignatureInspector.swift
    Resources/form-registry.json, form-specs.json
  Sources/iTaxViewerMac/
    App/ (entry, AppModel, AppDelegate, commands)
    Features/FileBrowser, DocumentViewer, PrintExport, SignatureInspector
  Tests/iTaxViewerCoreTests/ (33 tests + 9 fixtures)
  scripts/build_app.sh, validate_fixtures.py, Info.plist
```

## Commands

```bash
cd iTaxViewerMac
swift test
python3 scripts/validate_fixtures.py
scripts/build_app.sh --universal
open build/iTaxViewerMac.app
```

## Priorities after the build is green

| Priority | Task |
|---|---|
| P0 | Compile + all XCTest green; app bundle launches; file-open and drag-drop work |
| P1 | Visual parity for 01/GTGT, 05/KK-TNCN, 05/QTT-TNCN, 03/TNDN vs reference screenshots |
| P2 | Print and PDF export verified (values, pagination, A4 portrait/margins) |
| P3 | Add full specs for 864 (05/KK TT80), 395, BCTC, notices; official appendix layouts |
| P4 | Full XMLDSig verification (C14N + digest + RSA/ECDSA) and offline trust policy |
| P5 | Sandboxed, signed, notarized universal DMG |

## Likely first-pass compile risks to check

- `SecCertificateCopyValues` / `CFDictionary → NSDictionary` bridging in
  `SignatureInspector.swift`.
- `NSPrintInfo.AttributeKey.jobSavingURL` spelling and `NSMutableDictionary` subscript in
  `PrintExportService.swift`.
- SwiftPM resource bundle discovery (`Bundle.module`) after `build_app.sh` copies the
  `.bundle` into `Contents/Resources`.
- Main-actor isolation warnings in `AppModel` / `@StateObject` initialization (Swift 5 mode
  should accept them; fix with `@MainActor` if the toolchain is stricter).
- `Grid` / `GridRow` APIs require macOS 13 — deployment target is already 13.

## Definition of done

- `swift test` passes on macOS.
- `build/iTaxViewerMac.app` runs natively on arm64 and x86_64.
- Opening each fixture shows the correct form code, taxpayer, period, indicators and values.
- PDF export contains every value and prints on A4 with 20/20/20/10 mm margins.
- `COMPATIBILITY.md` is factual and contains no unexecuted PASS.
- No vendor asset or real taxpayer XML is committed.
