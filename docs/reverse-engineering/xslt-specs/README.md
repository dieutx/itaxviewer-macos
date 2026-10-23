# Trích cấu trúc biểu mẫu từ XSLT của iTax Viewer (Windows)

Nguồn: `C:\Program Files (x86)\iTax Viewer\data\xslt` (bản cài 21/10/2026, `itaxviewer.jar`
29/09/2026). Script: [`../tools/extract_xslt_specs.py`](../tools/extract_xslt_specs.py).

Thư mục này là **dữ kiện máy đọc**, không phải bản clone đã hoàn thành. Nó trả lời câu hỏi
"mẫu này có những khối, cột, nhãn và mã chỉ tiêu nào" — không trả lời "app macOS đã render
đúng mẫu đó chưa".

## 1. Cách chạy lại

```bash
python3 docs/reverse-engineering/tools/extract_xslt_specs.py \
  --xslt-root "C:/Program Files (x86)/iTax Viewer/data/xslt" \
  --out docs/reverse-engineering/xslt-specs \
  --verify iTaxViewerMac/Sources/iTaxViewerCore/Resources/form-specs.json
```

- `--verify` so bản trích với 8 spec đã viết tay. Exit code `1` nếu có mục lệch.
- Chỉ dùng thư viện chuẩn Python; không cần JDK, không cần mạng.
- Không ghi gì vào `Program Files`; chỉ đọc.

## 2. Đầu ra

| File | Nội dung |
|---|---|
| `xslt-specs.json` | Một entry cho mỗi template (đã khử trùng lặp giữa các thư mục `XSLT x.y.z`), gồm SHA-256 nguồn, `displayCodes`, `title`, `columns`, `layout`, `rows[]` |
| `xslt-specs-index.csv` | Bảng phẳng để review: mã, template, version, số cột, số dòng, số chỉ tiêu, số khối |
| `xslt-specs-summary.json` | Tổng hợp số liệu của lần chạy |

Mỗi dòng (`rows[]`) có: `stt`, `label`, `indicator`, `codes`, `values[{root,path}]`, `kind`
và `sourceOrder`. Trường ngoài bảng được đánh `origin=outside-table`; thứ tự theo tài liệu.
`--verify` dùng đúng `sourceEvidence.path` và SHA-256 của spec khi có, không lấy nhầm
template cùng tên ở version mới hơn. Kiểm này đo nhãn/chỉ tiêu/cột, không chứng minh visual parity.

## 3. Số liệu lần chạy 2026-10-23

- 1.035 template đã khử trùng lặp, từ **2.163 tệp `*.xslt`** trong 103 thư mục — phần lớn
  là bản sao theo version `XSLT 2.0.6` … `XSLT 3.0.9` (thư mục cha còn 783 tệp include
  `*.xsl`, không phải biểu mẫu, nên không tính).
- 774 template khai báo mã biểu mẫu qua `xsl:with-param name="mauTKhai"` → **447 mã** khác nhau.
- Lượt sau sửa extractor: **15.469 dòng / 3.448 chỉ tiêu**, gồm 2.374 khối tiêu đề,
  12.305 dòng dữ liệu, 786 dòng danh sách và bốn checkbox theo heuristic. Có **253 trường
  ngoài bảng**; nhận diện được đường dẫn nằm trong `formatNumber(...)`. Baseline trước sửa
  là 15.201 dòng / 2.786 chỉ tiêu. Các phân loại heuristic chưa thay thế spec đã review.
- **46 template không trích được dòng nào** (23 trong số đó có mã biểu mẫu): mẫu không có
  bảng, hoặc bảng không có tiêu đề `STT` — xem gap register.
- **7 template không parse được** vì chính vendor viết sai XML (mismatched tag):
  `lenhhoan_in.xslt`, `pluc_06_1_bk_tncn.xslt`, `tkhai_02_xd_pntt - copy.xslt`,
  `tkhai_02_xd_pntt_cu.xslt`, `tkhai_02pthu_vsp.xslt`, `tkhai_30_dk_th_tct_tt86.xslt`,
  `tkhai_bk01_ac.xslt`. Đây là lỗi của bản gốc; ghi lại để không ai tưởng là thiếu sót của
  pipeline.

