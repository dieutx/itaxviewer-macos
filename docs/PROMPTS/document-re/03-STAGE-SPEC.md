# Stage 3 — Spec JSON cho từng loại tài liệu

**Mục tiêu:** mô tả layout + mapping đủ để renderer dựng lại.

**Đầu ra:** `documents/<kind>/<id>.json`, `<id>.md`, cập nhật `progress.json` (`spec-done`).

---

## 3.1. Schema chung

```json
{
  "id": "01-GTGT",
  "kind": "declaration",
  "root": "HSoThueDTu",
  "detect": {
    "maTKhai": "842",
    "versions": ["2.8.3"],
    "filingTypes": ["C", "B"]
  },
  "title": "…",
  "orientation": "portrait",
  "pageBreakBefore": false,
  "headerFields": [],
  "sections": [],
  "appendices": {
    "mode": "dynamic",
    "known": ["PL_NQ43_GTGT", "PL_NQ142_GTGT"]
  },
  "unknowns": []
}
```

## 3.2. Detection

Mỗi loại phải có quy tắc nhận diện rõ:

| Kind | Detect |
|---|---|
| declaration | root `HSoThueDTu` + `maTKhai` + `pbanTKhaiXML` |
| notice | root trong `TBaoThueDTu`, `THONGBAO`, `THONG_BAO`, `TBAO_*` + `maTBao`/`MSo` |
| paymentVoucher | root `CHUNGTU` + `MA_CTU`/`MAHIEU_CTU` + `PBAN_TLIEU_XML` |
| registration | root `DKyThueDTu` + `maHSo`/`maDKy` |
| catalog | root `DanhMucDTu` |
| eInvoice | root `TKhai`, `DNghi`, `TBao`, `BCTHSDBLai`, `BLai` |
| customs | root `TOKHAI_OBJ`, `TOKHAISUA_OBJ`, `*:Envelope` |

Detection không được dựa vào tên file.

## 3.3. Sections

Dùng cùng cấu trúc như appendix:

- `kind`: `table`, `fields`, `prose`, `mixed`, `note`;
- `recordPath`, `columns`, `totals`, `emptyBehaviour`;
- `fields` cho khối label/value;
- `paragraphs` cho thông báo/văn bản.

```json
{
  "id": "body",
  "kind": "prose",
  "paragraphs": [
    { "source": "TBao/NoiDung", "style": "body" }
  ]
}
```

## 3.4. Header fields

- Giữ numbering thật (`[01]`, `[02]`, …).
- Với chứng từ, numbering có thể khác; ghi đúng.
- Với thông báo, có thể không có numbering; dùng `label`.

## 3.5. Bảng

- `source` tương đối với `recordPath`.
- `format`: `text`, `number`, `percent`, `index`, `date`, `checkbox`, `currencyWords`.
- `align`: `left`, `right`, `center`.
- `width`: % tương đối.
- `totals` + `formula`.
- `rowRules` cho bold/negative/hidden.

## 3.6. Chứng từ đặc biệt

- Số tiền bằng chữ: `format: "currencyWords"` và ghi rõ nguồn (`SoTienBangChu`).
- Bảng `NDUNG_CTU`: `recordPath` + cột.
- Nhiều tài khoản/KBNN: `kind: "fields"` hoặc bảng.

## 3.7. Thông báo đặc biệt

- Nội dung có thể là HTML/prose; **không render HTML thô** từ XML. Chỉ text đã escape.
- Ghi rõ đoạn nào là tiêu đề, đoạn nào là nội dung, đoạn nào là danh sách.
- Nếu template gốc dùng ảnh/logo: **không copy**; ghi nhận vị trí, dùng text/placeholder.

## 3.8. Validate

```powershell
python -c "import json,sys; json.load(open(sys.argv[1], encoding='utf-8')); print('OK')" file.json
```

Checklist:

- [ ] JSON parse OK.
- [ ] `id` khớp tên file.
- [ ] `detect` đủ để phân biệt.
- [ ] Mọi `source` tồn tại trong fixture.
- [ ] Không có source trỏ chữ ký.
- [ ] `unknowns` có nội dung nếu chưa chắc.

## 3.9. Acceptance

- [ ] Spec cho ít nhất một mẫu mỗi kind ưu tiên.
- [ ] `.md` có ảnh + bảng tóm tắt.
- [ ] `progress.json` cập nhật `spec-done`.
