# Công cụ để mở rộng — cần cài gì, để làm gì, thay cho gap nào

Cập nhật 2026-10-23. Tài liệu này trả lời: **với 16 gap còn lại, cần thêm công cụ gì thì
mới làm tiếp được**, cái nào đã có sẵn trên máy, cái nào phải viết, và cái nào **không nên**
dùng. Prompt giao việc cho agent kế tiếp nằm ở
[`NEXT-AGENT-PROMPT.md`](NEXT-AGENT-PROMPT.md).

## 0. Trạng thái máy đang dùng (Windows 11, đã kiểm tra)

| Có sẵn | Phiên bản / đường dẫn | Dùng cho |
|---|---|---|
| 7-Zip | 26.05 x64 — `C:/Program Files/7-Zip/7z.exe` | **Đọc được RAR5** → đã đóng gap #8, không cần `unrar` |
| Python | Python 3.12 qua `py -X utf8` | Công cụ chuẩn thư viện; lượt hiện tại không có `Pillow`/`pypdf` trong interpreter này |
| Windows Script Host | `cscript` + MSXML 3.0/6.0 | **Oracle render** (`tools/msxml_oracle.js`) — engine đúng như app gốc |
| JDK | `_re/tools/jdk/bin/java.exe` (17) | Chạy `updater.jar`, CFR, thử pd4ml |
| JRE của app | `iTax Viewer/jre` = 1.8.0_112 32-bit | Chạy app gốc nếu cần capture |
| Node.js | 20 (kèm npm) | Port `data/js` + bước `.number`, headless print |
| `pdftotext` | `/ucrt64/bin/pdftotext` | Bóc chữ từ PDF tham chiếu |
| `gh`, `git` | có | CI macOS, commit |

Thiếu (xem mục 2): `pdftoppm`, `mutool`, `fonttools`, `pypdf`, `pytest`, `jq`, `swift`
(không có Xcode trên Windows — `swift test` chỉ chạy được trên GitHub Actions).

## 1. Công cụ đã triển khai

### 1.1 Oracle render — ĐÃ XONG

`tools/msxml_oracle.js` chạy XSLT của bản cài bằng đúng engine app dùng:

```bash
cscript //nologo docs/reverse-engineering/tools/msxml_oracle.js \
  "C:/samples/01GTGT.xml" \
  "C:/Program Files (x86)/iTax Viewer/data/xslt/TKhaiThue/xslt/GTGT/TKhai_GTGT_01_TT80.xslt" \
  "_re/oracle/01GTGT.html"
```

Đã đính chính 2026-10-23: probe 9.353 ký tự ban đầu dùng template TNCN khác. Registry
864/2.9.3 chọn `TKhai_05_KK_TNCN_TT80.xslt`; oracle đúng cho 7.970 ký tự UTF-16,
127 ô và đủ 13/13 số tiền. HTML oracle hỗ trợ so nội dung; nó không thay thế ảnh/PDF Windows.

Điều học được ngay từ oracle (quan trọng cho bản clone):

- App render bằng **MSXML/IE** (`data/run.html` → `ActiveXObject("Microsoft.XMLDOM")` →
  `transformNode`), **không phải Java XSLTC**. Vì vậy `msxsl:script` (37 hàm JScript) chỉ chạy
  trong ngữ cảnh này; port sang Swift bắt buộc, không thể "chạy XSLT bằng libxslt".
- Các hàm đó dùng `node.nextNode()` của DOM IE. Gọi `ihtkk:formatNumber('123')` bằng chuỗi sẽ
  lỗi `Object doesn't support this property or method` — chỉ gọi được với node-set.
- Sau transform, `run.html` còn một **bước thứ hai**: `$('.number').each(...)` chạy
  `formatNumber` trên text của mọi phần tử `class="number"`. Oracle trả HTML **trước** bước này;
  muốn ra HTML cuối cùng phải port thêm bước đó.

### 1.2 `oracle_batch` — đã có

Đã có `tools/oracle_batch.py`, chọn template theo mã/version registry và ghi
`_re/oracle/batch/index.json`. Baseline 21 fixture: 18 transform được, một voucher tối giản
lỗi transform, một notice cũ không có registry match, một XXE bị từ chối. Không che exit 1
của lượt còn lỗi. Kết quả public chỉ có hash/count/status; HTML vendor luôn ở `_re/`.
Đây là baseline nội dung cho regression; không phải bộ ảnh chuẩn hoặc bằng chứng bố cục.
Tiêu chí: chạy hết fixture hiện có trong `iTaxViewerMac/Tests/iTaxViewerCoreTests/Fixtures/`
+ mọi fixture thật thu được, 0 lỗi `TRANSFORM FAIL` không giải thích.

### 1.3 `html_diff` — đã có, so HTML theo ô

`tools/html_diff.py` so text `<td>`/`<th>` sau chuẩn hoá whitespace, báo vị trí và số lượng
ô khác mà không in dữ liệu người nộp thuế. Self-diff 864: 127 ô, không khác. Đó là kiểm tra
công cụ, chưa phải bằng chứng Windows/macOS khớp. Visual và PDF parity phải đo riêng.

## 2. Cài thêm — mỗi mục một gap