## 4. Kiểm chứng với spec viết tay

`--verify` so từng dòng của 8 entry trong `form-specs.json` với bản trích:

| Mẫu | Kết quả |
|---|---|
| 01/GTGT (`TKhai_GTGT_01_TT80`) | khớp 27/27 dòng, cột và chỉ tiêu |
| 05/KK-TNCN (`TKhai_05KK_TNCN`) | khớp 16/16 (chỉ khác STT do spec tay chép nhãn vào cột STT) |
| 05/QTT-TNCN (`TKhai_05QTT_TNCN_TT80`) | khớp 26/26 |
| 05/KK-TNCN TT80 (`TKhai_05_KK_TNCN_TT80`) | khớp 18/18 |
| 05/QTT-TNCN cũ (`TKhai_05QTT_TNCN`) | khớp 26/26 |
| 03/TNDN (`TKhai_TNDN_03_TT80`) | khớp 74 dòng; bản trích **thừa 1 dòng** hợp lệ ("Loại thu nhập miễn thuế") và **nhiều hơn** 3 mã (`C3a`, `C3b`, `C8a` từng để trống) |
| 04/GTGT TT80 | khớp sau khi bổ sung trường ngoài bảng và ghim đúng template/hash |
| 04/GTGT (cũ) | khớp sau khi bổ sung trường ngoài bảng và giữ nguyên dấu câu của nguồn được chọn |

Cách đo: mọi dòng của spec phải xuất hiện **đúng thứ tự** trong bản trích (so theo nhãn); nếu
spec có mã chỉ tiêu thì bản trích phải trùng mã. Bản trích được phép **thừa** dòng/mã vì nó là
nguồn gốc đầy đủ hơn — số dòng thừa được in ra để review.

Kết quả đã chạy sau đợt thêm mẫu TT89/BCTC: **14/14 khớp**. Bộ trích nhận mã số
dạng số ở đúng cột mã (giữ `01`, không đổi thành `1`); năm hồi quy chuẩn thư viện
được chạy trong CI. Đây là kiểm tra nhãn, mã, cột và thứ tự, không phải kiểm tra bố cục
hoặc điều kiện động.

## 5. Giới hạn (đọc trước khi dùng để tuyên bố "clone")

1. **Trích xuất vẫn có giới hạn.** Ngoài bảng có tiêu đề `STT`, công cụ đã lấy trường
   chỉ tiêu có nhãn trong `div`/`p` và ghi `origin: outside-table`. Những cấu trúc khác
   vẫn cần đối chiếu thủ công; không được tự động xem toàn bộ 1.035 template là đã hỗ trợ.
2. **Không trích công thức.** Chuỗi `([27]=[29]+[30]+…)` chỉ nằm trong nhãn, không được tách
   thành biểu thức có thể tính.
3. **Không trích điều kiện hiện/ẩn** (`xsl:if` theo giá trị), chỉ ghi nhận dòng có nhánh
   rẽ → `kind = checkbox`.
4. **Không trích CSS.** Bố cục thật còn phụ thuộc `data/css/ihtkk.css` (và `ihtkk_ntdt.css`
   cho chứng từ). Repo không copy hai file này.
5. **Không thay thế capture Windows.** Muốn đạt mốc 90–100% theo
   [`../COVERAGE-REVIEW.md`](../COVERAGE-REVIEW.md) vẫn cần đối chiếu ảnh/PDF từ app gốc chạy
   trên Windows (máy này không có JDK trong PATH cho tới khi dùng `_re/tools/jdk`, xem
   [`../java/README.md`](../java/README.md)).
6. **App chỉ dùng spec đã review.** `scripts/import_static_specs.py` nhập các spec chọn lọc
   có đường dẫn nguồn, SHA-256 và phiên bản cụ thể. Bản trích hàng loạt này không tự động
   trở thành bố cục trong app. Swift và WebKit/PDFKit được chạy trên macOS GitHub Actions.
