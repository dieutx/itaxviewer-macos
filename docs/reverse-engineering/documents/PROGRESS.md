# Tiến độ RE tài liệu — iTax Viewer Windows

Cập nhật lần cuối: **2026-10-22** (phiên 2: inventory toàn bộ + capture P0).

> File này là bản người đọc. Bản máy đọc: `progress.json`. Kết quả chi tiết:
> `results/<kind>-<id>.md`. Inventory: `document-inventory.md` / `.json` / `document-registry.csv`.

## 1. Tổng quan theo loại tài liệu

| Loại | Root | Trạng thái clone | Inventory | Capture | Spec | Fixture | Handoff |
|---|---|---|---|---|---|---|---|
| Tờ khai | `HSoThueDTu` | **partial** — 4 form full | ✅ 1150 entry / 410 mã / 568 template | 🟡 4 form | 🟡 4 form | 🟡 | 🟡 |
| Phụ lục | `PLuc` | **partial** — NQ43/101/142 | ✅ | 🟡 | 🟡 | 🟡 | 🟡 |
| Thông báo | `TBaoThueDTu`, `THONGBAO`, `TBao`, … | **partial** — 3 mẫu có spec | ✅ 226 entry (9 registry) | 🟡 843 / 844 / 01-TB-BSTT | 🟡 3 mẫu | 🟡 3 fixture | 🟡 |
| Giấy nộp tiền | `CHUNGTU` | **partial** — CT-01 có spec + layout | ✅ 5 entry, 1 mã | ✅ 4.0.1 (2 biến thể) | ✅ CT-01 | ✅ 1 fixture | 🟡 |
| Đăng ký thuế | `DKyThueDTu` | generic-only | ✅ 11 entry / 10 mã | ⬜ | ⬜ | ⬜ | ⬜ |
| Danh mục | `DanhMucDTu` | generic-only | 🟡 1 entry mẫu (template placeholder) | ⬜ | ⬜ | ⬜ | ⬜ |
| Hóa đơn điện tử | `TKhai`, `DNghi`, `TBao`, … | generic-only | 🟡 nhận diện qua `MSo` regex, không có registry riêng | ⬜ | ⬜ | ⬜ | ⬜ |
| Hải quan | `TOKHAI_OBJ`, … | generic-only | ✅ 173/170/174 entry | ⬜ | ⬜ | ⬜ | ⬜ |

Ký hiệu: ✅ xong · 🟡 một phần · ⬜ chưa làm.

## 2. Tờ khai đã có renderer đầy đủ

| Mã | Mẫu số | Version | Render | PDF | Verify Windows | Ghi chú |
|---|---|---|---|---|---|---|
| 842 | 01/GTGT | 2.8.3 | ✅ | ✅ 2 trang | 🟡 header/table | phụ lục NQ142 |
| 394 | 05/KK-TNCN | 2.1.6 | ✅ | ✅ 2 trang | 🟡 header/table | |
| 953 | 05/QTT-TNCN | 2.9.3 | ✅ | ✅ 2 trang | 🟡 header/table | |
| 892 | 03/TNDN | 2.9.4 | ✅ | ✅ 4+1 trang | ⬜ reference invalid | |

## 3. Thông báo & chứng từ mới (phiên 2)

| Kind / mã | Root | Version | Capture | Spec | Fixture | PDF |
|---|---|---|---|---|---|---|
| `CT-01` (C1-02/NS) | `CHUNGTU` | 4.0.1 | ✅ 2 ảnh + 2 PDF | ✅ `paymentVouchers/CT-01.json` | ✅ `voucher-CT-01-vnd-multi.xml` | 1 trang A4 dọc |
| `843` (01-01/TB-TĐT) | `TBaoThueDTu` | 2.5.6 | ✅ nhánh `Y` | ✅ `notices/843.json` | ✅ `notice-843-minimal.xml` | 1 trang A4 dọc |
| `844` (01-2/TB-TĐT) | `TBaoThueDTu` | 2.4.9 | ✅ nhánh `Y` | ✅ `notices/844.json` | ✅ `notice-844-minimal.xml` | 1 trang A4 dọc |
| `01/TB-BSTT` | **`TBao`** | 2.1.0 | ✅ form chính | ✅ `notices/01-TB-BSTT.json` | ✅ `notice-01-TB-BSTT-minimal.xml` | 1 trang A4 dọc |

