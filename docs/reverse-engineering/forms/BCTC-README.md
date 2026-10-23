# Financial statements 701, 702 and 1254

These specifications contain factual official labels, six-column table structure,
field paths and source hashes from the installed Windows registry-selected templates.
The Swift renderer is independently authored. Vendor XSLT, styles, scripts, fonts and
images are not distributed.

| Code | Display / XML version | Selected source | Data rows / mapped paths |
|---|---|---|---:|
| 701 | B01/BCTC / 2.3.5 | `TKhai_BCTC_107_DD.xslt` | 34 / 102 |
| 702 | B05/BCTC / 2.3.5 | `TKhai_BCTC_107_DG.xslt` | 18 / 54 |
| 1254 | B01/BCTC / 2.9.0 | `TKhai_BCTC24_2024_Nam.xslt` | 66 / 198 |

The columns are STT, Chỉ tiêu, Mã số, Thuyết minh, Số cuối năm and Số đầu năm.
Each data row maps one explanatory reference and two yearly amounts. Explanatory
references are text: leading zeros and dots must survive unchanged. Amounts use
Vietnamese grouping, decimal comma and parentheses for negative numbers.

The header says “Tại ngày … tháng … năm …”, sourced from
`TKhaiThue/KyKKhaiThue/kyKKhaiDenNgay`. Codes 701/702 use the TT107 identity and audit
blocks. Code 1254 uses the TT24 supervising-agency/entity header. Footer names come from
the statement root for 701/702 and `PhanKy` for 1254. In particular, the 702 representative
path is **`thuTruongdonVi`**, whereas 701 uses **`thuTruongDonVi`**. Names printed in
signature positions are document data and do not verify an electronic signature.

Unknown statement leaves remain visible in a separately labelled path/value table;
unknown versions use the existing structured fallback. The three associated statement
appendix families have not been promoted to dedicated layouts by this batch.

Each code has independently generated minimal, zero and negative fixtures under its
`fixtures/` directory. The minimal fixture is mirrored as `financial_<code>_static.xml`
in XCTest resources. All identities are invented, tax codes are zero placeholders and
no signature is included. Distinct amounts distinguish the beginning/end-of-year columns.

Executed on Windows on 2026-10-23: PowerShell validated JSON array shapes and all fixture
paths; the root agent executed `py -X utf8 docs/reverse-engineering/tools/oracle_batch.py`
and confirmed every BCTC amount was present in the selected templates' MSXML output.
This establishes field presence in transformed HTML, not Windows JavaScript number
formatting or UI/print parity. Local transformed vendor HTML stays in gitignored `_re/`.

`FinancialStatementTests.swift` checks all mapped values, raw explanatory references,
period/header differences, exact footer case, negative formatting, unknown-data escaping
and preservation beyond 5,000 leaves, and rejection of uninspected versions. Their macOS
execution and native PDF evidence must be recorded from the actual subsequent CI run.
Windows screenshots/PDF pagination and cross-platform visual parity remain **pending**.
