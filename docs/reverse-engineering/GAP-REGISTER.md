# Gap register — hạng mục chưa đủ cơ sở để render, cần tìm sau

Cập nhật 2026-10-23. Mỗi dòng: **thiếu gì**, **vì sao chưa có**, **lấy bằng cách nào**, **ưu tiên**.

Đã lấy được (không còn trong danh sách này): mã + phiên bản + template của 1.917 entry
registry; nhãn/mã chỉ tiêu/cột của 1.035 template; quy tắc định dạng số, đọc tiền, kỳ thuế
(37 hàm JScript); cấu hình in/PDF (A4, lề 20/20/20/10 mm, footer, `enableTableBreaks(false)`);
danh mục 94 class Java; 4.188 tệp bản cài kèm hash.

Bổ sung 2026-10-23 (sau khi kiểm chứng lại bằng công cụ mới):

- **Engine render là MSXML/IE**, không phải Java: `data/run.html` → `ActiveXObject("Microsoft.XMLDOM")`
  → `transformNode`, rồi một pass jQuery `.number` sửa lại text số. Đã dựng lại được bằng
  `tools/msxml_oracle.js` (xem mục 16).
- **Registry → tệp thật**: 1.920 tham chiếu `XSLT` (thiếu 13), 2.184 `PLucXSLT` (thiếu 18),
  1.015 `XMLSchema` (**thiếu 1.006**) — số liệu tái lập bằng `tools/resolve_registry_refs.py`,
  kết quả ở `evidence/registry-refs.json`.
- **RAR đã mở** (7-Zip 26.05): 145 tệp, 10 tệp duy nhất — xem mục 8.

