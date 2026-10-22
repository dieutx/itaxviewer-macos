# Security Design — iTax Viewer for macOS

## 1. Threat model

The app opens **untrusted XML files** supplied by users, accountants or downloaded from tax
portals. The main risks are:

1. XML External Entity (XXE) / SSRF / local file disclosure;
2. entity-expansion (“billion laughs”) and memory exhaustion;
3. script injection from tax data into the preview;
4. remote content loading (tracking, data exfiltration);
5. misleading signature claims;
6. leaking taxpayer data through logs, caches or network.

## 2. Implemented controls

| Control | Implementation | Test |
|---|---|---|
| Reject DTD/DOCTYPE/ENTITY before parsing | `SecureXMLParser.rejectDoctype(in:)` checks UTF-8 and UTF-16 representations | `ParserTests.testRejectsXXEAndDoctype` |
| Disable external entities | `parser.shouldResolveExternalEntities = false` | same |
| Size limit | default 64 MB (`XMLSecurityLimits.maxBytes`) | `testRejectsOversizedDocument` |
| Depth limit | 256 nested elements | code path |
| Node limit | 500,000 elements | code path |
| Bounded traversal | `descendants(named:limit:)`, `leaves(limit:)` | code |
| Output escaping | every data value rendered through `VietnameseFormat.htmlEscape` | renderer tests |
| No script execution | `WKWebpagePreferences.allowsContentJavaScript = false` | code |
| No remote loads | self-contained HTML with `Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; img-src data:`; no `http(s)` URLs emitted | `testGeneratedHTMLIsScriptFreeAndHasNoRemoteResources` |
| Navigation blocked | `WKNavigationDelegate` cancels link activation and any non-`about`/`data` scheme | code |
| No persistent web cache | `WKWebsiteDataStore.nonPersistent()` | code |
| No upload / cloud | no networking code; no URLSession; no analytics | code review |
| No content logging | errors use generic localized descriptions; XML values are never printed to console | code review |
| No data mutation | values are read, never written back; export is PDF only | code |
| No shell execution | `Process` is not used; printing uses `NSPrintOperation` | code review |
| Signature honesty | status is always “Chưa xác minh (Not verified)”; no green “valid” state | `testSignatureIsNotReportedAsVerified` |

## 3. Deliberate non-goals

* **Full XMLDSig verification** is not implemented (see
  `docs/reverse-engineering/signature-verification.md`). The app never claims a document is
  cryptographically valid.
* **Online revocation** is not implemented; the app is offline by design.
* **Automatic updates** are not implemented.
* **Opening arbitrary file types** is not supported; only XML content is parsed.
* **Sandbox**: the development build is not sandboxed. A distribution build should enable
  App Sandbox with only `com.apple.security.files.user-selected.read-only` and **no**
  network entitlement (see §5).

## 4. Data retention

* Recent file list: **paths only**, stored in `UserDefaults` under `itax.recentFiles.v1`.
  No XML content, taxpayer names or field values are stored. “Xóa” clears the list.
* No temporary XML/HTML/PDF files are written during viewing.
* PDF export writes only to the location chosen in `NSSavePanel`.
* The WKWebView uses a non-persistent data store, so no page cache survives relaunch.

## 5. Recommended distribution hardening

```xml
<!-- iTaxViewerMac.entitlements -->
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.files.user-selected.read-only</key><true/>
<!-- intentionally no com.apple.security.network.client -->
```

Then:

```bash
codesign --force --options runtime \
  --entitlements iTaxViewerMac.entitlements \
  --sign "Developer ID Application: …" build/iTaxViewerMac.app
```

Notarize with `notarytool` and staple. The development build produced by
`scripts/build_app.sh` is unsigned/ad-hoc and is not notarized.

## 6. Residual risks

| Risk | Mitigation | Residual |
|---|---|---|
| Memory exhaustion under 64 MB | limits + bounded traversal | A 64 MB deeply repetitive file can still allocate significant memory; acceptable for a desktop viewer |
| Malicious CSS in data? | data is escaped; no templates from files | none known |
| Huge number of appendix children | structured appendices cap at 20,000 rows per table and show an explicit truncation row; the generic fallback caps at 10,000 leaves | data beyond the cap is not displayed, but the limit is visible in the document |
| Print/PDF engine bugs | system WebKit | inherited from macOS |
| Certificate store absence | trust status labelled explicitly | user may misinterpret “untrusted”; UI explains |
| Path disclosure in recent list | local only | expected desktop behaviour |

## 7. Reporting

Security issues should be reported privately to the maintainer of this independent project.
This application is **not** an official product of the Vietnamese tax authority.
