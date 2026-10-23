# 01 — Tờ khai (declarations)

Batch này dùng cùng `00-MASTER.md`. Danh sách đầy đủ: `docs/reverse-engineering/inventory/declarations.csv`.
Cột `wave` cho biết mức ưu tiên.

## 0. Hiện trạng

- 410 mã `maTKhai`, 237 mã hiển thị.
- Đã có layout đầy đủ: **01/GTGT** (`842`, legacy `01`), **05/KK-TNCN** (`394`),
  **05/QTT-TNCN** (`953`), **03/TNDN** (`892`).
- 405 mã còn lại đang ở structured view.

Quy tắc: **không capture từng mã nếu chúng dùng chung template**. Ghi
`sharedLayoutWith: ["mã khác", …]` vào spec.

Phạm vi prompt này là **toàn bộ 237 mã hiển thị**, không chỉ GTGT. Mục 1 chia thành 17 họ
(GTGT, TNCN, TNDN, BCTC, tài nguyên, BVMT, TTĐB/TTS, NTNN, hộ kinh doanh, xổ số/bảo hiểm,
phí/lệ phí, môn bài, tem, vận tải, HTQT, đăng ký/chuyên ngành). Số liệu theo họ:
`inventory/declaration-families.csv`.

---

## WAVE 0 — bắt buộc làm trước (8 mẫu, 14 mã)

### 0.1 `04/GTGT` — mã `07` (cũ) và `847` (TT80)

- Template: `TKhai_GTGT_04.xslt` (07) và `TKhai_GTGT_04_TT80.xslt` (847).
- Version: `07`: 2.0.0 → 2.1.2 → 2.5.0; `847`: 2.5.1 → 2.7.4.
- Đã có 3 file thật trên máy macOS (version 2.1.2) — dùng để đối chiếu cấu trúc, nhưng
  **chưa có nhãn chính thức**, nên hiện chỉ structured view.
- Cấu trúc XML đã biết (từ file thật): `CTieuTKhaiChinh` gồm `ct21`,
  `PPhoiCCapHHoa/ct22-23`, `DVuXDungKoBaoThauNVL/ct24-25`,
  `HHoaXDungCoBaoThauNVL/ct26-27`, `HDongKDoanhKhac/ct28-29`,
  `TongCong/ct30-31`, `ct32`, `ct33`.
- Cần capture:
  1. Form đầy đủ ở version 2.1.2 **và** 2.7.4 (layout có thể khác).
  2. Header `[01]–[11c]`, tiêu đề, căn cứ pháp lý (TT 156/2013 vs TT 80/2021).
  3. Nhãn + công thức cho `[21]–[33]`, cột tiền, dòng tổng.
  4. Trường hợp có/không phát sinh, số âm, phụ lục đi kèm (`plucIds`).
- Câu hỏi: `[21]` là checkbox hay số? `ct32/ct33` là tổng nào? Có dòng "Trong đó" không?
- Output: `forms/07/spec.json`, `forms/847/spec.json` + evidence + 3 fixture.

### 0.2 `05/KK-TNCN` TT80 — mã `864`

- Template: `TKhai_05_KK_TNCN_TT80.xslt`, version 2.5.1 / 2.8.3 / 2.9.3.
- Khác `394` ở bộ chỉ tiêu `[16]–[32]` (README đã ghi nhận).
- Cần: bảng chỉ tiêu mới, nhãn, đơn vị, cột "Số người/Số tiền", các dòng tổng.
- So sánh trực tiếp với `394` để lập bảng "dòng nào đổi mã".
- Output: `forms/864/spec.json` (có thể tách `versions` 2.5.1 và 2.9.3 nếu layout khác).

### 0.3 `05/QTT-TNCN` cũ — mã `395`

- Template: `TKhai_05QTT_TNCN.xslt`, version 2.1.6 / 2.4.2.
- Cần: layout trước TT80, đặc biệt phần uỷ quyền quyết toán và bảng thu nhập.
- So sánh với `953` để map các dòng tương đương.
- Output: `forms/395/spec.json`.

