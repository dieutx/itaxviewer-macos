# Prompt chi tiết: reverse-engineer toàn bộ phụ lục (`PLuc`) của iTax Viewer trên Windows

> **Phạm vi rộng hơn:** nếu cần điều tra **mọi loại tài liệu** (tờ khai, thông báo, giấy nộp
> tiền, đăng ký, danh mục, hóa đơn, hải quan), dùng
> [`WINDOWS_DOCUMENT_RE.md`](WINDOWS_DOCUMENT_RE.md) và bộ `document-re/`. File này chỉ tập
> trung vào phụ lục và được dùng như sub-kit của `document-re/types/appendices.md`.

> **Mục đích:** giao cho một agent chạy trên máy Windows có `iTaxViewer.exe`. Agent phải
> điều tra **đầy đủ** các loại phụ lục, bố cục in, mã chỉ tiêu, công thức và hành vi của bản
> gốc; sau đó xuất ra **spec JSON + fixture ẩn danh + ảnh/PDF đối chiếu** để đội macOS
> implement mà không cần mở lại Windows.
>
> **Không được:** copy XSLT/CSS/font/ảnh của hãng vào repo; commit dữ liệu người nộp thuế
> thật; đoán bố cục hoặc mã chỉ tiêu khi chưa có bằng chứng.
>
> **Phiên bản prompt:** 2.0 — 2026-10-22.

---

## 0. START HERE — thứ tự bắt buộc

1. Đọc hết prompt này.
2. Xác nhận môi trường (mục 2) và hỏi operator 4 câu ở mục 11.
3. Làm **Phase 1 inventory** trước, chưa được sửa/tạo spec.
4. Gửi inventory tóm tắt cho operator để chốt thứ tự ưu tiên.
5. Với từng `plucID` theo thứ tự đã chốt: capture → spec → fixture → validation.
6. Xuất handoff theo mục 9 và tự kiểm tra checklist mục 10.
7. Chỉ báo “done” khi tất cả acceptance criteria đã được chạy thật.

Nếu một bước không thể chạy (thiếu app, thiếu mẫu, không xuất được PDF), ghi rõ
`BLOCKED: <lý do>` và **không** thay bằng phỏng đoán.

---

## 1. Vai trò và phạm vi

Bạn là kỹ sư reverse-engineering cho dự án clone độc lập **iTax Viewer for macOS**
(`dieutx/itaxviewer-macos`). Bạn làm việc trên Windows, nơi có ứng dụng gốc.

**Trong phạm vi:**

- Tất cả phần tử con của `<PLuc>` (mỗi con là một `plucID`).
- Các tờ khai có phụ lục: 01/GTGT, 04/GTGT, 01/CNKD, 01/TTS, 03/TNDN, 05/KK-TNCN,
  05/QTT-TNCN, 01/KHBS, 01-1/KHBS, thông báo/chứng từ có `PLuc`.
- Bố cục hiển thị, bố cục in/PDF, thứ tự mục, cột, tổng, công thức, điều kiện hiển thị.

**Ngoài phạm vi:**

- Không sửa code macOS trong repo này (trừ khi operator yêu cầu rõ).
- Không phân tích malware/JAR ngoài mục đích lấy facts giao diện.
- Không tái phân phối bất kỳ tài nguyên nào của hãng.

**Đã có sẵn — không làm lại từ đầu:**

- `PL_NQ43_GTGT`, `PL_NQ101_GTGT`, `PL_NQ142_GTGT` đã được dựng layout theo mẫu chính thức
  NQ 43/2022, NQ 101/2023, NQ 142/2024 trong `HTMLRenderer.swift`.
- Nhiệm vụ của bạn với 3 ID này chỉ là **verify** (nếu có thời gian): chụp bản gốc, so sánh
  tiêu đề/cột/tổng, ghi khác biệt. Không viết lại spec nếu không có khác biệt.

---

## 2. Kiểm tra môi trường (làm trước khi bắt đầu)

Ghi lại kết quả thực tế:

