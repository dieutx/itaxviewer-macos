# Stage 1 — Inventory toàn bộ loại tài liệu

**Mục tiêu:** biết chính xác iTax Viewer hỗ trợ những root/document kind nào, mã nào, version
nào, template nào, tần suất ra sao — trước khi capture/spec.

**Đầu ra:**

- `docs/reverse-engineering/documents/document-inventory.json`
- `docs/reverse-engineering/documents/document-inventory.md`
- `docs/reverse-engineering/documents/document-usage.csv`
- cập nhật `PROGRESS.md` + `progress.json`

---

## 1.1. Inventory root types

Quét `DMucTKhai.xml`, registry phụ (nếu có), và thư mục template để lập bảng:

| Root element | Kind | Registry/template | Số mã | Ghi chú |
|---|---|---|---|---|
| `HSoThueDTu` | Tờ khai thuế | `DMucTKhai.xml` + `data/xslt` | 410 form codes | có `PLuc` |
| `TBaoThueDTu` | Thông báo | template thông báo | ? | nhiều `maTBao` |
| `THONGBAO`, `THONG_BAO`, `TBAO_*` | Thông báo | ? | ? | |
| `CHUNGTU` | Giấy nộp tiền/chứng từ | `MA_CTU`/`MAHIEU_CTU` | ? | nhiều mẫu |
| `DKyThueDTu` | Đăng ký thuế | ? | ? | |
| `DanhMucDTu` | Danh mục | ? | ? | |
| `TKhai`, `DNghi`, `TBao`, `BCTHSDBLai`, `BLai` | Hóa đơn điện tử | ? | ? | |
| `TOKHAI_OBJ`, `TOKHAISUA_OBJ`, `*:Envelope` | Hải quan | ? | ? | |
| khác | ? | ? | ? | ghi `unknown` |

Không suy đoán kind nếu chưa thấy app xử lý; ghi `unknown`.

## 1.2. Inventory mã trong từng loại

### Tờ khai

- `HSoKhaiThue/TTinChung/TTinTKhaiThue/TKhaiThue/maTKhai`
- `pbanTKhaiXML`, `loaiTKhai`, `tenTKhai`
- `PLuc` con (chuyển sang `appendix-re/`)

### Thông báo

- root element
- `TBao/maTBao`, `pbanTBao`, `tenTBao`
- `MSo`, `maThongBao` (nếu có)
- các section/prose/body
- có bảng/`PLuc` không

### Giấy nộp tiền/chứng từ

- `MA_CTU` / `MAHIEU_CTU`
- `PBAN_TLIEU_XML`
- `SO_GNT` / `SO_CTU`
- các khối: người nộp, KBNN, tài khoản, số tiền, diễn giải
- có nhiều `NDUNG_CTU` không

### Đăng ký / danh mục / hóa đơn / hải quan

- root + mã (`maHSo`, `maDKy`, `MA_HIEU_CTU`, …)
- các bảng lặp
- template tương ứng (nếu tìm thấy)

## 1.3. Inventory corpus

Quét toàn bộ corpus, chỉ ghi:

- root element
- mã nhận diện (form/notice/voucher)
- version
- kind dự đoán theo classifier
- số bảng/section
- số bản ghi
- có `PLuc` không
- có chữ ký không (boolean)

CSV gợi ý:

```text
sample,root,code,version,kind,sections,records,plucs,signature
sample-001,HSoThueDTu,842,2.8.3,declaration,6,120,PL_NQ142_GTGT,no
sample-002,CHUNGTU,01,4.0.1,paymentVoucher,3,1,,no
sample-003,TBaoThueDTu,843,2.5.6,notice,2,0,,no
```

Không dùng tên file thật nếu chứa MST/tên người nộp.

## 1.4. Inventory template

Với mỗi loại, ghi:

- thư mục template (XSLT/CSS) — chỉ path, không copy;
- quy tắc chọn template (theo mã/version/loaiTKhai);
- template có nhánh theo `plucID`, `MA_CTU`, `maTBao` không;
- có template mặc định/fallback không.

## 1.5. Đối chiếu và priority

Bảng:

| Kind | Có trong registry | Thấy trong corpus | Số file | Template | Ưu tiên |
|---|---|---|---|---|---|

Đề xuất priority mặc định:

| Priority | Nhóm |
|---|---|
| P0 | Giấy nộp tiền `CHUNGTU` phổ biến; thông báo `TBaoThueDTu` phổ biến |
| P1 | Tờ khai có phụ lục: 01/GTGT + `PL01_KHBS`/`PL01_1_KHBS`; 03/TNDN + `BaoCaoTaiChinh` |
| P1 | 05/KK-TNCN, 05/QTT-TNCN (và phụ lục nếu có) |
| P2 | Đăng ký thuế, danh mục |
| P2 | Hóa đơn điện tử |
| P3 | Hải quan, long-tail |

Operator có thể đổi; ghi lý do.

## 1.6. Acceptance

- [ ] Có bảng root types + số mã.
- [ ] Có inventory mã cho ít nhất: declarations, notices, vouchers.
- [ ] Có `document-usage.csv` với số file/số bản ghi.
- [ ] Có danh sách `unknown`/`unmapped`.
- [ ] Không có giá trị người nộp thuế.
- [ ] `PROGRESS.md` + `progress.json` cập nhật stage 1.