### 0.4 `04/TNDN` TT89/2025 — mã `2002`

- Template: `TKhai_TNDN_04_TT89.xslt`, version 3.0.9.
- Cần: toàn bộ layout mới (khác `03/TNDN` hiện tại).
- Output: `forms/2002/spec.json`.

### 0.5 `02/TNDN` TT89/2025 — mã `2003`

- Template: `TKhai_TNDN_02_TT89.xslt`, version 3.0.9.
- Cần: layout TT89, đặc biệt các dòng `[A1]–[E]` nếu khác `892`.
- Output: `forms/2003/spec.json`.

### 0.6 `05/TNDN` TT89/2025 — mã `2004`

- Template: `TKhai_TNDN_05_TT89.xslt`, version 3.0.9.
- Output: `forms/2004/spec.json`.

### 0.7 `01/CNKD` — mã `386`, `473`, `1240`, `1266`

- Template: `CNKK_01_CNKD.xslt` (386 cũ), `TKhai_01_CNKD_TT40.xslt` (473),
  `TKhai_01_CNKD.xslt` (1240/1266).
- Version: 386: 2.1.6/2.5.0/2.8.3; 473: 2.4.9→2.8.3; 1240: 2.8.9; 1266: 2.9.8.
- Cần: layout theo từng giai đoạn TT40/TT80, bảng doanh thu, thuế suất, hộ khoán.
- Output: tối thiểu 2 spec (`386` cũ, `1240/1266` mới) + ghi `sharedLayoutWith` cho 473.

### 0.8 BCTC — mã `701`, `702`, `1254`

- `701` = B01/BCTC (2.3.5) — `TKhai_BCTC_107_DD.xslt`
- `702` = B05/BCTC (2.3.5) — `TKhai_BCTC_107_DG.xslt`
- `1254` = B01/BCTC (2.9.0, mẫu 2024) — `TKhai_BCTC24_2024_Nam.xslt`
- Cần: toàn bộ bảng nhiều cột (mã số, chỉ tiêu, số cuối kỳ/đầu kỳ…), số trang PDF,
  orientation, phụ lục `PL_LCTT*`.
- Output: `forms/701/spec.json`, `forms/702/spec.json`, `forms/1254/spec.json`.

---

## 1. Bản đồ toàn bộ họ tờ khai (237 mã hiển thị)

Đây chỉ là cách chia để review/capture, không phải phân loại pháp lý chính thức. Mỗi họ
đều nằm trong phạm vi clone 90–100%; khác nhau ở thứ tự ưu tiên.

| Họ | Số mã hiển thị | Số mã `maTKhai` | Version | Template | Ghi chú |
|---|---:|---:|---:|---:|---|
| Đăng ký, khai lần đầu & chuyên ngành | 91 | 119 | 169 | 118 | Nhiều mẫu ít dùng; quét theo template |
| BCTC & thuyết minh | 36 | 61 | 82 | 60 | B01/B02/B05 + thuyết minh + CTCK/NH/HTX |
| TNCN | 24 | 32 | 66 | 31 | Khấu trừ, quyết toán, thu nhập khác |
| TNDN | 17 | 33 | 76 | 31 | Gồm TT89/2025 |
| Tài nguyên | 9 | 17 | 39 | 15 | Khai thác tài nguyên, dầu khí |
| Hộ kinh doanh | 8 | 13 | 22 | 11 | CNKD/HKD, TMĐT, xổ số |
| Tem điện tử | 8 | 12 | 23 | 12 | Tem thuốc lá/rượu |
| Xổ số / Bảo hiểm | 7 | 10 | 24 | 9 | Xổ số, bảo hiểm |
| Nhà thầu nước ngoài | 7 | 12 | 28 | 12 | NTNN/NCCNN |
| Phí / lệ phí | 7 | 7 | 20 | 7 | Phí, lệ phí, phí BVMT |
| GTGT | 6 | 11 | 56 | 11 | Đã có 01/GTGT; còn 02/03/04/05 |
| Bảo vệ môi trường | 5 | 7 | 17 | 7 | BVMT, túi nilon |
| Hiệp định thuế / HTQT | 4 | 4 | 5 | 4 | HTQT |
| TTĐB / TTS | 5 | 10 | 30 | 10 | Tiêu thụ đặc biệt/TTS |
| Thuế môn bài | 2 | 3 | 7 | 2 | Môn bài |
| Vận tải | 1 | 2 | 4 | 2 | VTNN |
| Không mã hiển thị / nội bộ | 1 | 57 | 89 | 49 | P3 |

