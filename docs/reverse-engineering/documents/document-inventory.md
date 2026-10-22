# Document inventory — iTax Viewer (Windows)

Ngày: **2026-10-22**. Máy đọc: [`document-inventory.json`](document-inventory.json).
Danh sách mã: [`document-registry.csv`](document-registry.csv). Corpus: [`document-usage.csv`](document-usage.csv).

## 1. Môi trường & định danh artefact

| Hạng mục | Giá trị | Cách lấy |
|---|---|---|
| Windows | Windows 11 Pro N 10.0.22631 | `Win32_OperatingSystem` |
| App | `C:\Program Files (x86)\iTax Viewer` | đường dẫn cài đặt |
| Publisher | `Tong cuc thue`, InstallDate `20261021` | Uninstall registry key |
| Version | không có `DisplayVersion`; `update/latest.xml` pkgver `2.8.4` | registry + file |
| `itaxviewer.jar` SHA-256 | `5AC31CBA3990221004376883D9B90D5A55339F49BF6BC97C56542ED27BFA9F4E` | `Get-FileHash` |
| `iTaxViewer.exe` SHA-256 | `B579E63B0D598F1228408FCA36E20F51C3D0CAD6451691F58FF553458D386B5F` | `Get-FileHash` |
| JRE | 1.8.0_112 (bundled) | `jre\bin\java.exe -version` |
| Browser engine | SWT 4.3 (`org.eclipse.swt.win32.win32.x86_64-4.3.jar`) → MSHTML/ActiveX `Microsoft.XMLDOM` | `data/run.html` `transform()` |
| PDF | PD4ML + pdfbox 1.8.8, A4, lề 20/20/20/10 mm | `TKhaiConverter.java` |
| Decompiler | CFR 0.152 (`_re/src`, không commit) | `_re/src/summary.txt` |

## 2. Registry theo loại tài liệu

`entries` = số element cùng tên entry mà `getElementsByTagName` của app nhìn thấy (gồm cả entry lồng
nhau); `ids` = số mã duy nhất; `versions` = số phiên bản duy nhất.

| Registry | Kind | Handler | Entries | IDs | Versions | Templates | Ghi chú |
|---|---|---|---:|---:|---:|---:|---|
| `DMucTKhai.xml` | declaration | `TKhaiThue` | 1150 | 410 | 104 | 568 | tờ khai + phụ lục |
| `DMucTbao.xml` | notice | `TBaoThue` | 128 | 106 | 32 | 111 | 126 `TBao` trực tiếp + 2 `TBao` lồng (mã 960); file còn 6 `BKe` bị bỏ qua |
| `DMucTbao_InCDoi.xml` | notice | `TBaoThue` | 10 | 10 | 1 | 10 | dùng khi có `TTinVBanCDoi` |
| `DMucTBaoNtdt.xml` | notice | `TBaoThueNtdt` | 46 | 21 | 8 | 28 | root `THONGBAO`, `TBAO_*` |
| `DMucTBaoNtdt22.xml` | notice | — | 27 | 11 | 3 | 11 | **không** được `ConfigInfo` nạp |
| `DMucTBaoKDTT.xml` | notice | `TBaoKDTT` | 2 | 2 | 1 | 2 | còn 3 `BKe` (thuộc `BKE_TBAO`) |
| `DmucTSoatNtdt.xml` | notice | `TSoatNtdt` | 3 | 1 | 3 | 3 | `TRASOAT_THUE` |
| `DmucBtruNtdt.xml` | notice | `BuTruNtdt` | 1 | 1 | 1 | 1 | `XULY_NTHUA` |
| `DMucXNhanCTuNtdt.xml` | notice | `XNhanCTuNtdt` | 4 | 1 | 4 | 4 | `XACNHAN_*` |
| `DMucBKeKDTT.xml` | notice | `BKeKDTT` | 5 | 5 | 1 | 3 | `BKE_TBAO` |
| `DMucCTu.xml` | paymentVoucher | `GNTNSNN` | 5 | **1** (`01`) | 5 | 5 | chỉ `maCTu=01`, 5 template |
| `DMucHSoDky.xml` | registration | `DKyThue` | 11 | 10 | 1 | 10 | `DKyThueDTu` |
| `DMucDMuc.xml` | catalog | `DMuc` | 1 | 1 | 1 | 1 | chỉ entry mẫu, template là placeholder (`XSLTmaDanhMuc`) |
| `DMucHquan.xml` | customs | `HquanForm` | 173 | 172 | 1 | 3 | `TOKHAI_OBJ` |
| `DMucHquan1.xml` | customs | `HquanForm1` | 170 | 170 | 1 | 1 | `TOKHAISUA_OBJ` |
| `DMucHquanNew.xml` | customs | `HquanFormNew` | 174 | 173 | 1 | 4 | `*:Envelope` |

