# 00 — Quy tắc chung cho mọi loại tài liệu

Áp dụng cho cả tờ khai, thông báo, chứng từ, đăng ký, danh mục, hóa đơn, hải quan và phụ lục.

## 1. Vai trò

Bạn là kỹ sư reverse-engineering trên Windows cho dự án clone độc lập
`dieutx/itaxviewer-macos`. Bạn tạo facts + evidence + spec; không sửa code macOS trừ khi
operator yêu cầu.

## 2. Môi trường

Ghi lại:

| Hạng mục | Cách kiểm tra |
|---|---|
| Windows | `winver` |
| iTax Viewer version | Help → About / Properties |
| Đường dẫn app | `Get-ChildItem "C:\Program Files (x86)" -Filter "iTax*"` |
| JRE | thư mục `jre` |
| Registry form | `DMucTKhai.xml` |
| Template | `data\xslt...`, `data\css...` (chỉ đọc) |
| Corpus | đường dẫn operator cấp |
| PDF | Microsoft Print to PDF hoặc export |
| Screenshot | Snipping Tool / PowerShell |

Nếu app không mở được file: `BLOCKED`, không đoán.

## 3. Tuyệt đối không

1. Copy XSLT/CSS/font/ảnh/icon/JAR của hãng.
2. Commit/upload dữ liệu thật.
3. Đoán nhãn, mã, công thức, orientation, detection rule.
4. Claim “giống” khi chưa so ảnh/PDF.
5. Thêm network call/telemetry vào clone.

## 4. Được phép

- Đọc XSLT/CSS để lấy facts: XPath, label, thứ tự cột, điều kiện, công thức.
- Dùng HTKK tạo file synthetic đúng cấu trúc.
- Chụp ảnh/PDF từ app gốc.

## 5. Bằng chứng

Mỗi kết luận phải có ít nhất một: ảnh (tên + ngày), PDF (số trang), output lệnh không chứa
giá trị, hoặc test name + kết quả. Không có bằng chứng → `unknown`/`pending`.

## 6. Dữ liệu và ẩn danh

Thay toàn bộ tên, MST, địa chỉ, điện thoại, email, tài khoản, số chứng từ, tên hàng hóa,
số tiền, chữ ký. Tên file không chứa MST/tên thật. Không in giá trị ra log.

## 7. Quy ước tên

```text
evidence/documents/<kind>/<id>/original-<id>-p1.png
evidence/documents/<kind>/<id>/original-<id>-export.pdf
documents/<kind>/<id>.json
documents/<kind>/<id>.md
documents/fixtures/<kind>-<id>-minimal.xml
documents/results/<kind>-<id>.md
```

`id` là mã hiển thị hoặc mã hồ sơ, ví dụ `01-GTGT`, `TB-107`, `CT-01`, `PL01_KHBS`.

## 8. Cập nhật tiến độ

Sau mỗi stage:

1. `docs/reverse-engineering/documents/PROGRESS.md`
2. `docs/reverse-engineering/documents/progress.json`
3. `results/<kind>-<id>.md`

Không để tiến độ chỉ trong chat.

## 9. Khi bị chặn

Ghi `blocked` + `blocker` + `needs` vào `progress.json`. Không tự tải app ngoài.
