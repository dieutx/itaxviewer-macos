# Type: `PL_NQ*_GTGT` — phụ lục giảm thuế GTGT

**Đã implement trong clone:**

- `PL_NQ43_GTGT` (NQ 43/2022/QH15)
- `PL_NQ101_GTGT` (NQ 101/2023/QH15)
- `PL_NQ142_GTGT` (NQ 142/2024/QH15)

**Cần verify + tìm ID 2026:** `PL_NQ204_GTGT` hoặc ID thực tế khác.

## 1. Trạng thái hiện tại

| plucID | Layout clone | Cần làm |
|---|---|---|
| `PL_NQ43_GTGT` | bảng phẳng + tổng `[07]`/`[08]` | verify ảnh gốc |
| `PL_NQ101_GTGT` | bảng phẳng + tổng `[07]`/`[08]` | verify ảnh gốc |
| `PL_NQ142_GTGT` | mục I/II/III + `[05]`–`[09]` | verify ảnh gốc |
| `PL_NQ204_GTGT` | chưa có | inventory + spec |

## 2. Cấu trúc đã biết

### NQ142

```text
PL_NQ142_GTGT
  HH_DV_MuaVaoTrongKy
    BangKeTenHHDV          (tenHHDVMuaVao, giaTriHHDVMuaVao, thueGTGTHHDV)
    tongCongGiaTriHHDVMuaVao
    tongCongThueGTGTHHDV
  HH_DV_BanRaTrongKy
    BangKeTenHHDV          (tenHHDV, giaTriHHDV, thueSuatTheoQuyDinh,
                            thueSuatSauGiam, thueGTGTDuocGiam)
    tongCongGiaTriHHDV
    tongCongThueGTGTDuocGiam
  ChenhLech
    ct9
```

### NQ43 / NQ101

```text
PL_NQ43_GTGT / PL_NQ101_GTGT
  BangKeTenHHDV (lặp)
  tongCongGiaTriHHDV
  tongCongThueGTGTDuocGiam
```

## 3. Verify checklist

- [ ] Chụp ảnh bản gốc cho NQ43, NQ101, NQ142.
- [ ] So tiêu đề, căn cứ pháp lý.
- [ ] So khối `[01]`–`[04]`.
- [ ] So cột, thứ tự cột, header.
- [ ] So tổng `[05]`–`[09]`, công thức `[09] = [08] - [06]`.
- [ ] So orientation + số trang PDF.
- [ ] So cách xử lý bảng dài.
- [ ] Ghi khác biệt vào `results/<plucID>.md`.

## 4. Tìm phụ lục 2026

- [ ] Quét `DMucTKhai.xml` xem có `PL_NQ204_GTGT` hoặc ID mới.
- [ ] Quét corpus 2026 xem `plucID` thực tế.
- [ ] Nếu vẫn là `PL_NQ142_GTGT`: ghi rõ, không tạo ID mới.
- [ ] Nếu ID mới: capture + spec theo mẫu NQ142, so sánh cấu trúc.
- [ ] Kiểm tra chính sách mới nhất (NQ 204/2025) và căn cứ pháp lý trên form.

## 5. Fixture

Đã có `gtgt_842_nq142.xml` trong clone. Cần thêm:

- `pl_nq43_minimal.xml`
- `pl_nq101_minimal.xml`
- `pl_nq204_minimal.xml` (nếu tồn tại)

## 6. Kết quả

Ghi vào `results/PL_NQ142_GTGT.md`, `results/PL_NQ43_GTGT.md`, … và cập nhật
`progress.json`.
