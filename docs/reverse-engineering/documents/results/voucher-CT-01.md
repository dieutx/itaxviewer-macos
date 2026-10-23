# Kết quả RE — `paymentVoucher/CT-01`

## 1. Nhận diện

- Kind: `paymentVoucher`
- Root element: `CHUNGTU`
- Mã hiển thị / mã hồ sơ: `MA_CTU=01` (mẫu C1-02/NS)
- Version: `PBAN_TLIEU_XML=4.0.1` (registry có 1.0.0/3.0.0/4.0.0/4.0.1/4.0.2)
- File mẫu: `test-data/anonymized/gnt/sample-01.xml`, synthetic `voucher-CT-01-vnd-multi.xml`
- Ngày capture: 2026-10-22
- App version: không có DisplayVersion; `update/latest.xml` pkgver 2.8.4; jar SHA-256 `5AC31CBA…9F4E`

## 2. Inventory

- Có trong registry: có (`data/DMucCTu.xml`, 5 entry, chỉ `maCTu=01`)
- Số file trong corpus: 4 (3 anonymised + 1 synthetic)
- Số section: 5 (header, payer, detail table, amount-in-words, KBNN)
- Số bảng: 2 (chi tiết 8 cột; KBNN 3 cột)
- Số bản ghi: 1–3 `ROW_CTIET`
- Có `PLuc`: không

## 3. Layout

- Orientation: portrait
- Số trang PDF: 1 (cả hai mẫu)
- Lề: PD4ML 20/20/20/10 mm (top/left/right/bottom)
- Font/size: Times New Roman; số liệu 10.5–12 pt
- Lặp header khi sang trang: không (PDF 1 trang, chưa có mẫu dài)
- Tổng: một dòng "Tổng tiền" cuối bảng

## 4. Sections / columns

| Section | Kiểu | Record path | Columns | Totals |
|---|---|---|---|---|
| header | fields | `CHUNGTU/NDUNG_CTU_NH` | — | — |
| payer | fields | `…/NDUNG_CTU/CHUNGTU_HDR` | — | — |
| detail | table | `…/CHUNGTU_CTIET/ROW_CTIET` | 8 | `TONG_TIEN` |
| amountInWords | note | `…/CHUNGTU_HDR/TONG_TIEN` | — | — |
| kbac | fields | — | 3 | — |

## 5. Mã chỉ tiêu và công thức

| Mã | Nhãn | Nguồn | Công thức |
|---|---|---|---|
| — | Số tiền VND | `TIEN_PNOP` | `formatNumber` (dấu `.` ngăn nghìn) |
| — | Số nguyên tệ | `TIEN_PNOP` | `toFormatDecimall` (2 số lẻ) khi `MA_NGUYENTE=USD` |
| — | Tổng tiền | `TONG_TIEN` | `formatNumber` |
| — | Tiền bằng chữ | `TONG_TIEN` | `DocTienBangChu` + " đồng" |

## 6. Evidence

- Ảnh: `evidence/documents/paymentVouchers/CT-01/original-CT-01-p1.png`, `…-vnd-multi-p1.png`, `…-vnd-multi-totals.png`
- PDF: `…/original-CT-01-export.pdf` (1 trang), `…/original-CT-01-vnd-multi-export.pdf` (1 trang)
- Ghi chú capture: `…/capture-notes.md`

## 7. Test

- Fixture: `documents/fixtures/voucher-CT-01-vnd-multi.xml`
- Test name: `testVoucherCT01UsesOfficialLayout`, `testAmountInWordsHandlesZeroAndSmallValues`
- Kết quả macOS: PASS (layout C1-02/NS + số tiền bằng chữ)
- Kết quả: bản gốc mở và render OK (ảnh/PDF ở trên)
- Ngày chạy: 2026-10-22

## 8. Trạng thái

- Stage 1 inventory: done
- Stage 2 capture: done (2 mẫu)
- Stage 3 spec: done
- Stage 4 fixture: done (1 synthetic)
- Stage 5 handoff: một phần (spec + ảnh + PDF đã nằm trong repo)
- Verification: partial — đã so ảnh gốc; clone macOS chưa render lại để so

## 9. Unknown / blocker

- `GNT_4_0_2.xsl` chưa capture.
- `MA_CTU=02` không có trong registry bản cài này.

## 10. Ghi chú

- Tiền mặt/chuyển khoản là hard-code; `HTHUC_NOP` không được dùng.
- `MA_NGUYENTE=00000` làm trống cột tiền và tiền bằng chữ (quan sát trên ảnh).