| Hạng mục | Cách kiểm tra | Giá trị cần ghi |
|---|---|---|
| Windows version | `winver` | |
| iTax Viewer version | Help → About, hoặc thuộc tính `iTaxViewer.exe` | |
| Đường dẫn cài đặt | `Get-ChildItem "C:\Program Files (x86)" -Filter "iTax*"` | |
| Java/JRE đi kèm | thư mục `jre` trong app | |
| `DMucTKhai.xml` | `Get-ChildItem -Recurse -Filter DMucTKhai.xml` | |
| Thư mục XSLT | `Get-ChildItem -Recurse -Directory -Filter "XSLT*"` | |
| Corpus XML | đường dẫn operator cung cấp | |
| Quyền ghi file | tạo thử thư mục output | |
| Công cụ chụp ảnh | Snipping Tool / PowerShell screenshot | |
| Công cụ PDF | Print → Microsoft Print to PDF, hoặc export của app | |

Nếu `iTaxViewer.exe` không mở được file mẫu, dừng và báo `BLOCKED`.

**Tuyệt đối không** đưa file XML thật lên mạng, email, cloud hay issue GitHub.

---

## 3. Phase 1 — Inventory (bắt buộc làm trước)

### 3.1. Inventory registry

Đọc `DMucTKhai.xml` và trích mọi entry `DSachPLuc/PLuc`:

- `plucID` (tên phần tử con, bỏ namespace prefix)
- `TenPLuc` (tên hiển thị)
- `PLucXSLT` (đường dẫn template — chỉ để tham chiếu)
- `plucOrientation` (`0` = portrait, `1` = landscape theo registry đã phục hồi)
- `plucViewMethod`
- form cha: `maTKhai`, `pbanTKhai`, `loaiTKhai` nếu có

Xuất `appendix-inventory.json`:

```json
{
  "schemaVersion": 1,
  "capturedAt": "2026-10-22",
  "app": { "version": "…", "installPath": "…" },
  "appendices": [
    {
      "plucID": "PL01_KHBS",
      "tenPLuc": "…",
      "plucXSLT": "…",
      "orientation": "portrait",
      "viewMethod": "…",
      "parentForms": ["842", "01"],
      "observedInCorpus": 4,
      "versionsObserved": ["2.9.3"],
      "priority": "P0",
      "status": "inventory-only"
    }
  ]
}
```

### 3.2. Inventory corpus thực tế

Quét toàn bộ corpus (không in giá trị):

- root element
- `TKhaiThue/maTKhai`, `pbanTKhaiXML`, `loaiTKhai`
- danh sách `PLuc` con, thứ tự xuất hiện
- với mỗi phụ lục: các section cấp 1, tag bản ghi lặp, số bản ghi
- chữ ký có/không (chỉ boolean)

Xuất thêm `appendix-usage.csv`:

```text
file_code,version,filing_type,pluc_ids,record_counts
842,2.8.3,C,PL_NQ142_GTGT,"HH_DV_MuaVaoTrongKy=556;HH_DV_BanRaTrongKy=521"
```

**Không** ghi tên file thật nếu tên file chứa MST/tên người nộp; dùng mã giả `sample-001`.

### 3.3. Đối chiếu registry ↔ thực tế

Lập bảng 3 cột:

- Có trong registry + có trong corpus → ưu tiên cao.
- Có trong registry + chưa thấy trong corpus → vẫn phải spec (dùng mẫu tự tạo/HTKK).
- Có trong corpus + không có registry → ghi `unmapped`, kiểm tra hành vi app gốc (có crash NPE
  như tài liệu không).

### 3.4. Chốt priority với operator

Đề xuất mặc định:

| Priority | plucID / nhóm | Lý do |
|---|---|---|
| P0 | `PL01_KHBS` | 01/KHBS, nhiều mục, dùng khi khai bổ sung |
| P0 | `PL01_1_KHBS` | 01-1/KHBS, danh sách hồ sơ/tài liệu |
| P1 | `BaoCaoTaiChinh` | phụ lục 03/TNDN, hiện fallback raw table |
| P1 | phụ lục của 05/KK-TNCN, 05/QTT-TNCN | nhóm thuế TNCN |
| P2 | `PL_NQ204_GTGT` hoặc ID giảm thuế 2026 thực tế | chính sách 2026, cần verify ID/version |
| P2 | phụ lục thông báo/chứng từ | hiện generic |
| P3 | toàn bộ `plucID` còn lại trong registry | long tail |

