# Recovered Document-Type Registry

The original does **not** classify by display code ("01/GTGT"). Declarations are identified
by the internal numeric `maTKhai` plus `pbanTKhaiXML` plus `loaiTKhai`, then looked up in
`data/DMucTKhai.xml`. Display codes below were recovered from the `mauTKhai` parameter in
each referenced XSLT.

## 1. Measured catalogue size

| Metric | Value | Source |
|---|---:|---|
| Registry `<TKhai>` entries | **1,150** | `data/DMucTKhai.xml` |
| Distinct `maTKhai` codes | **410** | parsed registry |
| Distinct display codes (Mẫu số) | **244** | `mauTKhai` extraction from templates |
| `viewMethod` values | 100 % `1` (HTML) | registry attributes |
| Orientation distribution | 990 portrait / 157 landscape / 3 missing | registry attributes |
| `loaiTKhai` values | `C` 736, `B` 409, plus `T`, `DK`, `TD`, `CD` | registry attributes |

## 2. Root-level kinds (verified)

| Kind | Roots | Implementation |
|---|---|---|
| Tax declaration | `HSoThueDTu` | `TKhaiThue` |
| Tax-authority notice | `TBaoThueDTu`, `THONGBAO`, `THONG_BAO`, `TBAO_TKHOAN_NH`, `TBAO_TKHOAN_NT`, `TBAO_NGUNG` | `TBaoThue` / `TBaoThueNtdt` |
| Payment voucher | `CHUNGTU` | `GNTNSNN` |
| Tax registration | `DKyThueDTu` | `DKyThue` |
| Catalog | `DanhMucDTu` | `DMuc` |
| Customs | `TOKHAI_OBJ`, `TOKHAISUA_OBJ`, `*:Envelope` | `HquanForm*` |
| E-invoice | `TKhai`, `DNghi`, `TBao`, `BCTHSDBLai`, `BLai` | invoice classes |
| Refund / audit / confirmation | `XULY_NTHUA`, `TRASOAT_THUE`, `XACNHAN_THUE`, `XACNHAN_NVTHUE` | NTDT classes |

Namespace rule (verified by running the original): classification compares the raw
`getTagName()` against these literals, so a **prefixed** root (`ns0:TBaoThueDTu`) is rejected as
"Tệp hồ sơ không đúng định dạng". A default namespace is accepted; the notice/voucher handlers
write a temp copy with `xmlns="…"` stripped before running XSLT.

## 3. Priority forms — verified mappings

| Display code | `maTKhai` | Verified versions | Template (example) | Orientation | Renderer in macOS app |
|---|---|---|---|---|---|
| **01/GTGT** | `842` (legacy `01`) | 2.5.1, 2.6.8, 2.7.4, **2.8.3** | `data/xslt/XSLT 2.8.3/TKhaiThue/xslt/GTGT/TKhai_GTGT_01_TT80.xslt` | portrait | **Full** (27 rows, 21 mapped indicators) |
| **05/KK-TNCN** | `394` (also `42`, `864`) | **2.1.6** | `data/xslt/XSLT 2.1.6/TKhaiThue/xslt/CNKK/TKhai_05KK_TNCN.xslt` | portrait | **Full** (16 rows) |
| **05/QTT-TNCN** | `953` (legacy `395`) | 2.5.1, 2.5.2, 2.7.9, 2.8.3, 2.8.4, 2.8.5, **2.9.3** | `data/xslt/XSLT 2.9.3/TKhaiThue/xslt/TNCN/TKhai_05QTT_TNCN_TT80.xslt` | portrait | **Full** (26 rows, incl. `NVuQToanThay`) |
| **03/TNDN** | `892` (legacy `03`) | 2.5.1, 2.8.3, 2.9.2, **2.9.4** | `data/xslt/XSLT 2.9.2/TKhaiThue/xslt/TNDN/TKhai_TNDN_03_TT80.xslt` | portrait | **Full** (74 rows, 66 mapped indicators) |
| Financial statement B01/BCTC | `701` (and `1254`) | up to 2.9.0 | `TKhai_BCTC41_Nam.xslt` (v2.9.0 set) | portrait | Structured data view |
| Financial statement B05/BCTC | `702` | 2.3.5 | B05 template | portrait | Structured data view |
| Notice 01/TB-BSTT | `01/TB-BSTT` (notice registry key) | 2.1.0 | `data/xslt/XSLT 2.8.1/TBaoThue/xslt/TBao_107_TB_BSTT.xslt` | portrait | Structured data view |
| Payment voucher | `CHUNGTU`, `MA_CTU=01` | `PBAN_TLIEU_XML` e.g. 4.0.1 | `data/xslt/CTu/GNT_4_0_1.xsl` | portrait | Structured data view |

