# Review độ phủ & khoảng trống so với iTax Viewer (Windows)

Cập nhật: **2026-10-23** · Mục tiêu: clone **90–100%** giao diện/in và dữ liệu của iTax
Viewer gốc cho các hồ sơ người dùng thực sự dùng.

> Kết luận ngắn: app đã clone tốt 4 tờ khai + 3 phụ lục giảm thuế + 4 mẫu thông báo/chứng
> từ. **Phần lớn phụ lục (207/210), thông báo (119/122 mã) và tờ khai (405/410 mã) vẫn
> chưa có layout chính thức** vì chưa có capture Windows. Muốn đạt 90–100% phải capture
> thêm trên Windows; không thể suy đoán nhãn/công thức.

## 1. Cách đo “clone 90–100%”

Mỗi mẫu được chấm theo 5 trục, mỗi trục 20%:

| Trục | Đạt 100% khi |
|---|---|
| Nhận diện | Đúng root, mã, phiên bản, kỳ, trạng thái (kể cả file bị app gốc từ chối) |
| Bố cục | Đúng thứ tự khối, tiêu đề, cột, độ rộng tương đối, font/cỡ chữ, lề A4 |
| Nhãn & chỉ tiêu | Đúng 100% nhãn, mã chỉ tiêu, công thức, điều kiện hiện/ẩn |
| Giá trị | Đúng định dạng số/ngày/chữ, dòng tổng, số âm, giá trị rỗng |
| In/PDF & chữ ký | Đúng số trang, ngắt trang, header/footer, khối chữ ký, trạng thái chữ ký |

Mốc thực dụng:

- **90–100%**: mở file thật, in PDF, đặt cạnh ảnh/PDF Windows — không thấy khác biệt về
  nội dung; chỉ có thể khác vài pixel.
- **70–89%**: đúng dữ liệu và thứ tự khối, sai khoảng cách/font/nhãn phụ.
- **<70%**: còn bảng dữ liệu thay cho layout, hoặc thiếu khối.

Trạng thái hiện tại của các mẫu đã làm: **~85–95%** (đúng layout/dữ liệu, chưa có visual
diff từng pixel với Windows). Các mẫu còn lại: **0–40%** (chỉ structured view).

## 2. Nguồn dữ liệu & phương pháp review

- `documents/document-registry.csv`: **1.512 dòng** trích từ 16 registry của bản Windows,
  gồm mã, version, template XSLT, XSD, orientation, phụ lục đi kèm.
- `Sources/iTaxViewerCore/Resources/form-registry.json`: 410 mã tờ khai / 237 mã hiển thị.
- `documents/progress.json` + `PROGRESS.md`: những gì đã capture/spec/implement.
- Code macOS: `HTMLRenderer`, `NoticeRenderer`, `VoucherRenderer`, `form-specs.json`.
- Script sinh inventory: `tools/generate_coverage.py` (chạy lại bất cứ lúc nào).

Inventory máy đọc (dùng để chia batch khi RE):

| File | Nội dung |
|---|---|
| [`inventory/declarations.csv`](inventory/declarations.csv) | 410 mã tờ khai, family, version, template, trạng thái, wave |
| [`inventory/declaration-families.csv`](inventory/declaration-families.csv) | 17 họ tờ khai: số mã hiển thị, mã `maTKhai`, version, template |
| [`inventory/notices.csv`](inventory/notices.csv) | 158 dòng registry × 122 mã thông báo |
| [`inventory/appendices.csv`](inventory/appendices.csv) | 210 phụ lục, số tờ khai cha, trạng thái, wave |
| [`inventory/vouchers.csv`](inventory/vouchers.csv) | 5 dòng chứng từ |
| [`inventory/registration-catalog.csv`](inventory/registration-catalog.csv) | 10 đăng ký thuế + 1 danh mục |
| [`inventory/coverage-summary.json`](inventory/coverage-summary.json) | Tổng hợp số liệu |

## 3. Tổng quan độ phủ