Danh sách mã đầy đủ theo từng họ: `docs/reverse-engineering/inventory/declarations.csv`
(cột `family`), thống kê: `inventory/declaration-families.csv`.

## WAVE 1 — làm theo họ tờ khai (không chỉ GTGT)

Mỗi họ dưới đây là một **batch card**. Trong mỗi họ, chọn mẫu đại diện cho mỗi template
XSLT; capture rồi map các mã dùng chung (`sharedLayoutWith`). Không bỏ qua họ nào nếu corpus
thực tế có mẫu đó.

### 1.1 TNCN (24 mã hiển thị)

- **Khấu trừ**: `02/KK-TNCN` (`47`,`391`,`859`), `05/KK-TNCN` (`394` đã có, `42`, `864`),
  `06/KK-TNCN` (`103`), `07/KK-TNCN` (`147`), `08/KK` (`136`), `08A` (`151`), `08B` (`15`),
  `09/KK` (`16`), `13/KK` (`20`), `19/KK` (`144`).
- **Quyết toán**: `02/QTT-TNCN` (`392`,`952`,`1000`), `05/QTT-TNCN` (`953` đã có, `395` cũ).
- **Thu nhập khác/chuyển nhượng**: `04/CNV-TNCN` (`860`), `04/DTV-TNCN` (`861`),
  `04/TKQT-TNCN` (`862`), `04/NNG-TNCN` (`863`), `05/DS-TNCN` (`393`),
  `03/BĐS_TNCN` (`1185`), `02/CNKD-TNCN-QTT` (`1244`,`1271`),
  `02/ĐK-NPT-TNCN` (`390`).
- Capture: bảng chỉ tiêu, cột "Số người/Số tiền", đơn vị, dòng uỷ quyền quyết toán,
  phụ lục TNCN (`PLuc_05*`, `PL05A/B`, `PLuc_06*`).
- Câu hỏi: khác nhau giữa TT92/TT80/TT89; chỉ tiêu nào đổi mã; cách in "trong đó".

### 1.2 TNDN (17 mã hiển thị)

- `02/TNDN` (`71`,`837`,`1267`), `03/TNDN` (`892` đã có), `04/TNDN` (`13`,`833`,`2002`),
  `05/TNDN` (`687`,`828`,`1268`,`2004`), `06/TNDN` (`304`,`829`), `07/TNDN` (`2005`),
  `01A/TNDN` (`11`), `01B/TNDN` (`12`).
- Đăng ký/khai lần đầu: `01/TNDN-DK`, `01A/01B/TNDN-DK`, `02/03/TNDN-DK`,
  các `*-VSP` (dầu khí).
- Capture: layout TT89/2025 vs TT80; bảng `[A1]–[E]`; phụ lục `PL03_*_TNDN`;
  trường hợp lỗ/chuyển lỗ, ưu đãi thuế.
- Câu hỏi: mã chỉ tiêu nào đổi giữa 892 và 2002–2004; dòng nào bắt buộc.

### 1.3 BCTC & thuyết minh (36 mã hiển thị)

- `B01/BCTC` (`701`), `B05/BCTC` (`702`), `B01/BCTC` mẫu 2024 (`1254`).
- Các biến thể: `B01 - DN`, `B01a`, `B01b`, `B-01/DN`, `B-01/DNN`, `B-01/TCTD`,
  `B01 - CTCK`, `B01 - DNNKLT`, `B01 - DNSN`, `B01 - DNSS`, `B01 - HTX`, `B01 – CTQ`,
  `B02/TCTD`, `B02a`, `B02b`, `BC01/AC`, `BC08/AC`, `BC21/AC`, `BC26/AC`, `BC7/AC`,
  `BK01/AC`, `TB01/AC`, `TB03/AC`, `TB04/AC`, `01/SDDNN`, `03/SDDNN`, `BK04.1-ĐKT`.
