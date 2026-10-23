# iTax Viewer (Windows) — giải nén và decompile `itaxviewer.jar`

Bản cài: `C:\Program Files (x86)\iTax Viewer` (jar 214.057 byte, 29/09/2026).
Đây là **ứng dụng Java** (SWT) đóng gói cùng JRE, không phải .NET/Electron.

Không file vendor nào được commit: mã decompile nằm trong `_re/decompiled/`, và `_re/` đã
nằm trong `.gitignore`.

## 1. Cách tái lập

```bash
# JDK portable + CFR đặt trong workspace phân tích (không cài hệ thống)
_re/tools/jdk/bin/java -jar _re/tools/decompiler/cfr-0.152.jar \
  _re/itaxviewer.jar --outputdir _re/decompiled

# REA: chỉ inventory artifact (REA không có provider Java bytecode)
npx -y rea-agents@6.7.0 inspect-artifact _re/itaxviewer.jar --format json \
  > _re/rea-inspect-artifact.json
```

- JDK: Temurin 21.0.12.1+1 (`_re/tools/jdk`).
- Decompiler: CFR 0.152 (`_re/tools/decompiler/cfr-0.152.jar`).
- REA 6.7.0: `inspect-artifact` chạy được với provider `rea-artifact-graph`, Evidence
  `ev_cff4d4e2a32ac05a2525d9a324dbad487dc3f54787198b3d069ebf2298569ff9`.
  `rea inspect _re/itaxviewer.jar` **thất bại** (`capability_unavailable`,
  `unsupported_provider`): provider khả dụng là Ghidra/Hopper/IDA/Kuna, đều không đọc
  Java bytecode. Vì vậy phần code dưới đây đến từ CFR, không phải REA.

## 2. Quy mô

- 116 entry trong jar, 68 file `.java` sau khi decompile, 9.693 dòng.
- Lớn nhất: `signature/IHTKKXMLSignature.java` (989 dòng), `taxview/HSoThueViewer.java`
  (545), `signature/IHTKKXMLTemSignature.java` (479), `taxview/TaxViewer.java` (456),
  `taxreturn/DMucTKhai.java` (371), `taxMessage/DMucTBao.java` (367).

## 3. Phát hiện có ảnh hưởng trực tiếp tới bản macOS

### 3.1 Render bằng XSLT trong browser nhúng, không phải layout native

`taxview/HSoThueViewer.java` gọi JavaScript của SWT `Browser`:

```java
String xsltFileName = new File(this.hso.getXsltFile()).toURI().toURL().toString();
String html = (String)fileBrowser.evaluate(
    "return transform('" + xmlFileName + "','" + xsltFileName + "');");
```

Nghĩa là giao diện gốc = `data/xslt/**.xslt` + `data/css/ihtkk.css` (chứng từ dùng
`data\css\ihtkk_ntdt.css`). Muốn "giống 100%" thì phải tái tạo đúng hai thứ này; repo hiện
tự viết renderer Swift thay vì copy XSLT/CSS của vendor (đúng luật trong `AGENTS.md`).

### 3.2 Bảng phân loại theo root tag — nguồn chuẩn cho `DocumentClassifier`

`taxdoc/HSoThueFactory.java` chọn lớp xử lý bằng tên root element (namespace-aware):

| Root tag | Loại |
|---|---|
| `HSoThueDTu` | Tờ khai thuế |
| `TKhai` | Tờ khai HĐĐT |
| `CHUNGTU` | Chứng từ |
| `TBaoThueDTu`, `THONGBAO`, `TBAO_TKHOAN_NH`, `TBAO_TKHOAN_NT`, `TBAO_NGUNG`, `THONG_BAO` | Thông báo |
| `DanhMucDTu` | Danh mục |
| `DKyThueDTu` | Đăng ký thuế |
| `TOKHAI_OBJ`, `TOKHAISUA_OBJ`, `*:Envelope` | Hải quan |
| `BKE_TBAO` | Bảng kê khai |
| `TRASOAT_THUE` | Tra soát |
| `XACNHAN_THUE`, `XACNHAN_NVTHUE` | Xác nhận |
| `XULY_NTHUA` | Xử lý nộp thừa |
| `DNghi`, `BCTHSDBLai`, `TBTNhan`, `BLai` | HĐĐT (đề nghị / bảng lại / thông báo) |
| `TBao` + `MSo` | Phân biệt tiếp nhận HĐĐT và tờ khai HĐĐT (`isTBaoHDDT` / `isTKHaiTBaoHDDT`) |

Đối chiếu: `DocumentClassifier.swift` của bản macOS hiện nhận diện theo tập root tag riêng —
bảng trên là nguồn đối chiếu đầy đủ nhất từ chính app gốc.

### 3.3 XPath đọc dữ liệu thông báo

`ConfigInfo.java`:
`TBaoXpath=/TBaoThueDTu/TBaoThue`, `DmucXpath=/DanhMucDTu/DanhMuc`,
`DkyXpath=/DKyThueDTu/DKyThue`, `TBaoNtdtXpath=/THONGBAO/NDUNG_TBAO`.

### 3.4 Chữ ký số

`signature/IHTKKXMLSignature.verifyXMLSignature` xác thực trên XPath
`/HSoThueDTu/HSoKhaiThue` (tờ khai) và `/TKhai/DLTKhai` (HĐĐT), đọc `ReferenceURI`, thuộc
tính ký và thời gian ký; kèm `CertVerifier` (337 dòng) kiểm tra chuỗi chứng thư. Bản macOS
vẫn phải giữ `SignatureInspector = .notVerified` cho tới khi có C14N + digest + kiểm tra
chữ ký thật.

### 3.5 In/PDF — `taxview/TKhaiConverter.java`

Toàn bộ cấu hình in nằm trong 93 dòng của lớp này: A4, lề **20/20/20/10 mm**, `htmlWidth`
**892** (portrait) / **1262** (landscape), `enableTableBreaks(false)`, `enableImgSplit(false)`,
font TTF qua `useTTF("java:fonts", true)`, footer `$[page]/$[total]` Times New Roman 12.
Chi tiết bảng tham số: [`../render-semantics/README.md`](../render-semantics/README.md) mục 6.

### 3.6 EXE chỉ là launcher

`iTaxViewer.exe` là PE32 i386 do **Launch4j** sinh ra (chuỗi `Launch4j`, `--l4j-debug`,
`itaxviewer.jar`, `Bundled JRE:`). Không có logic nghiệp vụ trong EXE; JRE riêng là
**Java 8 (1.8.0_112), 32-bit**. Số liệu: [`../install-inventory.md`](../install-inventory.md).

### 3.7 Không có telemetry, nhưng có gọi mạng cập nhật

`autoupdate/AutoUpdate.java` gọi `https://thuedientu.gdt.gov.vn/etaxnnt/static/update/latest.xml`
(qua `HttpsURLConnection`). Đây là kiểm tra cập nhật; không gửi nội dung hồ sơ.

## 4. Giới hạn

- CFR 0.152 cho mã nguồn **gần đúng**, không phải source gốc: tên biến cục bộ và một số
  generic bị suy diễn, `switch` trên string có thể khác hình thức.
- Không chạy được app gốc trên máy này (không có JDK trong PATH mặc định và không chạy JRE
  của vendor để tránh thay đổi trạng thái cài đặt) → mọi kết luận ở trên là **đọc tĩnh**.
- Chưa decompile `itaxviewer_lib/*.jar` (bcprov, pd4ml, pdfbox) vì đó là thư viện bên thứ ba.
- Chưa làm: capture UI trực tiếp, so pixel với bản macOS (phải chạy trên macOS).
