# Type: Tờ khai thuế (declarations)

**Root:** `HSoThueDTu`  
**Registry:** `DMucTKhai.xml` (410 form codes)  
**Clone hiện tại:** 4 form full, còn lại structured table / fallback.

## 1. Inventory

- [ ] Liệt kê toàn bộ `maTKhai`, `pbanTKhaiXML`, `loaiTKhai`.
- [ ] Xác định form nào có `PLuc`.
- [ ] Xác định form nào có nhiều layout theo version.
- [ ] Xác định form nào clone đã full: 842, 394, 953, 892.

## 2. Capture

- [ ] Header `[01]`–`[11c]` theo form.
- [ ] Bảng chỉ tiêu (số dòng, mã, label, section).
- [ ] Checkbox/indicator đặc biệt.
- [ ] Footer chữ ký/ngày.
- [ ] Orientation/số trang.
- [ ] Phụ lục → `appendix-re/types/`.

## 3. Spec

- Form không có phụ lục: dùng `FormSpec` hiện tại (rows + values).
- Form mới: tạo `FormSpec` mới trong `form-specs.json`.
- Mapping phải trace được từ `docs/reverse-engineering/document-types.md`.
- Không bịa mã/label.

## 4. Fixture

- `declaration_<code>_minimal.xml`
- `declaration_<code>_negative.xml`
- `declaration_<code>_large.xml`
- `declaration_<code>_appendix.xml`

## 5. Ưu tiên

1. Các form phổ biến: 01/GTGT, 03/TNDN, 05/KK, 05/QTT.
2. Các form có phụ lục.
3. Form 2025/2026 mới (TT 89/2025, NQ 204/2025).
4. Long-tail 406 mã.

## 6. Kết quả

Ghi `documents/results/declaration-<code>.md`, cập nhật `progress.json`.
