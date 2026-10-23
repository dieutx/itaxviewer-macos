# Hợp đồng render lấy từ bản Windows (số liệu máy đọc)

Mục tiêu: khi renderer Swift phải "giống 100%", mọi quy tắc dưới đây là **nguồn**, không phải
suy đoán. Nguồn: `data/*.html`, `data/js/common.js`, `<msxsl:script>` trong `data/xslt/**`,
`data/css/ihtkk.css`, và `TKhaiConverter` (decompile, xem [`../java/README.md`](../java/README.md)).

Katalog hàm JScript: [`functions.json`](functions.json) (37 hàm) + `functions-summary.json`.
Nội dung JS đầy đủ **không** nằm trong repo: `_re/js-functions/*.js` (gitignored).

## 1. Trang host và khung nhìn

`data/itax.html` (host của cửa sổ xem):

- Nền ngoài `rgb(86,86,86)`; khối trắng bên trong `padding: 40px`, `width: 100%`,
  `font-family: Tahoma`, `font-size: 9pt`, `align: center`.
- Nội dung render đổ vào `<div id="tkhai" align="left">`; khối chữ ký là
  `<div id="signature">`.
- Trang nạp `css/ihtkk.css` + `css/ihtkk_ntdt.css` và `js/common.js`, `js/jquery.min.js`.

Điều này nghĩa là renderer macOS phải có **khung 40 px + Tahoma 9pt bao ngoài** nếu muốn khớp
ảnh chụp; bảng biểu bên trong mới dùng Times New Roman 12pt (mục 5).

## 2. Pipeline biến đổi

`HSoThueViewer` gọi `fileBrowser.evaluate("return transform(xmlUrl, xsltUrl)")`; host dùng
XSLT 1.0 (`Microsoft.XMLDOM` + `transformNode` trên MSHTML, `XSLTProcessor` cho trình duyệt
khác — `data/itax.html`).

- Nhiều phần (tờ khai + phụ lục) được render **nối tiếp** vào cùng một chuỗi HTML.
- Giữa hai phần, host chèn `<p style='page-break-before: always' /><br/>`; **không** chèn sau
  phần cuối (`if(last != 1)`).
- Sau khi chèn HTML, jQuery chạy khi DOM ready: mọi phần tử `.number` được thay bằng
  `formatNumber(text)` (`$(document).ready(... .number ...)`).

### 2.1 Dựng lại được ngay trên Windows — `tools/msxml_oracle.js`

Không cần GUI: `cscript //nologo docs/reverse-engineering/tools/msxml_oracle.js <ho-so.xml>
<mau.xslt> <ra.html>` chạy đúng MSXML 3.0 + `XSLTemplate` như `data/run.html`. Đã kiểm chứng
2026-10-23. Lượt probe 9.353 ký tự ban đầu dùng template TNCN khác, không chứng minh
mapping 864. Batch đúng registry ở `evidence/oracle-batch-2026-10-23.json` xác nhận
864/2.9.3 có 7.970 ký tự, 127 ô và đủ 13 số tiền tổng hợp khác nhau.

Ba giới hạn phải nhớ khi dùng oracle:

1. `xsl:include` resolve theo đường dẫn tương đối của mẫu → phải trỏ vào **cây XSLT của bản cài**,
   không copy lẻ từng tệp.
2. `<msxsl:script>` chạy được, nhưng các hàm dùng `node.nextNode()` (DOM của IE). Gọi
   `ihtkk:formatNumber('123')` bằng chuỗi → `Object doesn't support this property or method`;
   chỉ gọi được với node-set. Đây là lý do phải **port** các hàm sang Swift, không thể thay
   bằng libxslt.
3. Oracle trả HTML **trước** bước `.number`; muốn HTML cuối cùng phải port `formatNumber` từ
   `data/js/common.js` rồi áp lên phần tử `class="number"`.

## 3. Định dạng số — quy tắc chính xác

Hai bản copy cùng một thuật toán: `data/js/common.js` (chạy sau render) và JScript
`formatNumber` trong `<msxsl:script>` của `common.xsl` (chạy trong lúc transform).
Ba biến thể `formatNumber` tồn tại trong các version XSLT (xem `functions.json`).

Thuật toán (theo mã):

1. Chuỗi rỗng/`null` → trả chuỗi rỗng.
2. Nếu bắt đầu bằng `-` → bỏ dấu, ghi nhớ để bọc ngoặc đơn.
3. Nếu có dấu `.` (thập phân kiểu máy): phần lẻ tách ra, phần nguyên lấy trước dấu.
4. Làm tròn 2 chữ số: `Math.floor(x*100 + 0.50000000001) / 100` → **làm tròn nửa lên**,
   không phải banker's rounding.
5. Nhóm nghìn bằng dấu `.` mỗi 3 chữ số.
6. Ghép lại: `phần nguyên + ',' + phần lẻ` → **dấu phẩy là dấu thập phân**.
7. Số âm → bọc trong ngoặc đơn, ví dụ `(1.234,50)`.
8. Mọi lỗi trong `try` bị nuốt, trả chuỗi rỗng.

