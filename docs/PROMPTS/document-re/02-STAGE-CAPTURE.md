# Stage 2 — Capture bản gốc cho từng loại tài liệu

**Mục tiêu:** có ảnh/PDF đủ để tái tạo layout.

**Đầu ra:** `evidence/documents/<kind>/<id>/*.png`, `*.pdf`, `capture-notes.md`.

---

## 2.1. Nguyên tắc chung

- Mỗi loại tài liệu chụp ít nhất: toàn cửa sổ, phần đầu, từng bảng/section, footer/chữ ký.
- Luôn có PDF và ghi số trang/orientation.
- Case biên: rỗng, âm, thập phân, dài, nhiều bảng, nhiều `PLuc`.
- Nếu ảnh sẽ commit: ẩn danh trước.
- Ghi app version + ngày + mã giả file mẫu.

## 2.2. Ma trận theo loại

### Tờ khai (`declarations`)

- [ ] Header `[01]`–`[11c]` tùy form.
- [ ] Bảng chỉ tiêu (27/16/26/74 dòng…).
- [ ] Section rows, checkbox, dòng tổng.
- [ ] Footer chữ ký + ngày.
- [ ] Phụ lục (xem `appendix-re/02-STAGE-CAPTURE.md`).
- [ ] Orientation + số trang.

### Thông báo (`notices`)

- [ ] Root/mã (`maTBao`, `MSo`), tiêu đề.
- [ ] Cơ quan ban hành, người nhận, địa chỉ.
- [ ] Các đoạn văn/prose, danh sách, bảng (nếu có).
- [ ] Số/ký hiệu văn bản, ngày ban hành.
- [ ] Chữ ký số/hình thức.
- [ ] Khác biệt theo `maTBao`/version.
- [ ] Có `PLuc` không.

### Giấy nộp tiền/chứng từ (`paymentVouchers`)

- [ ] `MA_CTU` / `MAHIEU_CTU` + version.
- [ ] Tiêu đề mẫu.
- [ ] Người nộp (tên, MST, địa chỉ, tài khoản).
- [ ] KBNN/cơ quan thu, tài khoản, mã chương.
- [ ] Nội dung kinh tế/diễn giải.
- [ ] Số tiền bằng số + bằng chữ.
- [ ] Ngày lập, chữ ký.
- [ ] Các `NDUNG_CTU` lặp (nếu có).
- [ ] Orientation/số trang.

### Đăng ký thuế (`registration`)

- [ ] `maHSo`/`maDKy`, tiêu đề.
- [ ] Các mục thông tin doanh nghiệp/người đại diện.
- [ ] Bảng ngành nghề, vốn, lao động (nếu có).
- [ ] Tài liệu đính kèm.

### Danh mục (`catalogs`)

- [ ] Mã danh mục, tên.
- [ ] Cấu trúc bảng/cây.
- [ ] Có render như bảng dữ liệu hay form?

### Hóa đơn điện tử (`e-invoices`)

- [ ] Root (`TKhai`, `DNghi`, `TBao`, …).
- [ ] Mẫu số/ký hiệu hóa đơn.
- [ ] Người bán/mua, MST, địa chỉ.
- [ ] Bảng hàng hóa/dịch vụ, thuế, tổng.
- [ ] Chữ ký số.

### Hải quan (`customs`)

- [ ] Root `TOKHAI_OBJ`/`TOKHAISUA_OBJ`/Envelope.
- [ ] Số tờ khai, loại hình, cơ quan hải quan.
- [ ] Bảng hàng hóa, thuế, container (nếu có).
- [ ] Tài liệu đính kèm.

## 2.3. Ảnh cần chụp

```text
evidence/documents/<kind>/<id>/
  original-<id>-p1.png
  original-<id>-sections.png
  original-<id>-print-preview.png
  original-<id>-export.pdf
  capture-notes.md
```

`capture-notes.md`:

```markdown
# <kind>/<id>

- App version:
- Windows:
- Ngày giờ:
- File mẫu: sample-001
- Orientation:
- PDF pages:
- Sections:
- Rows:
- Unknown:
```

## 2.4. Acceptance

- [ ] Ảnh toàn cửa sổ + từng section/bảng.
- [ ] PDF + page count/orientation.
- [ ] Case biên theo loại.
- [ ] `capture-notes.md` có `unknown`.
- [ ] Không có dữ liệu thật nếu commit.
- [ ] `progress.json` cập nhật `captured`.
