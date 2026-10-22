# Type: `PL01_KHBS` — phụ lục 01/KHBS

**Ưu tiên:** P0  
**Form cha quan sát:** `842` (01/GTGT), khai bổ sung  
**Orientation:** cần xác nhận từ registry/app gốc (mặc định nghi portrait)  
**Đã có trong clone:** chưa (fallback raw table)

## 1. Cấu trúc đã quan sát từ XML

```text
PL01_KHBS
  Header
    maTKhai
    tenTKhai
    maGiaoDich
    KyKKhaiThue
      kieuKy
      kyKKhai
      kyKKhaiTuNgay
      kyKKhaiDenNgay
      kyKKhaiTuThang
      kyKKhaiDenThang
    soLan
    mst
    tenNNT
    mstDLyThue
    tenDLyThue
    soHDongDLyThue
    ngayKyHDDLyThue
  ma_DonViTien
  ten_DonViTien
  Muc_A
    Muc_I
      Muc_1
        ChiTiet
        tongCong_ct10
      Muc_2
        DSachPLuc
      Muc_3
        ct3a_1
        ct3a_2
        ct3b
    Muc_II
      ChiTiet        (ct2_ma, ct2_ten, ct3)
      tongCong_ct12
    Muc_III
      ChiTiet        (ct2_ma, ct2_ten, ct3)
      tongCong_ct13
  Muc_B
    Muc_I
      ct_1
      ct_2_so
      ct_2_ngay
      ct_2_CQT_ma
      ct_2_CQT_ten
      ct_3_so
      ct_3_ngay
    Muc_II
      ct_1
      ct_2
```

> Cấu trúc trên lấy từ file thật đã ẩn danh; **không** suy ra label từ tên tag.

## 2. Cần xác định

- [ ] Tiêu đề chính xác + căn cứ pháp lý.
- [ ] Khối `[01]`–`[04]`: nhãn, thứ tự, field nào lấy từ đâu.
- [ ] `Muc_I` gồm mấy mục con? `Muc_1`, `Muc_2`, `Muc_3` in ra sao?
- [ ] `ChiTiet` là bảng lặp? Có cột `ct2_ma`, `ct2_ten`, `ct3`? Tiêu đề cột?
- [ ] `tongCong_ct10`, `ct12`, `ct13` là tổng của bảng nào? Công thức?
- [ ] `Muc_2/DSachPLuc` hiển thị danh sách phụ lục con hay chỉ là text?
- [ ] `Muc_3` (`ct3a_1`, `ct3a_2`, `ct3b`) là checkbox/text/số?
- [ ] `Muc_B/Muc_I` hiển thị dạng bảng hay các dòng label/value?
- [ ] `Muc_B/Muc_II` (`ct_1`, `ct_2`) là gì?
- [ ] Có chữ ký/footer riêng?
- [ ] Section rỗng hiển thị thế nào?
- [ ] Có page break trước mục B không?

## 3. Capture checklist

- [ ] Ảnh toàn cửa sổ.
- [ ] Ảnh `Muc_A/Muc_I/Muc_1` (header cột + dòng tổng).
- [ ] Ảnh `Muc_A/Muc_II`, `Muc_III`.
- [ ] Ảnh `Muc_B/Muc_I`, `Muc_II`.
- [ ] PDF + số trang/orientation.
- [ ] Case mục rỗng.
- [ ] Case âm/thập phân (nếu có).

## 4. Spec notes

- `recordPath` dự kiến: `Muc_A/Muc_I/Muc_1/ChiTiet`, `Muc_A/Muc_II/ChiTiet`,
  `Muc_A/Muc_III/ChiTiet`.
- `headerFields` dự kiến lấy từ `Header/*`.
- `Muc_B` có thể là `kind: "fields"` chứ không phải bảng.
- Không được bỏ qua `DSachPLuc` nếu nó chứa danh sách phụ lục con.

## 5. Fixture

- `pl01_khbs_minimal.xml` — 1 dòng mỗi bảng.
- `pl01_khbs_empty.xml` — mục II/III rỗng.
- `pl01_khbs_negative.xml` — số âm.
- `pl01_khbs_large.xml` — ≥ 200 dòng ở mục I.

## 6. Kết quả

Ghi vào `docs/reverse-engineering/appendices/results/PL01_KHBS.md` và cập nhật
`progress.json`.
