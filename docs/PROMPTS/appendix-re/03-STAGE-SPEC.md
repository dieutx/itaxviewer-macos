# Stage 3 — Viết spec JSON

**Mục tiêu:** chuyển ảnh/PDF + cấu trúc XML thành spec máy đọc được, đủ để renderer dựng
lại mà không cần Windows.

**Đầu ra:**

- `docs/reverse-engineering/appendices/<plucID>.json`
- `docs/reverse-engineering/appendices/<plucID>.md`
- cập nhật `PROGRESS.md` + `progress.json` (status `spec-done`)

**Điều kiện vào:** Stage 2 đã `captured` cho `plucID` đó.

---

## 3.1. Schema

```json
{
  "id": "PL01_KHBS",
  "title": "…",
  "citation": "…",
  "orientation": "portrait",
  "pageBreakBefore": true,
  "versions": ["2.9.3"],
  "sourceTemplates": ["XSLT 2.9.3/…"],
  "headerFields": [
    { "code": "01", "label": "Tên người nộp thuế", "source": "Header/tenNNT", "format": "text" }
  ],
  "sections": [
    {
      "id": "Muc_I",
      "title": "I. …",
      "kind": "table",
      "pageBreakBefore": false,
      "recordPath": "Muc_A/Muc_I/Muc_1/ChiTiet",
      "emptyBehaviour": "show-empty-row",
      "columns": [
        { "key": "stt", "title": "STT", "format": "index", "align": "center", "width": "5%" },
        { "key": "ten", "title": "…", "source": "ct2_ten", "format": "text", "align": "left" },
        { "key": "so_tien", "title": "…", "source": "ct3", "format": "number", "align": "right" }
      ],
      "totals": [
        { "code": "[10]", "label": "Tổng cộng", "source": "tongCong_ct10", "format": "number", "formula": null }
      ],
      "rowRules": [],
      "notes": []
    }
  ],
  "unknowns": []
}
```

## 3.2. Từ điển trường

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| `id` | Có | đúng `plucID`, giữ chữ hoa |
| `title` | Có | tiêu đề in, giữ dấu |
| `citation` | Có | nghị quyết/nghị định/thông tư |
| `orientation` | Có | `portrait`/`landscape` |
| `pageBreakBefore` | Có | phụ lục có bắt đầu trang mới? |
| `versions` | Có | version đã kiểm chứng; nếu khác nhau ghi override |
| `headerFields` | Có | `[01]`–`[04]` hoặc numbering riêng |
| `sections` | Có | danh sách mục theo thứ tự |
| `kind` | Có | `table`, `fields`, `mixed`, `note` |
| `recordPath` | table | path tới phần tử lặp |
| `emptyBehaviour` | Có | `show-empty-row`, `hide-section`, `show-header-only` |
| `columns[].source` | Có | path tương đối trong record (hoặc gốc section) |
| `columns[].format` | Có | `text`,`number`,`percent`,`index`,`date`,`checkbox` |
| `columns[].align` | Có | `left`,`right`,`center` |
| `columns[].width` | Nên | % hoặc px tương đối |
| `totals[].formula` | Nếu có | chuỗi công thức, ví dụ `[09] = [08] - [06]` |
| `rowRules` | Nếu có | style/format theo điều kiện |
| `unknowns` | Có | mọi điểm chưa xác minh |

## 3.3. Quy tắc mapping

- `source` là path **tương đối** so với `recordPath` (bảng) hoặc gốc phụ lục (header/tổng).
- Không dùng XPath tuyệt đối dài; dùng path local-name, phân tách `/`.
- Giữ nguyên thứ tự cột như ảnh.
- Mã chỉ tiêu nằm ở cột nào thì ghi `code` trong cột đó hoặc `totals[].code`.
- Nếu một ô có cả label + mã (ví dụ `[05] Tổng cộng`), tách thành `code` + `label`.
- Số âm: dùng format `number`, renderer tự bọc ngoặc.
- Percent: dùng `percent`, không tự thêm `%` nếu bản gốc không có.
- Section không có bảng: dùng `kind: "fields"` và mô tả từng dòng trong `fields`.
- Nếu layout đổi theo version: thêm `versionOverrides: { "2.8.3": { ... } }`.

## 3.4. Validate spec

```powershell
python -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8')); print('OK')" PL01_KHBS.json
```

Hoặc dùng `jq`:

```powershell
Get-Content PL01_KHBS.json -Raw | ConvertFrom-Json | Out-Null; "OK"
```

Kiểm tra thêm:

- [ ] `id` khớp tên file.
- [ ] Mọi `section.id` duy nhất.
- [ ] Mọi `columns[].source` tồn tại trong ít nhất một fixture.
- [ ] `totals[].source` tồn tại.
- [ ] Không có source trỏ tới node chữ ký.

## 3.5. Viết file `.md` đi kèm

`<plucID>.md` gồm:

- ảnh nhúng (relative path);
- bảng section/column/total;
- công thức;
- khác biệt version;
- `unknown`.

## 3.6. Acceptance

- [ ] JSON parse OK.
- [ ] Có đủ section/column/total theo ảnh.
- [ ] Có `unknowns` (có thể rỗng nếu thật sự đủ).
- [ ] `.md` có ảnh + bảng tóm tắt.
- [ ] `progress.json` cập nhật `spec-done`.
