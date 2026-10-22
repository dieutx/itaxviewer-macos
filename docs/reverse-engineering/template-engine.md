# Template Engine — Recovered Behaviour and macOS Design

## 1. What the original actually uses

**Not** a custom drawing engine and **not** a PDF-first renderer. The pipeline is:

```
XML → (MSXML DOM) → XSLT 1.0 + msxsl:script (JavaScript) → HTML fragment
    → injected into data/run.html → SWT Browser (MSHTML) → screen
    → HTML + CSS → PD4ML → PDF → PDFBox merge → print/open
```

Evidence:

| Mechanism | Evidence |
|---|---|
| Browser host | `HSoThueViewer` fields `static Browser fileBrowser`; `new Browser(viewArea, 0)` |
| Page shell | `new File("data\\run.html").toURI().toURL()` loaded via `fileBrowser.setUrl` |
| Transform | `fileBrowser.evaluate("return transform('<xml>','<xslt>')")` |
| XSLT engine | `run.html`: `new ActiveXObject("Microsoft.XMLDOM")`, `TransformToHtmlText`, `XSLTProcessor` fallback |
| Extension functions | `common.xsl`: `<msxsl:script language="JavaScript" implements-prefix="ihtkk">` |
| HTML injection | `fileBrowser.execute("document.getElementById('tkhai').innerHTML=...")` |
| Width detection | `document.getElementById('tkhaiTable').offsetWidth` |
| PDF | `TKhaiConverter` → `org.zefer.pd4ml.PD4ML` |

XSLT is **1.0** (`<xsl:stylesheet version="1.0">`), not 2.0/3.0. No XSLT 2 engine is bundled.

## 2. Template composition

Each form XSLT includes three shared pieces:

```xml
<xsl:include href="../../include/TKhaiHeader.xsl"/>   <!-- national header + taxpayer block -->
<xsl:include href="../../include/TKhaiFooter.xsl"/>   <!-- signature area, date -->
<xsl:include href="../../common/common.xsl"/>         <!-- formatNumber, dates, number-to-words -->
```

`TKhaiHeader.xsl` (v2.8.3: 644,619 B) contains a *separate template per form*
(`tkhaiHeader_01_GTGT_TT80_283`, `tkhaiHeader_03TNDN`, `tkhaiHeader_05_KK_TNCN_TT80_283`, …),
selected by the form XSLT via `xsl:call-template`.

Header layout recovered from `BieuNguDatNuoc`:

* left ~80 %: `CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM` / `Độc lập – Tự do – Hạnh phúc` + rule;
* right ~17 %: `Mẫu số: <code>` and italic legal reference;
* centred uppercase `tenTKhai`;
* italic scope note (`ghuchuTK`);
* taxpayer block: `[04]` name, `[05]` tax code, optional delegated-tax-agent block
  `[06]–[08]`, address `[09]–[11]`, period `[01]/[01b]`, filing type `[02]/[03]`.

Footer (`TKhaiFooter.xsl`) = place/date line, “NGƯỜI NỘP THUẾ” / “CƠ QUAN THUẾ” signature
columns, and `<div id="sigDiv"></div>` which the Java layer replaces with the signature
status table.

## 3. Layout constants recovered from code

| Quantity | Value | Source |
|---|---|---|
| A4 portrait HTML width | 892 px | `HSoThueViewer.viewHTML` (`pageFormat=="0"`), `printFile` |
| A4 landscape HTML width | 1262 px | `HSoThueViewer.viewHTML` (`pageFormat=="1"`) |
| Page margins | 20/20/20/10 mm | `TKhaiConverter` fields, `setPageInsets` |
| Default font | Times New Roman (Arial, Courier fallback) | `setDefaultTTFs` |
| Footer font | Times New Roman 12 | `PD4PageMark.setFont` |
| Footer template | `$[page]/$[total]` | `setPageNumberTemplate` |
| Table page breaks | disabled (`enableTableBreaks(false)`) | `TKhaiConverter` |
| Image splitting | disabled | `TKhaiConverter` |
| Page-break CSS | `tr,td,tbody,thead,tfoot { page-break-inside: avoid }` | `run.html` `<style>` |

The XSD comment for `orientation` is inverted; code uses `"0"` → 892 px portrait and
`"1"` → 1262 px landscape. That is what the macOS app follows.

## 4. Number / date / text formatting

All `ihtkk:*` helpers are **JavaScript** inside `msxsl:script`. Recovered algorithms:

