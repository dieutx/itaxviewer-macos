# XML Processing Pipeline (Recovered)

Every step below is tied to a decompiled symbol. The macOS implementation follows the
same observable rules but replaces the browser/MSXML execution with an independent renderer.

## 1. Read → parse

**Original** (`HSoThueFactory.createHSoThue`, `taxdoc/HSoThueFactory.java:76`):

1. Repair legacy Vietnamese filenames (`fixVietnameseFileName`, lines 191–223) — maps
   Windows-1252 bytes that were used for Vietnamese characters (`Ð→Đ`, `þ→ư`, `¢→ấ`, …).
2. `URLDecoder.decode(fileName, "UTF-8")`.
3. Read the file as UTF-8 text (`FileUtils.readFileToString`).
4. Choose the parser input:
   * if the text contains `:Envelope` (namespaced customs XML), parse a `StringReader`;
   * otherwise parse the **file bytes** with a namespace-aware `DocumentBuilder`.
5. Any `SAXException` → `ITaxInvalidDocException("Tệp hồ sơ không đúng định dạng.")`.

**Verified properties**

| Property | Behaviour |
|---|---|
| Namespaces | `dbf.setNamespaceAware(true)` |
| Encoding | Delegated to Xerces: BOM/`<?xml encoding=...?>`; UTF-8 and UTF-16 accepted |
| Vietnamese Unicode | Preserved in DOM; templates read text nodes directly |
| DTD / external entities | **Not hardened** (default factory): XXE is possible in the original |
| XSD validation | **None.** `xsdFile` is resolved from the registry and null-checked only; no `SchemaFactory`/`Validator` exists in the JAR |
| Root detection | Exact qualified tag name (`getTagName()`), not local name |

**macOS implementation** (`SecureXMLParser.swift`):

* parses raw `Data` (so XML declaration/BOM controls encoding);
* `shouldResolveExternalEntities = false`, and any `<!DOCTYPE`/`<!ENTITY` is rejected
  before parsing (also in UTF-16 encodings);
* limits: 64 MB, depth 256, 500k nodes;
* namespace-aware tree with local-name lookup;
* readable Vietnamese errors matching the original wording where observed.

## 2. Root-element document dispatch

`HSoThueFactory.createHSoThue` maps the root element to a document implementation:

| Root tag | Implementation | Meaning |
|---|---|---|
| `HSoThueDTu` | `TKhaiThue` | Tax declaration |
| `TBaoThueDTu` | `TBaoThue` | Tax-authority notice |
| `CHUNGTU` | `GNTNSNN` | Payment voucher |
| `THONGBAO`, `THONG_BAO`, `TBAO_TKHOAN_NH`, `TBAO_TKHOAN_NT`, `TBAO_NGUNG` | `TBaoThueNtdt` | Notices / bank-account notices |
| `DanhMucDTu` | `DMuc` | Catalog |
| `DKyThueDTu` | `DKyThue` | Tax registration |
| `TOKHAI_OBJ` | `HquanForm` | Customs declaration (old) |
| `TOKHAISUA_OBJ` | `HquanForm1` | Amended customs declaration |
| `*:Envelope` | `HquanFormNew` | New customs envelope |
| `BKE_TBAO` | `BKeKDTT` | Notice list |
| `TRASOAT_THUE` | `TSoatNtdt` | Tax audit/check |
| `XULY_NTHUA` | `BuTruNtdt` | Refund/offset processing |
| `XACNHAN_THUE`, `XACNHAN_NVTHUE` | `XNhanCTuNtdt` | Tax confirmation |
| `TKhai` | `TkhaiInvoice` | E-invoice declaration |
| `DNghi`, `BCTHSDBLai` | `DNghiInvoice` | E-invoice proposal / book |
| `TBao` + `MSo` regex | `TBaoHDDT` / `TKhaiHDDTInvoice` | E-invoice notices |
| `BLai` | `BLaiInvoice` | E-invoice book |
| anything else | `ITaxInvalidDocException` | “Tệp hồ sơ không đúng định dạng.” |

