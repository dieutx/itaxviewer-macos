# Type: Phụ lục (`PLuc`)

Phụ lục là phần lồng trong tờ khai (`HSoThueDTu/.../PLuc`). Quy trình chi tiết nằm ở
`docs/PROMPTS/appendix-re/`.

## Liên kết nhanh

- `appendix-re/01-STAGE-INVENTORY.md`
- `appendix-re/02-STAGE-CAPTURE.md`
- `appendix-re/03-STAGE-SPEC.md`
- `appendix-re/04-STAGE-FIXTURES.md`
- `appendix-re/05-STAGE-HANDOFF.md`
- `appendix-re/types/PL01_KHBS.md`
- `appendix-re/types/PL01_1_KHBS.md`
- `appendix-re/types/BaoCaoTaiChinh.md`
- `appendix-re/types/NQ_GTGT.md`
- `appendix-re/types/05_TNCN.md`
- `appendix-re/types/OTHER.md`

## Trạng thái hiện tại trong clone

| plucID | Trạng thái |
|---|---|
| `PL_NQ43_GTGT` | implemented-macos, cần verify |
| `PL_NQ101_GTGT` | implemented-macos, cần verify |
| `PL_NQ142_GTGT` | implemented-macos, cần verify |
| `PL01_KHBS` | generic-only |
| `PL01_1_KHBS` | generic-only |
| `BaoCaoTaiChinh` | generic-only |
| khác | generic-only/unknown |

## Nguyên tắc

- Mỗi `plucID` là một spec riêng.
- Không gộp nhiều phụ lục thành một bảng phẳng.
- Giữ thứ tự `PLuc` như XML.
- Page break trước mỗi phụ lục.
- Orientation có thể khác tờ khai chính.
- Lưu tiến độ trong `docs/reverse-engineering/appendices/` (sub-kit) và tổng hợp trong
  `documents/progress.json`.