Verified notice/voucher rows (2026-10-22): `843` (2.5.6, `TBao_01_1_TT19_KeKhai.xslt`), `844`
(2.4.9, `TBao_01_2_TT19_KeKhai.xslt`) and `01/TB-BSTT` (2.1.0). For `01/TB-BSTT` the root element
is **`TBao`** (handled by `TBaoHDDT`) and the registry key is `MSo`; the numeric `107` is a
declaration code (financial statements), not a notice code. A file with `root=TBaoThueDTu`,
`maTBao=107`, `pbanTBao=3.0.7` is rejected by the original.

Version semantics: a document's `pbanTKhaiXML` is matched exactly. When a file declares a
version whose registry row is absent, the original raises “Mã hồ sơ … không đúng”. The macOS
app is deliberately more forgiving for the four supported codes: it renders the known spec
and raises a compatibility warning instead of refusing the file.

## 4. Other recovered display codes (sample of 244)

| Display code | `maTKhai` codes | Newest version |
|---|---|---|
| 02/GTGT | 02, 844 | 2.7.0 |
| 03/GTGT | 04, 846 | 2.5.1 |
| 04/GTGT | 07, 847 | 2.7.4 |
| 05/GTGT | 53, 850 | 2.8.3 |
| 02/KK-TNCN | 47, 391, 859 | 2.8.3 |
| 02/QTT-TNCN | 392, 952, 1000 | 2.8.3 |
| 06/TNCN | 396, 865, 2006 | 3.0.9 |
| 04/NNG-TNCN | 863 | 3.0.9 |
| 02/TNDN | 71, 837, 1267, 2003 | 3.0.9 |
| 04/TNDN | 13, 833, 2002 | 3.0.9 |
| 05/TNDN | 687, 828, 1268, 2004 | 3.0.9 |
| 06/TNDN | 304, 829 | 3.0.8 |
| 01/CNKD | 386, 473, 1240, 1266 | 2.9.8 |
| 01/HKNN | 66, 841 | 3.0.8 |
| B01/BCTC | 701, 1254 | 2.9.0 |

The full machine-readable mapping is shipped in
`iTaxViewerMac/Sources/iTaxViewerCore/Resources/form-registry.json`
(`codes` object: 410 entries, each with `displayCode`, `latestVersion`, `versions`,
`orientation`, `loai`). It is factual interoperability data parsed from the installed
registry, not copied template code.

## 5. Conditional and repeated structures

* **Filing type** `C` = first filing, `B` = supplementary (`soLan`). Header templates branch
  on this (`[02]/[03]`).
* **Period** `kieuKy` ∈ `M` (month), `Q` (quarter), `Y` (year), plus explicit
  `kyKKhaiTuNgay`/`kyKKhaiDenNgay`.
* **Appendices** are discovered dynamically from the first `<PLuc>` element; each child tag
  is the appendix ID. A form's appendix set is not fixed by the schema.
* **Tables that repeat** (e.g. appendix line items) are inside appendix XSLTs; the main forms
  in this project are fixed indicator tables.
* **Checkbox row** `[21]` of 01/GTGT accepts `true/false` or `1/0` (template tests both).

## 6. Forms deliberately not rendered pixel-perfectly yet

| Area | Current macOS behaviour | Gap |
|---|---|---|
| 02/GTGT … 06/TNDN, BCTC, registration, customs, e-invoice, notices | All leaf values shown with source paths | Official layout, grouped tables, prose paragraphs |
| Appendices (PLuc) | All appendix data shown after the main form | Official appendix layout per `plucID` |
| Excel-based forms (`viewMethod=2`) | Not applicable (no entry uses it) | — |
| Word forms (`viewMethod=3`) | Not applicable (no entry uses it) | — |

The classifier still names these documents correctly (display code + kind) and never drops
data.
