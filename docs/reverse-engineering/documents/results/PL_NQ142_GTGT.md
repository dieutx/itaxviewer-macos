# appendix / PL_NQ142_GTGT

- Kind: appendix (GTGT VAT reduction)
- Parent: 01/GTGT (`842`)
- Citation: NQ 142/2024/QH15
- Renderer clone: structured
- Fixture: `gtgt_842_nq142.xml`

## Layout đã dựng

- Khối `[01]`–`[04]`.
- Mục I: mua vào (tên, giá trị, thuế GTGT) + `[05]`, `[06]`.
- Mục II: bán ra (tên, giá trị, thuế suất quy định, thuế suất sau giảm, thuế GTGT được giảm)
  + `[07]`, `[08]`.
- Mục III: `[09] = [08] - [06]`.

## Kiểm tra

| Hạng mục | Kết quả |
|---|---|
| File thật 2026 (ngoài repo) | 1.132 dòng bảng, đủ `[05]`–`[09]`, không raw path |
| Test fixture | PASS |
| 150-row test | PASS (không cắt) |
| PDF synthetic | 3 trang (2 trang tờ khai + 1 trang phụ lục) |

## Còn lại

- Capture bản gốc Windows để verify từng nhãn/cột/tổng (chưa có ảnh).
- Kiểm tra `PL_NQ204_GTGT`/phụ lục 2026 nếu chính sách mới dùng ID khác.

## Trạng thái

`implemented-macos`, verification **pending**.
