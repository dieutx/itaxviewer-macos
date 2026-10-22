# iTaxViewer — Reverse-Engineering Architecture Map

**Target:** `C:\Program Files (x86)\iTax Viewer` (official Vietnamese GDT iTax Viewer, Windows)
**Analysis date:** 2026-10-22
**Method:** static artifact inspection + JAR decompilation (CFR 0.152) + XML/XSLT asset analysis. No proprietary code is reused in the macOS implementation.

## 1. Verified technology stack

| Layer | Finding | Evidence |
|---|---|---|
| Runtime | Oracle JRE **1.8.0_112** (32-bit client VM), bundled | `jre/bin/java.exe -version` output |
| Application | Java SE, compiled for **class file major 52** (Java 8) | `TaxViewer.class` bytes 6–7 |
| Entry point | `seatechit.ihtkk.tool.taxview.TaxViewer` | `META-INF/MANIFEST.MF` → `Main-Class` |
| Desktop UI | **Eclipse SWT 4.3** (Win32 x86_64), not Swing/JavaFX | `itaxviewer_lib/org.eclipse.swt.win32.win32.x86_64-4.3.jar`, imports in `TaxViewer.java` |
| Document view | SWT `Browser` + MSXML/ActiveX XSLT transform | `HSoThueViewer.createHTMLViewer`, `data/run.html` |
| HTML→PDF | **PD4ML Pro 360fx1** | `itaxviewer_lib/pd4ml.jar` manifest (`Implementation-Version: 360fx1`) |
| PDF merge | **Apache PDFBox 1.8.8** | `itaxviewer_lib/pdfbox-app-1.8.8.jar`, `TKhaiConverter.mergePDF` |
| XML signatures | **BouncyCastle bcprov-jdk16-146** + `javax.xml.crypto.dsig` | `IHTKKXMLSignature.java`, `CertVerifier.java` |
| Utilities | commons-io 1.4, commons-lang3 3.3.2 | `itaxviewer_lib/` |

It is **not** .NET, Electron, JavaFX or a native C/C++ application.

### Renderer engine inference (high confidence)

`HSoThueViewer.java:103` sets `org.eclipse.swt.browser.DefaultType=edge`, but the bundled SWT 4.3
predates WebView2/Edge support (added in SWT 4.17, 2021). The same class loads `data/run.html`
whose `transform()` unconditionally instantiates `new ActiveXObject("Microsoft.XMLDOM")`
(`run.html` lines 45–47). The shipped `common.xsl` declares
`<msxsl:script language="JavaScript" implements-prefix="ihtkk">` and the templates call
`ihtkk:formatNumber`, `ihtkk:kyTinhThue`, etc. Those extension functions only exist in
Microsoft MSXML. **Therefore the actual rendering engine is the Windows MSHTML/MSXML stack
(IE mode), and the "edge" property is ineffective.** This is an inference from shipped
artifacts; it was not observed by attaching a debugger.

## 2. Module map (94 classes)

```
seatechit.ihtkk.tool
├── TaxViewer                         main window, menus, toolbar, file open, CLI arg[0]
├── ConfigInfo                        loads data/DMuc*.xml registries + certstore
├── taxview
│   ├── HSoThueViewer                 SWT Browser host, HTML injection, print, Excel OLE
│   ├── TKhaiConverter                PD4ML A4 PDF generation + PDFBox merge
│   ├── SignatureList                 signature detail dialog
│   ├── TKhaiConverter / SignerLogger
├── taxdoc
│   ├── HSoThue (abstract)            document model: maHSo, version, xsltFile, orientation…
│   ├── HSoThueFactory                root-element dispatch + Vietnamese filename repair
│   ├── PLuc                          appendix model
├── taxreturn
│   ├── TKhaiThue                     tax declaration implementation (core classification)
│   ├── DMucTKhai                     (maTKhai, pbanTKhai, loaiTKhai) → template registry
│   ├── TkhaiInvoice / DNghiInvoice / TKhaiHDDTInvoice / BLaiInvoice   e-invoice documents
├── taxMessage / taxMessageNtdt / taxMessagekdtt   notices and tax-authority messages
├── taxvoucher.GNTNSNN                payment voucher (CHUNGTU)
├── taxRegistration.DKyThue           tax registration
├── taxCatalog.DMuc                   catalogs
├── hquanform / hquanformnew          customs declarations
├── signature                         XMLDSig verification, X.509 chain, OCSP
└── autoupdate                        HTTP update client (not needed by the macOS app)
```

## 3. End-to-end document flow (verified)

