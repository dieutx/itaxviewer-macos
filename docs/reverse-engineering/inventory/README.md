# Inventory phục vụ RE

Sinh tự động bằng:

```bash
python3 docs/reverse-engineering/tools/generate_coverage.py
```

| File | Nội dung | Cách dùng |
|---|---|---|
| `declarations.csv` | 410 mã `maTKhai`, version, template, orientation | lọc `wave` để chia batch |
| `notices.csv` | 158 dòng registry × 122 mã thông báo | lọc `wave` + `registry` |
| `appendices.csv` | 210 phụ lục, số tờ khai cha | lọc `wave`, ưu tiên `parentCount` lớn |
| `vouchers.csv` | 5 dòng chứng từ CT-01 | capture theo version |
| `registration-catalog.csv` | 10 đăng ký thuế + 1 danh mục | batch riêng |
| `coverage-summary.json` | số liệu tổng | báo cáo |

Quy ước `wave`:

- `done`: đã có layout macOS.
- `P0`: làm ngay (mẫu phổ biến, có trong corpus thật, hoặc chặn mục tiêu 90%).
- `P1`: nghiệp vụ phổ biến.
- `P2`: ít dùng, quét theo template.
- `P3`: mẫu nội bộ/không có mã hiển thị.

Prompt tương ứng nằm trong `docs/PROMPTS/windows-re/`.