| Loại | Tổng | Đã có layout | Chỉ structured | Ghi chú |
|---|---:|---:|---:|---|
| Tờ khai | 410 mã / 237 mã hiển thị | **5 mã** (01/GTGT, 05/KK-TNCN, 05/QTT-TNCN, 03/TNDN + legacy `01`) | 405 | 4 layout đầy đủ + alias version cũ |
| Thông báo | 122 mã (158 dòng registry) | **3** (843, 844, 01/TB-BSTT) | 119 | 9 registry thông báo |
| Phụ lục | 210 mã | **3** (NQ43/NQ101/NQ142 GTGT) | 207 | PL01_KHBS & PL01_1_KHBS là P0 |
| Chứng từ | 5 dòng (đều CT-01) | **1** (4.0.1) | 4 | 1.0.0/3.0.0/4.0.0/4.0.2 chưa capture |
| Đăng ký thuế | 10 mã | 0 | 10 | chưa capture |
| Danh mục | 1 | 0 | 1 | không phải tờ khai |
| Hóa đơn điện tử | 5 root | 0 | 5 | chưa có registry riêng |
| Hải quan | 181 mã / 515 dòng | 0 | 181 | P3, ngoài phạm vi thuế nội địa |

Điểm đáng chú ý: **210 phụ lục** nhưng chỉ 3 cái có layout; đây là khoảng trống lớn nhất
so với cảm nhận người dùng, vì mỗi tờ khai thường kèm 1–11 phụ lục.

## 4. Tờ khai

### 4.1 Đã clone đầy đủ

| Mẫu | Mã | Version đã map | Ghi chú |
|---|---|---|---|
| 01/GTGT | `842`, legacy `01` | 2.5.1–2.8.3; legacy 2.0.6–2.6.2 | Có cảnh báo khi version legacy chưa capture |
| 05/KK-TNCN | `394` | 2.1.6 | TT 92/2015 |
| 05/QTT-TNCN | `953` | 2.5.1–2.9.3 | TT 80/2021 |
| 03/TNDN | `892` | 2.5.1–2.9.4 | 74 dòng |

### 4.2 Wave P0 — làm ngay (14 mã, 8 mẫu)

| Mã | Mẫu | Version | Template |
|---|---|---|---|
| `07`, `847` | **04/GTGT** | 2.0.x–2.1.2; 2.5.1–2.7.4 | `TKhai_GTGT_04*.xslt` |
| `864` | **05/KK-TNCN (TT80)** | 2.5.1; 2.8.3; 2.9.3 | `TKhai_05_KK_TNCN_TT80.xslt` |
| `395` | **05/QTT-TNCN (cũ)** | 2.1.6; 2.4.2 | `TKhai_05QTT_TNCN.xslt` |
| `2002` | **04/TNDN (TT89/2025)** | 3.0.9 | `TKhai_TNDN_04_TT89.xslt` |
| `2003` | **02/TNDN (TT89/2025)** | 3.0.9 | `TKhai_TNDN_02_TT89.xslt` |
| `2004` | **05/TNDN (TT89/2025)** | 3.0.9 | `TKhai_TNDN_05_TT89.xslt` |
| `386`, `473`, `1240`, `1266` | **01/CNKD** (hộ kinh doanh) | 2.1.6–2.9.8 | `TKhai_01_CNKD*.xslt`, `CNKK_01_CNKD.xslt` |
| `701`, `702`, `1254` | **B01/B05 BCTC** | 2.3.5; 2.9.0 | `TKhai_BCTC*.xslt` |

Lý do ưu tiên: đây là các mẫu phổ biến, có trong registry, và 04/GTGT đã xuất hiện trong
corpus thật của người dùng (3/12 file).

### 4.3 Wave P1 — các họ tờ khai còn lại (không chỉ GTGT)

Ngoài GTGT, toàn bộ 237 mã hiển thị được chia thành 17 họ để review/capture (bảng đầy đủ
trong `inventory/declaration-families.csv`):

