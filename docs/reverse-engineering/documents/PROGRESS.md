# Tiến độ RE tài liệu — iTax Viewer Windows

Cập nhật lần cuối: **2026-10-24** (kiểm thử native arm64 + Intel, sửa dải trang xuất PDF, rà ảnh kết quả).

**Kết quả thực thi mới:** mỗi runner arm64/Intel chạy 99 XCTest (98 pass, một test tuỳ chọn
skip); integration chín sample pass trên arm64. Cùng gói universal mở và load WebKit đủ
29 fixture trên cả hai kiến trúc; mỗi runner xuất 29 PDF (55 trang A4) và từ chối XXE.
Kiểm thử hồi quy xuất đủ trang sau một lần chỉ chọn trang 2 pass; 05/KK-TNCN 394 một trang. Xem
[`../../../COMPATIBILITY.md`](../../../COMPATIBILITY.md) và
[`results/native-review-2026-10-24.md`](results/native-review-2026-10-24.md). Các số trang trong
những phần tiếp theo là kết quả lịch sử; đối chiếu ảnh Windows của layout mới vẫn pending.

> File này là bản người đọc. Bản máy đọc: `progress.json`. Kết quả chi tiết:
> `results/<kind>-<id>.md`. Inventory: `document-inventory.md` / `.json` / `document-registry.csv`.
>
> **Review độ phủ & khoảng trống (2026-10-23):** [`../COVERAGE-REVIEW.md`](../COVERAGE-REVIEW.md) —
> tổng hợp 410 mã tờ khai, 122 mã thông báo, 210 phụ lục, chứng từ, chữ ký số và prompt
> reverse trên Windows: [`../../PROMPTS/windows-re/`](../../PROMPTS/windows-re/README.md).

## 1. Tổng quan theo loại tài liệu

| Loại | Root | Trạng thái clone | Inventory | Capture | Spec | Fixture | Handoff |
|---|---|---|---|---|---|---|---|
| Tờ khai | `HSoThueDTu` | **partial** — 14 spec theo version + alias 01 | ✅ 1150 entry / 410 mã / 568 template | 🟡 4 form | 🟡 14 spec | 🟡 | 🟡 |
| Phụ lục | `PLuc` | **partial** — NQ43/101/142 | ✅ | 🟡 | 🟡 | 🟡 | 🟡 |
| Thông báo | `TBaoThueDTu`, `THONGBAO`, `TBao`, `TBTNhan`, … | **partial** — 6 mẫu có spec | ✅ 226 entry (9 registry) | 🟡 843 / 844 / 01-TB-BSTT | 🟡 6 mẫu | 🟡 | 🟡 |
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
| 394 | 05/KK-TNCN | 2.1.6 | ✅ | ✅ **1 trang native** | 🟡 header/table, số trang khớp | nhóm địa bàn/liên hệ chung hàng |
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

**Renderer macOS (2026-10-23):** `843` (nhánh Y/N), `844` (Y/N) và `01/TB-BSTT` dùng layout
công văn chính thức; `CT-01` dùng layout C1-02/NS (bảng chi tiết, cột VND/USD, tổng tiền,
số tiền bằng chữ). Đã chạy XCTest; đối chiếu ảnh/PDF Windows vẫn **pending**.

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
| `PL01_KHBS` | layout TT80, exact parent/version | ⬜ | ✅ facts tĩnh | ✅ synthetic | native PDF đã chạy; Windows visual pending |
| `PL01_1_KHBS` | layout TT80, exact parent/version | ⬜ | ✅ facts tĩnh | ✅ synthetic | native PDF đã chạy; Windows visual pending |
| `BaoCaoTaiChinh` | generic-only | ⬜ | ⬜ | 🟡 fixture tối giản | ⬜ |
| khác | generic-only | ⬜ | ⬜ | ⬜ | ⬜ |

## 5. Việc tiếp theo

Thực hiện theo **wave** trong [`../COVERAGE-REVIEW.md`](../COVERAGE-REVIEW.md) và prompt
tương ứng trong [`../../PROMPTS/windows-re/`](../../PROMPTS/windows-re/README.md):

1. **Wave 0 (Windows):** 04/GTGT (`07`,`847`), 05/KK-TNCN TT80 (`864`), 05/QTT cũ (`395`),
   02/03/04/05/TNDN TT89 (`2002`–`2004`), 01/CNKD (`386`,`473`,`1240`,`1266`),
   BCTC (`701`,`702`,`1254`), `PL01_KHBS`, `PL01_1_KHBS`, 6 mẫu `01/TB-*`, chữ ký số.
2. **Wave 1:** 58 mã tờ khai P1, 90 thông báo P1, 134 phụ lục P1.
3. **Wave 2:** quét theo template XSLT cho 276 mã P2, 51 thông báo P2, 71 phụ lục P2.
4. **Wave 3:** hải quan, hóa đơn điện tử, danh mục, mẫu nội bộ.
5. Sau mỗi batch: cập nhật `results/*.md`, `progress.json`, rồi implement macOS + test +
   so ảnh/PDF.
6. Chỉ chuyển trạng thái `verified` khi có ảnh/PDF đối chiếu **và** renderer macOS đã chạy.

## 6. Nhật ký thay đổi

| Ngày | Thay đổi | Người |
|---|---|---|
| 2026-10-22 | Tạo tracker; ghi nhận 4 form full + NQ43/101/142; xác định phần còn thiếu | agent |
| 2026-10-22 | Inventory 16 registry (1.512 dòng id+version); capture CT-01, 843, 844, 01/TB-BSTT; thêm spec/fixture/evidence; sửa namespace fixture thông báo; phát hiện sai khoá `maTBao=107` | agent |
| 2026-10-22 | Mở lại 4 fixture tờ khai bằng bản gốc: 842 = 2 trang, 394 = **1 trang** (clone đang 2), 953 = 2 trang, 892 = NPE/blocked; capture nhánh `trangThai=N` của 843; thử capture phụ lục NQ142 = blocked | agent |
| 2026-10-23 | Map legacy `maTKhai=01` (XML 2.1.2–2.6.2) sang layout 01/GTGT; implement layout 843/844/01-TB-BSTT + CT-01; sửa classifier root `TBao`; thêm 7 test; chạy 12 file thật (9 full, 3 × 04/GTGT structured) | agent |
| 2026-10-23 | Sửa sidebar bị cắt (bỏ NavigationSplitView bị lỗi layout); phụ lục chưa có spec (PL01_KHBS, PL01_1_KHBS…) hiển thị dạng cây cấu trúc thay vì bảng path; thêm tự động báo bản phát hành mới (GitHub Releases, 1 lần/ngày, không gửi dữ liệu hồ sơ) | agent |
| 2026-10-23 | Review độ phủ toàn bộ: 410 mã tờ khai / 122 mã thông báo / 210 phụ lục / 5 chứng từ; sinh inventory CSV (17 họ tờ khai); viết bộ prompt Windows RE (gồm chữ ký số) để đạt 90–100% | agent |
