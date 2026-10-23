# Windows RE prompt pack — clone iTax Viewer 90–100%

Bộ prompt này dùng cho agent/người ngồi máy **Windows có cài iTax Viewer gốc**. Mục tiêu là
thu thập bằng chứng + spec để clone giao diện/in của bản gốc, không phải viết code macOS.

## Cách dùng

1. Mở `00-MASTER.md`, copy toàn bộ làm prompt mở đầu cho agent Windows.
2. Chọn batch theo thứ tự wave trong `../reverse-engineering/COVERAGE-REVIEW.md`.
3. Gửi kèm file chuyên biệt:
   - Tờ khai: `01-DECLARATIONS.md` (bao gồm **toàn bộ 17 họ**, không chỉ GTGT)
   - Thông báo: `02-NOTICES.md`
   - Phụ lục: `03-APPENDICES.md`
   - Chứng từ: `04-VOUCHERS.md`
   - Chữ ký số: `05-SIGNATURES.md`
   - Đăng ký/danh mục/hóa đơn/hải quan: `06-OTHER-KINDS.md`
4. Mỗi batch tối đa **5 mẫu** (hoặc 10 mã nếu cùng template) để tránh mất chi tiết.
5. Khi xong, agent Windows trả về **handoff message** theo mẫu ở cuối `00-MASTER.md`.

## Danh sách inventory để chia batch

Các file CSV nằm trong `docs/reverse-engineering/inventory/`:

- `declarations.csv` — lọc `wave=P0` trước, rồi `P1`, `P2`, `P3`.
- `notices.csv` — lọc theo `wave` và `registry`.
- `appendices.csv` — lọc `wave=P0`, `P1`, `P2`.
- `vouchers.csv`, `registration-catalog.csv`.
- `coverage-summary.json` — số liệu tổng.

Không cần capture hết 410 mã tờ khai ngay. Ưu tiên đúng wave; các mã cùng một template
XSLT dùng chung một spec (ghi rõ `sharedTemplateWith`).

## Nguyên tắc bất di bất dịch

- Không copy XSLT/CSS/font/ảnh/icon/JAR của hãng vào repo.
- Không commit dữ liệu thuế thật; fixture phải ẩn danh hoặc synthetic.
- Không đoán nhãn/công thức/version. Không có bằng chứng → ghi `unknown`.
- Mỗi kết luận phải kèm ảnh/PDF/tên test hoặc log không chứa giá trị.
- Chữ ký số chỉ được ghi “valid” khi có kiểm tra mật mã thực sự; nếu chỉ đọc metadata thì
  ghi “metadata only”.
