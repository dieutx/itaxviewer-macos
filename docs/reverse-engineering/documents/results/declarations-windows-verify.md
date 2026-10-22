# Kết quả RE — xác minh tờ khai trên Windows (2026-10-22)

Mục tiêu: mở lại 4 fixture tờ khai bằng **bản gốc Windows** để có mốc so sánh thật (thay cho
ảnh reference cũ), ghi số trang PDF và các khác biệt bố cục.

## 1. Kết quả chạy

| Mã | Fixture | Bản gốc mở? | PDF trang | Ghi chú |
|---|---|---|---|---|
| 842 (01/GTGT) | `gtgt_842_return.xml` | ✅ | **2** | khớp số trang clone |
| 394 (05/KK-TNCN) | `tncn_394_05kk_tt92.xml` | ✅ | **1** | clone từng ghi 2 trang → lệch |
| 953 (05/QTT-TNCN) | `tncn_953_05qtt.xml` | ✅ | **2** | khớp |
| 892 (03/TNDN) | `tndn_892_03tndn_v2.9.4.xml` | ❌ `NullPointerException` | — | **blocked**, không claim |

Ảnh/PDF: `evidence/documents/declarations/<mã>/`, chi tiết trong `capture-notes.md`.

## 2. Khác biệt bố cục quan sát được (bản gốc)

### 01/GTGT (842)

- Có phụ đề in nghiêng dưới tiêu đề: "(Áp dụng đối với người nộp thuế tính thuế theo phương pháp
  khấu trừ có hoạt động sản xuất kinh doanh)".
- `[11]` là một dòng nhãn riêng; `[11a]`, `[11b]`, `[11c]` nằm chung một dòng.
- Khung "Mẫu số: 01/GTGT" có viền, đặt bên phải; phần quốc hiệu canh giữa.
- Bảng: header chỉ đặt nhãn cho 4 cột (STT, Chỉ tiêu, Giá trị hàng hóa/dịch vụ, Thuế GTGT);
  các ô mã `[21]`, `[22]`… là cột hẹp không có nhãn riêng.

### 05/KK-TNCN (394)

- `[06] Địa chỉ` chiếm cả dòng.
- `[07] Quận/Huyện` + `[08] Tỉnh/Thành phố` cùng dòng.
- `[09] Điện thoại` + `[10] Fax` + `[11] E-mail` cùng dòng.
- `[12]`–`[20]` là khối đại lý thuế (tên, MST, địa chỉ, quận/huyện, tỉnh, điện thoại, fax, email,
  hợp đồng).
- Chỉ **1 trang** A4 dọc.

## 3. Chưa làm được

- Phụ lục NQ142: bấm link `PL 142/2024/QH15 – 174/2024/QH15 – 204/2025/QH15` trên thanh trạng thái
  không đổi nội dung (2 lần thử). Cần UIA/điều khiển khác — ghi `blocked`, chưa có ảnh phụ lục.
- 892: app gốc lỗi NPE với fixture hiện tại; cần fixture khác trước khi kết luận.

## 4. Trạng thái

- Capture: 842/394/953 xong; 892 blocked; PLuc blocked.
- Verification clone ↔ Windows: **partial** (mới có ảnh/PDF gốc, chưa render lại bằng app macOS).