```
argv[0] / FileDialog
   │
   ▼
HSoThueFactory.createHSoThue(file, ConfigInfo)          taxdoc/HSoThueFactory.java:76
   │  • read file as UTF-8 text; parse with DocumentBuilder (namespaceAware=true)
   │  • root element dispatch (see document-types.md)
   ▼
TKhaiThue(Document, file, config)                       taxreturn/TKhaiThue.java:30
   │  • read maTKhai, pbanTKhaiXML, loaiTKhai, tenTKhai
   │  • apply legacy version rewrite (42/43/44/103 → 2.0.0 unless 2.0.5/2.0.8)
   │  • DMucTKhai lookup → XSD path, XSLT path, viewMethod, orientation
   │  • build PLuc list from <PLuc> children
   │  • verify XMLDSig (javax.xml.crypto + BouncyCastle)
   │  • create temporary XML with default namespace declaration stripped
   ▼
HSoThueViewer.createHSoViewer                           taxview/HSoThueViewer.java:106
   │  • loads data/run.html into SWT Browser
   │  • transform(xmlURL, xsltURL) in MSXML
   │  • injects resulting HTML into <div id="tkhai">
   │  • measures #tkhaiTable.offsetWidth (892 / 1262 baseline)
   │  • renders signature status table into #signature
   ▼
Print: HSoThueViewer.printFile                          taxview/HSoThueViewer.java:404
   │  • wraps HTML in fixed-width table
   │  • PD4ML → A4 PDF (20 mm top/left/right, 10 mm bottom, Times New Roman)
   │  • appends one PDF per appendix, merges with PDFBox
   ▼
Windows print dialog / Acrobat / Desktop.open(pdf)
```

## 4. Windows dependencies and macOS replacements

| Original dependency | Purpose | macOS replacement (this project) |
|---|---|---|
| SWT 4.3 + MSHTML/MSXML | UI + XSLT in browser | SwiftUI/AppKit + WKWebView (JS disabled) |
| `ActiveXObject("Microsoft.XMLDOM")` | XSLT 1.0 + `msxsl:script` JS extensions | No XSLT at runtime; declarative Swift form specs + HTML/CSS renderer |
| PD4ML | HTML→PDF | Native `WKWebView.printOperation` (all pages) / `createPDF` fallback |
| PDFBox merge | Merge main form + appendices | Single HTML document with page breaks; one print job |
| OLE/Excel viewer (`OleClientSite`) | Excel-template forms | Not supported; those forms use structured data view |
| JRE 1.8 | Runtime | Native arm64/x86_64 binary |
| `java.awt.Desktop.open(pdf)` | Open PDF | `NSWorkspace.shared.open` (not required; export panel used) |
| Online OCSP in `CertVerifier` | Revocation | Explicitly **not checked** offline; UI states "Not verified" |
| `FileDialog` filter `*.xml` | Open dialog | `NSOpenPanel` + UTType.xml + Finder document types |

## 5. Original security posture (do not copy)

The original `HSoThueFactory` uses a default `DocumentBuilderFactory` without
`disallow-doctype-decl`, `external-general-entities=false` or secure processing. It reads the
whole file as a string and parses it. It also executes JavaScript inside `msxsl:script` and
opens PDFs through the shell. The macOS implementation deliberately hardens all of this
(see `docs/security.md` and `SecureXMLParser.swift`).

## 6. Evidence index

| Claim | Artifact / symbol |
|---|---|
| Java 8, class major 52 | `itaxviewer.jar`, `TaxViewer.class` |
| Root dispatch table | `HSoThueFactory.createHSoThue`, constants lines 49–74 |
| Registry lookup by 3-tuple | `DMucTKhai.getTTinTKhai`, `getXSLTTKhai` |
| Version rewrite | `TKhaiThue` constructor, lines 46–48 |
| Namespace stripping before XSLT | `TKhaiThue.createTemFileForView`, lines 86–98 |
| HTML injection | `HSoThueViewer` lines 199–215, 261–285 |
| Print geometry | `TKhaiConverter.convertToHSoPDF` lines 32–73 |
| Signature verification | `IHTKKXMLSignature.verifyXMLSignature` lines 96–222 |
| Trust stores | `ConfigInfo` lines 54–55; `certstore/root` (76 files), `certstore/trust` (124 files) |

## 7. Unknowns / limitations

* We did not execute the Windows GUI under a debugger; engine identification is static inference.
* The vendor's exact build toolchain and source revision are not recoverable from the JAR
  (no `SourceFile`/line tables beyond decompiler output; JAR is not obfuscated).
* No license file is shipped. For that reason **no XSLT, CSS, fonts, images or icons from the
  original installation are copied into this project**. Form specs contain only official
  field identifiers/labels and are rendered by independently written HTML/CSS.
