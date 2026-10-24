# Native PDF review — 2026-10-24

Reviewed the 55 PDFKit page images for all 29 safe fixtures from
[macOS run 39970873502](https://github.com/dieutx/itaxviewer-macos/actions/runs/39970873502),
commit `c327fe310bf4ae1fc76eb5158aea1f27f92b99ca`. Review used contact sheets of
every page and full-size views of the priority-form continuation pages and 394.
This is a review of native output collected by CI, performed on Windows; it is
not manual interaction with a Mac or independent verification of every XML value.

| Output | Observed visual limitation |
|---|---|
| 842, UTF-16 variant, legacy 01, NQ142 parent and correction parent | GTGT row `[30]`/`[31]` splits across pages; page 2 begins with the end of its label and has no column headings |
| 394 | All 16 rows and signature blocks fit on one A4 page; comparison to the captured Windows 394 screenshot shows different masthead proportions, period placement and label weights |
| 953 | Row `[26]` continues at the top of page 2 without column headings |
| 892 | Five pages including the raw appendix; continuation tables lack column headings, section D is stranded at the bottom of page 2 and the H2 label crosses pages 3–4 |
| 07 / 847 | Below-table totals and signature blocks occupy a sparse second page |
| 864, 395, TT89 and BCTC | Tables continue without repeated headings; several boundaries split a row or section label |
| TT80 correction appendices | The long allocation-table heading crosses pages 3–4 of the combined fixture |
| NSD / BSTT-NNT | NSD supplementary data moves to page 2; BSTT-NNT signature and supplementary data occupy page 2 |
| Other notices, vouchers, NQ142 appendix and structured fallback | Pages render with visible content; no Windows visual-parity claim is made |
| Synthetic signed fixture | Signature footer visibly says “Chưa xác minh (Not verified)” |

Compared priority native pages with the existing Windows `reference-gtgt.png`,
`reference-tncn-05qtt.png` and captured 394 screenshot. The GTGT dependent-unit
address fields are stacked rather than arranged in three columns; the 953 title
wraps to two lines and its address rows differ. The Windows `reference-tndn-03.png`
was inspected and contains only the splash screen, so it cannot establish form parity.

Preserved native screenshots from that run:

- [GTGT page 2](../../evidence/native-review-2026-10-24/gtgt_842_return-page-2.png)
- [394 single page](../../evidence/native-review-2026-10-24/tncn_394_05kk_tt92-page-1.png)

The GTGT screenshot demonstrates that CSS `break-inside: avoid` and
`thead { display: table-header-group }` do not establish correct native pagination
on the tested WebKit runtime. Numeric-value presence checks must not be described
as visual or pagination parity. No CSS-only fix is claimed here.

## Full-document export regression

The app previously copied `NSPrintInfo.shared` without resetting a prior job's
selected page range. Native QA used separate print setup that explicitly selected
all pages, so it did not exercise that production state.

The app and QA now use `NativePrintSettings`. Each operation copies its base,
sets A4 orientation/margins, clears inherited first/last page bounds, selects all
pages and sets the current spool/PDF destination. The previous job is unchanged.
Native QA deliberately supplies a previous PDF job restricted to page 2 before
exporting every fixture. Unit tests cover isolation, destination reset and geometry.

[Run 40048655534](https://github.com/dieutx/itaxviewer-macos/actions/runs/40048655534)
passed XCTest/build/app-open but its native print step exited 251 on the first
multi-page fixture. That revision selected all pages but retained first/last page
bounds. The follow-up clears those bounds. AppKit recreates the default range
as first page 1 / last page `Int.max` when its dictionary is read; the regression
test asserts those values. This failure is retained as evidence, not a PASS.

In [run 40048951554](https://github.com/dieutx/itaxviewer-macos/actions/runs/40048951554),
arm64 XCTest passed (99 tests, 98 passed, one optional test skipped), all safe
fixtures opened through the actual app, and native QA exported 29 PDFs / 55 pages.
Every one of those 55 page PNGs is SHA-256-identical to the reviewed baseline images.
Intel XCTest also passed with the same count. That run's Intel package step failed
because the new `lipo -verify_arch` command placed the input after the architecture
list; the workflow follow-up fixes the argument order. Final Intel app-open/PDF
results are recorded below and in `COMPATIBILITY.md`.

Final [run 40049293344](https://github.com/dieutx/itaxviewer-macos/actions/runs/40049293344)
at commit `3beb9ceba7e6783dd04f5cc966a6d1e4d8c86eef` passed both jobs. Each runner
executed 99 tests (98 passed, one optional skip), opened all 29 safe fixtures through
the actual app and exported 29 PDFs / 55 A4 pages with numeric-cell/marker checks.
Both rejected XXE. Intel verified SHA-256, ad-hoc signature and both binary slices
before launching the exact ZIP from arm64. Toolchains: Xcode 15.4 / Swift 5.10 on
macOS 14 arm64, Xcode 16.4 / Swift 6.1.2 on macOS 15 Intel.

Downloaded the Intel evidence and independently counted 29 successful PDFs, 55 pages
and 29 distinct app WebKit loads. Every fixture's page count matches arm64. Full-size
spot checks of Intel GTGT page 2, 394 and 953 page 2 show the same continuation-header
and split-row limitations; this is not a full visual comparison of every Intel page.
Permanent fixture-only records:

- [Intel export report](../../evidence/native-review-2026-10-24/intel-report-40049293344.json)
- [Intel app-open events](../../evidence/native-review-2026-10-24/intel-app-open-40049293344.json)
- [Intel GTGT page 2](../../evidence/native-review-2026-10-24/intel-gtgt-page-2.png)

The workflow also adds Intel execution of the exact universal ZIP built by the
arm64 job, with SHA-256/signature checks, all safe fixture opens, XCTest and native
PDF QA. Finder gestures, printer hardware, visual parity, signing/notarization
and cryptographic XMLDSig verification remain separate unresolved checks.
