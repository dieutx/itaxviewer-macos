# Tiến độ RE tài liệu — iTax Viewer Windows

Cập nhật lần cuối: **2026-10-22**.

> File này là bản người đọc. Bản máy đọc: `progress.json`. Kết quả chi tiết:
> `results/<kind>-<id>.md`.

## 1. Tổng quan theo loại tài liệu

| Loại | Root | Trạng thái clone | Inventory | Capture | Spec | Fixture | Handoff |
|---|---|---|---|---|---|---|---|
| Tờ khai | `HSoThueDTu` | **partial** — 4 form full, còn lại structured | ✅ | 🟡 4 form | 🟡 4 form | 🟡 4 form | 🟡 |
| Phụ lục | `PLuc` | **partial** — NQ43/101/142 có layout | ✅ sơ bộ | 🟡 | 🟡 | 🟡 | 🟡 |
| Thông báo | `TBaoThueDTu`, `THONGBAO`, … | generic-only | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Giấy nộp tiền | `CHUNGTU` | generic-only | 🟡 CT-01 | ⬜ | ⬜ | ⬜ | ⬜ |
| Đăng ký thuế | `DKyThueDTu` | generic-only | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Danh mục | `DanhMucDTu` | generic-only | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Hóa đơn điện tử | `TKhai`, `DNghi`, … | generic-only | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| Hải quan | `TOKHAI_OBJ`, … | generic-only | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |

Ký hiệu: ✅ xong · 🟡 một phần · ⬜ chưa làm.

## 2. Tờ khai đã có renderer đầy đủ

| Mã | Mẫu số | Version | Render | PDF | Verify Windows | Ghi chú |
|---|---|---|---|---|---|---|
| 842 | 01/GTGT | 2.8.3 | ✅ | ✅ 2 trang | 🟡 header/table | phụ lục NQ142 |
| 394 | 05/KK-TNCN | 2.1.6 | ✅ | ✅ 2 trang | 🟡 header/table | |
| 953 | 05/QTT-TNCN | 2.9.3 | ✅ | ✅ 2 trang | 🟡 header/table | |
| 892 | 03/TNDN | 2.9.4 | ✅ | ✅ 4+1 trang | ⬜ reference invalid | |

## 3. Phụ lục

| plucID | Clone | Capture gốc | Spec | Fixture | Verify |
|---|---|---|---|---|---|
| `PL_NQ142_GTGT` | ✅ layout I/II/III | ⬜ | ✅ | ✅ synthetic | ⬜ |
| `PL_NQ43_GTGT` | ✅ bảng phẳng | ⬜ | ✅ | ✅ test in-memory | ⬜ |
| `PL_NQ101_GTGT` | ✅ bảng phẳng | ⬜ | ✅ | ⬜ | ⬜ |
| `PL01_KHBS` | generic-only | ⬜ | ⬜ | ⬜ | ⬜ |
| `PL01_1_KHBS` | generic-only | ⬜ | ⬜ | ⬜ | ⬜ |
| `BaoCaoTaiChinh` | generic-only | ⬜ | ⬜ | 🟡 fixture tối giản | ⬜ |
| khác | generic-only | ⬜ | ⬜ | ⬜ | ⬜ |

## 4. Việc tiếp theo (đề xuất)

1. Chạy `document-re/01-STAGE-INVENTORY.md` trên Windows cho toàn bộ corpus.
2. Ưu tiên P0: `PL01_KHBS`, `PL01_1_KHBS`.
3. P1: `BaoCaoTaiChinh`, thông báo phổ biến, giấy nộp tiền phổ biến.
4. Cập nhật `progress.json` + `results/*.md` sau mỗi bước.
5. Chỉ chuyển trạng thái `verified` khi có ảnh/PDF đối chiếu.

## 5. Nhật ký thay đổi

| Ngày | Thay đổi | Người |
|---|---|---|
| 2026-10-22 | Tạo tracker; ghi nhận 4 form full + NQ43/101/142; xác định phần còn thiếu | agent |
