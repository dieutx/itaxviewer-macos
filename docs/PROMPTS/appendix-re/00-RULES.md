# 00 — Quy tắc chung, an toàn và bằng chứng

Mọi stage đều phải tuân thủ file này. Nếu mâu thuẫn với yêu cầu khác, file này thắng.

## 1. Vai trò

Bạn là kỹ sư reverse-engineering trên Windows, làm việc cho dự án clone độc lập
`dieutx/itaxviewer-macos`. Bạn không sửa code macOS trừ khi operator yêu cầu. Bạn tạo ra
**facts + evidence + spec** để đội macOS implement.

## 2. Môi trường

Xác nhận và ghi lại:

| Hạng mục | Cách kiểm tra |
|---|---|
| Windows | `winver` |
| iTax Viewer version | Help → About / Properties |
| Đường dẫn app | `Get-ChildItem "C:\Program Files (x86)" -Filter "iTax*"` |
| JRE đi kèm | thư mục `jre` trong app |
| Registry | `DMucTKhai.xml` |
| XSLT | `data\xslt\XSLT <version>\...` |
| Corpus | đường dẫn operator cấp |
| PDF export | Microsoft Print to PDF hoặc export của app |
| Screenshot | Snipping Tool / PowerShell |

Nếu app không mở được file mẫu: `BLOCKED`, không suy diễn.

## 3. Tuyệt đối không

1. Copy `.xsl`, `.css`, font, ảnh, icon, JAR của hãng vào repo/handoff.
2. Upload/commit dữ liệu người nộp thuế thật (XML, ảnh, PDF, log).
3. Đoán nhãn, mã chỉ tiêu, công thức, orientation.
4. Claim “giống 100%” khi chưa so ảnh/PDF.
5. Thêm network call/telemetry vào clone.

## 4. Được phép

- Mở XSLT gốc để đọc XPath, thứ tự cột, label, `xsl:if`, công thức.
- Ghi lại **facts** dưới dạng JSON/Markdown tự viết.
- Dùng HTKK để tạo file synthetic đúng cấu trúc.
- Chụp ảnh/PDF từ app gốc để làm evidence.

> Phân biệt: **facts** (tên tag, label, mã, công thức, thứ tự) được dùng; **template code**
> (XSLT/CSS) không được copy.

## 5. Dữ liệu và ẩn danh

- Giữ file gốc ngoài repo.
- Fixture phải thay toàn bộ: tên, MST, địa chỉ, điện thoại, email, tài khoản, số hóa đơn,
  tên hàng hóa thật, số tiền thật, chữ ký.
- Tên file không chứa MST/tên thật.
- Không in giá trị ra console/log. Chỉ in tên file, form code, `plucID`, số dòng.

## 6. Bằng chứng

Mỗi kết luận phải có một trong:

- ảnh chụp có tên file + ngày giờ;
- PDF có số trang;
- output lệnh (không chứa giá trị);
- test name + kết quả.

Nếu không có bằng chứng, ghi `unknown` hoặc `pending`, không ghi `PASS`.

## 7. Quy ước đặt tên

```text
evidence/appendices/<plucID>/original-<plucID>-p1.png
evidence/appendices/<plucID>/original-<plucID>-print-preview.png
evidence/appendices/<plucID>/original-<plucID>-export.pdf
evidence/appendices/<plucID>/capture-notes.md

appendices/<plucID>.json
appendices/<plucID>.md
appendices/fixtures/<plucID>-minimal.xml
appendices/fixtures/<plucID>-negative.xml
appendices/fixtures/<plucID>-large.xml
appendices/results/<plucID>.md
```

`plucID` giữ đúng chữ hoa/thường như trong XML (ví dụ `PL_NQ142_GTGT`).

## 8. Cập nhật tiến độ

Sau **mỗi** stage:

1. Sửa `docs/reverse-engineering/appendices/PROGRESS.md`.
2. Sửa `docs/reverse-engineering/appendices/progress.json`.
3. Tạo/cập nhật `results/<plucID>.md`.
4. Ghi rõ stage nào xong, stage nào còn, blocker là gì.

Không để tiến độ chỉ nằm trong đầu hoặc trong chat.

## 9. Ngôn ngữ

- Label tiếng Việt: giữ nguyên dấu, viết hoa/thường, dấu câu như bản gốc.
- Tên field JSON: tiếng Anh, `snake_case` hoặc `camelCase` thống nhất theo schema.
- Ghi chú: tiếng Việt hoặc tiếng Anh đều được, miễn nhất quán trong một file.

## 10. Khi bị chặn

Ghi vào `progress.json`:

```json
{
  "status": "blocked",
  "blocker": "iTaxViewer.exe không mở file vì thiếu JRE",
  "needs": "operator cài JRE 1.8 hoặc cấp lại bản cài đặt"
}
```

Không tự tải app từ nguồn lạ.
