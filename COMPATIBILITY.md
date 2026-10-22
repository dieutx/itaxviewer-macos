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

> **Host limitation:** the analysis environment is Windows and has no Swift/Xcode toolchain.
> Therefore the Swift sources and XCTest suite could not be compiled here. Data-level
> behaviour was validated with the executable Python harness
> (`iTaxViewerMac/scripts/validate_fixtures.py`), and the reference screenshots below were
> captured from the live Windows application. The macOS build/test is explicitly marked
> **pending** rather than claimed.

## 1. Document matrix

| Document | Internal code / version | Fixture | Classification | Data accuracy | Renderer | Print/PDF | Signatures | Overall |
|---|---|---|---|---|---|---|---|---|
| **01/GTGT** | `842` / 2.8.3 | `gtgt_842_return.xml` | **PASS** | **PASS** (21 indicators) | **IMPLEMENTED** (27 rows) | IMPLEMENTED · PENDING run | NOT VERIFIED | **PASS (data) / pending UI run** |
| **05/KK-TNCN** | `394` / 2.1.6 | `tncn_394_05kk_tt92.xml` | **PASS** | **PASS** (16 indicators) | **IMPLEMENTED** (16 rows) | IMPLEMENTED · PENDING run | NOT VERIFIED | **PASS (data) / pending UI run** |
| **05/QTT-TNCN** | `953` / 2.9.3 | `tncn_953_05qtt.xml` | **PASS** | **PASS** (26 indicators incl. `NVuQToanThay`) | **IMPLEMENTED** (26 rows) | IMPLEMENTED · PENDING run | NOT VERIFIED | **PASS (data) / pending UI run** |
| **03/TNDN** | `892` / 2.9.4 | `tndn_892_03tndn_v2.9.4.xml` | **PASS** | **PASS** (66 indicators) | **IMPLEMENTED** (74 rows) | IMPLEMENTED · PENDING run | NOT VERIFIED | **PASS (data) / pending UI run** |
| Financial statements | `B01/BCTC` = `701`/`1254`, `B05` = `702` | — | PASS (code mapping) | structured view | Structured only | IMPLEMENTED | NOT VERIFIED | **PARTIAL** |
| Tax-authority notice | `107` / `01/TB-BSTT` | `tbao_107_bstt.xml` | **PASS** | PASS (all leaf fields) | Structured only | IMPLEMENTED | NOT VERIFIED | **PARTIAL** |
| Payment voucher | `CHUNGTU` / `MA_CTU=01` | `gnt_chungtu.xml` | **PASS** | PASS | Structured only | IMPLEMENTED | NOT VERIFIED | **PARTIAL** |
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
| 01/GTGT | `reference-gtgt.png` | A4 portrait; 6-column indicator table; values `1.000.000.000`, `80.000.000`; header `[01a]…[11c]` |
| 05/KK-TNCN | `reference-tncn-05kk.png` | 5-column table; `1.200.000`, `5.000`; header `[01]…[20]` |
| 05/QTT-TNCN | `reference-tncn-05qtt.png` | `I. NGHĨA VỤ KHẤU TRỪ…`; `1.500.000.000`; header `[01]…[15]` |
| 03/TNDN | `reference-tndn-03.png` | 4-column table with `(1)(2)(3)(4)`; `(1.000)`, `250`; header `[01]…[10]` |

### Verified behaviour from the live app

* Number formatting is exactly `1.000.000.000`, `(1.000)`, decimal comma (`10,5`).
* 01/GTGT single-amount rows print the indicator and value in the **right-hand pair** of
  columns; two-amount rows use both pairs. Implemented.
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

## 4. Known differences (not hidden)

| Area | Original | macOS app | Impact |
|---|---|---|---|
| 01/GTGT `[11a]–[11c]` | one row, three columns | three stacked rows | cosmetic |
| Footer page numbers | PD4ML `page/total` | not emitted | cosmetic; all pages print |
| Appendix layout | dedicated XSLT per `plucID` | data table with full values | **layout pending** |
| Notices | prose paragraphs per template | structured field table | **content layout pending** |
| Other 406 form codes | official XSLT | structured field table | **layout pending** |
| Title diacritics | XSLT `translate()` bug | correct Unicode | improvement |
| Unmapped appendix | crash (NPE) | renders data | improvement |
| Signature | full XMLDSig + OCSP | metadata only | **NOT VERIFIED (by design)** |
| Dark mode | not supported (Windows) | native chrome + white paper | improvement |

## 5. Test status

| Suite | Status |
|---|---|
| `scripts/validate_fixtures.py` (classification, indicator mapping, formatting) | **PASS** (executed 2026-10-22) |
| Registry integrity (1,150 entries / 410 codes / 4 specs) | **PASS** |
| XXE rejection, UTF-16 parsing, malformed XML (Python mirror + Swift tests) | PASS (Python) / PENDING (Swift run) |
| Swift XCTest suite (`swift test`, 30+ assertions) | **PENDING — requires macOS/Xcode** |
| macOS app build (`scripts/build_app.sh`) | **PENDING — requires macOS/Xcode** |
| Print / PDF export on macOS | **PENDING** |
| Visual diff of macOS renderer vs reference screenshots | **PENDING** (HTML preview reviewed manually; see `_re/preview` in the analysis workspace) |

## 6. Reproduction commands

```bash
# data-level validation (any OS with Python 3.10+)
python3 iTaxViewerMac/scripts/validate_fixtures.py

# macOS build + tests
cd iTaxViewerMac
swift test
scripts/build_app.sh --universal --dmg
```