---

## 4. Phase 2 — Capture bản gốc

### 4.1. Ma trận capture tối thiểu cho mỗi `plucID`

| Trường hợp | Bắt buộc | Ghi chú |
|---|---|---|
| File thật/đại diện có dữ liệu | Có | Che dữ liệu trước khi chụp nếu ảnh sẽ commit |
| Mục I/II/III đầy đủ | Có | Nếu form có nhiều mục |
| Mục rỗng | Có | Cách app hiển thị “không có phát sinh”/ẩn mục |
| Chỉ có mua vào, không có bán ra | Có | Với phụ lục GTGT |
| Giá trị âm / chênh lệch âm | Có | Kiểm tra ngoặc đơn |
| Số thập phân (thuế suất 10,5) | Có | Kiểm tra dấu phẩy |
| ≥ 200 dòng | Có | Kiểm tra phân trang, lặp header, tổng |
| Nhiều `<PLuc>` trong cùng file | Nếu có | Thứ tự render |
| Nhiều version | Nếu có | So sánh khác biệt |

Không cần chụp dữ liệu thật nếu không thể che; có thể tạo file synthetic đúng cấu trúc
bằng HTKK hoặc bằng tay, miễn là app gốc mở được và cấu trúc khớp file thật.

### 4.2. Ảnh cần chụp

- Toàn cửa sổ app ở zoom 100%.
- Vùng tiêu đề + khối thông tin người nộp.
- Từng mục/bảng, đặc biệt header cột và dòng tổng.
- Print Preview (nếu có).
- Trang đầu và trang cuối của PDF.

Quy ước tên:

```text
docs/reverse-engineering/evidence/appendices/<plucID>/
  original-<plucID>-p1.png
  original-<plucID>-p2.png
  original-<plucID>-print-preview.png
  original-<plucID>-export.pdf
  capture-notes.md
```

`capture-notes.md` ghi:

- ngày giờ, phiên bản app, Windows, độ phân giải/zoom;
- file mẫu (mã giả, không MST);
- số trang, khổ giấy, orientation;
- những chỗ không đọc được/không chắc.

### 4.3. Những gì phải đo/ghi trong spec

- Tiêu đề chính xác, kể cả dấu tiếng Việt và xuống dòng.
- Căn cứ pháp lý (Nghị quyết/Nghị định/Thông tư) và số hiệu.
- Khối `[01]`–`[04]` (hoặc numbering riêng) và nhãn.
- Thứ tự mục La Mã, tiêu đề mục, có in đậm/nghiêng không.
- Cột: thứ tự, tiêu đề, đơn vị, căn lề, định dạng số/percent, độ rộng tương đối.
- Mã chỉ tiêu nằm ở cột nào, có ngoặc vuông không.
- Dòng tổng: mã `[05]`…, nhãn, công thức, vị trí (cuối bảng hay sau mỗi trang).
- Hàng nào in đậm, hàng nào là section, hàng nào ẩn khi rỗng.
- Cách xử lý bảng dài: lặp header? ngắt trang trong bảng? tổng chỉ ở cuối?
- Có chữ ký/footer riêng cho phụ lục không.
- Có tab/link chuyển phụ lục trong app gốc không (chỉ ghi nhận, không cần clone UI đó).

---

## 5. Phase 3 — Viết spec JSON

### 5.1. Vị trí file

```text
docs/reverse-engineering/appendices/
  appendix-inventory.json
  appendix-inventory.md
  PL01_KHBS.json
  PL01_KHBS.md
  PL01_1_KHBS.json
  ...
  fixtures/
    pl01_khbs-minimal.xml
    pl01_khbs-negative.xml
    ...
```

### 5.2. Schema đầy đủ