Bằng chứng: `docs/reverse-engineering/evidence/documents/<kind>/<id>/` (ảnh `PrintWindow`, PDF do app tự xuất qua Ctrl+P, `capture-notes.md`).

### Phát hiện quan trọng

1. **Root thông báo phải không có prefix.** `ns0:TBaoThueDTu` → "Tệp hồ sơ không đúng định dạng".
   Default namespace thì hợp lệ và bị app xoá trước khi XSLT.
2. **`maTBao` là khoá registry, không phải mã số.** Thông báo `01/TB-BSTT` phải có
   `MSo=01/TB-BSTT`, `PBan=2.1.0` và root `TBao`; fixture clone `tbao_107_bstt.xml`
   (`TBaoThueDTu`, `maTBao=107`, `3.0.7`) **bị bản gốc từ chối**.
3. **GNT hard-code "Chuyển khoản [X]"**; `HTHUC_NOP` không được dùng.
4. **`MA_NGUYENTE=00000`** để trống cột tiền và dòng tiền bằng chữ.
5. **Template 01/TB-BSTT in mẫu số `01/TB-BSTT-NNT`** (hard-code trong `tbaoheader.xsl`).

## 4. Phụ lục

| plucID | Clone | Capture gốc | Spec | Fixture | Verify |
|---|---|---|---|---|---|
| `PL_NQ142_GTGT` | ✅ layout I/II/III | ⬜ | ✅ | ✅ synthetic | ⬜ |
| `PL_NQ43_GTGT` | ✅ bảng phẳng | ⬜ | ✅ | ✅ test in-memory | ⬜ |
| `PL_NQ101_GTGT` | ✅ bảng phẳng | ⬜ | ✅ | ⬜ | ⬜ |
| `PL01_KHBS` | generic-only | ⬜ | ⬜ | ⬜ | ⬜ |
| `PL01_1_KHBS` | generic-only | ⬜ | ⬜ | ⬜ | ⬜ |
| `BaoCaoTaiChinh` | generic-only | ⬜ | ⬜ | 🟡 fixture tối giản | ⬜ |
| khác | generic-only | ⬜ | ⬜ | ⬜ | ⬜ |

## 5. Việc tiếp theo (đề xuất)

1. Sửa fixture/classifier thông báo trong app macOS theo `notices/*.json` (root `TBao`, khoá `MSo`/`PBan`).
2. Viết renderer + test cho CT-01 và 3 mẫu thông báo từ spec JSON.
3. Capture nhánh `trangThai=N` của 843/844 và trường hợp số tiền âm.
4. Ưu tiên P1: `PL01_KHBS`, `PL01_1_KHBS`, `BaoCaoTaiChinh`.
5. Cập nhật `progress.json` + `results/*.md` sau mỗi bước.
6. Chỉ chuyển trạng thái `verified` khi có ảnh/PDF đối chiếu **và** renderer macOS đã chạy.

## 6. Nhật ký thay đổi

| Ngày | Thay đổi | Người |
|---|---|---|
| 2026-10-22 | Tạo tracker; ghi nhận 4 form full + NQ43/101/142; xác định phần còn thiếu | agent |
| 2026-10-22 | Inventory 16 registry (1.512 dòng id+version); capture CT-01, 843, 844, 01/TB-BSTT; thêm spec/fixture/evidence; sửa namespace fixture thông báo; phát hiện sai khoá `maTBao=107` | agent |