Tổng: **16 registry**, **1.512 dòng (id, version) duy nhất**, **410 mã tờ khai**.
(`DMucTbao.xml` / `DMucTBaoKDTT.xml` chứa lẫn element `BKe`; app tra cứu bằng
`getElementsByTagName("TBao")` nên các `BKe` đó không bao giờ khớp.)

## 3. Quy tắc nhận diện (từ `HSoThueFactory`)

| Root element | Handler | Ghi chú |
|---|---|---|
| `HSoThueDTu` | `TKhaiThue` | `maTKhai` + `pbanTKhaiXML` + `loaiTKhai` |
| `TBaoThueDTu` | `TBaoThue` | `maTBao` + `pbanTBao`; `maTBao` là khoá chuỗi, ví dụ `843`, `01/TB-BSTT` |
| `CHUNGTU` | `GNTNSNN` | `MA_CTU` + `PBAN_TLIEU_XML` |
| `THONGBAO`, `THONG_BAO`, `TBAO_TKHOAN_NH`, `TBAO_TKHOAN_NT`, `TBAO_NGUNG` | `TBaoThueNtdt` | |
| `DanhMucDTu` | `DMuc` | |
| `DKyThueDTu` | `DKyThue` | |
| `TOKHAI_OBJ` / `TOKHAISUA_OBJ` / `*:Envelope` | `HquanForm` / `HquanForm1` / `HquanFormNew` | |
| `BKE_TBAO` | `BKeKDTT` | |
| `TRASOAT_THUE` / `XULY_NTHUA` / `XACNHAN_*` | `TSoatNtdt` / `BuTruNtdt` / `XNhanCTuNtdt` | |
| `TKhai` | `TkhaiInvoice` | |
| `DNghi`, `BCTHSDBLai` | `DNghiInvoice` | |
| `TBao` + `MSo` regex, hoặc `TBTNhan` + `MSo` regex | `TBaoHDDT` | regex: `01/TB-SSĐT`, `01/TB-ĐKĐT`, `01/TB-TNĐT`, `01/TB-BSTT-NNT`, `01/TB-NSD`, `01/TB-BSTT`, `01/CCTT-TB` |
| `TBao` + `MSo` regex `04/SS-CTĐT`, `04/SS-HĐĐT`, `01/TB-ĐKĐT`, `01/TB-BSTT` | `TKhaiHDDTInvoice` | |
| `BLai` | `BLaiInvoice` | |

Hai quy tắc quan trọng đã kiểm chứng bằng cách chạy app:

1. **Root phải không có prefix.** `ns0:TBaoThueDTu` bị từ chối ("Tệp hồ sơ không đúng định dạng")
   vì app so sánh `getTagName()` với tên không namespace. Default namespace thì hợp lệ và được
   app xoá trước khi chạy XSLT (`createTemFileForView`).
2. **`maTBao` của thông báo là khoá registry, không phải mã số.** `01/TB-BSTT` (kèm `PBan=2.1.0`)
   mới mở được; `maTBao=107` + `pbanTBao=3.0.7` bị từ chối. Mã `107` là `maTKhai` của BCTC,
   không phải mã thông báo.

