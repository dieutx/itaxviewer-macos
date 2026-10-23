# Kiem ke bản cài iTax Viewer (Windows) — dữ liệu gốc để clone

Đo 2026-10-23 trên `C:\Program Files (x86)\iTax Viewer`. Sinh lại bằng
[`tools/inventory_install.py`](tools/inventory_install.py) → `_re/inventory/files.csv`
(4.188 dòng: path, size, sha256) và `_re/inventory/summary.json`.

## 1. Tổng quan

| Hạng mục | Giá trị |
|---|---:|
| Tổng tệp | **4.188** |
| Tổng dung lượng | **345.938.851 byte** (~346 MB) |
| `jre/` | 681 tệp · 187,8 MB |
| `data/` | 3.190 tệp · 118,9 MB |
| `itaxviewer_lib/` | 9 tệp · 19,6 MB |
| `update/` (gói cập nhật) | 5 tệp · 14,1 MB |
| `certstore/` | 274 tệp · 482 KB |
| `image/` + `infor/` | 22 tệp · 490 KB |

Thành phần theo đuôi: `.xslt` 2.163 · `.xsl` 783 · `.cer` 249 · `.bak` 157 · `.dll` 90 ·
`.xml` 48 · `.jar` 40 · `.crt` 25 · `.properties` 25 · `.gif` 13 · `.png` 11 · `.rar` 10 ·
`.xsd` 9 · `.ttf` 8 · `.html` 7 · `.ico` 7 · `.pf` 5.

## 2. Hash của artifact then chốt

| Tệp | SHA-256 |
|---|---|
| `iTaxViewer.exe` (27.136 B) | `b579e63b0d598f1228408fca36e20f51c3d0cad6451691f58ff553458d386b5f` |
| `itaxviewer.jar` (214.057 B) | `5ac31cba3990221004376883d9b90d5a55339f49bf6bc97c56542ed27bfa9f4e` |
| `data/js/common.js` | `888ac8d55b47cfbf50696e29c01763a1c11b56deaa55eba8a08cd3da2a3f503a` |
| `data/css/ihtkk.css` | `17f949adfced33414b5227e0444611987a0cd39de38435df3dcb82af9f45c4e6` |
| `data/css/ihtkk_ntdt.css` | `5d5cb4ef5cba08c9b5c3d31866be1cce224d7a5a6a1e00efcda396154addc3ab` |
| `update/latest.xml` | `73f28f96e0dfdcfa0ca231e6d1b8759ca7ad159f69e03d31e19aed93a2f55882` |
| `update/updater.jar` | `f3e3de4a6fd1e0d920404c7420ebd2f74f08d7f4d3a16f23354ea8a57fd01f00` |

## 3. `iTaxViewer.exe` không chứa logic

- PE32 (`machine 0x14c` = i386), 27.136 byte.
- Là launcher **Launch4j** (chuỗi `Launch4j`, `--l4j-debug`, `-jar`, `itaxviewer.jar`,
  `bin\java.exe`, `Bundled JRE:`).
- Nghĩa là toàn bộ logic nằm trong `itaxviewer.jar` + `data/`; EXE chỉ chọn JRE và chạy
  `-jar itaxviewer.jar` với `-Xmx` giới hạn theo 32-bit.

Hệ quả: "lấy nguyên gốc từ EXE" = lấy từ `itaxviewer.jar` + `data/`; đã làm (xem
[`java/README.md`](java/README.md), [`xslt-specs/`](xslt-specs/README.md),
[`render-semantics/`](render-semantics/README.md)).

## 4. Runtime

- JRE riêng: `JAVA_VERSION="1.8.0_112"`, `OS_ARCH="i586"` → **Java 8, 32-bit**.
- Vì vậy bytecode là Java 8; CFR 0.152 đọc tốt (đã kiểm chứng: 94 class → 68 file `.java`).
- `itaxviewer_lib/` (9 jar): `swt.jar`, `org.eclipse.swt.win32.win32.x86_64-4.3.jar` (UI),
  `pd4ml.jar` + `ss_css2.jar` (render PDF + CSS), `pdfbox-app-1.8.8.jar` (gộp PDF),
  `bcprov-jdk16-146.jar` (crypto), `commons-io-1.4.jar`, `commons-lang3-3.3.2.jar`,
  `fonts.jar` (8 TTF nhúng).

## 5. Certificate store (không được redistribute)

| Nhóm | Số tệp |
|---|---:|
| `certstore/root/` | 76 |
| `certstore/trust/` | 124 |
| `certstore/trust_bk/` | 74 |

Dùng cho `CertVerifier`. Bản macOS **không** copy; chính sách tin cậy phải dựa trên mô tả
subject/issuer và trust store của hệ điều hành — xem [`signature-verification.md`](signature-verification.md).

## 6. Gói cập nhật `update/`

- `latest.xml`: `pkgver 2.8.4`, `pkgrel 1`, `pubDate Fri, 23 July 2021`.
- `update.xml`: 2 instruction `MOVE` (`BC01ACImporter.jar`, `latest.xml`).
- `update.zip`: **13.523.032 byte**, **4.032 tệp** (payload đầy đủ: `certstore/`, `data/`,
  `update/`). Đây là bản payload cũ hơn bản cài hiện tại (`itaxviewer.jar` trong bản cài
  ngày 29/09/2026) → chỉ dùng để đối chiếu lịch sử, không phải nguồn mới hơn.
- `updater.jar` (526.742 B) **chưa decompile** — xem gap register.

## 7. Tệp "lạ" cần biết

- **10 tệp `.rar`** nằm rải trong `data/xslt/**` (ví dụ `XSLT 2.8.4/TKhaiThue/xslt.rar`,
  `XSLT 2.2.3/XSLT 2.5.2/TKhaiThue.rar`). **Đã mở được** bằng 7-Zip 26.05: 145 tệp, 135 là
  XSLT/XSL, **10 tệp không có bản nào trên đĩa** — chi tiết ở
  [`rar-archives.md`](rar-archives.md).
- 157 tệp `.bak` (bản cũ của XSLT/registry) — hữu ích để so version cũ.
- 5 tệp `.pf` thuộc `jre/lib/cmm` (color profile của JRE, không liên quan).
- 8 tệp `.ttf` là font Lucida của JRE (`jre/lib/fonts/`), không phải font tài liệu.
  Font tài liệu (Times New Roman/Arial/Courier New) lấy từ `itaxviewer_lib/fonts.jar` qua
  `pd4ml.useTTF("java:fonts", true)` — **không** phải font rời trong `data/`.
