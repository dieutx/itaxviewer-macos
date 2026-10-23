# 06 — Đăng ký thuế, danh mục, hóa đơn điện tử, hải quan

Dùng cùng `00-MASTER.md`. Các loại này hiện **chưa có capture** trên macOS.

## 1. Đăng ký thuế (`DKyThueDTu`)

10 mã trong `registration-catalog.csv`:

| Mã | Version | Template |
|---|---|---|
| `216` | 2.0.9 | `01_DK_T_VAN.xslt` |
| `217` | 2.0.9 | `02-DK_T-VAN.xslt` |
| `218` | 2.0.9 | `03-DK_T-VAN.xslt` |
| `219` | 2.0.9 | `04-DK_T-VAN.xslt` |
| `220` | 2.0.9 | `05-DK_T-VAN.xslt` |
| `221` | 2.0.9 | `01_DK_T_VAN-DLT.xslt` |
| `222` | 2.0.9 | `02-DK_T-VAN-DLT.xslt` |
| `223` | 2.0.9 | `03-DK_T-VAN.xslt` |
| `350` | 2.0.9 | `DKyKhaiThueDTu_NNT.xslt` |
| `351` | 2.0.9 | `DKyKhaiThueDTu_DLT.xslt` |

Cần capture:

1. Header (mẫu số, tên hồ sơ, cơ quan thuế).
2. Các khối thông tin: người nộp thuế, địa chỉ, ngành nghề, vốn, người đại diện, đại lý
   thuế, danh sách thành viên/chi nhánh.
3. Bảng lặp (nếu có): cổ đông/thành viên/chi nhánh.
4. Chữ ký, nơi nhận, số trang.

Ưu tiên `216`–`220` (đăng ký mới/ thay đổi) và `350`/`351` (đại lý thuế).

Output: `forms/registration/<maDKy>/spec.json` + evidence + fixture.

## 2. Danh mục (`DanhMucDTu`)

- 1 mẫu, template `XSLTmaDanhMuc`.
- Mục đích: tra cứu danh mục, không phải tờ khai in.
- Chỉ cần capture nếu người dùng thực sự mở; hiện giữ structured view.
- Nếu capture: ghi rõ loại danh mục, cột, cách hiển thị; không cần layout in.

## 3. Hóa đơn điện tử

Root: `TKhai`, `DNghi`, `TBao`, `BCTHSDBLai`, `BLai`. Chưa có registry riêng.

Cần lấy ít nhất 2 mẫu mỗi root (nếu có trong corpus):

1. `TKhai` — tờ khai/thông báo hóa đơn.
2. `DNghi` — đề nghị cấp/đăng ký.
3. `TBao` — thông báo (phân biệt với `TBao` của thông báo thuế: dùng `MSo` regex).
4. `BCTHSDBLai` — báo cáo tình hình sử dụng.
5. `BLai` — bảng kê.

Với mỗi mẫu:

- Ghi `MSo`/`PBan`/root và quy tắc nhận diện.
- Capture form chính + bảng + chữ ký.
- Ghi rõ khác nhau giữa `TBao` hóa đơn và `TBao` thông báo thuế (cùng tên root).

## 4. Hải quan (P3)

- 181 mã / 515 dòng, root `TOKHAI_OBJ`, `TOKHAISUA_OBJ`, `*:Envelope`.
- Ngoài phạm vi thuế nội địa; chỉ làm khi có nhu cầu.
- Nếu làm: chọn 3–5 mẫu đại diện (tờ khai nhập/xuất, sửa, envelope), capture bảng chính,
  không cần toàn bộ 181 mã.

## 5. Output & cập nhật

- Spec: `forms/<kind>/<id>/spec.json` theo schema phù hợp (fields/sections/tables).
- Evidence: `evidence/<kind>/<id>/`.
- Fixture: `test-data/<kind>/`.
- Cập nhật `documents/progress.json` với `kind` tương ứng.

## 6. Handoff

```text
BATCH: OTHER-<...>
LOẠI: <registration|invoice|customs|catalog>
MÃ/ROOT: ...
ĐÃ TẠO: ...
PHÁT HIỆN: ...
UNKNOWNS: ...
```
