# Type: Đăng ký thuế và danh mục

## Đăng ký thuế (`DKyThueDTu`)

**Clone hiện tại:** structured field table.

Cần xác định:

- [ ] `maHSo` / `maDKy`, tiêu đề.
- [ ] Thông tin doanh nghiệp: tên, MST, địa chỉ, người đại diện.
- [ ] Ngành nghề, vốn, lao động (bảng?).
- [ ] Tài liệu đính kèm.
- [ ] Orientation/số trang.

Capture: toàn văn bản + bảng ngành nghề + footer.
Fixture: `registration_minimal.xml`, `registration_multi.xml`.

## Danh mục (`DanhMucDTu`)

**Clone hiện tại:** structured field table.

Cần xác định:

- [ ] Mã danh mục, tên danh mục.
- [ ] Cấu trúc bảng/cây.
- [ ] App gốc render bảng hay chỉ text?
- [ ] Có phân trang/lặp header không.

Fixture: `catalog_minimal.xml`, `catalog_large.xml`.

## Kết quả

`documents/results/registration-<maHSo>.md`, `documents/results/catalog-<ma>.md`.
