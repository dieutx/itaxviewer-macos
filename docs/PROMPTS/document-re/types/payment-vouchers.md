# Type: Giấy nộp tiền / chứng từ (payment vouchers)

**Root:** `CHUNGTU`  
**Mã:** `MA_CTU` / `MAHIEU_CTU`, version `PBAN_TLIEU_XML`  
**Clone hiện tại:** structured field table, chưa có layout chứng từ.

## 1. Cấu trúc đã quan sát

Fixture `gnt_chungtu.xml`:

```text
CHUNGTU
  NDUNG_CTU_NH
    MAHIEU_CTU
    SO_CTU
    NDUNG_CTU
      CHUNGTU_HDR
        PBAN_TLIEU_XML
        ID_CTU
        SO_GNT
        MA_CTU
        HTHUC_NOP
        MST_NNOP
        TEN_NNOP
```

File thật có thể có thêm: địa chỉ, tài khoản, KBNN, cơ quan thu, nội dung kinh tế, số tiền
bằng số/chữ, nhiều `NDUNG_CTU`.

## 2. Cần xác định

- [ ] `MA_CTU` nào tồn tại? (01, 02, …)
- [ ] Mỗi mã có layout khác nhau không?
- [ ] `PBAN_TLIEU_XML` ảnh hưởng layout không?
- [ ] Các khối: người nộp, người nhận, KBNN, tài khoản, thuế.
- [ ] Số tiền bằng số + bằng chữ (field nào?).
- [ ] `NDUNG_CTU` lặp? Bảng hay khối?
- [ ] Chữ ký/ngày lập.
- [ ] Có `PLuc` không.

## 3. Capture

- [ ] Ảnh toàn chứng từ.
- [ ] Ảnh phần người nộp + KBNN.
- [ ] Ảnh bảng nội dung/số tiền.
- [ ] Ảnh chữ ký.
- [ ] PDF + page count/orientation.
- [ ] Case nhiều `NDUNG_CTU`.
- [ ] Case số tiền lớn.

## 4. Spec

- `kind: "paymentVoucher"`.
- `detect`: `MA_CTU` + version.
- `headerFields`: người nộp, MST, địa chỉ, tài khoản.
- `sections`:
  - thông tin KBNN/cơ quan thu;
  - bảng nội dung kinh tế;
  - tổng tiền;
  - tiền bằng chữ (`format: "currencyWords"`);
  - chữ ký.
- Không copy mẫu in/font/logo.

## 5. Fixture

- `voucher_ct01_minimal.xml`
- `voucher_ct01_multi.xml` (nhiều `NDUNG_CTU`)
- `voucher_large_amount.xml`
- `voucher_no_account.xml`

## 6. Kết quả

`documents/results/voucher-<MA_CTU>.md`.
