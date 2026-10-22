# Compatibility Matrix — iTax Viewer for macOS

Reference application: official **iTax Viewer** installed at
`C:\Program Files (x86)\iTax Viewer` (bundled JRE 1.8.0_112; registry contains XSLT
templates through **3.0.9** and 2026 CA certificates).
Comparison date: 2026-10-22.

Status legend:

* **PASS** — executed and verified in this project
* **IMPLEMENTED** — code written and covered by tests, but the macOS build/run is pending
* **PARTIAL** — supported with a documented limitation
* **PENDING** — not verified yet
* **NOT VERIFIED** — deliberately not claimed (cryptographic signatures)

> **Executed on macOS 15 (Intel) on 2026-10-22** with Xcode 16.1 / Swift 6.0.2.
> `swift test` ran 45 tests (44 passed, 1 skipped because `ITAX_FIXTURE_DIR` was not set),
> `scripts/build_app.sh` produced a launchable ad-hoc-signed `.app`, and the HTML/CSS
> renderer was exercised for all four priority forms. The Windows reference screenshots
> below were captured from the live Windows application. Items that still require a manual
> native-print run are marked **pending**, not claimed as passed.

## 1. Document matrix

| Document | Internal code / version | Fixture | Classification | Data accuracy | Renderer | Print/PDF | Signatures | Overall |
|---|---|---|---|---|---|---|---|---|
| **01/GTGT** | `842` / 2.8.3 | `gtgt_842_return.xml` | **PASS** | **PASS** (21 indicators) | **PASS** (27 rows) | **PASS** (CSS pagination, 2 A4 pages) · native print pending | NOT VERIFIED | **PASS (render/pagination)** |
| **05/KK-TNCN** | `394` / 2.1.6 | `tncn_394_05kk_tt92.xml` | **PASS** | **PASS** (16 indicators) | **PASS** (16 rows) | **PARTIAL** — Windows prints **1** A4 page, cloned output reported 2 · native print pending | NOT VERIFIED | **PARTIAL (pagination gap)** |
| **05/QTT-TNCN** | `953` / 2.9.3 | `tncn_953_05qtt.xml` | **PASS** | **PASS** (26 indicators incl. `NVuQToanThay`) | **PASS** (26 rows, authorisation section renumbered 1–6) | **PASS** (CSS pagination, 2 A4 pages) · native print pending | NOT VERIFIED | **PASS (render/pagination)** |
| **03/TNDN** | `892` / 2.9.4 | `tndn_892_03tndn_v2.9.4.xml` | **PASS** | **PASS** (66 indicators) | **PASS** (74 rows) | **PASS** (CSS pagination, 4 A4 pages + appendix) · native print pending | NOT VERIFIED | **PASS (render/pagination) / visual diff pending** |
| Financial statements | `B01/BCTC` = `701`/`1254`, `B05` = `702` | — | PASS (code mapping) | structured view | Structured only | IMPLEMENTED | NOT VERIFIED | **PARTIAL** |
| Tax-authority notice | `843` / 2.5.6 (`01-01/TB-TĐT`), `844` / 2.4.9 (`01-2/TB-TĐT`), `01/TB-BSTT` / 2.1.0 | `notice-843-minimal.xml`, `notice-844-minimal.xml`, `notice-01-TB-BSTT-minimal.xml` | Windows **PASS** (opens and renders 1 page each) | Windows PASS | macOS structured only; specs in `documents/notices/` | Windows PDF **PASS** (1 page each) | NOT VERIFIED | **PARTIAL (Windows spec done)** |
| Payment voucher | `CHUNGTU` / `MA_CTU=01` | `gnt_chungtu.xml`, `voucher-CT-01-vnd-multi.xml` | Windows **PASS** (4.0.1) | Windows PASS | macOS structured only; spec `documents/paymentVouchers/CT-01.json` | Windows PDF **PASS** (1 page) | NOT VERIFIED | **PARTIAL (Windows spec done)** |
| Other 406 declaration codes | various | — | PASS (display code from registry) | structured view | Structured only | IMPLEMENTED | NOT VERIFIED | **PARTIAL** |

