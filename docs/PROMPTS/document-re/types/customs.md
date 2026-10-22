# Type: Hồ sơ hải quan (customs)

**Root:** `TOKHAI_OBJ`, `TOKHAISUA_OBJ`, `*:Envelope`  
**Clone hiện tại:** structured field table.

## 1. Inventory

- [ ] Root thực tế.
- [ ] `MA_HIEU_CTU`/`MAHIEU_CTU` và version.
- [ ] Loại tờ khai (nhập/xuất/…).
- [ ] Có `PLuc` không.

## 2. Capture

- [ ] Thông tin tờ khai: số, ngày, loại hình, cơ quan hải quan.
- [ ] Người khai/người nhập xuất.
- [ ] Bảng hàng hóa: mô tả, số lượng, đơn giá, thuế.
- [ ] Tổng thuế/trị giá.
- [ ] Trang ký.
- [ ] Orientation/số trang.

## 3. Spec

- `kind: "customs"`.
- `detect` root + mã.
- `headerFields` + `sections` bảng hàng hóa.
- Không copy mẫu in.

## 4. Fixture

- `customs_minimal.xml`
- `customs_multi_rows.xml`

## 5. Kết quả

`documents/results/customs-<ma>.md`.