| Cài | Lệnh | Mở ra gap nào |
|---|---|---|
| `pdftoppm` (Poppler bản đủ) | `choco install poppler` hoặc `scoop install poppler` | #5/#16: PDF tham chiếu → PNG, đếm trang, so pixel |
| `mutool` (MuPDF) | `choco install mupdf` | #5: render/đếm trang PDF **không cần Adobe**, nhanh hơn Poppler khi batch |
| `fonttools` | `pip install fonttools` | #6: đọc `hmtx`/`OS2` từ `itaxviewer_lib/fonts.jar` để lấy **metric** Times/Arial — hợp pháp, không copy TTF |
| `pypdf` | `pip install pypdf` | #5: đếm trang, so `/MediaBox` (kiểm A4 595×842 pt), tách text layer |
| `pytest` | tuỳ chọn | Bộ trích xuất đã có năm hồi quy `unittest` chuẩn thư viện và được thêm vào CI; không cần pytest cho bước này |
| `jq` | `choco install jq` | Soi nhanh `evidence/*.json`, `functions.json` khi review |
| `swift` + Xcode | **không cài trên Windows** — dùng `gh workflow run` | Chạy `swift test`/`swift build` trên runner macOS |

Không cần / không nên:

- `unrar`: 7-Zip 26.05 đã mở cả RAR5. Cài thêm chỉ để làm script phụ thuộc thêm một binary.
- `libxslt`/`xsltproc`/`lxml.XSLT` làm oracle: chúng **không** có `msxsl:script`, sẽ ra HTML
  rỗng ở mọi ô số → dễ kết luận sai là "mẫu không có dữ liệu". Chỉ dùng để smoke-test cú pháp.
- Font của vendor (`fonts.jar`) copy ra: vi phạm redistribute. Chỉ đọc metric.
- Adobe Acrobat để in PDF: `mutool`/`pdftoppm` đủ, không cần license.

## 3. Bảng: gap → công cụ → lệnh cụ thể

| Gap (theo `GAP-REGISTER.md`) | Công cụ | Việc phải chạy |
|---|---|---|
| #1 46 template 0 dòng | `msxml_oracle.js` + `html_diff` | Render oracle với XML thật, xem HTML có bảng/đoạn văn; phân loại thư–công văn |
| #2 chỉ tiêu ngoài `<table>` | `tools/extract_xslt_specs.py` đã sửa | Đã trích 253 trường ngoài bảng; đối chiếu 14 spec hiện tại đạt 14/14 |
| #3 công thức | script mới `formula_extract.py` + `common.xsl` | Regex `\[(\d+)\]\s*=\s*([^;\n]+)` trên nhãn → JSON đồ thị; test bằng `sumNumber` |
| #4 ẩn/hiện dòng | script mới `visibility_extract.py` | Trích `xsl:if/@test`, `xsl:choose` theo từng `<tr>` → JSON; xác nhận bằng oracle với 2 bộ dữ liệu khác nhau |
| #5 số trang / A4 | `mutool` + `pypdf` (+ pd4ml nếu dựng harness Java) | In PDF từ app gốc hoặc dựng lại pd4ml; `mutool info` đếm trang, `pypdf` xem MediaBox |
| #6 metric font | `fonttools` | `python -m fontTools.ttx`/API đọc `hmtx` từ `fonts.jar`, ghi bảng độ rộng ký tự |
| #7 chứng thư | `cscript` + `certutil` | `certutil -store Root` xuất subject/issuer/thumbprint thành CSV mô tả (không kèm khóa) |
| #8 RAR | **đã xong bằng 7-Zip** | Xem `GAP-REGISTER.md` mục 8 |
| #9 7 XSLT hỏng | oracle | Chạy oracle để xác nhận lỗi parse của vendor; không sửa file vendor |
| #10 updater.jar | JDK + CFR (đã có `_re/tools/decompiler`) | `java -jar cfr.jar updater.jar --outputdir _re/decompiled-updater` |
| #11 .bak / layer version | script mới `merge_version_layers.py` | Ghép version dir + RAR thành cây đầy đủ cho từng `pbanTKhai` |
| #12 Hải quan/HĐĐT/Đăng ký | `extract_xslt_specs.py` với `--xslt-root` khác | Chạy cho `data/xslt/TKhaiHQ`, `HDDT`, `DangKyThue` |
| #13 chữ ký | JDK + `bcprov-jdk16-146.jar` | Harness Java verify C14N+digest bằng chính bcprov của app |
| #14 corpus thật | — | Thu thập hồ sơ thật, ẩn danh, lưu ngoài repo `~/itax-samples/` |
| #15 asset/icon | — | Không cần công cụ, chỉ đối chiếu kích thước |
| #16 chạy app gốc | `cscript` (đã đủ) + `PrintWindow` nếu cần GUI | Ưu tiên oracle; chỉ chụp GUI khi cần ảnh màn hình thật |

## 4. Thứ tự làm đề nghị

1. `oracle_batch` + `html_diff` (mục 1.1–1.3) — mọi việc sau đó đều cần thước đo này.
2. `formula_extract.py` (#3) + `visibility_extract.py` (#4) — hai pass còn thiếu của pipeline.
3. Mở rộng hồi quy chuẩn thư viện và `--verify` cho các họ mẫu mới; không xem mọi bản trích là bố cục app.
4. `mutool`/`pypdf` (#5) và `fonttools` (#6) — chỉ khi đã có PDF tham chiếu.
5. `merge_version_layers.py` (#11) cho hồ sơ cũ; `updater.jar` (#10) sau cùng.