`TBao` sub-dispatch uses `MSo` (e.g. `01/TB-BSTT`, `04/SS-HĐĐT`, `01/TB-NSD`).

## 3. Declaration metadata and validation

`TKhaiThue` constructor (`taxreturn/TKhaiThue.java:30`) requires, in order:

| Element | Required | Error if absent |
|---|---|---|
| `maTKhai` | yes | `Cấu trúc tệp hồ sơ không đúng: không có thẻ dữ liệu 'maTKhai'` |
| `pbanTKhaiXML` | yes | `… 'pbanTKhaiXML'` |
| `loaiTKhai` | yes, except the DKT code list | `… 'loaiTKhai'` |
| `tenTKhai` | yes | `… 'tenTKhai'` |
| `kieuKy` | yes, except the same DKT list | `… 'kieuKy'` |

**Legacy version rewrite (verified, lines 46–48):**

```
if maTKhai ∈ {42, 43, 44, 103} and pbanTKhaiXML ∉ {2.0.5, 2.0.8}
    pbanTKhaiXML = "2.0.0"
```

This is reproduced in `FormRegistry.normalizedVersion`.

## 4. Template resolution

`DMucTKhai` (`taxreturn/DMucTKhai.java`) loads `data/DMucTKhai.xml` (1,150 `<TKhai>` entries)
and performs a **linear scan** for the first element whose attributes match:

```
maTKhai == <doc maTKhai>
pbanTKhai == <doc pbanTKhaiXML>
loaiTKhai == <doc loaiTKhai>
```

Then it reads child elements:

| Child | Use |
|---|---|
| `XMLSchema` | XSD path; existence check only |
| `XSLT` | Stylesheet for viewing |
| `ExcelTemplate` | Excel template (viewMethod=2) |
| `DSachPLuc/PLuc@plucID` | Appendix list; each has `TenPLuc`, `PLucXSLT`, `plucOrientation`, `plucViewMethod` |

`viewMethod` is `1` for **all 1,150 entries** (HTML). No Word renderer is used.
`orientation`: `"0"` = portrait (892 px), `"1"` = landscape (1262 px) — this is the
**actual code behaviour**; the annotation in `DMucTKhai.xsd` (“0=ngang, 1=dọc”) is inverted
relative to use and should not be trusted.

If no registry row matches: `Mã hồ sơ (<maHSo>) hoặc phiên bản hồ sơ (<pban>) không đúng`.

### Lookup exceptions

For the DKT code list in `TKhaiThue` (`680, 800…1314`), `loaiTKhai` is ignored and the
DKT-specific lookup (`getXSLTTKhaiDKT`) is used. The macOS classifier reproduces the
resolution order but only ships verified renderers for four forms.

## 5. Appendix handling

`TKhaiThue.getPLucList` finds the first `PLuc` element and treats **every element child**
as an appendix. The child tag name is the `plucID` (prefix stripped). Each appendix gets its
own XSLT and orientation. `HSoThueViewer` renders the main form first, then every appendix,
and `printFile` emits one PDF per appendix before merging.

**macOS:** every `PLuc` child is rendered on a new page. `PL_NQ43_GTGT`, `PL_NQ101_GTGT` and
`PL_NQ142_GTGT` have independently recreated official layouts (identity block, purchase and
sale tables, totals and the NQ142 difference `[09]`). Other `plucID` values fall back to a
path/value table. The remaining layouts are listed in
`docs/PROMPTS/WINDOWS_APPENDIX_RE.md`.

## 6. Namespace normalisation before transformation

`TKhaiThue.createTemFileForView` reads the XML as UTF-8, removes the literal string

```
xmlns="http://kekhaithue.gdt.gov.vn/TKhaiThue"
```

