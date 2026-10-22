# Stage 4 — Fixture ẩn danh cho từng loại

**Mục tiêu:** fixture nhỏ, an toàn, bao phủ case biên, dùng được cho XCTest/Python.

**Đầu ra:** `documents/fixtures/<kind>-<id>-*.xml`, test, `results/<kind>-<id>.md`.

---

## 4.1. Fixture theo loại

### Tờ khai

- minimal (1 dòng/section)
- empty optional
- negative/decimal
- large (≥ 200 dòng)
- multi-PLuc

### Thông báo

- minimal (1 đoạn)
- notice có bảng
- notice dài nhiều trang
- nhiều `maTBao`/version
- có/không chữ ký

### Giấy nộp tiền

- minimal (1 `NDUNG_CTU`)
- nhiều `NDUNG_CTU`
- số tiền lớn
- có/không tài khoản
- có/không chữ ký

### Đăng ký / danh mục / hóa đơn / hải quan

- minimal đúng cấu trúc
- case nhiều bảng/dòng
- case thiếu optional

## 4.2. Ẩn danh

Bắt buộc thay:

- [ ] tên, MST, địa chỉ, điện thoại, email
- [ ] số tài khoản/ngân hàng/KBNN
- [ ] số chứng từ/hóa đơn/hợp đồng
- [ ] tên hàng hóa/dịch vụ thật
- [ ] số tiền thật
- [ ] chữ ký/X509

Kiểm tra:

```powershell
Select-String -Path ".\fixtures\*.xml" -Pattern "mst|tenNNT|dchiNNT|email|dthoai|soTK|ten_HSo"
```

## 4.3. Vị trí

```text
iTaxViewerMac/Tests/iTaxViewerCoreTests/Fixtures/
  gtgt_842_nq142.xml
  notice_107_minimal.xml
  voucher_ct01_minimal.xml
  ...
```

## 4.4. Test tối thiểu

- [ ] classification đúng kind/code.
- [ ] tiêu đề/nhãn/mã.
- [ ] bảng + tổng.
- [ ] số âm/thập phân.
- [ ] section rỗng.
- [ ] large không cắt.
- [ ] không còn raw path cho kind đã có spec.

## 4.5. Acceptance

- [ ] Fixture parse OK.
- [ ] Không dữ liệu thật.
- [ ] Có minimal + case biên.
- [ ] Test chạy/pass hoặc `BLOCKED`.
- [ ] `progress.json` cập nhật `fixture-done`.