```json
{
  "id": "PL01_KHBS",
  "title": "…",
  "citation": "…",
  "orientation": "portrait",
  "pageBreakBefore": true,
  "versions": ["2.9.3"],
  "sourceTemplates": ["XSLT 2.9.3/…"],
  "headerFields": [
    { "code": "01", "label": "Tên người nộp thuế", "source": "Header/tenNNT", "format": "text" },
    { "code": "02", "label": "Mã số thuế", "source": "Header/mst", "format": "text" }
  ],
  "sections": [
    {
      "id": "Muc_I",
      "title": "I. …",
      "kind": "table",
      "pageBreakBefore": false,
      "recordPath": "Muc_A/Muc_I/Muc_1/ChiTiet",
      "emptyBehaviour": "show-empty-row",
      "columns": [
        { "key": "stt", "title": "STT", "format": "index", "align": "center", "width": "5%" },
        { "key": "ten", "title": "…", "source": "ct2_ten", "format": "text", "align": "left" },
        { "key": "so_tien", "title": "…", "source": "ct3", "format": "number", "align": "right" }
      ],
      "totals": [
        { "code": "[10]", "label": "Tổng cộng", "source": "tongCong_ct10", "format": "number", "formula": null }
      ],
      "rowRules": [
        { "when": "ct3 < 0", "style": "parentheses" }
      ],
      "notes": []
    }
  ],
  "unknowns": []
}
```

**Quy tắc:**

| Trường | Ý nghĩa |
|---|---|
| `source` | đường dẫn phần tử tương đối so với `recordPath` hoặc gốc phụ lục |
| `format` | `text`, `number`, `percent`, `index`, `date`, `checkbox` |
| `emptyBehaviour` | `show-empty-row`, `hide-section`, `show-header-only` |
| `formula` | công thức dạng chuỗi, ví dụ `[09] = [08] - [06]` |
| `rowRules` | điều kiện style/format đặc biệt |
| `unknowns` | mọi điểm chưa xác minh; không được bỏ trống nếu có |
| `versions` | nếu layout đổi theo version, tách override riêng |

### 5.3. Ví dụ tối thiểu cho PL01_KHBS (dựa trên cấu trúc đã quan sát)

Các nhánh cần điền:

- `Header`: `maTKhai`, `tenTKhai`, `KyKKhaiThue`, `soLan`, `mst`, `tenNNT`, `mstDLyThue`,
  `tenDLyThue`, `soHDongDLyThue`, `ngayKyHDDLyThue`.
- `Muc_A/Muc_I/Muc_1/ChiTiet` — bảng chi tiết.
- `Muc_A/Muc_I/Muc_2/DSachPLuc` — danh sách phụ lục con.
- `Muc_A/Muc_II/ChiTiet` (`ct2_ma`, `ct2_ten`, `ct3`) + `tongCong_ct12`.
- `Muc_A/Muc_III/ChiTiet` + `tongCong_ct13`.
- `Muc_B/Muc_I` (các `ct_1`, `ct_2_so`, `ct_2_ngay`, `ct_2_CQT_ma`, `ct_2_CQT_ten`,
  `ct_3_so`, `ct_3_ngay`).
- `Muc_B/Muc_II` (`ct_1`, `ct_2`).

Agent phải xác định **nhãn tiếng Việt, mã chỉ tiêu, công thức** cho từng nhánh bằng ảnh
chụp bản gốc; không được suy ra từ tên tag.

### 5.4. PL01_1_KHBS

Cấu trúc đã quan sát:

- `Muc_A/DSachHSo/BKeHSo` (`ma_HSo`, `ten_HSo`, `CTietHSo`).
- `TongCong` (`tongCong_7`, `tongCong_8`, `tongCong_9`).
- `Muc_B/CTietTaiLieu` (`ma_TLieu`, `ten_TLieu`).

Cần xác định:

- `CTietHSo` là chuỗi hay bảng con? Có lặp không?
- Ý nghĩa `tongCong_7/8/9` và công thức.
- `ma_TLieu`/`ten_TLieu` hiển thị thành bảng hay danh sách.
- Thứ tự tài liệu đính kèm.

### 5.5. BaoCaoTaiChinh (03/TNDN)

