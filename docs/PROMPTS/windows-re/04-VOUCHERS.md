# 04 — Chứng từ / giấy nộp tiền (payment vouchers)

Dùng cùng `00-MASTER.md`. Inventory: `docs/reverse-engineering/inventory/vouchers.csv`.

## 1. Hiện trạng

| Mã | Version | Trạng thái macOS | Template |
|---|---|---|---|
| `CT-01` | 4.0.1 | **Đã có layout** C1-02/NS (VND, nhiều dòng, số tiền bằng chữ) | `GNT_4_0_1.xsl` |
| `CT-01` | 1.0.0 | structured view | `GNT.xsl` |
| `CT-01` | 3.0.0 | structured view | `GNT_3_0_0.xsl` |
| `CT-01` | 4.0.0 | structured view | `GNT_4_0_0.xsl` |
| `CT-01` | 4.0.2 | structured view | `GNT_4_0_2.xsl` |

Ngoài registry còn `MA_CTU=02` (chưa có trong bản cài hiện tại) — nếu có mẫu phải capture.

## 2. Cần capture

### 2.1 Theo version

- 1.0.0, 3.0.0, 4.0.0, 4.0.2: mỗi version 1 ảnh + 1 PDF, so sánh với 4.0.1.
- Ghi rõ version nào layout giống nhau; nếu giống, spec dùng `sharedLayoutWith`.

### 2.2 Theo tình huống

1. **VND nhiều dòng** (`NDUNG_CTU/CHUNGTU_CTIET/ROW_CTIET` ≥ 3 dòng).
2. **USD**: cột "Số nguyên tệ" thay cho "Số tiền VND"; tổng tiền; số tiền bằng chữ.
3. **`MA_NGUYENTE` rỗng hoặc `00000`**: cột tiền có để trống không? Dòng tiền bằng chữ?
4. **Số tiền âm**: dấu ngoặc, vị trí, chữ.
5. **Nhiều `NDUNG_CTU`**: mỗi `NDUNG_CTU` lặp lại toàn bộ thân chứng từ (header + bảng +
   KBNN). Ghi rõ ngắt trang giữa các `NDUNG_CTU`.
6. **`MAHIEU_CTU`/`SO_CTU` rỗng**: in dấu `............` hay bỏ trống.
7. **KBNN block**: luôn trống (phần KBNN ghi tay) hay có dữ liệu?
8. **`HTHUC_NOP`**: xác nhận lại template hard-code "Tiền mặt [ ] Chuyển khoản [X]".
9. **Chữ ký**: khối chữ ký in gì; có ảnh/seal không (không copy ảnh).

## 3. Câu hỏi phải trả lời

1. Tiêu đề, mẫu số C1-02/NS, căn cứ pháp lý (TT 84/2016).
2. Bố cục header: mã hiệu, số, số tham chiếu, tiền mặt/chuyển khoản, loại tiền.
3. Thứ tự và nhãn các trường người nộp/nộp thay/ngân hàng/KBNN.
4. Bảng chi tiết: 8 cột? Tiêu đề chính xác? Cột nào ẩn theo `MA_NGUYENTE`?
5. `GHI_CHU` nối vào cột nội dung thế nào (`;Ghi chú : ...` hay `;`).
6. Dòng tổng: nhãn "Tổng tiền", vị trí, có in khi `MA_CTU=01`?
7. Số tiền bằng chữ: quy tắc đọc (lăm/mốt/tư, "không trăm", "linh"), đơn vị.
8. Checkbox tài khoản thu (`STK_THU`), `ID_TK_KNGHI`.
9. Số trang, orientation, lề.
10. Chữ ký số hiển thị/in thế nào (xem thêm `05-SIGNATURES.md`).

## 4. Fixture tối thiểu

- `voucher-CT-01-4.0.2-vnd.xml`
- `voucher-CT-01-usd.xml`
- `voucher-CT-01-empty-amount.xml`
- `voucher-CT-01-negative.xml`
- `voucher-CT-01-multi-ndung.xml`
- `voucher-CT-02-*.xml` (nếu có)

Tất cả ẩn danh; không dùng MST/tên thật.

## 5. Output

- `docs/reverse-engineering/documents/paymentVouchers/CT-01-<version>.json` (hoặc một file
  `CT-01.json` có `variants` theo version nếu layout giống).
- `documents/results/voucher-CT-01-<version>.md`
- Evidence: `evidence/documents/paymentVouchers/CT-01/<version>/...`
- Cập nhật `documents/progress.json`.

## 6. Handoff

```text
BATCH: VOUCHER-<...>
CT-01 version <...>: PDF <n> trang — VND/USD — <số dòng>
ĐÃ TẠO: documents/paymentVouchers/CT-01.json, fixtures, evidence
KHÁC BIỆT VERSION: ...
UNKNOWNS: ...
```
