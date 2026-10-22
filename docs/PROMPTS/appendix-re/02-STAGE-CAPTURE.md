# Stage 2 — Capture bản gốc

**Mục tiêu:** có bằng chứng đủ để tái tạo layout mà không cần mở lại Windows.

**Đầu ra:**

- ảnh PNG từng trang/vùng quan trọng;
- PDF export;
- `capture-notes.md` cho từng `plucID`;
- cập nhật `PROGRESS.md` + `progress.json` (status `captured` hoặc `blocked`).

**Chưa được:** viết spec khi chưa đủ ảnh cho các trường hợp bắt buộc.

---

## 2.1. Chuẩn bị file mẫu

1. Chọn 1 file đại diện cho mỗi `plucID` (ưu tiên file có đủ mục).
2. Nếu ảnh/PDF sẽ commit: tạo bản ẩn danh trước (xem Stage 4) hoặc che dữ liệu bằng
   editor ảnh.
3. Nếu không thể ẩn danh: **không chụp** dữ liệu thật; dùng file synthetic đúng cấu trúc
   do HTKK tạo.
4. Ghi mã giả `sample-001`, không ghi MST.

## 2.2. Ma trận capture

| Trường hợp | Bắt buộc | Ghi chú |
|---|---|---|
| Đầy đủ mục/bảng | Có | Ảnh toàn cửa sổ + từng mục |
| Mục rỗng | Có | App ẩn mục hay hiện “không có phát sinh”? |
| Chỉ mua, không bán (GTGT) | Có | |
| Chỉ bán, không mua (GTGT) | Có | |
| Giá trị âm | Có | Ngoặc đơn? |
| Thập phân 10,5 | Có | Dấu phẩy? |
| ≥ 200 dòng | Có | Phân trang + lặp header |
| Nhiều `<PLuc>` | Nếu có | Thứ tự và page break |
| Nhiều version | Nếu có | Khác biệt layout |

## 2.3. Ảnh cần chụp

1. Toàn cửa sổ app, zoom 100%.
2. Tiêu đề + khối `[01]`–`[04]` + đơn vị tiền.
3. Từng section: header cột + 2–3 dòng dữ liệu + dòng tổng.
4. Vùng chuyển trang (nếu bảng dài).
5. Print Preview.
6. Trang đầu + trang cuối PDF.

Tên file:

```text
docs/reverse-engineering/evidence/appendices/<plucID>/
  original-<plucID>-p1.png
  original-<plucID>-p2.png
  original-<plucID>-section-I.png
  original-<plucID>-section-II.png
  original-<plucID>-print-preview.png
  original-<plucID>-export.pdf
  capture-notes.md
```

## 2.4. Ghi `capture-notes.md`

```markdown
# <plucID> — capture notes

- App version:
- Windows:
- Ngày giờ:
- File mẫu: sample-001 (synthetic / anonymised)
- Orientation: portrait / landscape
- Số trang PDF:
- Số section:
- Số dòng từng bảng:
- Có lặp header khi sang trang: có / không / không rõ
- Tổng chỉ ở cuối hay lặp mỗi trang: …
- Unknown:
  - …
```

## 2.5. Đo layout

Ghi lại (ước lượng % hoặc mm):

- lề trên/dưới/trái/phải;
- chiều rộng tương đối từng cột;
- font family/size (nếu đọc được);
- căn lề: trái/phải/giữa;
- border, bold, italic;
- vị trí mã chỉ tiêu (cột nào, có `[ ]` không);
- page break trước/sau section;
- header/footer của phụ lục.

## 2.6. Hành vi đặc biệt

- Khi section không có dữ liệu.
- Khi tổng = 0.
- Khi giá trị âm.
- Khi thiếu node tùy chọn.
- Khi `PLuc` không map registry (app gốc có crash NPE?).
- Khi file có nhiều phụ lục: thứ tự render có theo XML không?

## 2.7. Acceptance

- [ ] Có ảnh toàn cửa sổ + ảnh từng section.
- [ ] Có PDF và ghi số trang/orientation.
- [ ] Có case rỗng/âm/thập phân/dài.
- [ ] `capture-notes.md` đầy đủ, có `unknown`.
- [ ] Không có dữ liệu thật trong ảnh/PDF nếu sẽ commit.
- [ ] `PROGRESS.md` + `progress.json` cập nhật `captured`.
