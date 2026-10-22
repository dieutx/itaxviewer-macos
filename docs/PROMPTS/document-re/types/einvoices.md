# Type: Hóa đơn điện tử (e-invoices)

**Root:** `TKhai`, `DNghi`, `TBao`, `BCTHSDBLai`, `BLai`  
**Clone hiện tại:** structured field table.

## 1. Inventory

- [ ] Root nào thực tế xuất hiện?
- [ ] Mã mẫu số/ký hiệu hóa đơn.
- [ ] Có nhiều loại (hóa đơn GTGT, bán hàng, điều chỉnh, thay thế…)?
- [ ] Có `PLuc` không?

## 2. Capture

- [ ] Đầu hóa đơn (người bán/mua, MST, địa chỉ).
- [ ] Bảng hàng hóa/dịch vụ: cột, thuế suất, thành tiền.
- [ ] Tổng tiền, thuế, tiền bằng chữ.
- [ ] Chữ ký số/hình ảnh.
- [ ] Orientation/số trang.

## 3. Spec

- `kind: "eInvoice"`.
- `detect` theo root + mẫu số/ký hiệu.
- `headerFields` + `sections` (bảng hàng hóa, tổng).
- Không copy logo/mẫu in.

## 4. Fixture

- `einvoice_minimal.xml`
- `einvoice_multi_rows.xml`
- `einvoice_adjustment.xml`

## 5. Kết quả

`documents/results/einvoice-<mau>.md`.