- Capture: bảng nhiều cột (mã số, chỉ tiêu, số đầu kỳ/cuối kỳ), số trang PDF, orientation,
  thuyết minh, phụ lục `PL_LCTT*`, `PL_KQHD*`, `PL_BC*`.
- Câu hỏi: mẫu 2024 khác mẫu 107 thế nào; in nhiều trang/ngắt trang ra sao.

### 1.4 Tài nguyên (9 mã hiển thị)

- `01/TAIN` (`06`,`832`,`1242`), `02/TAIN` (`08`,`924`), `03/TĐ-TAIN` (`133`),
  `01/TAIN-DK` (`135`,`444`,`868`), `02/TAIN-DK` (`88`,`446`,`884`),
  các `*-VSP` (dầu khí), `03A/TĐ-TAIN` (`84`).
- Capture: bảng sản lượng/giá tính thuế/thuế suất, kỳ khai, phụ lục tài nguyên.
- Câu hỏi: đơn vị tính, làm tròn, dòng tổng; khác nhau giữa 01/02/03.

### 1.5 Bảo vệ môi trường (5 mã hiển thị)

- `01/BVMT` (`59`,`1238`), `02/BVMT` (`60`), `01/PBVMT` (`878`), `02/PBVMT` (`893`),
  `01/TBVMT` (`128`,`914`).
- Capture: bảng hàng hoá chịu thuế, đơn vị, thuế suất, túi nilon; phụ lục BVMT.
- Câu hỏi: mẫu nào dùng cho túi nilon; cách tính miễn/giảm.

### 1.6 TTĐB / TTS (5 mã hiển thị)

- `01/TTĐB` (`05`,`401`,`830`,`1239`,`1259`), `02/TTĐB` (`831`), `01/KK-TTS` (`252`),
  `01/TTS` (`388`,`470`).
- Capture: bảng hàng hoá, thuế suất, doanh thu, thuế phải nộp; phân biệt TTĐB và TTS.
- Câu hỏi: `TTS` là mẫu gì (lấy tiêu đề chính thức); khác TTĐB ở cột nào.

### 1.7 Nhà thầu nước ngoài (7 mã hiển thị)

- `01/NTNN` (`41`,`838`), `02/NTNN` (`74`,`921`,`2013`), `03/NTNN` (`73`,`840`),
  `04/NTNN` (`72`,`922`), `01/NTNN, NCCNN` (`2012`), `03/NCCNN` (`1401`),
  `04/NCCNN` (`1501`).
- Capture: bảng nhà thầu, tỷ lệ phân bổ, thuế GTGT/TNDN, phụ lục NTNN.
- Câu hỏi: khác nhau giữa NTNN và NCCNN; nhiều nhà thầu trong một tờ khai.

### 1.8 Hộ kinh doanh (8 mã hiển thị)

- `01/CNKD` (`386`,`473`,`1240`,`1266`), `01/CNKD-TMĐT` (`1140`,`1144`),
  `02/CNKD-TMĐT` (`1142`), `03/CNKD-TMĐT` (`1248`), `01/HKD-ĐNH` (`1243`),
  `01/TKN-CNKD` (`472`,`1245`), `01/BC-SDHĐ-CNKD` (`385`),
  `01/XSBHDCMG-CNKD` (`2000`), `02/CNKD-TNCN-QTT` (`1244`,`1271`).
- Capture: bảng doanh thu theo ngành, thuế suất, hộ khoán, TMĐT, sử dụng hoá đơn.
- Câu hỏi: khác nhau TT40/TT80/TT89; hộ khoán vs hộ kê khai.

### 1.9 Xổ số / Bảo hiểm (7 mã hiển thị)