### Known coverage gaps (different indicator numbering)

| Document | Code / versions | Why not full | Current behaviour |
|---|---|---|---|
| 05/KK-TNCN under TT 80/2021 | `864` / 2.5.1, 2.8.3, 2.9.3 | different rows `[16]–[32]` | structured view + warning |
| 05/QTT-TNCN legacy | `395` / 2.1.6, 2.4.2 | pre-TT80 layout | structured view + warning |
| CIT under TT 89/2025 | `2002`, `2003`, `2004` | new 2025 layouts | structured view + warning |
| BCTC B01/B05 | `701`, `1254`, `702` | multi-table financial statements | structured view + warning |

These are never presented as “fully rendered”; the classifier still reports the correct
display code and all source values remain visible.

### Bundled anonymised real-structure samples

`test-data/anonymized/` contains **3 payment vouchers** and **2 tax-authority notices**
derived from real files with all identity, tax codes, accounts, IDs, amounts, contact data
and signatures removed. They exercise the real element structure (including nested
`ROW_CTIET` rows and notice bodies) without exposing taxpayer data. See
`test-data/README.md`. Windows reference comparison for these anonymised copies is **PENDING**
because they are derived, not the originals.

```bash
python3 iTaxViewerMac/scripts/validate_directory.py test-data
ITAX_FIXTURE_DIR=test-data swift test --filter ExternalFixturesTests
```

## 2. Fixture identity

| Fixture | Bytes | SHA-256 (16 hex) | Origin |
|---|---:|---|---|
| `gtgt_842_return.xml` | 2,771 | `E6637E1B63D869F6` | anonymised local fixture (MST 0000000000) |
| `tncn_394_05kk_tt92.xml` | 1,236 | `EF30864D9B09C14B` | anonymised local fixture |
| `tncn_953_05qtt.xml` | 1,851 | `7D44240F9C94A5D9` | synthetic, authored for this project |
| `tndn_892_03tndn_v2.9.4.xml` | 3,113 | `A354BCE8839695BE` | anonymised local fixture |
| `tbao_107_bstt.xml` | 708 | `D99006385D083F0B` | synthetic notice |
| `gnt_chungtu.xml` | 418 | `8875950CA263C924` | synthetic voucher |
| `gtgt_842_return_utf16.xml` | 5,262 | `3035FE351ED4CD78` | UTF-16LE/BOM variant of the GTGT fixture |
| `xxe_attack.xml` | 470 | `0A4C6F9070004D6D` | malicious XXE test input (rejected) |
| `signed_demo.xml` | 2,913 | `2217E6E6515E05A5` | synthetic signature structure with self-signed cert |

## 3. Reference captures (live Windows application)

Screenshots captured from `iTaxViewer.exe` rendering the same fixtures
(`docs/reverse-engineering/evidence/`):

| Fixture | Reference image | Observed |
|---|---|---|
| 01/GTGT | `reference-gtgt.png` | A4 portrait; 6-column indicator table; values `1.000.000.000`, `80.000.000`; header `[01a]…[11c]`; `[01b] Tháng 06 năm 2025` |
| 05/KK-TNCN | `reference-tncn-05kk.png` | 5-column table; `1.200.000`, `5.000`; header `[01]…[20]`; parent rows bold |
| 05/QTT-TNCN | `reference-tncn-05qtt.png` | `I. NGHĨA VỤ KHẤU TRỪ…`; `1.500.000.000`; header `[01]…[15]`; parent rows bold |
| 03/TNDN | `reference-tndn-03.png` | **Invalid capture:** the file currently shows the Windows splash screen, not the rendered form. The claim `(1.000)`, `250` is therefore **not visually verified**; only the data-level fixture check passes. |

### Windows re-capture 2026-10-22 (declarations, notices, vouchers)

Fresh captures from the live app (screenshots via `PrintWindow`, PDF via the app's own
Ctrl+P → PD4ML path). Files live under
`docs/reverse-engineering/evidence/documents/<kind>/<id>/`.