| Họ | Mã hiển thị | Ghi chú |
|---|---:|---|
| Đăng ký, khai lần đầu & chuyên ngành | 91 | `*-DK`, `*-VSP`, `ĐK-TCT`, khai lần đầu |
| BCTC & thuyết minh | 36 | B01/B02/B05, CTCK/NH/HTX, thuyết minh |
| TNCN | 24 | Khấu trừ, quyết toán, thu nhập khác, chuyển nhượng, BĐS |
| TNDN | 17 | Gồm TT89/2025, dầu khí |
| Tài nguyên | 9 | Khai thác, dầu khí, tài nguyên |
| Hộ kinh doanh | 8 | CNKD/HKD, TMĐT, xổ số |
| Tem điện tử | 8 | Tem thuốc lá/rượu |
| Xổ số / Bảo hiểm | 7 | Xổ số, bảo hiểm |
| Nhà thầu nước ngoài | 7 | NTNN/NCCNN |
| Phí / lệ phí | 7 | Phí, lệ phí, phí BVMT |
| GTGT | 6 | Đã có 01/GTGT; còn 02/03/04/05 |
| TTĐB / TTS | 5 | Tiêu thụ đặc biệt/TTS |
| Bảo vệ môi trường | 5 | BVMT, túi nilon |
| Hiệp định thuế / HTQT | 4 | HTQT |
| Thuế môn bài | 2 | Môn bài |
| Vận tải | 1 | VTNN |
| Không mã hiển thị / nội bộ | 1 (57 mã) | P3 |

Prompt `01-DECLARATIONS.md` có batch card chi tiết cho **từng họ** ở trên, kèm mã, version,
template và câu hỏi capture. Các họ P1/P2 không bị bỏ qua; thứ tự chỉ là ưu tiên.

### 4.4 Wave P2/P3 — 333 mã

- 276 mã P2 có mã hiển thị nhưng ít dùng (thuế tiêu thụ đặc biệt, tài nguyên, bảo vệ môi
  trường, đất đai, chứng khoán, ngân hàng, bảo hiểm, v.v.).
- 57 mã P3 không có mã hiển thị hoặc là mẫu nội bộ.
- Cách làm: **không capture từng mã**. Chọn 1 mẫu đại diện cho mỗi template XSLT trong
  `declarations.csv`, capture rồi map các mã dùng chung template.

### 4.5 Câu hỏi phải trả lời khi RE tờ khai

1. Bố cục header `[01]–[11c]` theo đúng mẫu (khác nhau giữa các mẫu).
2. Danh sách chỉ tiêu: STT, nhãn, mã `[x]`, số cột, công thức, điều kiện ẩn/hiện.
3. Quan hệ cha–con (dòng tổng in đậm, dòng `Trong đó`, dòng bắt buộc).
4. Định dạng số âm, số 0, số thập phân, đơn vị tiền, ngày tháng.
5. Phụ lục đi kèm (lấy từ `plucIds` trong CSV).
6. Số trang PDF, orientation, ngắt trang, lặp header bảng.
7. Trường hợp đặc biệt: không phát sinh, bổ sung lần N, tờ khai bị từ chối, NNT ngừng HĐ.

## 5. Thông báo

- 122 mã, 158 dòng registry, 9 registry: `DMucTbao.xml`, `DMucTBaoNtdt.xml`,
  `DMucTBaoNtdt22.xml`, `DMucTbao_InCDoi.xml`, `DMucBKeKDTT.xml`,
  `DMucXNhanCTuNtdt.xml`, `DmucTSoatNtdt.xml`, `DMucTBaoKDTT.xml`, `DmucBtruNtdt.xml`.
- Đã capture/spec 3: `843` (01-01/TB-TĐT), `844` (01-2/TB-TĐT), `01/TB-BSTT`.
- **P0 còn lại (11 mã)**: nhóm `01/TB-*` (`01/TB-BSTT-NNT`, `01/TB-NSD`, `01/TB-SSĐT`,
  `01/TB-TNĐT`, `01/TB-ĐKĐT`, `01/CCTT-TB`) và các mã hay gặp
  `448`, `450`, `451`, `801`, `818`, `960`, `998`.
- **P1: 90 mã** trong `DMucTbao.xml` (thông báo thuế nội địa).
- **P2: 51 mã** thuộc registry chứng từ điện tử/hóa đơn/đối chiếu.

Mỗi mã thông báo cần capture tối thiểu:

1. Nhánh mặc định (`trangThai=Y` hoặc không có).
2. Nhánh từ chối/không chấp nhận (`trangThai=N`) nếu có.
3. Bảng dữ liệu (lý do, mã định danh khoản nộp, danh sách hồ sơ…).
4. Phụ lục đính kèm (`PLuc`/`TBao_*`).
5. Footer, nơi nhận, chữ ký, số trang.

## 6. Phụ lục — khoảng trống lớn nhất

### 6.1 Đã có layout

