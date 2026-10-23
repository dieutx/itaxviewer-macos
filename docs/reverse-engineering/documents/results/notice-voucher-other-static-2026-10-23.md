# Notice, voucher and other-document safety review — 2026-10-23

Evidence type: **static local analysis**, not a fresh Windows runtime capture.
Read-only PowerShell/XML/source searches inspected the installed iTax Viewer data
and the already-decompiled `_re/src` tree. REA MCP tools were unavailable in this
agent session; this report does not claim a REA execution or a visual comparison.

## Artifact identity

SHA-256 values read during this review:

| Local artifact | SHA-256 |
|---|---|
| `_re/itaxviewer.jar` | `5AC31CBA3990221004376883D9B90D5A55339F49BF6BC97C56542ED27BFA9F4E` |
| installed `data/DMucCTu.xml` | `145E1CE6DECFC042A593DE4B25937E4F0FF6C17CDE5BD3E9063CE53FCD23C912` |
| installed `data/DMucHSoDky.xml` | `7F172D3E56B267AB40B31CC36FBF99DE4A0CB4EDB3071E849B474DCCBE694A4B` |
| installed `data/DMucDMuc.xml` | `BED87C8977BD1D8DD1C6658E8687C09EE4E167034DF027BF52663F2859470F77` |
| installed `data/xslt/XSLT 2.4.9/TBaoThue/xslt/TBao_01_2_TT19_KeKhai.xslt` | `9450D57542BBC34BC85F33B2665140A49EFE2BE99E0FC8DC0E1F2C86F493D4AC` |

The installation root was `C:/Program Files (x86)/iTax Viewer`. No vendor
asset was copied into tracked source. Decompilation line references below are
within `_re/src/seatechit/ihtkk/tool/`; `_re` remains excluded from commits.

## Findings and implemented corrections

* `NoticeRenderer` previously chose the BSTT form for **every** `TBao` root.
  `taxdoc/HSoThueFactory.java:157–188` instead routes by `MSo` and several
  independent forms exist. The dedicated renderer now requires the captured
  `MSo=01/TB-BSTT`, `PBan=2.1.0`; other codes/versions use the structured view.
* 843/844 had no version or status guard. The recreated layouts now require
  the versions actually captured in the existing notice specs: 843/2.5.6
  (Y/0/N) and 844/2.4.9 (Y/N). Unknown statuses cannot produce an almost-empty
  document that appears accepted.
* Multiple `CTietHoSoThue` records now remain visible; header HTML is closed;
  the BSTT issuing tax office and subject are included from its existing spec.
* 844 rejection descriptions and supplementary tax notes now follow
  `documents/notices/844.json`. The installed template lines 105–107 confirm
  that supplementary status comes from `HoSoThue/CTietHoSoThue/loaiToKhai`,
  while the signed amount comes from the current `CTietIDKhoanNop` row.
* `VoucherRenderer` previously combined **all** `ROW_CTIET` records with the
  **first** `CHUNGTU_HDR`. It now repeats a complete body for each direct
  `NDUNG_CTU_NH/NDUNG_CTU` and scopes each table and total to that record.
  The record path and repeat behavior are documented in `paymentVouchers/CT-01.json`.
* Dedicated voucher rendering now requires each record to be CT-01/4.0.1.
  Other versions are registry-known but have not been captured with this layout.
  USD, unknown currency and negative/invalid/overflow totals use the structured
  view because the previous formatter printed Vietnamese **đồng** words even
  for USD and stripped negative signs from words. This is an explicit coverage
  limitation pending separate branches, not a claim of USD parity.
* Voucher number uses the spec's envelope `SO_CTU`, and recommendation checkboxes
  use `ID_TK_KNGHI`; `Tỷ giá hạch toán` is no longer printed for CT-01 because
  its spec reserves it for CT-02.

## Other document detection facts for the shared classifier/metadata work

| Family | Observed rule | Source |
|---|---|---|
| Payment voucher | descendant `MA_CTU`; version `PBAN_TLIEU_XML`, absent default `1.0` (which differs from registered `1.0.0`) | `taxvoucher/GNTNSNN.java:22–33` |
| CT-02/03 | **No** `maCTu=02` or `03` in the inspected `DMucCTu.xml`; five rows all `01`, versions 1.0.0/3.0.0/4.0.0/4.0.1/4.0.2. Existence of conditional template branches does not prove factory acceptance. | installed `DMucCTu.xml:4–23` |
| Registration | descendant `maDKy` and exact-case `pBanDKy`, both required | `taxRegistration/DKyThue.java:33–44` |
| Catalog | descendant `maDanhMuc` and exact-case `pBanDanhMuc`, both required | `taxCatalog/DMuc.java:33–44` |
| Electronic payment notices | descendant `MA_THONGBAO`, fallback `MA_TBAO`; `PBAN_TLIEU_XML` defaults to 4.0.0 if absent/empty | `taxMessageNtdt/TBaoThueNtdt.java:32–47` |
| TBaoHDDT | unprefixed input uses `MSo`/`PBan`; `TTinVBanCDoi` switches to the comparison registry | `taxMessage/TBaoHDDT.java:32–49` |
| Notice roots | `THONGBAO`, `TBAO_TKHOAN_NH`, `TBAO_TKHOAN_NT`, `TBAO_NGUNG`, `THONG_BAO`, `BKE_TBAO`, `TRASOAT_THUE`, `XULY_NTHUA`, `XACNHAN_THUE`, `XACNHAN_NVTHUE`; `TBTNhan` uses the same MSo gate as TBao | `taxdoc/HSoThueFactory.java:50–164` |
| Customs original | descendant `MA_LH`; absent `PBAN_XML` defaults to 1.0.0 | `hquanform/HquanForm.java:35–48` |
| Customs correction | descendant `MA_LH_XNK`; same version default | `hquanform1/HquanForm1.java:35–48` |
| Customs Envelope | first tries `Envelope/Body/ListExImDeclarationResponse/Declarations/ExImCode`; next path is `InquiryAMADeclarationResponse/AMADeclaration/ExImCode`, but decompiled code then unconditionally assigns `BSSTQ`; version `PBAN_XML`, absent default 1.0.0 | `hquanformnew/HquanFormNew.java:47–82` |

The Envelope `BSSTQ` assignment is an observed static implementation detail,
not a rule recommended for replication without a runtime fixture. The customs
classes also overwrite some signature results to GOOD after calling the
verifier; the independent viewer must continue `.notVerified` and must not copy
that behavior.

## Validation and remaining work

Added `NoticeVoucherSafetyTests.swift` covering dispatch boundaries, unsupported
versions/statuses/currencies, repeated notice details and voucher header/row
isolation. This agent had no Swift executable; test execution is **pending**.
The parent agent owns build/test integration. No macOS native visual/print/PDF
result is claimed by this review. All remaining notice/registration/catalog/
customs layouts still require template-specific evidence and Windows captures;
registry entries alone are not implemented layouts.