- `01/XSBHĐC` (`389`,`471`,`1246`), `01/KK-XS` (`46`), `02/KK-XS` (`44`),
  `01/KK-BH` (`9`,`139`), `02/KK-BH` (`43`), `01/TKN-XSBHĐC` (`387`),
  `03/LNCL-XSĐT` (`360`).
- Capture: bảng doanh thu, hoa hồng, thuế suất; phụ lục.

### 1.10 Phí / lệ phí (7 mã hiển thị)

- `01/PH` (`879`), `01/PHLP` (`61`), `01/PHLPNG` (`851`), `02/PH` (`920`),
  `02/PHLP` (`62`), `02/PHLPNG` (`950`), `01/LP` (`880`).
- Capture: bảng phí/lệ phí, đơn vị thu, số tiền, miễn giảm.
- Câu hỏi: phân biệt PH/PHLP/LP; mẫu nộp ngân sách.

### 1.11 Thuế môn bài (2 mã hiển thị)

- `01/MBAI` (`55`,`464`), `01/LPMB` (`824`).
- Capture: bảng bậc môn bài, vốn, số tiền; trường hợp mới thành lập/ngừng.

### 1.12 Tem điện tử (8 mã hiển thị)

- `01/TEM` … `07/TEM`, `CTT24/TEM` (`958`–`969`, `961`).
- Capture: bảng tem, số lượng, loại hàng, mẫu tem; in tem.
- Câu hỏi: đây có phải tờ khai in không; có cần layout đặc biệt.

### 1.13 Vận tải (1 mã hiển thị)

- `01/VTNN` (`67`,`923`).
- Capture: bảng vận tải, doanh thu, thuế suất, kỳ khai.

### 1.14 Hiệp định thuế / HTQT (4 mã hiển thị)

- `01/HTQT` (`1147`), `02/HTQT` (`1150`), `03/HTQT` (`1151`), `06/HTQT` (`1173`).
- Capture: bảng thông tin hiệp định, thuế suất, miễn giảm.

### 1.15 Đăng ký, khai lần đầu & chuyên ngành (91 mã hiển thị)

Gồm các mẫu `*-DK`, `*-VSP`, `ĐK-TCT`, thông báo, xác nhận, khai lần đầu, đăng ký
phương pháp tính thuế, đăng ký người phụ thuộc, đăng ký giao dịch liên kết, v.v.

Cách làm:

1. Lọc `declarations.csv` với `family = "Đăng ký, khai lần đầu & chuyên ngành"`.
2. Nhóm theo template XSLT (118 template).
3. Mỗi template chọn 1 mẫu mới nhất; capture.
4. Ghi `sharedLayoutWith` cho các mã cùng template.

Không cần làm hết 91 mã trong một batch; ưu tiên các mẫu có trong corpus thực tế và các
mẫu `ĐK-TCT`/`05-ĐK-TH-TCT`/`20-ĐK-TCT`/`30/31-ĐK-TCT`.

## WAVE 2 — 276 mã P2

Cách làm nhanh:

1. Nhóm `declarations.csv` theo `template` (bỏ version).
2. Mỗi template chọn 1 mã mới nhất + 1 mã cũ nhất.
3. Capture 2 mẫu đó; nếu layout giống → một spec + `sharedLayoutWith`.
4. Chỉ làm các template có trong corpus thực tế trước.

## WAVE 3 — 57 mã P3

Không có mã hiển thị hoặc là mẫu nội bộ. Chỉ capture khi có file thật hoặc khi được yêu cầu.

---

## Checklist riêng cho tờ khai

- [ ] Header `[01]–[11c]` đúng thứ tự và nhãn.
- [ ] Mỗi dòng: STT, nhãn, mã chỉ tiêu, số cột giá trị, công thức.
- [ ] Dòng section/tổng in đậm đúng.
- [ ] Checkbox in `☐/☒` đúng điều kiện.
- [ ] Số âm in ngoặc đơn; số 0 in `0`; thập phân dấu phẩy.
- [ ] Ngày `dd/MM/yyyy`; kỳ `Tháng/Quý/Năm`.
- [ ] Số trang + orientation + chỗ ngắt trang.
- [ ] Phụ lục `plucIds` có được in kèm hay không.
- [ ] Trường hợp bổ sung lần N, không phát sinh, bị từ chối.

