# declaration / 01/GTGT

- Kind: declaration
- Root: `HSoThueDTu`
- Mã: `842` → `01/GTGT`
- Version: 2.8.3
- Renderer clone: full
- Fixture: `gtgt_842_return.xml`, `gtgt_842_nq142.xml`

## Kết quả đã chạy

| Hạng mục | Kết quả |
|---|---|
| `swift test` | PASS |
| Render rows | 27 |
| PDF | 2 trang A4 portrait (594×841 pt) |
| Parser | UTF-8, security pass |
| Header | `[01a]`–`[11c]` |
| Reference | `docs/reverse-engineering/evidence/reference-gtgt.png` |

## Đã sửa

- `[01b]` dùng `kieuKy` → “Tháng 06 năm 2025” thay vì khoảng ngày.
- GTGT header gộp cặp cột giá trị/thuế.
- Dòng B in đậm; dòng A (checkbox) in đậm.
- Phụ lục NQ142 có layout riêng.

## Còn lại

- Verify pixel-level với Windows (ảnh đã có, chưa so từng pixel).
- Native WKWebView print panel chưa automate.

## Trạng thái

`implemented-macos`, verification **partial**.