`PL_NQ43_GTGT`, `PL_NQ101_GTGT`, `PL_NQ142_GTGT` (bảng giảm thuế GTGT).

### 6.2 P0

| Phụ lục | Số tờ khai cha | Ghi chú |
|---|---:|---|
| `PL01_KHBS` | 34 | Phụ lục 01/KHBS — khai bổ sung; nhiều mục A/B, bảng chi tiết |
| `PL01_1_KHBS` | 12 | Phụ lục 01-1/KHBS — danh sách hồ sơ/tài liệu |

Đây là lý do người dùng thấy “nhiều phụ lục chưa render được”: hầu hết file khai bổ sung
đều có 2 phụ lục này.

### 6.3 P1 — 134 mã, các họ chính

- **GTGT**: `PL01_1..7_GTGT`, `PL01_2_1..2_9_GTGT`, `PL_01_1/2_TD_GTGT`,
  `PL_ND92_GTGT`, `PL_ND15_GTGT`, `PL02_1_HT`…
- **TNDN**: `PL03_1A..8_TNDN` và các biến thể `PLuc_03_*_TNDN`.
- **TNCN**: `PLuc_05_*_BK_QTT`, `PL05A/B_BK-TNCN`, `PLuc_06_*_BK_TNCN`,
  `PLuc_02_1_BK_QTT_TNCN`, `PL27MGT-TNCN`, `PL09-*_TNCN`…
- **Đăng ký/khai lần đầu**: `PL_01_*_DK_TCT`, `PL_02..05_01_DK_TCT`, `PLuc_01_DK`,
  `PLuc_01_1/2/3_TTDB`, `PL_01_1/2/3_VTNN`…
- **Hộ kinh doanh**: `PLuc_01_1_BK_CNKD`, `PLuc_01_1_PL_CNKD`, `PLuc_HKD_CNKD`…
- **BCTC**: `PL_LCTT`, `PL_LCTTGT`, `PL_LCTTTT`, `PL_KQHDSXKD`, `PL_KQHDXSKD`,
  `PL_BCKQHD*`, `PL_THVCSH`…
- **Theo tờ khai đặc thù**: `PL_CDTK`, `PL_01_XSDT`, `PL_GDLK2-01..04`, `Pluc_01_TT146`,
  `PL_ND114`, `PL_01/02/03/04_ND20`…

### 6.4 P2 — 71 mã còn lại

Xem `inventory/appendices.csv`, lọc `wave=P2`. Phần lớn là phụ lục của các tờ khai ít
dùng; chỉ làm khi corpus thực tế có.

### 6.5 Câu hỏi phải trả lời khi RE phụ lục

1. Tiêu đề, căn cứ pháp lý, mẫu số in trên đầu trang.
2. Các mục (A/B/I/II/1/2…), mục nào có bảng, mục nào chỉ là dòng text.
3. Cột bảng: tiêu đề, thứ tự, độ rộng, canh lề, công thức tổng.
4. Record path và khóa lặp; trường hợp mảng rỗng.
5. Quan hệ với tờ khai cha: số liệu lấy từ tờ khai hay từ chính phụ lục.
6. Số trang, orientation, ngắt trang trước mục B, lặp header.
7. Cách in số 0, số âm, số thập phân, đơn vị tiền.
8. Chữ ký/footer riêng của phụ lục (nếu có).

## 7. Chứng từ

| Mã | Version | Trạng thái |
|---|---|---|
| CT-01 | 4.0.1 | Đã có layout C1-02/NS (VND, nhiều dòng, số tiền bằng chữ) |
| CT-01 | 1.0.0 / 3.0.0 / 4.0.0 / 4.0.2 | Chưa capture |
| MA_CTU=02 | ? | Chưa có trong registry, chưa capture |

Cần capture thêm: nhiều `NDUNG_CTU`, USD, `MA_NGUYENTE` rỗng/`00000`, số tiền âm, tổng
tiền, phần KBNN ghi, chữ ký.

## 8. Các loại khác

- **Đăng ký thuế**: 10 mã (219–223, 216–218, 350, 351), template trong
  `data/XSLT 2.0.9/TBaoThue/xslt/…`. Chưa capture.
- **Danh mục**: 1 mẫu, không phải tờ khai.
- **Hóa đơn điện tử**: root `TKhai`, `DNghi`, `TBao`, `BCTHSDBLai`, `BLai`; chưa có
  registry riêng, cần mẫu XML đại diện cho từng root.