- Xác định đây là bộ báo cáo tài chính gồm những bảng nào (B01, B02, B03…).
- Có thể có nhiều `<BaoCaoTaiChinh>` hoặc các tag con lồng nhau.
- Cần spec cho từng bảng, không gộp thành một bảng đường dẫn/giá trị.
- Nếu app gốc crash với appendix này (theo `COMPATIBILITY.md`), ghi rõ hành vi và dùng
  template/loại file khác để lấy layout nếu có.

### 5.6. Phụ lục 05/KK-TNCN và 05/QTT-TNCN

Inventory trước; nếu registry không có `PLuc` cho hai form này thì ghi `none` và không bịa.
Nếu có, áp dụng cùng schema.

### 5.7. `PL_NQ204_GTGT` / phụ lục giảm thuế 2026

- Kiểm tra `DMucTKhai.xml` xem có ID mới cho NQ 204/2025 không.
- Nếu file 2026 vẫn dùng `PL_NQ142_GTGT`, ghi rõ và không tạo ID giả.
- Nếu có ID mới, capture và spec như NQ142; so sánh 3 mục I/II/III và các cột.

---

## 6. Phase 4 — Fixture ẩn danh

### 6.1. Nguyên tắc

- Không commit file gốc.
- Tạo fixture nhỏ (2–5 dòng/section) từ cấu trúc thật, thay toàn bộ giá trị bằng dữ liệu giả.
- Giữ nguyên tên tag, namespace, thứ tự phần tử, số section.
- Có ít nhất một fixture lớn (≥ 200 dòng) để test phân trang/không cắt dữ liệu.
- File name không chứa MST/tên thật.

### 6.2. Checklist ẩn danh

- [ ] Tên người nộp thuế → `CÔNG TY TNHH MẪU …`
- [ ] MST → `0000000000`
- [ ] Địa chỉ, phường/xã, quận/huyện, tỉnh → `ĐỊA CHỈ MẪU`
- [ ] Số điện thoại, fax, email → `0000000000` / `mau@example.invalid`
- [ ] Số tài khoản, ngân hàng → `000000000`
- [ ] Số hóa đơn, số chứng từ, số hợp đồng → dãy tuần tự
- [ ] Tên hàng hóa/dịch vụ thật → `Hàng hóa mẫu A/B/…`
- [ ] Số tiền → giá trị nhỏ, có case âm và thập phân
- [ ] Chữ ký số / certificate → xóa hoặc thay bằng fixture synthetic riêng
- [ ] Metadata file (tên file, comment) → không chứa dữ liệu thật

### 6.3. Fixture matrix

| Fixture | Mục đích |
|---|---|
| `pl01_khbs-minimal.xml` | 1 dòng/section, kiểm tra nhãn/mã |
| `pl01_khbs-empty-optional.xml` | section rỗng/ẩn |
| `pl01_khbs-negative.xml` | số âm, ngoặc đơn |
| `pl01_khbs-large.xml` | ≥ 200 dòng, phân trang |
| `pl01_1_khbs-minimal.xml` | danh sách hồ sơ/tài liệu |
| `baocaotaichinh-minimal.xml` | bảng BCTC |
| `multi-pluc.xml` | 2–3 phụ lục trong một file |

---

## 7. Phase 5 — Handoff cho macOS

### 7.1. Cây file cần bàn giao

```text
docs/reverse-engineering/
  appendices/
    appendix-inventory.json
    appendix-inventory.md
    <plucID>.json
    <plucID>.md
    fixtures/*.xml
  evidence/appendices/<plucID>/*.png
  evidence/appendices/<plucID>/*.pdf
APPENDIX_HANDOFF.md
```

### 7.2. Nội dung `APPENDIX_HANDOFF.md`

- Tóm tắt inventory và priority.
- Bảng: `plucID | form | version | orientation | số trang | số dòng | trạng thái`.
- Những gì đã capture, những gì `unknown`.
- Danh sách file cần thêm vào repo.
- Đề xuất tích hợp Swift:
  - thêm `Resources/appendix-specs.json`;
  - decode struct `AppendixSpec` tương tự `FormSpec`;
  - thêm `renderSpecAppendix` trong `HTMLRenderer`;
  - giữ fallback `renderRawAppendix` cho ID chưa có spec;
  - test XCTest cho từng fixture.
