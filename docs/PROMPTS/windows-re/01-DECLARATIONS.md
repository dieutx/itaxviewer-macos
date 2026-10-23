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

## WAVE 1 — 58 mã, gom batch theo họ template

Không làm từng mã rời. Mỗi batch chọn **1 mẫu đại diện cho mỗi template XSLT**, capture
rồi map các mã dùng chung.

| Batch | Họ | Mã (mẫu) | Template gợi ý |
|---|---|---|---|
| 1A | GTGT | `02`,`844`; `04`,`846`; `53`,`850`; `132` | `TKhai_GTGT_02/03/05`, `TKhai_GTGT_TD` |
| 1B | TNCN khấu trừ/quyết toán | `47`,`391`,`859`; `392`,`952`,`1000`; `396`,`865`,`2006`; `863` | `TKhai_02KK_TNCN`, `TKhai_02QTT_TNCN`, `TKhai_06TNCN`, `TKhai_04NNG_TNCN` |
| 1C | TNDN | `71`,`837`,`1267`; `13`,`833` | `TKhai_TNDN_02`, `TKhai_TNDN_04` |
| 1D | Tài sản/TAIN/NTNN | `06`,`1242`,`832`; `08`,`924`; `135`,`444`,`868`; `133`; `41`,`838`; `74`,`921`; `73`,`840`; `72`,`922` | `TKhai_TAIN`, `TKhai_NTNN` |
| 1E | Khác | `388`,`470` (TTS); `128`,`914` (TBVMT); `66`,`841` (HKNN); `68`,`1261`,`843` (TBH); `389`,`471`,`1246` (XSBHĐC); `43`; `44`; `384`; `55`,`464`; `67`,`923` | theo CSV |

Với mỗi batch:

1. Mở `declarations.csv`, lọc các mã trên, lấy template/version/orientation.
2. Tạo XML synthetic bằng HTKK cho mẫu đại diện.
3. Capture như Wave 0.
4. Ghi rõ mã nào dùng chung layout, mã nào khác.

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
