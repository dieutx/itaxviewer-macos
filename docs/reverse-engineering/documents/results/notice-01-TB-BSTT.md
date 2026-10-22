# Kết quả RE — `notice/01-TB-BSTT`

## 1. Nhận diện

- Kind: `notice`
- Root element: `TBao` (bắt buộc; **không** phải `TBaoThueDTu`)
- Mã hiển thị / mã hồ sơ: `MSo=01/TB-BSTT`, in ra `01/TB-BSTT-NNT`
- Version: `PBan=2.1.0`
- File mẫu: synthetic `notice-01-TB-BSTT-minimal.xml`
- Ngày capture: 2026-10-22
- App version: xem `paymentVouchers/CT-01` capture-notes

## 2. Inventory

- Có trong registry: có (`data/DMucTBao.xml`, key `maTBao="01/TB-BSTT"`)
- Số file trong corpus: 1 (fixture clone cũ **không** hợp lệ với bản gốc)
- Số section: 5
- Số bảng: 0 (khối "Nơi nhận"/chữ ký là bảng bố cục)
- Số bản ghi: 0
- Có `PLuc`: có phụ lục ngoài (`TBao_107_TB_BSTT_PL.xslt`) — chưa capture

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
| header | fields | `TBao/STBao`, `TBao/DLTBao` | — | — |
| recipient | fields | `TBao/DLTBao` | — | — |
| body | prose | `TBao/DLTBao` | — | — |
| note | prose | literal | — | — |
| signature | fields | literal + `sigDiv` | — | — |

## 5. Mã chỉ tiêu và công thức

| Mã | Nhãn | Nguồn | Công thức |
|---|---|---|---|
| — | Số | `TBao/STBao/So` | literal |
| — | Ngày | `TBao/STBao/NTBao` | `dd/mm/yyyy` |
| — | Lần | `TBao/DLTBao/LGTrinh` | "THÔNG BÁO (Lần n)" |
| — | Ngày phân tích | `TBao/DLTBao/NPTich` | `dd/mm/yyyy` |
| — | Hạn bổ sung | `TBao/DLTBao/THGTBSung` | `dd`, `mm`, `yyyy` |

## 6. Evidence

- Ảnh: `evidence/documents/notices/01-TB-BSTT/original-01-TB-BSTT-p1.png`
- PDF: `…/original-01-TB-BSTT-export.pdf` (1 trang)
- Ghi chú: `…/capture-notes.md`

## 7. Test

- Fixture: `documents/fixtures/notice-01-TB-BSTT-minimal.xml`
- Test name: chưa có
- Kết quả: bản gốc render OK; fixture cũ `tbao_107_bstt.xml` bị từ chối
- Ngày chạy: 2026-10-22

## 8. Trạng thái

- Stage 1: done
- Stage 2: done (main form)
- Stage 3: done
- Stage 4: done (main form)
- Stage 5: một phần
- Verification: partial

## 9. Unknown / blocker

- Phụ lục giải trình chưa capture.
- Các mã `01/TB-*` khác chưa capture.

## 10. Ghi chú

- Đây là lỗi nhận diện trong bản clone: `maTBao` của thông báo là khoá registry dạng chuỗi
  (`01/TB-BSTT`), không phải số `107`; root là `TBao`, không phải `TBaoThueDTu`.
- Mẫu số in ra bị hard-code `01/TB-BSTT-NNT` — giữ nguyên hành vi gốc.