| # | Thiếu | Vì sao | Cách lấy sau | Ưu tiên |
|---|---|---|---|---|
| 1 | 46 template không trích được dòng nào (23 có mã biểu mẫu) | Không có bảng, hoặc bảng không có tiêu đề `STT`; nhiều mẫu là thư/công văn dạng đoạn văn | Đọc XSLT bằng mắt từng mẫu, hoặc capture ảnh Windows | P0 |
| 2 | Dòng chỉ tiêu nằm **ngoài** `<table>` | **Đã sửa cho 04/GTGT**: spec/renderer giữ tổng `[32]/[33]` của 07 và `[32]` của 847 ngoài bảng; oracle đúng registry xác nhận đủ 13/13 và 12/12 giá trị. Extractor tổng quát vẫn chưa bao phủ mọi template | Các template khác vẫn cần pass riêng; xem `results/gap-build-2026-10-23.md` | P0, một phần đã sửa |
| 3 | **Công thức** (`[27]=[29]+[30]+[32]+[32a]`) | Công thức chỉ nằm trong chuỗi nhãn; Java tính toán nằm trong `TaxViewerUtils`/`sumNumber` | Tách bằng regex từ nhãn + xác nhận bằng `sumNumber` trong `common.xsl`; dựng engine tính và test với số thật | P0 |
| 4 | Điều kiện **ẩn/hiện** dòng theo dữ liệu | Chưa trích `xsl:if/@test` / `xsl:choose` theo từng dòng | Pass riêng: đếm và phân loại điều kiện theo template, đối chiếu ảnh | P1 |
| 5 | **Số trang / ngắt trang** thực tế của từng mẫu | Cấu hình pd4ml đã biết nhưng chưa có PDF tham chiếu | In/PDF từ app gốc trên Windows cho từng mẫu trong bộ fixture; lưu số trang + hash | P0 |
| 6 | **Metric font** Times New Roman/Arial/Courier New của `fonts.jar` | Không được copy font của vendor | macOS: dùng Times New Roman (có trong Microsoft Office) hoặc Liberation Serif; đo lại bề rộng cột, không copy TTF | P1 |
| 7 | Danh sách **chứng thư tin cậy** (76 root + 124 trust) | Không được redistribute | Trích subject/issuer/keyusage thành bảng mô tả; chính sách = trust store hệ điều hành + kinh doanh | P1 |
| 8 | ~~10 tệp `.rar` backup template~~ **ĐÃ ĐÓNG 2026-10-23** | — | 7-Zip 26.05 đọc được RAR/RAR5: 10 tệp → 145 tệp ở `_re/rar/`. 135 là XSLT/XSL; **125 tệp trùng nội dung với đĩa, 10 tệp là duy nhất**, trong đó `TKhai_01_CNKD_TT40.xslt` và `PLuc_04_1_DK_TCT_BK01.xslt` mới hơn mọi bản trên đĩa. RAR `XSLT 2.8.4/TKhaiThue/xslt.rar` có 120 tệp so với 53 tệp trong thư mục cùng tên → RAR là cây **đầy đủ**, thư mục version chỉ là **lớp thay đổi**. Việc còn lại: hợp nhất lớp (mục 11) | Đã xong |
| 9 | 7 XSLT vendor viết sai XML | Lỗi của chính vendor (mismatched tag) | Không sửa; nếu mẫu đó cần hỗ trợ thì dựng layout từ ảnh capture + XSD | P2 |
| 10 | `update/updater.jar` (526.742 B) chưa decompile; `update.zip` (4.032 tệp) chưa diff với bản cài | Ngoài phạm vi lượt này | Decompile `updater.jar` bằng CFR; diff `update.zip` với `data/` để biết file nào đổi giữa các bản | P2 |
| 11 | 157 tệp `.bak` (XSLT/registry bản cũ) | Chỉ chọn version mới nhất khi trích | Chạy pipeline với `--xslt-root` trỏ vào từng thư mục version nếu cần hỗ trợ hồ sơ cũ | P2 |
| 12 | Hải quan (515 dòng) + hóa đơn điện tử + đăng ký thuế: **layout** | Registry đã có, nhưng chưa có spec/ảnh cho từng mẫu | Cùng pipeline cho `data/xslt/TKhaiHQ`, `HDDT`; sau đó capture ảnh | P1 |
| 13 | Chữ ký số: verify thật (C14N + digest + RSA/ECDSA) | `IHTKKXMLSignature` đã decompile nhưng chưa phân tích chi tiết thuật toán/transform | Đọc 989 dòng `IHTKKXMLSignature` + `CertVerifier`, ghi rõ `CanonicalizationMethod`, `Transform`, thứ tự kiểm tra | P1 |
| 14 | Corpus XML thật cho từng họ mẫu | Chỉ có 9 fixture tổng hợp/ẩn danh | Thu thập hồ sơ thật, ẩn danh hoá, lưu ngoài repo (`~/itax-samples/`) | P0 |
| 15 | Ảnh/icon của vendor (`image/`, `infor/homepage`) | Không được copy asset | Giữ icon tự vẽ hiện có; chỉ đối chiếu kích thước/bố cục | P3 |
| 16 | Chạy app gốc để chụp màn hình/PDF | Có JRE bundled + JDK portable nhưng chưa chạy GUI (tránh thay đổi trạng thái cài đặt/registry) | **Một nửa đã giải**: `tools/msxml_oracle.js` render đúng engine app (MSXML 3.0) ra HTML gốc, không cần GUI — đã chạy, tái lập byte-identical. Phần ảnh màn hình thật vẫn cần VM + `PrintWindow` | P1 |
| 17 | **Bản cài không có XSD khai báo** | `data/XMLSchema` không tồn tại; cả bản cài chỉ có 9 `.xsd` (đều là schema của registry) và `update.zip` chỉ có 2. Registry vẫn tham chiếu 1.015 XSD, trong đó 1.006 không resolve được (186 đường dẫn) | Quyết định: renderer macOS **không validate**, hoặc lấy XSD từ nguồn khác và ghi rõ nguồn. Không được coi "có XSD" là điều kiện render | P0 |
| 18 | ~~Fixture 864 không đúng schema~~ **ĐÃ ĐÍNH CHÍNH 2026-10-23** | Đã chọn nhầm template khi lập nhận xét: registry `864/2.9.3` trỏ tới `XSLT 2.9.3/.../TKhai_05_KK_TNCN_TT80.xslt`, đọc ct16–32/ct25_1 phẳng. MSXML với đúng template render đủ **13/13 số tiền tổng hợp khác nhau**, có `[25.1]` | Giữ fixture đúng và các assertion; không sửa sang nhánh của template khác. Bằng chứng hash/count trong `evidence/oracle-batch-2026-10-23.json`; ảnh/PDF Windows vẫn pending | Đã xác minh đường dẫn/giá trị, chưa xác minh hình ảnh |
| 19 | **37 hàm JScript phụ thuộc DOM của IE** | `common.xsl` dùng `node.nextNode()`, không có trong MSXML thuần/Java XSLTC. Gọi `ihtkk:formatNumber('123')` bằng chuỗi → `Object doesn't support this property or method` | Phải **port sang Swift** theo đúng logic JScript (đã trích trong `render-semantics/functions.json`), không thể chạy XSLT bằng libxslt rồi coi là tương đương | P0 |
| 20 | **Bước hậu xử lý `.number` sau transform** | Đã sửa port Swift: tách phần lẻ **trước** bước làm tròn phần nguyên, tránh `1234.999` bị đổi thành `1.235,999`; thêm assertion dương/âm. Renderer Swift định dạng giá trị trước khi tạo HTML, không chạy JS | Oracle vẫn là kết quả trước postprocess; chưa thể tuyên bố toàn bộ 1.035 template tương đương. Các điều kiện/format riêng khác còn phải đối chiếu | Một phần đã sửa |

## Ghi chú về mức độ "100%"

- Mốc đo vẫn theo [`COVERAGE-REVIEW.md`](COVERAGE-REVIEW.md): 5 trục × 20%. Những gì đã có
  nguồn: **Nhận diện** (bảng root tag + registry), **Nhãn & chỉ tiêu** (15.201 dòng trích),
  **Giá trị** một phần (định dạng số/ngày/kỳ đã có quy tắc).
- Những gì **chưa thể tuyên bố**: **Bố cục** pixel và **In/PDF** số trang (cần mục 5, 6),
  và **chữ ký** (mục 13). Riêng HTML gốc thì **đã có** nguồn (mục 16) — từ nay không được
  nói "chưa có tham chiếu" cho bước so nhãn/giá trị, chỉ chưa có cho bước so ảnh/PDF.
- Không có mục nào trong bảng trên được phép "đoán". Nếu chưa có nguồn, renderer phải hiển thị
  structured view và ghi rõ là chưa đối chiếu.
