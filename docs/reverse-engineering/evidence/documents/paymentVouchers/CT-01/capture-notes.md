# paymentVouchers/CT-01

- App: iTax Viewer (publisher "Tong cuc thue"), installed 2026-10-21, jar SHA-256 `5AC31CBA3990221004376883D9B90D5A55339F49BF6BC97C56542ED27BFA9F4E`
- Runtime: bundled JRE 1.8.0_112, Windows 11 Pro N 10.0.22631
- Captured: 2026-10-22
- Method: `jre\bin\java.exe -cp itaxviewer.jar seatechit.ihtkk.tool.taxview.TaxViewer <file>`; window captured with `PrintWindow`; PDF obtained with Ctrl+P (app writes temp PDF then opens it)
- Samples:
  - `test-data/anonymized/gnt/sample-01.xml` — `MA_CTU=01`, `PBAN_TLIEU_XML=4.0.1`, `MA_NGUYENTE=00000`, 1 row
  - synthetic `voucher-vnd-multi.xml` — `MA_NGUYENTE=VND`, 3 rows, total 1,234,580,235
- Orientation: portrait
- PDF pages: 1 (both samples), MediaBox 595×842, /Rotate 0
- Sections: header block, payer fields, bank/KBNN fields, checkbox lines, 8-column detail table, totals, amount in words, KBNN block, signature rule
- Rows: 1 (anonymised sample), 3 (synthetic)
- Quirks observed:
  - "Chuyển khoản [X]" is hard-coded; `HTHUC_NOP` is not read.
  - `MA_NGUYENTE=00000` leaves the money columns and the amount-in-words line empty.
  - Detail note is appended as `;Ghi chú : <GHI_CHU>` (or just `;`).
- Unknown: `GNT_4_0_2.xsl`; `MA_CTU=02` is not registered in this install.
