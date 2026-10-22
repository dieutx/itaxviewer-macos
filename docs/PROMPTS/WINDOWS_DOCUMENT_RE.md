# Prompt tổng: reverse-engineer mọi loại tài liệu của iTax Viewer trên Windows

> **Dùng file này** khi giao việc cho agent trên Windows. Nó bao quát **tất cả** loại tài
> liệu: tờ khai, phụ lục, thông báo, giấy nộp tiền, đăng ký, danh mục, hóa đơn điện tử,
> hải quan — không chỉ 01/GTGT.

## Mục tiêu

Tạo ra bộ **facts + ảnh/PDF + spec JSON + fixture ẩn danh + tiến độ** để clone macOS
(`dieutx/itaxviewer-macos`) render giống bản gốc, cho từng loại tài liệu và từng mã.

## Bộ prompt đã chia nhỏ

Toàn bộ hướng dẫn chi tiết nằm trong `docs/PROMPTS/document-re/`:

| File | Nội dung |
|---|---|
| `document-re/README.md` | cấu trúc kit, cách chạy, status |
| `document-re/00-RULES.md` | quy tắc an toàn, evidence, không copy vendor |
| `document-re/01-STAGE-INVENTORY.md` | inventory mọi root type + mã + template |
| `document-re/02-STAGE-CAPTURE.md` | chụp ảnh/PDF theo từng loại |
| `document-re/03-STAGE-SPEC.md` | schema spec JSON cho document |
| `document-re/04-STAGE-FIXTURES.md` | fixture ẩn danh + test |
| `document-re/05-STAGE-HANDOFF.md` | bàn giao + tích hợp macOS |
| `document-re/types/declarations.md` | tờ khai |
| `document-re/types/notices.md` | thông báo/văn bản |
| `document-re/types/payment-vouchers.md` | giấy nộp tiền/chứng từ |
| `document-re/types/registration-catalog.md` | đăng ký/danh mục |
| `document-re/types/einvoices.md` | hóa đơn điện tử |
| `document-re/types/customs.md` | hải quan |
| `document-re/types/appendices.md` | phụ lục, trỏ sang `appendix-re/` |

Phụ lục chi tiết (PL01_KHBS, NQ142, Báo cáo tài chính…):
`docs/PROMPTS/appendix-re/`.

## Thứ tự bắt buộc

1. `document-re/00-RULES.md` + xác nhận môi trường.
2. `document-re/01-STAGE-INVENTORY.md` cho **tất cả** root types.
3. Chốt priority với operator.
4. Với mỗi loại/mã: `02-STAGE-CAPTURE` → `03-STAGE-SPEC` → `04-STAGE-FIXTURES`.
5. Phụ lục: làm thêm `appendix-re/`.
6. `05-STAGE-HANDOFF`.
7. Cập nhật `docs/reverse-engineering/documents/PROGRESS.md` + `progress.json` sau mỗi bước.

## Ưu tiên mặc định

| Priority | Nhóm |
|---|---|
| P0 | Giấy nộp tiền `CHUNGTU` phổ biến, thông báo `TBaoThueDTu` phổ biến |
| P1 | Tờ khai 01/GTGT + `PL01_KHBS`/`PL01_1_KHBS`; 03/TNDN + `BaoCaoTaiChinh` |
| P1 | 05/KK-TNCN, 05/QTT-TNCN |
| P2 | Đăng ký thuế, danh mục, hóa đơn điện tử |
| P3 | Hải quan, long-tail |

Operator có thể đổi; ghi lý do vào `progress.json`.

## Tuyệt đối không

- Copy XSLT/CSS/font/ảnh/JAR của hãng vào repo.
- Commit/upload dữ liệu người nộp thuế thật.
- Đoán nhãn/mã/công thức/orientation.
- Ghi `PASS`/`verified` khi chưa chạy và chưa so ảnh/PDF.

## Lưu tiến độ

Sau mỗi stage:

- `docs/reverse-engineering/documents/PROGRESS.md` (người đọc)
- `docs/reverse-engineering/documents/progress.json` (máy đọc)
- `docs/reverse-engineering/documents/results/<kind>-<id>.md` (kết quả từng tài liệu)

Không để tiến độ chỉ trong chat.
