# Stage 1 — Inventory (registry + corpus)

**Mục tiêu:** biết chính xác có bao nhiêu loại phụ lục, form nào dùng, phiên bản nào, tần
suất ra sao, trước khi chụp hay viết spec.

**Thời lượng gợi ý:** 0.5–1 ngày.

**Đầu ra:**

- `docs/reverse-engineering/appendices/appendix-inventory.json`
- `docs/reverse-engineering/appendices/appendix-inventory.md`
- `docs/reverse-engineering/appendices/appendix-usage.csv`
- cập nhật `PROGRESS.md` + `progress.json`

**Chưa được:** chụp ảnh hàng loạt, viết spec, sửa code.

---

## 1.1. Inventory registry

Đọc `DMucTKhai.xml`, lấy mọi `DSachPLuc/PLuc`. Ghi:

- `plucID`
- `TenPLuc`
- `PLucXSLT`
- `plucOrientation` (`0` portrait, `1` landscape)
- `plucViewMethod`
- form cha (`maTKhai`, `pbanTKhai`, `loaiTKhai` nếu có)

Gợi ý PowerShell:

```powershell
$reg = "C:\Program Files (x86)\iTax Viewer\data\DMucTKhai.xml"
[xml]$x = Get-Content $reg
$x.SelectNodes("//*[local-name()='PLuc']") | ForEach-Object {
  [pscustomobject]@{
    plucID = $_.LocalName
    xml = $_.OuterXml
  }
} | Export-Csv appendix-registry.csv -NoTypeInformation -Encoding UTF8
```

Nếu tag chứa namespace, dùng `LocalName` để bỏ prefix.

## 1.2. Inventory corpus

Quét toàn bộ corpus, **chỉ đếm**:

- `maTKhai`, `pbanTKhaiXML`, `loaiTKhai`
- danh sách `PLuc` con theo đúng thứ tự
- với mỗi phụ lục: section cấp 1, tag bản ghi lặp, số bản ghi
- có chữ ký hay không (boolean)

Xuất CSV:

```text
sample,form,version,filing_type,pluc_ids,record_counts,signature
sample-001,842,2.8.3,C,PL_NQ142_GTGT,HH_DV_MuaVaoTrongKy=556;HH_DV_BanRaTrongKy=521,no
```

Không dùng tên file thật nếu tên chứa MST/tên người nộp. Đổi thành `sample-###`.

## 1.3. Đối chiếu

Tạo bảng:

| plucID | Có trong registry | Thấy trong corpus | Form cha | Versions | Số file | Ưu tiên |
|---|---|---|---|---|---|---|

Phân loại:

- `registry+corpus`: ưu tiên cao, có mẫu thật.
- `registry-only`: vẫn cần spec; tạo mẫu bằng HTKK hoặc file synthetic.
- `corpus-only`: `unmapped`; kiểm tra app gốc có crash/không render không.
- `neither`: bỏ qua.

## 1.4. Đề xuất priority

Mặc định (operator có thể đổi):

| Priority | Nhóm |
|---|---|
| P0 | `PL01_KHBS`, `PL01_1_KHBS` |
| P1 | `BaoCaoTaiChinh`, phụ lục 05/KK-TNCN, 05/QTT-TNCN |
| P2 | `PL_NQ204_GTGT` / phụ lục giảm thuế 2026, phụ lục thông báo/chứng từ |
| P3 | còn lại |

Ghi lý do vào `appendix-inventory.md`.

## 1.5. Acceptance

- [ ] `appendix-inventory.json` parse được, có `schemaVersion`, `capturedAt`, `app`.
- [ ] Mỗi `plucID` có `TenPLuc`, `orientation`, `parentForms`.
- [ ] `appendix-usage.csv` có số file và số bản ghi cho từng ID.
- [ ] Có danh sách `registry-only`, `corpus-only`, `unmapped`.
- [ ] Không có giá trị người nộp thuế trong output.
- [ ] `PROGRESS.md` + `progress.json` đã cập nhật stage 1 cho từng ID.

## 1.6. Mẫu kết quả

Trong `results/PL01_KHBS.md` (tạo sớm, điền dần):

```markdown
# PL01_KHBS — inventory

- Registry: có / không
- TenPLuc: …
- Orientation: portrait
- Form cha: 842 (01/GTGT), 01
- Số file trong corpus: 4
- Versions: 2.9.3
- Cấu trúc cấp 1: Header, ma_DonViTien, ten_DonViTien, Muc_A, Muc_B
- Stage 1: done (2026-10-22)
- Next: Stage 2 capture
```