Hệ quả cần test ở bản macOS: `-0.005` → `(0,01)`? (làm tròn nửa lên sau khi bỏ dấu),
`1234.5` → `1.234,50`, `0` → `0`, `''` → `''`.

## 4. Đọc số thành chữ và kỳ tính thuế

Các hàm JScript trong XSLT (đều là hàm của vendor, không phải chuẩn):

| Nhóm | Hàm | Ghi chú |
|---|---|---|
| Đọc tiền | `DocSo3ChuSo`, `DocTienBangChu`, `docso`, `dochangchuc`, `dochangtrieu` | "Số tiền bằng chữ" trên chứng từ; có 3 biến thể `DocTienBangChu` |
| Đọc tiền tiếng Anh | `toEnglishCash`, `toEnglishCashUSD` | chứng từ song ngữ |
| Kỳ | `kyTinhThue`, `kyTinhThueTruMot`, `kyTinhThue_hddt`, `convertKyBaoCao`, `getKHBM` | chuỗi "Năm X" / "Từ ngày … đến ngày …", kỳ trước một kỳ |
| Ngày giờ | `stringDatetime`, `stringDatetimeTEM`, `timeToString`, `getMonthFromString` | 7 biến thể `stringDatetime` |
| Số/tiền khác | `formatNumberUSD`, `formatNumberUSD1`, `toFormatDecimal`, `toFormatDecimal1`, `toFormatDecimall`, `sumNumber` | USD dùng dấu khác; `sumNumber` cộng trong XSLT |
| Nhãn động | `getTenCT` (13 biến thể), `getTenNganCT`, `getTenUpperCT`, `getTenPLP`, `getTenBVMT`, `getTenGhiChuBC26`, `getTTThayDoi`, `getTenTN` | tên chứng từ/phụ lục theo mã, có bảng tra riêng |
| Địa danh | `getTinh`, `getHuyen` | tỉnh/huyện từ mã |
| Khác | `formatVar`, `getMaCTcapTren`, `breakWord`, `docblock` | |

`functions.json` ghi `name`, `signature`, `arity`, và từng **biến thể** kèm danh sách version
XSLT dùng biến thể đó — cần biến thể nào thì lấy đúng file trong `_re/js-functions/<hash>.js`.

## 5. CSS (số liệu đo, không copy tệp)

`data/css/ihtkk.css` (4.884 byte, sửa 27/09/2025):

- `body`/bảng: `font-family: "Times New Roman", "Arial", "Courier New"`, `font-size: 12pt`.
- Đường kẻ bảng `border-width: 1px`; một số khối `margin-bottom: 10px`.
- Bảng phụ: `page-break-inside: avoid` (ví dụ khối chữ ký), `width: 100%`.
- Không có `@page` → khổ giấy và lề **không** do CSS quyết định mà do pd4ml (mục 6).
- Ký hiệu thụt dòng bằng `#tab50` (50pt), `#tab100` (100pt); đường kẻ tay `table_hr1/2/3`.

## 6. In/PDF — `TKhaiConverter.convertToHSoPDF` (decompile)

Đây là nguồn chính xác cho số trang/lề:

| Tham số | Giá trị |
|---|---|
| Khổ | `PD4ML.A4` |
| Lề | top **20**, left **20**, right **20**, bottom **10** (mm) |
| `htmlWidth` | **892** (portrait) / **1262** (landscape); nếu bề rộng thực lớn hơn → `realWidth + 40` |
| Font | `useTTF("java:fonts", true)`; mặc định `Times New Roman`, `Arial`, `Courier New` |
| AcroForm | `generatePdfForms(true, "Times New Roman")` |
| Ngắt bảng | `enableTableBreaks(false)` — **không** cắt bảng qua trang |
| Ngắt ảnh | `enableImgSplit(false)` |
| Footer | mẫu `$[page]/$[total]`, số trang canh phải (`alignment = 1`), tiêu đề canh trái (`0`), Times New Roman 12, `areaHeight = 20`, bắt đầu từ trang 1 |
| Vỏ HTML | `<html><head><meta http-equiv=Content-Type content="text/html; charset=utf-8"></head><body style="margin:0; align:center">` |

Phụ lục được gộp bằng `mergePDF` (PDFBox `PDFMergerUtility`) sau khi render từng phần.

## 7. Còn thiếu gì để "100%"

Xem [`../GAP-REGISTER.md`](../GAP-REGISTER.md). Tóm tắt: chưa có **PDF thật của từng mẫu** để
đối chiếu số trang; chưa có metric font TTF của `fonts.jar` (không được copy); vài dòng chỉ
tiêu nằm ngoài bảng XSLT.

Đã đóng trong lượt 2026-10-23: HTML gốc thì **đã có nguồn** (oracle MSXML, mục 2.1) — từ nay
chỉ còn thiếu PDF/ảnh cho bước so bố cục; 10 tệp `.rar` đã mở được bằng 7-Zip (145 tệp, 10 tệp
duy nhất); đã đo được registry → tệp thật (13/1.920 tham chiếu XSLT thiếu, 1.006/1.015
tham chiếu XSD thiếu vì bản cài không có `data/XMLSchema`).
