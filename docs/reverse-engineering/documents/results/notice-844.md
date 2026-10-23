# Kết quả RE — `notice/844`

## 1. Nhận diện

- Kind: `notice`
- Root element: `TBaoThueDTu` (không prefix)
- Mã hiển thị / mã hồ sơ: `maTBao=844`, mẫu `01-2/TB-TĐT`
- Version: `pbanTBao=2.4.9` (version duy nhất trong registry)
- File mẫu: `test-data/anonymized/notices/sample-02.xml` (đã sửa namespace)
- Ngày capture: 2026-10-22
- App version: xem `paymentVouchers/CT-01` capture-notes

## 2. Inventory

- Có trong registry: có (`data/DMucTBao.xml`)
- Số file trong corpus: 1
- Số section: 5 (header, căn cứ, nhánh chấp nhận, bảng khoản nộp, kết thúc)
- Số bảng: 1 (`IDKhoanNop`); nhánh `N` có bảng lý do
- Số bản ghi: 1
- Có `PLuc`: không

## 3. Layout

- Orientation: portrait
- Số trang PDF: 1
- Lề: 20/20/20/10 mm
- Font/size: Times New Roman
- Lặp header: chưa xác minh
- Tổng: không có

## 4. Sections / columns

| Section | Kiểu | Record path | Columns | Totals |
|---|---|---|---|---|
| header | fields | `TTinTBaoThue` + `trangThai` | — | — |
| accepted | prose | `NDungTBao` | — | — |
| idKhoanNop | table | `NDungTBao/IDKhoanNop/CTietIDKhoanNop` | 5 | — |
| rejected | table | `NDungTBao/LyDo/CTietLyDo` | 4 | — |

## 5. Mã chỉ tiêu và công thức

| Mã | Nhãn | Nguồn | Công thức |
|---|---|---|---|
| — | Số tiền thuế phải nộp | `soTienPNop` | `formatNumber` (`1.000.000`) |
| — | Ghi chú | `loaiToKhai`, `soTienPNop` | "tăng thêm"/"điều chỉnh giảm" khi `Bổ sung` |
| — | Ngày chấp nhận | `ngayHoanThanh`, `ngayChapNhan` | tách ngày/giờ |

## 6. Evidence

- Ảnh: `evidence/documents/notices/844/original-844-p1.png`
- PDF: `…/original-844-export.pdf` (1 trang)
- Ghi chú: `…/capture-notes.md`

## 7. Test

- Fixture: `documents/fixtures/notice-844-minimal.xml`
- Test name: `testNotice844AcceptedBranch`
- Kết quả macOS: PASS (nhánh Y; nhánh N dùng cùng bảng lý do như 843)
- Kết quả: bản gốc render OK
- Ngày chạy: 2026-10-22

## 8. Trạng thái

- Stage 1: done
- Stage 2: done (nhánh `Y`)
- Stage 3: done
- Stage 4: done
- Stage 5: một phần
- Verification: partial

## 9. Unknown / blocker

- Nhánh `N`, số tiền âm chưa capture.

## 10. Ghi chú

- Trích yếu đổi theo `trangThai` (`Y`/`N`).
- Bảng khoản nộp chỉ hiện khi `maDinhDanh` khác rỗng.
