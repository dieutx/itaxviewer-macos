# notices/01-TB-BSTT

- App: iTax Viewer (publisher "Tong cuc thue"), installed 2026-10-21, jar SHA-256 `5AC31CBA3990221004376883D9B90D5A55339F49BF6BC97C56542ED27BFA9F4E`
- Runtime: bundled JRE 1.8.0_112, Windows 11 Pro N 10.0.22631
- Captured: 2026-10-22
- Sample: synthetic `notice-bstt-root-tbao.xml` derived from the observed template paths (no taxpayer data)
- Detected: root `TBao`, `MSo=01/TB-BSTT`, `PBan=2.1.0` → `TBaoHDDT`
- Template: `data/xslt/XSLT 2.8.1/TBaoThue/xslt/TBao_107_TB_BSTT.xslt`
- Orientation: portrait
- PDF pages: 1, MediaBox 595×842, /Rotate 0
- Sections: header, recipient block, prose body, note, "Nơi nhận" + signing block, empty `sigDiv`
- Rows: 0
- Rejected variant (verified): `TBaoThueDTu` + `maTBao=107` + `pbanTBao=3.0.7` → "Mã Thông báo (107) hoặc phiên bản thông báo (3.0.7) không đúng"
- Unknown: the PL appendix (`TBao_107_TB_BSTT_PL.xslt`) and the other `01/TB-*` notice codes.
