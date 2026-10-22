# Type: `PL01_1_KHBS` — phụ lục 01-1/KHBS

**Ưu tiên:** P0  
**Form cha quan sát:** `842` (01/GTGT), khai bổ sung  
**Đã có trong clone:** chưa (fallback raw table)

## 1. Cấu trúc đã quan sát

```text
PL01_1_KHBS
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
    DSachHSo
      BKeHSo
        ma_HSo
        ten_HSo
        CTietHSo
      TongCong
        tongCong_7
        tongCong_8
        tongCong_9
  Muc_B
    CTietTaiLieu
      ma_TLieu
      ten_TLieu
```

## 2. Cần xác định

- [ ] Tiêu đề + căn cứ pháp lý.
- [ ] Khối `[01]`–`[04]`.
- [ ] `BKeHSo` có lặp không? `CTietHSo` là chuỗi hay bảng con?
- [ ] Tiêu đề cột của bảng hồ sơ (`ma_HSo`, `ten_HSo`, `CTietHSo`).
- [ ] `TongCong` hiển thị 3 dòng `[7]`, `[8]`, `[9]` hay một bảng? Nhãn/công thức?
- [ ] `Muc_B/CTietTaiLieu`: bảng danh sách tài liệu? Có lặp `CTietTaiLieu` không?
- [ ] Thứ tự tài liệu và page break.
- [ ] Empty state.

## 3. Capture checklist

- [ ] Ảnh `Muc_A` (bảng hồ sơ + tổng).
- [ ] Ảnh `Muc_B` (danh sách tài liệu).
- [ ] PDF + page count/orientation.
- [ ] Case không có tài liệu.
- [ ] Case nhiều hồ sơ.

## 4. Fixture

- `pl01_1_khbs_minimal.xml`
- `pl01_1_khbs_empty.xml`
- `pl01_1_khbs_many.xml` (≥ 20 hồ sơ)

## 5. Kết quả

Ghi vào `results/PL01_1_KHBS.md`, cập nhật `progress.json`.