- **Hải quan**: 181 mã / 515 dòng, root `TOKHAI_OBJ`, `TOKHAISUA_OBJ`, `*:Envelope`;
  P3, ngoài phạm vi thuế nội địa nhưng có thể làm sau.

## 9. Chữ ký số (bắt buộc cho mục tiêu 90–100%)

Hiện tại app chỉ hiển thị **metadata** chữ ký và luôn trả trạng thái “chưa xác minh”.
Để clone đúng bản Windows cần RE:

1. App gốc hiển thị trạng thái gì (hợp lệ/không hợp lệ/không tin cậy/hết hạn/thiếu cert).
2. Có kiểm tra chữ ký mật mã hay chỉ đọc `SignatureValue`?
3. Thuật toán: C14N / exclusive C14N, enveloped transform, SHA-1/256/512, RSA/ECDSA.
4. Chuỗi chứng thư: root CA, intermediate, trust store, CRL/OCSP, thời gian ký.
5. Có timestamp (TSA) không; hiển thị thời gian ký hay thời gian TSA.
6. Nhiều chữ ký, chữ ký bị sửa, cert hết hạn, cert không khớp MST.
7. Bố cục khối chữ ký trên bản in/PDF.

## 10. Prompt pack để reverse trên Windows

| File | Dùng cho |
|---|---|
| [`docs/PROMPTS/windows-re/00-MASTER.md`](../PROMPTS/windows-re/00-MASTER.md) | Quy trình chung, output contract, batch protocol |
| [`01-DECLARATIONS.md`](../PROMPTS/windows-re/01-DECLARATIONS.md) | 4 tờ khai P0 + 58 mã P1 + cách quét P2/P3 |
| [`02-NOTICES.md`](../PROMPTS/windows-re/02-NOTICES.md) | 119 mã thông báo còn lại |
| [`03-APPENDICES.md`](../PROMPTS/windows-re/03-APPENDICES.md) | 207 phụ lục, đặc biệt PL01_KHBS/PL01_1_KHBS |
| [`04-VOUCHERS.md`](../PROMPTS/windows-re/04-VOUCHERS.md) | CT-01 versions + MA_CTU khác |
| [`05-SIGNATURES.md`](../PROMPTS/windows-re/05-SIGNATURES.md) | Chữ ký số, C14N, trust, timestamp |
| [`06-OTHER-KINDS.md`](../PROMPTS/windows-re/06-OTHER-KINDS.md) | Đăng ký thuế, danh mục, hóa đơn, hải quan |

## 11. Kế hoạch đạt 90–100%

| Wave | Nội dung | Kết quả kỳ vọng |
|---|---|---|
| **0** | 8 mẫu P0 + PL01_KHBS/PL01_1_KHBS + 6 thông báo `01/TB-*` + chữ ký | Phủ hầu hết hồ sơ người dùng thật |
| **1** | 58 mã tờ khai P1 + 90 thông báo P1 + 134 phụ lục P1 | Phủ các nghiệp vụ phổ biến |
| **2** | Quét theo template cho 276 mã P2 + 51 thông báo P2 + 71 phụ lục P2 | Phủ phần còn lại của 237 mã hiển thị |
| **3** | Hải quan, hóa đơn, danh mục, mẫu nội bộ | Ngoài phạm vi 90% thuế nội địa |

Sau mỗi batch RE: cập nhật `documents/progress.json`, `PROGRESS.md`, `results/*.md`, rồi
giao lại để implement macOS + viết test + so ảnh/PDF.

## 12. Rủi ro / giới hạn

- Không có bản Windows ⇒ không thể xác nhận nhãn, công thức, số trang. **Không suy đoán.**
- Một số mẫu có nhiều version khác layout (04/GTGT, 01/CNKD, TT89/2025); phải capture
  từng version lớn.
- Phụ lục có thể phụ thuộc tờ khai cha; cùng tên nhưng khác layout giữa các version.
- Dữ liệu thật không được commit; fixture phải ẩn danh hoặc synthetic.
- 90–100% chỉ đạt được với các mẫu **đã capture**; các mẫu P3 hiếm vẫn có thể dừng ở
  structured view nếu không có trong corpus.
