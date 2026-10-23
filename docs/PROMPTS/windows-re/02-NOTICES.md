# 02 — Thông báo / văn bản cơ quan thuế

Dùng cùng `00-MASTER.md`. Inventory: `docs/reverse-engineering/inventory/notices.csv`.
Hiện trạng: **122 mã** (158 dòng registry) trên 9 registry; **3 mã đã capture**:
`843`, `844`, `01/TB-BSTT`.

## 1. Quy tắc nhận diện đã xác minh

- `TBaoThueDTu`: root **không prefix** (prefix `ns0:` bị app gốc từ chối).
  `maTBao`/`pbanTBao` nằm trong `TBaoThue/TTinChung/TTinTBaoThue`.
- `TBao` (họ `TBaoHDDT`): dùng `MSo` + `PBan`, **không** dùng `maTBao`; ví dụ
  `MSo=01/TB-BSTT`, `PBan=2.1.0`. Clone cũ `maTBao=107` bị bản gốc từ chối.
- Nhóm `01/TB-*` có thể là thông báo hóa đơn điện tử (root `TBao`) hoặc thông báo thuế.
- Mỗi registry có bộ mã riêng; cùng số `01` ở registry khác nhau là mẫu khác nhau.

## 2. P0 — 11 mã còn lại

| Registry | Mã | Version | Ghi chú |
|---|---|---|---|
| `DMucTbao.xml` | `01/TB-BSTT-NNT` | 2.1.0 | Cùng họ 01/TB-BSTT nhưng có phụ lục |
| `DMucTbao.xml` | `01/TB-NSD` | 2.1.0 | Thông báo người sử dụng |
| `DMucTbao.xml` | `01/TB-SSĐT` | 2.1.0 | Sai sót đăng ký thuế |
| `DMucTbao.xml` | `01/TB-TNĐT` | 2.1.0 | Thông báo thuế điện tử |
| `DMucTbao.xml` | `01/TB-ĐKĐT` | 2.1.0 | Đăng ký điện tử |
| `DMucTbao.xml` | `01/CCTT-TB` | 2.1.0 | Cung cấp thông tin |
| `DMucTbao.xml` | `448` | 2.2.4/2.5.2/2.5.3/3.0.0 | |
| `DMucTbao.xml` | `450` | 2.2.4–2.5.6 | |
| `DMucTbao.xml` | `451` | 2.2.4/2.2.5 | |
| `DMucTbao.xml` | `801` | 2.2.0/2.5.6 | |
| `DMucTbao.xml` | `818` | 1.0.0/2.5.6/2.8.9 | |
| `DMucTbao.xml` | `960` | 2.5.7/3.0.0 | |
| `DMucTbao.xml` | `998` | 4.0.0/4.1.0 | |

## 3. P1 — 90 mã trong `DMucTbao.xml`

Xem `notices.csv` (lọc `wave=P1`). Danh sách mã:

```text
01, 01GD_KQuaXThuc, 02, 03, 04, 05, 06, 07, 08, 09,
194, 196, 197, 198, 199, 200, 2004, 201, 202, 203,
205, 206, 207, 208, 209, 210, 211, 212, 213, 214,
215, 222, 262, 263, 264, 300, 3001, 301, 302, 303,
352, 353, 354, 397, 398, 399, 400, 407, 415, 416,
417, 418, 419, 440, 441, 449, 454, 688, 689, 691,
692, 693, 694, 695, 696, 697, 698, 699, 701, 704,
705, 706, 707, 708, 709, 819, 820, 821, 8431, 845,
846, 847, 900, 915, 916, 917, 961, 968, 970, 999
```

Chia batch 10 mã/lần. Ưu tiên các mã có version mới (4.0.x) và các mã 448/450/451/801/818
đã nằm ở P0.

## 4. P2 — 51 dòng thuộc registry chứng từ/hóa đơn

Gồm `DMucTBaoNtdt.xml`, `DMucTBaoNtdt22.xml`, `DMucTbao_InCDoi.xml`,
`DMucBKeKDTT.xml`, `DMucTBaoKDTT.xml`, `DMucXNhanCTuNtdt.xml`, `DmucTSoatNtdt.xml`,
`DmucBtruNtdt.xml`. Các mã trùng số với P1 nhưng khác registry/layout; khi capture phải
mở đúng loại file (hóa đơn điện tử, đối chiếu, biên bản…), không dùng file thuế nội địa.

## 5. Mỗi mã cần capture gì

1. **Nhánh mặc định**: `trangThai` nếu có; form chính.
2. **Nhánh từ chối**: `trangThai=N` (nếu mẫu có); bảng lý do.
3. **Bảng dữ liệu**: lý do, mã định danh khoản nộp, danh sách hồ sơ, bảng kê.
4. **Phụ lục** (`PLuc`/`TBao_*`): in kèm hay tách trang.
5. **Footer**: nơi nhận, chữ ký, mã tra cứu, số trang.
6. **Header**: mã mẫu, số, ngày, trích yếu, cơ quan ban hành.

Với mỗi mẫu tạo 3 fixture:

- `notice-<id>-minimal.xml` — nhánh chính.
- `notice-<id>-rejected.xml` — nhánh từ chối (nếu có).
- `notice-<id>-table.xml` — có bảng/danh sách.

## 6. Spec JSON

Dùng schema `documents/notices/*.json` hiện có. Bắt buộc thêm:

- `detect`:
  - `root`, `registry`, `versions`, `template`, `templateForCapturedVersion`
  - `namespaceRule` (prefix bị từ chối hay không)
  - `keyFields`: `maTBao` hay `MSo`, `pbanTBao` hay `PBan`
- `branches`: mảng `{ "when": {"trangThai": ["Y"]}, "sections": [...] }`
- `tables`: `recordPath`, `columns` (label/source/format/align/width), `totals`
- `verifiedAgainst`: app version, ngày, số trang PDF, orientation
- `unknowns`: câu hỏi cụ thể

## 7. Câu hỏi phải trả lời

1. Tiêu đề/trích yếu nào hard-code, trường nào lấy từ XML?
2. `tenTBao` có được in không, hay bị thay bằng chuỗi cố định?
3. Nhánh `Y/N` khác nhau những đoạn nào?
4. Bảng lý do có mấy cột, nhãn chính xác, thứ tự?
5. Có bảng mã định danh khoản nộp không; cột nào?
6. Số trang, orientation, ngắt trang, lặp header?
7. Phụ lục in cùng hay trang riêng; mẫu số phụ lục?
8. Chữ ký/nơi nhận in thế nào?

## 8. Batch plan

| Batch | Nội dung |
|---|---|
| NOTICE-0A | 6 mã `01/TB-*` + `01/CCTT-TB` |
| NOTICE-0B | `448`, `450`, `451`, `801`, `818`, `960`, `998` |
| NOTICE-1A…1I | 10 mã/lần theo danh sách P1 |
| NOTICE-2A… | Registry hóa đơn/chứng từ |

## 9. Handoff

```text
BATCH: NOTICE-<...>
MÃ: <id>/<version> — registry <...> — PDF <n> trang
NHÁNH: Y/N — bảng: <...> — phụ lục: <...>
ĐÃ TẠO: documents/notices/<id>.json, documents/fixtures/notice-<id>-*.xml,
        evidence/documents/notices/<id>/*
UNKNOWNS: ...
```
