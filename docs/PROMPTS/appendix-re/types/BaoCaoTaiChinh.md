# Type: `BaoCaoTaiChinh` — phụ lục báo cáo tài chính (03/TNDN)

**Ưu tiên:** P1  
**Form cha:** `892` (03/TNDN) và có thể dùng ở form khác  
**Đã có trong clone:** fallback raw table (fixture TNDN có `BaoCaoTaiChinh` tối giản)

## 1. Cấu trúc đã quan sát

Fixture hiện tại chỉ có:

```text
PLuc
  BaoCaoTaiChinh
    ctA1
    ctI1
```

File thật có thể chứa nhiều bảng B01/B02/B03/B05 lồng nhau. Cần inventory trước.

## 2. Cần xác định

- [ ] `BaoCaoTaiChinh` là một bảng hay bộ nhiều bảng?
- [ ] Các tag con thực tế (B01, B02, B03, B05, ct…).
- [ ] Mỗi bảng có tiêu đề gì, cột gì, mã chỉ tiêu gì.
- [ ] Có lặp theo dòng không? `recordPath` là gì?
- [ ] Tổng/công thức.
- [ ] Orientation (có thể landscape cho BCTC).
- [ ] App gốc có crash với appendix chưa map không? Ghi lại hành vi.
- [ ] Nếu app gốc crash: lấy layout từ mẫu BCTC chính thức hoặc file khác có cùng bảng.

## 3. Capture checklist

- [ ] Inventory các tag con từ corpus.
- [ ] Ảnh từng bảng (B01, B02, …).
- [ ] PDF + page count/orientation.
- [ ] Case nhiều bảng / nhiều trang.
- [ ] Case thiếu bảng.

## 4. Fixture

- `baocaotaichinh_minimal.xml` — mỗi bảng 1–2 dòng.
- `baocaotaichinh_multi.xml` — nhiều bảng.
- `baocaotaichinh_large.xml` — ≥ 100 dòng.

## 5. Ghi chú

Nếu `BaoCaoTaiChinh` thực chất chứa nhiều loại báo cáo, tách spec thành nhiều `sections`
trong cùng một appendix, không tạo nhiều `plucID` giả.

## 6. Kết quả

Ghi vào `results/BaoCaoTaiChinh.md`, cập nhật `progress.json`.
