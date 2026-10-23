# Reverse-Engineering Notes — Index

Target: official Vietnamese **iTax Viewer** for Windows
(`C:\Program Files (x86)\iTax Viewer`, 4,188 files incl. private JRE).

## Documents

| File | Contents |
|---|---|
| [architecture.md](architecture.md) | Technology stack, module map, end-to-end flow, Windows→macOS replacements |
| [file-inventory.md](file-inventory.md) | Full distribution inventory, hashes, registry sizes, template counts |
| [xml-pipeline.md](xml-pipeline.md) | Parsing, validation, version rules, template lookup, numbering, print pipeline |
| [document-types.md](document-types.md) | 410 codes / 244 display codes, priority mappings, root dispatch |
| [template-engine.md](template-engine.md) | MSXML/XSLT pipeline, layout constants, independent renderer design |
| [signature-verification.md](signature-verification.md) | XMLDSig + PKIX + OCSP behaviour; what macOS implements and what it does not |
| [evidence/](evidence/) | Live reference screenshots from the Windows application |
| [xslt-specs/](xslt-specs/README.md) | Máy trích cấu trúc từ 2.163 XSLT: cột, nhãn, mã chỉ tiêu, thứ tự khối |
| [render-semantics/](render-semantics/README.md) | Quy tắc render gốc: định dạng số, đọc tiền, kỳ thuế, khung host, cấu hình in/PDF |
| [registry-tables/](registry-tables/README.md) | Dump lossless 1.917 entry registry + đối chiếu với CSV cũ (1.512) |
| [install-inventory.md](install-inventory.md) | Kiểm kê bản cài: 4.188 tệp, hash, JRE, certstore, launcher Launch4j |
| [GAP-REGISTER.md](GAP-REGISTER.md) | Hạng mục chưa đủ cơ sở, cần capture/tìm sau để render |
| [java/](java/README.md) | Decompile `itaxviewer.jar` (CFR 0.152): bảng dispatch root tag, render XSLT trong browser nhúng, chữ ký |
| [../security.md](../security.md) | Threat model and hardening of the macOS app |

## Method (reproducible)

1. **Inventory** — `Get-ChildItem -Recurse` over the installation; group by extension.
2. **Fingerprint** — SHA-256 of key artifacts (`itaxviewer.jar`, `DMucTKhai.xml`, reference XSLT,
   `pd4ml.jar`, `swt.jar`); read JAR manifests and class-file version.
3. **Decompile** — CFR 0.152 against the 94-class JAR using the bundled JRE 8:
   ```
   java -jar cfr-0.152.jar itaxviewer.jar --outputdir _re/src --silent true
   ```
   (decompiled sources are analysis-only and excluded from this repository).
4. **Parse registries** — `data/DMucTKhai.xml` (1,150 entries) with namespace-aware Python
   `ElementTree`; recover `maTKhai → displayCode` from each template's `mauTKhai` parameter.
5. **Trace one workflow** — 01/GTGT (`maTKhai=842`, `pbanTKhaiXML=2.8.3`) through
   `HSoThueFactory → TKhaiThue → DMucTKhai → HSoThueViewer → TKhaiConverter`.
6. **Extract form facts** — indicator codes, official labels and XPath expressions from the
   literal-result XSLT into `form-specs.json`. No XSLT/CSS is copied into the app.
7. **Validate against the live app** — the Windows binary was launched on the fixtures and its
   window captured with `PrintWindow` (see `evidence/`). The same fixtures were then mapped by
   the executable Python harness.

## Key verified numbers

| Fact | Value |
|---|---|
| JAR classes | 94 |
| Registry entries | 1,150 |
| Internal form codes | 410 |
| Display codes (Mẫu số) | 244 |
| XSLT version directories | 95 (1.0.0 → 3.0.9) |
| XSLT files | 2,163 |
| Root CA certificates | 76 |
| Intermediate/trusted certificates | 124 |
| A4 HTML widths | 892 px portrait / 1262 px landscape |
| PDF margins | 20/20/20/10 mm |

Đo lại 2026-10-23 bằng lệnh đếm cụ thể (để tránh lệch cách hiểu):

| Fact | Value | Cách đếm |
|---|---:|---|
| `data/xslt` tổng số tệp | 3.149 | `find data/xslt -type f` |
| Template `*.xslt` | 2.163 | khớp số cũ |
| Tệp include `*.xsl` | 783 | `find -name "*.xsl"` |
| Thư mục con (version + loại) | 103 | `find -maxdepth 1 -type d` |
| Class trong `itaxviewer.jar` | 94 | `unzip -l` |
| File `.java` sau CFR | 68 | CFR gộp lớp lồng vào lớp ngoài |
| Mã biểu mẫu đọc từ `mauTKhai` | 447 | pipeline `xslt-specs` |
| Dòng / mã chỉ tiêu trích được | 14.432 / 2.786 | pipeline `xslt-specs` |

## Boundaries

* Static analysis of the JAR is complete for the viewer/print/classification paths; no
  proprietary algorithm is claimed beyond what the symbols and templates show.
* The Windows GUI was launched for reference captures, but not debugged.
* Cryptographic signature verification details are recovered, but the macOS app deliberately
  does **not** claim verification.
* No vendor assets are redistributed; see `README.md`.