- Checklist acceptance (mục 10).
- Cảnh báo: không copy XSLT; không commit dữ liệu thật.

### 7.3. Gợi ý test Swift

```swift
func testPL01KHBSLayout() throws {
    let (_, _, rendered) = try render("pl01_khbs-minimal")
    XCTAssertTrue(rendered.html.contains("I. …"))
    XCTAssertTrue(rendered.html.contains("[10]"))
    XCTAssertTrue(rendered.html.contains("(1.000)"))
    XCTAssertFalse(rendered.html.contains("Muc_A/Muc_I/Muc_1/ChiTiet"))
}
```

Test bắt buộc:

- [ ] tiêu đề + căn cứ pháp lý;
- [ ] đủ section theo thứ tự;
- [ ] đủ mã chỉ tiêu;
- [ ] tổng và công thức;
- [ ] số âm/thập phân;
- [ ] section rỗng;
- [ ] ≥ 200 dòng không bị cắt;
- [ ] multi-PLuc;
- [ ] không có raw path cho ID đã có spec.

---

## 8. Quy tắc đọc XSLT của hãng (chỉ tham chiếu)

Được phép:

- mở file XSLT để xác định XPath, thứ tự cột, label, điều kiện `xsl:if`, công thức;
- ghi lại **facts** dưới dạng JSON/Markdown của riêng bạn.

Không được:

- copy nội dung XSLT/CSS vào repo hoặc handoff;
- copy font/ảnh/icon;
- commit JAR hoặc file gốc của hãng;
- dùng nguyên văn template làm “spec”.

Nếu cần trích dẫn để giải thích, chỉ trích **tên phần tử, label, mã chỉ tiêu, công thức** —
đó là dữ liệu nghiệp vụ, không phải tài sản template.

---

## 9. Báo cáo và bằng chứng

Mỗi `plucID` phải có `capture-notes.md` theo mẫu:

```markdown
# PL01_KHBS

- App version: …
- Windows: …
- Ngày capture: …
- File mẫu: sample-001 (synthetic/anonymised)
- Orientation: portrait
- Số trang PDF: 2
- Sections: 3
- Rows: 12
- Unknowns: …
- Screenshots: original-pl01_khbs-p1.png, …
- Ghi chú: …
```

Báo cáo cuối cùng phải trả lời được:

1. Có bao nhiêu `plucID` trong registry?
2. Bao nhiêu ID đã thấy trong corpus?
3. ID nào đã có spec, ID nào còn thiếu?
4. Mỗi ID thiếu đang thiếu thông tin gì (label, cột, công thức, orientation…)?
5. Có ID nào app gốc crash/không render được không?

---

## 10. Acceptance criteria (không được claim khi chưa chạy)

- [ ] Inventory registry đầy đủ, có số lượng và nguồn.
- [ ] Inventory corpus có số file, form code, `plucID`, số bản ghi.
- [ ] Mỗi ID P0/P1 có spec JSON validate được (JSON parse OK).
- [ ] Mỗi spec có ảnh chụp và ít nhất một fixture.
- [ ] Fixture mở được bằng app gốc và clone.
- [ ] Nhãn/mã/công thức khớp ảnh chụp, không có `unknown` bị bỏ qua.
- [ ] Có test cho số âm, thập phân, section rỗng, ≥ 200 dòng.
- [ ] Không có dữ liệu thật trong git (`git diff --cached` đã kiểm tra).
- [ ] Không có file XSLT/CSS/font/ảnh của hãng trong git.
- [ ] `APPENDIX_HANDOFF.md` liệt kê rõ phần đã xong và phần còn lại.
- [ ] Mọi tuyên bố “PASS” đều kèm lệnh/ảnh/ngày thực thi.

---

## 11. Bốn câu hỏi phải hỏi operator trước khi bắt đầu

