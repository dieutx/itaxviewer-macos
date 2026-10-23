# Kết quả RE — `notice/843`

## 1. Nhận diện

- Kind: `notice`
- Root element: `TBaoThueDTu` (không prefix)
- Mã hiển thị / mã hồ sơ: `maTBao=843`, mẫu `01-01/TB-TĐT`
- Version: `pbanTBao=2.5.6`
- File mẫu: `test-data/anonymized/notices/sample-01.xml` (đã sửa namespace `ns0:` → default)
- Ngày capture: 2026-10-22
- App version: xem `paymentVouchers/CT-01` capture-notes

## 2. Inventory

- Có trong registry: có (`data/DMucTBao.xml`; 843 có 7 version)
- Số file trong corpus: 1
- Số section: 4 (header, căn cứ, nhánh tiếp nhận, kết thúc)
- Số bảng: 0 ở nhánh `Y`; 1 bảng lý do ở nhánh `N`
- Số bản ghi: 0
- Có `PLuc`: không

## 3. Layout

- Orientation: portrait
- Số trang PDF: 1
- Lề: 20/20/20/10 mm
- Font/size: Times New Roman
- Lặp header khi sang trang: chưa xác minh
- Tổng: không có

## 4. Sections / columns

| Section | Kiểu | Record path | Columns | Totals |
|---|---|---|---|---|
| header | fields | `TBaoThue/TTinChung/TTinTBaoThue` | — | — |
| received | prose | `TBaoThue/NDungTBao` | — | — |
| rejected | prose + table | `NDungTBao/LyDo/CTietLyDo` | 4 | — |
| closing | prose | `NDungTBao/maDVC` | — | — |

## 5. Mã chỉ tiêu và công thức

| Mã | Nhãn | Nguồn | Công thức |
|---|---|---|---|
| — | Số | `soTBao` | + `/TB-TĐT` |
| — | Ngày | `ngayTBao` | `dd/mm/yyyy` → "Hà Nội, ngày …" |
| — | Thời điểm tiếp nhận | `ngayHoSo` | `stringDatetime` tách hh/mi/dd/mm/yyyy |

## 6. Evidence

- Ảnh: `evidence/documents/notices/843/original-843-p1.png`
- PDF: `…/original-843-export.pdf` (1 trang)
- Ghi chú: `…/capture-notes.md`

## 7. Test

- Fixture: `documents/fixtures/notice-843-minimal.xml`
- Test name: `testNotice843UsesOfficialLayout`, `testNotice843RejectedBranchShowsReasonTable`
- Kết quả macOS: PASS (layout công văn, cả nhánh Y và N)
- Kết quả: bản gốc render OK
- Ngày chạy: 2026-10-22

## 8. Trạng thái

- Stage 1 inventory: done
- Stage 2 capture: done (nhánh `Y`)
- Stage 3 spec: done
- Stage 4 fixture: done
- Stage 5 handoff: một phần
- Verification: partial

## 9. Unknown / blocker

- 6 version còn lại chưa capture.
- Nhánh `N` đã capture nhưng chưa có mẫu thật (dùng fixture synthetic).

## 10. Ghi chú

- Root có prefix bị từ chối; default namespace được app bỏ trước khi XSLT.
- Tiêu đề "V/v: Tiếp nhận…" hard-code, `tenTBao` không được in.