and writes a temporary file. XSLT match patterns therefore see unprefixed
`HSoThueDTu/HSoKhaiThue/...`. `TBaoThue` removes `xmlns="…/TBaoThue"` and
`xmlns="…/TBThue_T-VAN"` the same way.

This is an interoperability quirk, not a general namespace fix. Documents that use a
prefix (`<gdt:HSoThueDTu xmlns:gdt="...">`) keep the prefix, and `TKhaiThue` looks up
`prefix:maTKhai` accordingly.

**macOS:** the tree is namespace-aware; lookups are by local name, so both styles work.

## 7. Value rendering rules

The templates use XSLT 1.0 plus Microsoft extension functions declared in
`data/xslt/XSLT 2.8.3/TKhaiThue/common/common.xsl`:

```xml
<msxsl:script language="JavaScript" implements-prefix="ihtkk">
```

Recovered `formatNumber` semantics:

* empty/missing → empty string;
* optional leading `-`; negative output is wrapped in parentheses: `(1.000)`;
* split at `.` (dot) into integer and fraction;
* round: `floor(value*100 + 0.50000000001)` then `floor(.../100)`;
* thousands separator `.`;
* fraction appended after `,` (e.g. `1.234,56`);
* `0` renders as `0`.

Recovered `kyTinhThue`/`stringDatetime` helpers format dates as `dd/mm/yyyy` and periods as
month/quarter/year text. The macOS port is in `VietnameseFormat.swift`.

**Conditional content:** headers switch `[02]/[03]` on `loaiTKhai == 'C'` vs `'B'`; optional
blocks are emitted only if the corresponding node exists (e.g. `DLyThue`, `ct09`/`ct10`).

## 8. Print / PDF pipeline

`HSoThueViewer.printFile` (lines 404–486):

1. Wrap rendered HTML in a table of width `max(pageWidth, 892/1262)`.
2. Replace `<div id="sigDiv"></div>` with the signature-status HTML.
3. Pick CSS: `data/css/ihtkk_ntdt.css` for `CTu` documents, else `ihtkk.css`.
4. `TKhaiConverter.convertToHSoPDF`:
   * page size A4; landscape if `orientation == "1"`;
   * insets: top 20 mm, left 20 mm, right 20 mm, bottom 10 mm;
   * HTML width 892 px (portrait) or 1262 px (landscape), expanded to measured width + 40;
   * fonts `java:fonts`, default `Times New Roman / Arial / Courier New`;
   * PDF form fields enabled (`generatePdfForms(true, "Times New Roman")`);
   * table breaks disabled; images not split;
   * footer page number template `$[page]/$[total]`, Times New Roman 12, area 20.
5. Appendices are converted separately and merged with PDFBox.
6. If an Acrobat plugin ≥ 9 is present, print via a hidden PDF `<object>`; otherwise open the
   merged PDF with the desktop shell.

**macOS:** A4, same margins, native `WKWebView.printOperation` for print and print-to-PDF
(all pages). Page numbers in the footer are not injected (WebKit does not support CSS page
counters); this is a documented difference.

## 9. Error surface (observed strings)

| Condition | Message |
|---|---|
| XML not well-formed | `Tệp hồ sơ không đúng định dạng.` |
| Missing declaration element | `Cấu trúc tệp hồ sơ không đúng: không có thẻ dữ liệu '<name>'` |
| Unknown code/version | `Mã hồ sơ (<code>) hoặc phiên bản hồ sơ (<version>) không đúng` |
| No signature | `Hồ sơ không có chữ ký điện tử` |
| Signature invalid | `Chữ ký điện tử không hợp lệ` / detailed crypto message |
| Certificate expired | `Chứng thư số đã hết hiệu lực.` |
| No OCSP connectivity | warning: `Không thể kết nối Internet tới đơn vị CA để kiểm tra tình trạng thu hồi…` |

The macOS app reuses the first three categories and replaces the signature messages with an
explicit “Chưa xác minh (Not verified)” state.
