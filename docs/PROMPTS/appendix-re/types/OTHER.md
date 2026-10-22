# Type: mọi `plucID` còn lại

Dùng file này khi `plucID` không thuộc các nhóm đã có file riêng.

## 1. Quy trình

1. Stage 1: thêm vào inventory, xác định form cha/version/tần suất.
2. Stage 2: chụp ảnh/PDF theo `02-STAGE-CAPTURE.md`.
3. Stage 3: spec JSON theo `03-STAGE-SPEC.md`.
4. Stage 4: fixture theo `04-STAGE-FIXTURES.md`.
5. Stage 5: handoff.

## 2. Câu hỏi đặc biệt cho ID lạ

- `plucID` có trong registry không?
- App gốc có render được không, hay crash NPE?
- Có phải là phụ lục lồng trong phụ lục (`DSachPLuc` con) không?
- Có nhiều version với layout khác nhau không?
- Có phải chỉ là danh sách tài liệu/hồ sơ, không phải bảng số liệu?
- Có page break/orientation riêng không?

## 3. Mẫu kết quả

```markdown
# <plucID>

- Form: …
- Version: …
- Orientation: …
- Pages: …
- Sections: …
- Rows: …
- Status: spec-done / fixture-done / handoff-done
- Evidence: …
- Unknown: …
```

## 4. Ưu tiên long-tail

- ID có trong corpus thật > ID chỉ có trong registry.
- ID có nhiều dòng/bảng > ID chỉ có vài field.
- ID dùng cho form phổ biến (01/GTGT, 03/TNDN) > form hiếm.
