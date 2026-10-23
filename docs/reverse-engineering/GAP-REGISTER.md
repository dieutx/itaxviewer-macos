# Gap register — hạng mục chưa đủ cơ sở để render, cần tìm sau

Cập nhật 2026-10-23. Mỗi dòng: **thiếu gì**, **vì sao chưa có**, **lấy bằng cách nào**, **ưu tiên**.

Đã lấy được (không còn trong danh sách này): mã + phiên bản + template của 1.917 entry
registry; nhãn/mã chỉ tiêu/cột của 1.035 template; quy tắc định dạng số, đọc tiền, kỳ thuế
(37 hàm JScript); cấu hình in/PDF (A4, lề 20/20/20/10 mm, footer, `enableTableBreaks(false)`);
danh mục 94 class Java; 4.188 tệp bản cài kèm hash.

| # | Thiếu | Vì sao | Cách lấy sau | Ưu tiên |
|---|---|---|---|---|
| 1 | 46 template không trích được dòng nào (23 có mã biểu mẫu) | Không có bảng, hoặc bảng không có tiêu đề `STT`; nhiều mẫu là thư/công văn dạng đoạn văn | Đọc XSLT bằng mắt từng mẫu, hoặc capture ảnh Windows | P0 |
| 2 | Dòng chỉ tiêu nằm **ngoài** `<table>` (04/GTGT: "Tổng doanh thu", "Tổng số thuế") | Pipeline chỉ trích `<tr>` trong bảng có `STT` | Mở rộng extractor quét `div`/`p` có `[NN]` + `xsl:value-of`; đối chiếu với 2 spec 04/GTGT đã viết tay | P0 |
| 3 | **Công thức** (`[27]=[29]+[30]+[32]+[32a]`) | Công thức chỉ nằm trong chuỗi nhãn; Java tính toán nằm trong `TaxViewerUtils`/`sumNumber` | Tách bằng regex từ nhãn + xác nhận bằng `sumNumber` trong `common.xsl`; dựng engine tính và test với số thật | P0 |
| 4 | Điều kiện **ẩn/hiện** dòng theo dữ liệu | Chưa trích `xsl:if/@test` / `xsl:choose` theo từng dòng | Pass riêng: đếm và phân loại điều kiện theo template, đối chiếu ảnh | P1 |
| 5 | **Số trang / ngắt trang** thực tế của từng mẫu | Cấu hình pd4ml đã biết nhưng chưa có PDF tham chiếu | In/PDF từ app gốc trên Windows cho từng mẫu trong bộ fixture; lưu số trang + hash | P0 |
| 6 | **Metric font** Times New Roman/Arial/Courier New của `fonts.jar` | Không được copy font của vendor | macOS: dùng Times New Roman (có trong Microsoft Office) hoặc Liberation Serif; đo lại bề rộng cột, không copy TTF | P1 |
| 7 | Danh sách **chứng thư tin cậy** (76 root + 124 trust) | Không được redistribute | Trích subject/issuer/keyusage thành bảng mô tả; chính sách = trust store hệ điều hành + kinh doanh | P1 |
| 8 | 10 tệp `.rar` backup template | Chưa có unrar/libarchive đọc RAR | Cài unrar/7-Zip (hoặc dùng `libarchive` qua bsdtar bản mới) rồi liệt kê; chỉ dùng để hỗ trợ bản cũ | P2 |
| 9 | 7 XSLT vendor viết sai XML | Lỗi của chính vendor (mismatched tag) | Không sửa; nếu mẫu đó cần hỗ trợ thì dựng layout từ ảnh capture + XSD | P2 |
| 10 | `update/updater.jar` (526.742 B) chưa decompile; `update.zip` (4.032 tệp) chưa diff với bản cài | Ngoài phạm vi lượt này | Decompile `updater.jar` bằng CFR; diff `update.zip` với `data/` để biết file nào đổi giữa các bản | P2 |
| 11 | 157 tệp `.bak` (XSLT/registry bản cũ) | Chỉ chọn version mới nhất khi trích | Chạy pipeline với `--xslt-root` trỏ vào từng thư mục version nếu cần hỗ trợ hồ sơ cũ | P2 |
| 12 | Hải quan (515 dòng) + hóa đơn điện tử + đăng ký thuế: **layout** | Registry đã có, nhưng chưa có spec/ảnh cho từng mẫu | Cùng pipeline cho `data/xslt/TKhaiHQ`, `HDDT`; sau đó capture ảnh | P1 |
| 13 | Chữ ký số: verify thật (C14N + digest + RSA/ECDSA) | `IHTKKXMLSignature` đã decompile nhưng chưa phân tích chi tiết thuật toán/transform | Đọc 989 dòng `IHTKKXMLSignature` + `CertVerifier`, ghi rõ `CanonicalizationMethod`, `Transform`, thứ tự kiểm tra | P1 |
| 14 | Corpus XML thật cho từng họ mẫu | Chỉ có 9 fixture tổng hợp/ẩn danh | Thu thập hồ sơ thật, ẩn danh hoá, lưu ngoài repo (`~/itax-samples/`) | P0 |
| 15 | Ảnh/icon của vendor (`image/`, `infor/homepage`) | Không được copy asset | Giữ icon tự vẽ hiện có; chỉ đối chiếu kích thước/bố cục | P3 |
| 16 | Chạy app gốc để chụp màn hình/PDF | Có JRE bundled + JDK portable nhưng chưa chạy (tránh thay đổi trạng thái cài đặt/registry) | Chạy trong máy ảo hoặc user profile riêng, chụp bằng `PrintWindow`/in PDF | P0 |

## Ghi chú về mức độ "100%"

- Mốc đo vẫn theo [`COVERAGE-REVIEW.md`](COVERAGE-REVIEW.md): 5 trục × 20%. Những gì đã có
  nguồn: **Nhận diện** (bảng root tag + registry), **Nhãn & chỉ tiêu** (15.201 dòng trích),
  **Giá trị** một phần (định dạng số/ngày/kỳ đã có quy tắc).
- Những gì **chưa thể tuyên bố**: **Bố cục** pixel và **In/PDF** số trang (cần mục 5, 6, 16),
  và **chữ ký** (mục 13).
- Không có mục nào trong bảng trên được phép "đoán". Nếu chưa có nguồn, renderer phải hiển thị
  structured view và ghi rõ là chưa đối chiếu.