### Chọn template

- Tra cứu tuyến tính trong registry theo cặp `(mã, phiên bản)`; không khớp → lỗi
  "Mã hồ sơ … hoặc phiên bản … không đúng".
- `viewMethod=1` cho mọi entry quan sát được → render HTML bằng XSLT trong browser.
- Phụ lục: đọc mọi element con đầu tiên của `PLuc`; mỗi tên element là một `plucID`, tra
  `DSachPLuc/PLuc[@plucID]` để lấy template/orientation.
- `TBaoThue` có nhánh đặc biệt: nếu có `TTinVBanCDoi` thì dùng `DMucTbao_InCDoi.xml`.

## 4. Corpus hiện có (19 file)

| File | Root | Kind | Mã | Version | Bản gốc mở? |
|---|---|---|---|---|---|
| `test-data/anonymized/gnt/sample-01..03.xml` | `CHUNGTU` | paymentVoucher | `01` | 4.0.1 | **có** (sample-01) |
| `test-data/anonymized/notices/sample-01.xml` | `TBaoThueDTu` | notice | `843` | 2.5.6 | **có** (sau khi bỏ prefix `ns0:`) |
| `test-data/anonymized/notices/sample-02.xml` | `TBaoThueDTu` | notice | `844` | 2.4.9 | **có** (sau khi bỏ prefix `ns0:`) |
| `test-data/declarations/gtgt_842_return.xml` | `HSoThueDTu` | declaration | `842` | 2.8.3 | chưa chạy lại trong phiên này |
| `…/tncn_394_05kk_tt92.xml` | `HSoThueDTu` | declaration | `394` | 2.1.6 | chưa |
| `…/tncn_953_05qtt.xml` | `HSoThueDTu` | declaration | `953` | 2.9.3 | chưa |
| `…/tndn_892_03tndn_v2.9.4.xml` | `HSoThueDTu` | declaration | `892` | 2.9.4 | chưa |
| `Tests/…/gnt_chungtu.xml` | `CHUNGTU` | paymentVoucher | `01` | 4.0.1 | chưa |
| `Tests/…/tbao_107_bstt.xml` | `TBaoThueDTu` | notice | `107` | 3.0.7 | **không** — sai khoá registry |
| `Tests/…/signed_demo.xml` | `HSoThueDTu` | declaration | `842` | 2.8.3 | chưa |
| `Tests/…/xxe_attack.xml` | `HSoThueDTu` | declaration | `842` | 2.8.3 | fixture bảo mật |

## 5. Ưu tiên & việc tiếp theo

| Ưu tiên | Việc | Trạng thái |
|---|---|---|
| P0 | Giấy nộp tiền `CT-01` (spec + ảnh + PDF) | **xong một phần** (4.0.1, nhánh VND/không VND) |
| P0 | Thông báo `843`, `844` (spec + ảnh + PDF) | **xong nhánh `Y`** |
| P0 | Thông báo `01/TB-BSTT` | **xong form chính**, phụ lục chưa |
| P0 | Sửa fixture thông báo của clone (`tbao_107_bstt.xml`) | cần làm ở giai đoạn macOS |
| P1 | Nhánh `trangThai=N` của 843/844; số tiền âm | chưa capture |
| P1 | `PL01_KHBS`, `PL01_1_KHBS`, `BaoCaoTaiChinh` | chưa |
| P2 | Đăng ký thuế, danh mục | chưa |
| P2 | Hóa đơn điện tử | chưa |
| P3 | Hải quan (173/170/174 mã) | chưa |

## 6. Unknown

- `DMucDMuc.xml` chỉ có entry mẫu với template placeholder → không thể kết luận app render được
  danh mục nào.
- Chưa xác minh `viewMethod` khác 1 (không có entry nào).
- Chưa đo được version chính xác của app (không có DisplayVersion).
