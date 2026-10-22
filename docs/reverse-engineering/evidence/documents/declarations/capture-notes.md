# declarations — Windows capture (2026-10-22)

App: iTax Viewer (publisher "Tong cuc thue"), jar SHA-256 `5AC31CBA3990221004376883D9B90D5A55339F49BF6BC97C56542ED27BFA9F4E`,
JRE 1.8.0_112, Windows 11 Pro N 10.0.22631.
Method: `TaxViewer <file>` → `PrintWindow` screenshot; Ctrl+P → app-generated PDF in `%TEMP%`.

| Fixture | maTKhai / version | Windows result | PDF pages | Evidence |
|---|---|---|---|---|
| `test-data/declarations/gtgt_842_return.xml` | 842 / 2.8.3 | opens, 01/GTGT layout | **2** (A4 portrait) | `842/original-842-p1.png`, `842/original-842-p2.png`, `842/original-842-export.pdf` |
| `test-data/declarations/tncn_394_05kk_tt92.xml` | 394 / 2.1.6 | opens, 05/KK-TNCN layout | **1** (A4 portrait) | `394/original-394-p1.png`, `394/original-394-export.pdf` |
| `test-data/declarations/tncn_953_05qtt.xml` | 953 / 2.9.3 | opens, 05/QTT-TNCN layout | **2** (A4 portrait) | `953/original-953-p1.png`, `953/original-953-export.pdf` |
| `test-data/declarations/tndn_892_03tndn_v2.9.4.xml` | 892 / 2.9.4 | **blocked** — `NullPointerException` in `TaxViewExceptionHandler`; no window | — | stderr 2026-10-22 |
| `Tests/…/gtgt_842_nq142.xml` | 842 / 2.8.3 + PLuc | opens; `Tờ khai` + `PL 142/2024/QH15 – 174/2024/QH15 – 204/2025/QH15` links shown | 2 (declaration) | `842/original-842-nq142-p1.png` |

Observations from the original screenshots:

- 01/GTGT: title has the italic sub-line "(Áp dụng đối với người nộp thuế tính thuế theo phương pháp
  khấu trừ có hoạt động sản xuất kinh doanh)"; `[11]` has its own label line, then `[11a]-[11c]`
  share one line. Table header labels only 4 columns (STT, Chỉ tiêu, Giá trị…, Thuế GTGT); the
  `[code]` cells are unlabeled narrow columns.
- 05/KK-TNCN: `[06] Địa chỉ` is full width; `[07] Quận/Huyện` + `[08] Tỉnh/Thành phố`,
  `[09] Điện thoại` + `[10] Fax` + `[11] E-mail` share lines; `[12]-[20]` are the agent block.
  The printed document is **one page**.
- 892 fixture: the original crashes; page count unknown, capture blocked.

PLuc appendix capture: clicking the `PL …` status-bar link did not change the view in two attempts
(coordinates 125/200 px on the link row). Appendix screenshot remains **not captured**.
