# Type: Thông báo / văn bản của cơ quan thuế (notices)

**Root:** `TBaoThueDTu`, `THONGBAO`, `THONG_BAO`, `TBAO_TKHOAN_NH`, `TBAO_TKHOAN_NT`,
`TBAO_NGUNG`, `BKE_TBAO`  
**Clone hiện tại:** structured field table, chưa có layout văn bản.

## 1. Cấu trúc đã quan sát

Fixture `tbao_107_bstt.xml`:

```text
TBaoThueDTu
  TBao
    maTBao
    pbanTBao
    MSo
    tenNNT
    mst
    DLTBao
      TNNT
      MST
      DCNNT
      TCQT
      DTCQT
      DCCQT
      NPTich
      THGTBSung
```

File thật có thể có nhiều `TBao`, nội dung dài, bảng, `PLuc`.

## 2. Cần xác định

- [ ] `maTBao` (mã thông báo) → layout/template nào?
- [ ] `MSo` (mẫu số) và `pbanTBao`.
- [ ] Cơ quan ban hành (TCQT/DTCQT/DCCQT) in ở đâu?
- [ ] Tiêu đề, số/ký hiệu, ngày ban hành.
- [ ] Nội dung: prose, danh sách, bảng?
- [ ] Các trường `NPTich`, `THGTBSung` nghĩa là gì?
- [ ] Có `PLuc` không?
- [ ] Chữ ký số/hình ảnh.
- [ ] Có nhiều loại thông báo khác nhau trong cùng root không?

## 3. Capture

- [ ] Ảnh toàn văn bản.
- [ ] Ảnh phần đầu (cơ quan, số ký hiệu).
- [ ] Ảnh bảng/danh sách (nếu có).
- [ ] Ảnh chữ ký/footer.
- [ ] PDF + page count/orientation.
- [ ] Case văn bản dài nhiều trang.
- [ ] Case có bảng.

## 4. Spec

- `kind: "notice"`.
- `headerFields`: cơ quan, số/ký hiệu, ngày, người nhận.
- `sections`: `prose` cho đoạn văn, `table` cho bảng.
- Không render HTML thô từ XML; chỉ text escaped.
- Không copy logo/ảnh; dùng placeholder text nếu cần.

## 5. Fixture

- `notice_107_minimal.xml`
- `notice_long.xml` (≥ 3 trang)
- `notice_table.xml`
- `notice_multi.xml` (nhiều `TBao`)

## 6. Kết quả

`documents/results/notice-<maTBao>.md`.