| Document | Windows result | Pages | Notes |
|---|---|---:|---|
| 01/GTGT (`842`/2.8.3) | opens | **2** | matches the cloned pagination |
| 05/KK-TNCN (`394`/2.1.6) | opens | **1** | clone pagination differs (2) |
| 05/QTT-TNCN (`953`/2.9.3) | opens | **2** | matches |
| 03/TNDN (`892`/2.9.4) | **NPE, no window** | — | reproducible on the bundled `<BaoCaoTaiChinh>` appendix; see the NPE note below |
| Notice `843` (2.5.6) | opens, received + rejected branches | 1 | rejected branch captured with a synthetic `LyDo` |
| Notice `844` (2.4.9) | opens, accepted branch | 1 | IDKhoanNop table renders `1.000.000` |
| Notice `01/TB-BSTT` (2.1.0) | opens | 1 | root must be **`TBao`**, registry key `MSo=01/TB-BSTT`, `PBan=2.1.0` |
| Voucher `CT-01` (4.0.1) | opens | 1 | `MA_NGUYENTE=00000` leaves amounts blank; VND prints `1.234.580.235` + words |

Corrections established by running the original:

* A **prefixed** root (`ns0:TBaoThueDTu`) is rejected; a default namespace is accepted and
  stripped before XSLT. The anonymised notice fixtures were fixed accordingly.
* The notice registry key is `maTBao` as a **string** (`843`, `844`, `01/TB-BSTT`), not the
  numeric declaration code. The old `tbao_107_bstt.xml` fixture (`107`/`3.0.7`, root
  `TBaoThueDTu`) is rejected by the original and must be replaced during macOS integration.
* Appendix capture for `PL_NQ142_GTGT` was attempted twice by clicking the status-bar link;
  the view did not change. Marked **blocked/pending**, not claimed.

### Verified behaviour from the live app

* Number formatting is exactly `1.000.000.000`, `(1.000)`, decimal comma (`10,5`).
* 01/GTGT single-amount rows print the indicator and value in the **right-hand pair** of
  columns; two-amount rows use both pairs. Implemented.
* Period text uses `kieuKy`: monthly/quarterly/yearly declarations print
  “Tháng 06 năm 2025”, “Quý 2 năm 2025”, “Năm 2024” even when
  `kyKKhaiTuNgay`/`kyKKhaiDenNgay` are present. The explicit date range is only a fallback
  when `kieuKy` is missing/unknown.
* Header numbering is **form-specific**:
  * 01/GTGT: `[06]–[08]` tax agent, `[09]–[11c]` dependent units.
  * 05/KK: `[06]` address, `[07]` district, `[08]` province, `[09]–[11]` contact,
    `[12]–[20]` agent.
  * 05/QTT: `[04]` authorisation statement, `[05]` name, `[06]` tax code, `[07]` address,
    `[08]` district, `[09]` province, `[10]–[12]` contact, `[13]–[15]` agent.
  * 03/TNDN: `[04]` industry, `[05]` rate, `[06]` name, `[07]` tax code, `[08]–[10]` agent.
  All implemented in `HTMLRenderer.headerFields`.
* Section rows are bold without background shading. Implemented.
* The original uppercases titles with XSLT `translate()`, which corrupts some Vietnamese
  diacritics (e.g. “TÀ? KHAI QUYẾ?T TOÁN”). The macOS app uses proper Unicode uppercasing —
  an intentional correction, not a missing mapping.
* The original **crashes (NPE)** when a declaration contains a `<PLuc>` child whose
  `plucID` has no registry entry. The fixture `tndn_892_03tndn_v2.9.4.xml` contains
  `<BaoCaoTaiChinh>` and reproducibly crashes the Windows app; the reference screenshot was
  taken after removing that unmapped appendix. The macOS app renders appendix data instead
  and never crashes.
* 01/GTGT appendices under NQ 43/2022, NQ 101/2023 and NQ 142/2024 now use a recreated
  official layout: identity `[01]`–`[04]`, section I (purchases), section II (sales),
  section III difference `[09] = [08] - [06]`, with all rows and totals. Covered by
  `gtgt_842_nq142.xml` and unit tests.