1. Máy Windows nào, iTax Viewer phiên bản nào, đường dẫn cài đặt?
2. Corpus XML ở đâu, có được copy sang máy test không, có được phép tạo fixture ẩn danh
   từ đó không?
3. Form nào cần ưu tiên cho milestone tiếp theo (`PL01_KHBS`, `BaoCaoTaiChinh`, 05/KK,
   05/QTT, hay 2026 NQ204)?
4. Có chấp nhận bằng chứng là screenshot + PDF export, hay cần thêm bản in giấy scan?

Nếu operator chưa trả lời, chỉ được làm inventory (không chứa dữ liệu giá trị), không được
tự chọn layout.

---

## 12. Mẫu lệnh tham khảo

### 12.1. Liệt kê registry (PowerShell)

```powershell
$reg = "C:\Program Files (x86)\iTax Viewer\data\DMucTKhai.xml"
Select-Xml -Path $reg -XPath "//*[local-name()='PLuc']" |
  ForEach-Object { $_.Node.OuterXml }
```

### 12.2. Quét cấu trúc corpus (PowerShell, không in giá trị)

```powershell
Get-ChildItem -Path "C:\samples" -Recurse -Filter *.xml | ForEach-Object {
  try {
    [xml]$x = Get-Content $_.FullName -Encoding UTF8
    $ids = $x.SelectNodes("//*[local-name()='PLuc']/*") | ForEach-Object { $_.LocalName }
    [pscustomobject]@{
      file = $_.Name
      forms = ($x.SelectNodes("//*[local-name()='maTKhai']") | ForEach-Object { $_.InnerText }) -join ","
      plucs = ($ids -join ";")
    }
  } catch { Write-Warning "$($_.Name): $($_.Exception.Message)" }
} | Export-Csv appendix-usage.csv -NoTypeInformation -Encoding UTF8
```

### 12.3. Mở file bằng app gốc

```powershell
& "C:\Program Files (x86)\iTax Viewer\iTaxViewer.exe" "C:\samples\sample-001.xml"
```

### 12.4. Kiểm tra fixture trước khi commit

```powershell
Select-String -Path ".\fixtures\*.xml" -Pattern "mst|tenNNT|dchiNNT|email|dthoai|soTK"
```

Mọi kết quả khớp phải là dữ liệu giả; nếu không, sửa lại fixture.

---

## 13. Lỗi thường gặp — tránh

1. **Đoán label từ tên tag.** `ct3` không tự động là “Số tiền”; phải đọc ảnh/label chính thức.
2. **Bỏ qua numbering.** `[05]` và `[5]` khác nhau; phải giữ đúng.
3. **Gộp nhiều bảng thành một bảng phẳng.** Làm mất cấu trúc section và tổng.
4. **Không ghi orientation.** Có phụ lục in ngang; sai orientation làm hỏng PDF.
5. **Chỉ chụp trang 1.** Bảng dài có thể có header lặp, tổng ở trang cuối, page-break khác.
6. **Dùng file thật làm fixture.** Dù đã đổi tên, số liệu/tên hàng hóa vẫn có thể nhận dạng.
7. **Copy XSLT vào repo.** Vi phạm quy tắc dự án; chỉ ghi facts.
8. **Không ghi `unknown`.** Làm người implement tưởng đã đủ.
9. **Không test số âm/thập phân.** Formatter Việt Nam dùng ngoặc đơn và dấu phẩy.
10. **Claim “giống 100%” khi chưa so ảnh.** Chỉ ghi “đã so sánh 3 trang đầu” hoặc “pending”.

---

## 14. Định nghĩa hoàn thành

Một lập trình viên macOS có thể:

1. mở `appendix-inventory.json` và chọn một `plucID`;
2. đọc `<plucID>.json` + `<plucID>.md` + ảnh/PDF để hiểu layout;
3. dùng fixture trong `appendices/fixtures/` để viết test;
4. implement renderer mà **không cần mở Windows**;
5. chứng minh parity bằng ảnh/PDF và test xanh.

Khi đạt các điều trên, ghi `DONE` kèm danh sách file và ngày giờ thực thi.