## Mẫu handoff cho batch tờ khai

```text
BATCH: DECL-W0-<tên>
MẪU: <mã>/<version> — PDF <n> trang — orientation <...>
TEMPLATE: <file xslt>
ĐÃ TẠO: forms/<mã>/spec.json, forms/<mã>/evidence/*, forms/<mã>/fixtures/*
PHÁT HIỆN: <khác biệt version, công thức, dòng đặc biệt>
UNKNOWNS: <...>
```

---

## Thứ tự batch đề xuất cho toàn bộ họ

| Batch | Họ | Mẫu ưu tiên | Ghi chú |
|---|---|---|---|
| DECL-0 | P0 | 04/GTGT, 864, 395, 2002–2004, 01/CNKD, BCTC | bắt buộc trước |
| DECL-TNCN-1 | TNCN | 02/KK, 02/QTT, 06/TNCN, 04/NNG | khấu trừ/quyết toán |
| DECL-TNCN-2 | TNCN | 04/CNV, 04/DTV, 04/TKQT, 05/DS, 03/BĐS | thu nhập khác |
| DECL-TNDN-1 | TNDN | 02/TNDN, 04/TNDN, 05/TNDN | gồm TT89 |
| DECL-BCTC-1 | BCTC | 701, 702, 1254 | B01/B05 |
| DECL-BCTC-2 | BCTC | các biến thể DN/CTCK/NH/HTX | quét template |
| DECL-TN-1 | Tài nguyên | 01/TAIN, 02/TAIN, 03/TĐ-TAIN | |
| DECL-BVMT-1 | BVMT | 01/BVMT, 02/BVMT, PBVMT | |
| DECL-TTDB-1 | TTĐB/TTS | 01/TTĐB, 02/TTĐB, 01/TTS | |
| DECL-NTNN-1 | NTNN | 01–04/NTNN, NCCNN | |
| DECL-CNKD-1 | Hộ kinh doanh | 01/CNKD, TMĐT, HKD | |
| DECL-XSBH-1 | Xổ số/Bảo hiểm | XSBHĐC, KK-XS, KK-BH | |
| DECL-PHI-1 | Phí/lệ phí | PH, PHLP, LP | |
| DECL-MBAI-1 | Môn bài | MBAI, LPMB | |
| DECL-TEM-1 | Tem | 01–07/TEM | |
| DECL-VT-1 | Vận tải | VTNN | |
| DECL-HTQT-1 | HTQT | 01–06/HTQT | |
| DECL-DK-1… | Đăng ký/chuyên ngành | ưu tiên ĐK-TCT, 05-ĐK-TH, 20/30/31-ĐK | quét template |

## Prompt mẫu để giao một họ cho agent Windows

```text
Bạn nhận batch DECL-<HỌ>-<số>. Làm theo docs/PROMPTS/windows-re/00-MASTER.md.

HỌ: <tên họ>
DANH SÁCH MÃ: lọc docs/reverse-engineering/inventory/declarations.csv với
family = "<tên họ>"; lấy các dòng wave = "<P0|P1|P2>".
SỐ MẪU TỐI ĐA: 5 mẫu đại diện template (ưu tiên version mới nhất + version cũ nhất).

YÊU CẦU
1. Capture từng mẫu: form + PDF + header/bảng/tổng/footer.
2. Đọc XSLT/XSD để lấy nhãn, XPath, công thức, điều kiện.
3. Tạo spec JSON theo mục 6.1 của 00-MASTER.md cho mỗi template đại diện.
4. Tạo fixture minimal/empty/negative (ẩn danh).
5. Ghi rõ sharedLayoutWith cho các mã cùng template.
6. Cập nhật results + progress, ghi unknowns.

TRẢ VỀ: handoff message theo mục 9 của 00-MASTER.md.
```