* `PL01_KHBS`, `PL01_1_KHBS`, `BaoCaoTaiChinh` and appendices of other forms still use the
  generic path/value table. The Windows RE prompt lists them for dedicated layout specs.

## 4. Known differences (not hidden)

| Area | Original | macOS app | Impact |
|---|---|---|---|
| 01/GTGT `[11a]–[11c]` | one row, three columns | three stacked rows | cosmetic |
| Footer page numbers | PD4ML `page/total` | not emitted | cosmetic; all pages print |
| Appendix layout | dedicated XSLT per `plucID` | **structured layout for `PL_NQ43_GTGT`, `PL_NQ101_GTGT`, `PL_NQ142_GTGT`** (I/II/III, totals `[05]`–`[09]`); other IDs use a path/value table | **partially implemented**; see [`docs/PROMPTS/WINDOWS_DOCUMENT_RE.md`](docs/PROMPTS/WINDOWS_DOCUMENT_RE.md) and [`documents/PROGRESS.md`](docs/reverse-engineering/documents/PROGRESS.md) for the remaining ID/types |
| Notices | prose paragraphs per template | structured field table | **content layout pending** |
| Other 406 form codes | official XSLT | structured field table | **layout pending** |
| Title diacritics | XSLT `translate()` bug | correct Unicode | improvement |
| Unmapped appendix | crash (NPE) | renders data | improvement |
| Table pagination | table breaks disabled; long table forced onto one page | breaks between rows, header repeats on each page | improvement; Windows prints 2 (842) / 1 (394) / 2 (953) pages; the cloned 394 output still produces 2 pages — parity gap |
| Signature | full XMLDSig + OCSP | metadata only | **NOT VERIFIED (by design)** |
| Dark mode | not supported (Windows) | native chrome + white paper | improvement |

## 5. Test status

> RE progress by document type is tracked in
> [`docs/reverse-engineering/documents/PROGRESS.md`](docs/reverse-engineering/documents/PROGRESS.md)
> and `progress.json` (declarations, appendices, notices, vouchers, registration, catalogs,
> e-invoices, customs).

| Suite | Status |
|---|---|
| `scripts/validate_fixtures.py` (classification, indicator mapping, formatting) | **PASS** (executed 2026-10-22) |
| Registry integrity (1,150 entries / 410 codes / 4 specs) | **PASS** |
| XXE rejection, UTF-16 parsing, malformed XML, oversized/hidden-DTD inputs | **PASS** (Swift XCTest) |
| Swift XCTest suite (`swift test`) | **PASS** — 45 tests executed, 44 passed, 1 skipped (`ExternalFixturesTests` without `ITAX_FIXTURE_DIR`) |
| External fixture run (`ITAX_FIXTURE_DIR=../test-data`) | **PASS** — all 9 XML files classified; test now walks subdirectories recursively |
| Appendix layout tests | **PASS** — NQ142 sections/totals/difference, 150-row no-truncation, NQ43 flat layout |
| macOS app build (`scripts/build_app.sh`) | **PASS** — `.app` built and launched on macOS 15 / x86_64 |
| App file-open, drag-and-drop | File-open path covered by tests and app launch; drag-and-drop not automated |
| Print / PDF export | CSS pagination **PASS** (headless Chromium, A4 594×841 pt, 2/2/2/4+appendix pages); **native WKWebView print panel pending** (no UI automation permission in this environment) |
| Visual diff of macOS renderer vs reference screenshots | **PARTIAL** — 01/GTGT, 05/KK-TNCN and 05/QTT-TNCN headers/tables match the captured reference; 03/TNDN reference capture is invalid (splash screen), so it remains pending |

## 6. Reproduction commands

```bash
# data-level validation (any OS with Python 3.10+)
python3 iTaxViewerMac/scripts/validate_fixtures.py

# macOS build + tests
cd iTaxViewerMac
swift test
scripts/build_app.sh --universal --dmg
```