| Function | Behaviour |
|---|---|
| `formatNumber` | empty → empty; round to integer; `.` thousands; `,` decimal; negatives in `( )` |
| `kyTinhThue` | builds “Tháng/Quý/Năm …” or “Từ ngày … đến ngày …” from kỳ fields |
| `stringDatetime` | slices a date string by requested format (`dd`, `mm`, `yyyy`, `dd/mm/yyyy`) |
| `DocSo3ChuSo` / `DocSo` | Vietnamese amount-in-words (used by vouchers) |

The macOS port is `VietnameseFormat.swift`; `formatNumber` is covered by unit tests and a
fixture harness with the exact JS semantics, including `(1.000)` for negative values.

## 5. Conditional sections and repeating tables

* `[02]/[03]`: `loaiTKhai == 'C'` → first filing; `'B'` → “Bổ sung lần thứ `soLan`”.
* 01/GTGT `[21]`: tests `ct21` against `true/false` **and** `1/0`.
* Header address rows `[09]–[11]` are emitted only when nodes exist; the delegated-agent block
  `[06]–[08]` switches on `TTinTKhaiThue/DLyThue`.
* `PLuc` appendices are dynamic: every element child of the first `<PLuc>` becomes a tab/link.
* Repeating tables occur inside appendix templates (line-item schedules), not in the four
  main forms implemented here.

## 6. Why the macOS app does not execute the shipped XSLT

1. **Legal:** no licence file accompanies the installation; the XSLT/CSS/images are vendor
   assets. The app must not redistribute them. Official *field identifiers and labels* are
   interoperability facts and are used as data.
2. **Technical:** the stylesheets depend on `msxsl:script` JavaScript extension functions that
   libxslt/XSLTProcessor do not implement. Running them under libxslt fails on
   `ihtkk:formatNumber`.
3. **Security:** executing vendor script and injecting raw HTML into a web view conflicts with
   the hardening requirements (no script execution, no external entities).

## 7. Independent macOS rendering architecture

```
TaxDocument (secure DOM + metadata)
   │
DocumentClassifier → FormRegistry (410 codes, 4 verified specs)
   │
HTMLRenderer
   ├── official header block (national title, form code, taxpayer, period, filing type)
   ├── declarative body table from FormSpec (indicator / label / value columns)
   ├── appendix data tables (PLuc)
   ├── signature block (always “Not verified”)
   └── self-contained CSS (@page A4, print rules, no external URLs, no JS)
   │
WKWebView (JavaScript disabled, non-persistent, navigation blocked)
   ├── screen preview + zoom (pageZoom)
   ├── print → NSPrintOperation (A4, 20/20/20/10 mm)
   └── export → print-to-PDF (all pages)
```

### Form specs

`Resources/form-specs.json` contains four specs (27 / 16 / 26 / 74 rows). Each row:

```json
{ "stt": "2", "indicator": "25", "codes": ["25"], "kind": "row",
  "label": "Thuế giá trị gia tăng của hàng hóa, dịch vụ mua vào được khấu trừ kỳ này",
  "values": [{"root":"tkchinh","path":"ct25"}] }
```

`root` ∈ `tkchinh` (`CTieuTKhaiChinh`), `ktru` (`NVuKhauTruThue`), `qtoan`
(`NVuQToanThay`), `ttkthue` (`TTinTKhaiThue`). Values are read **verbatim** from the DOM;
only display formatting is applied. Missing elements render as blank, exactly like
`xsl:value-of`.

### Screen and paper styling

* paper width 892 px (portrait) / 1262 px (landscape), matching the original baselines;
* white paper on neutral grey, Times New Roman-first font stack;
* `@page { size: A4 portrait|landscape; margin: 20mm 20mm 10mm 20mm }`;
* print media removes the shadow/background and repeats table headers;
* `Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; img-src data:`;
* no `<script>`, `<iframe>`, external font, image or stylesheet is emitted (asserted by tests).

### Dark / light appearance

The chrome (sidebar, toolbar, sheets) uses native SwiftUI materials and adapts automatically.
The document “paper” stays white in both appearances, matching printed output; the surrounding
canvas is neutral grey. The web view declares `color-scheme: light` so WebKit does not invert
document colours.

## 8. Known differences from the original renderer

| Area | Original | macOS app |
|---|---|---|
| XSLT engine | MSXML + JS extensions | none (declarative Swift specs) |
| Pixel-identical header | per-form 600 KB header templates | one shared official header, form-specific fields |
| Footer page numbers | PD4ML `$[page]/$[total]` | not emitted (WebKit limitation) |
| Appendices | official appendix XSLT per `plucID` | full data tables, page break, no official layout |
| Other 406 codes | full templates | structured data view with warning |
| Signature status | crypto + OCSP (online) | metadata only, “Not verified” |
