# notices/843

- App: iTax Viewer (publisher "Tong cuc thue"), installed 2026-10-21, jar SHA-256 `5AC31CBA3990221004376883D9B90D5A55339F49BF6BC97C56542ED27BFA9F4E`
- Runtime: bundled JRE 1.8.0_112, Windows 11 Pro N 10.0.22631
- Captured: 2026-10-22
- Sample: `test-data/anonymized/notices/sample-01.xml` (all names/IDs/addresses are synthetic)
- Fix applied before capture: the anonymiser had re-serialised the document with an `ns0:` prefix. The app rejects a prefixed root as "Tệp hồ sơ không đúng định dạng". Replacing `ns0:` with a default `xmlns` (as in real eTax notices) makes it open.
- Detected: root `TBaoThueDTu`, `maTBao=843`, `pbanTBao=2.5.6`
- Template: `data/xslt/XSLT 2.5.6/TBaoThue/xslt/TBao_01_1_TT19_KeKhai.xslt`
- Orientation: portrait
- PDF pages: 1, MediaBox 595×842, /Rotate 0
- Sections: header (mẫu số, cơ quan, số, ngày), legal basis, received branch, closing line, `maDVC`, empty signature placeholder
- Rows: 0 (no reason table in this branch)
- Unknown: `trangThai=N` branch; other 843 versions.
