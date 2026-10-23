# Declaration batch DECL-W0-STATIC (2026-10-23)

These are interoperability facts read from the installed Windows iTax Viewer templates,
with independently generated synthetic XML. No vendor template or rendering code is
redistributed. The installed registry selects each template; its SHA-256 and relative
path are recorded in `sourceEvidence`. Row `source.line` locates the first value XPath
in that template. Labels, indicators, units and value paths are factual mappings.

**Status: static mapping only.** No new Windows screenshot, Windows PDF, macOS build,
macOS display or native print comparison has been executed for these four forms.
They must not be reported as visually verified or `captured/spec-done`.

| Code | XML versions inspected/mapped | Indicators | Significant differences |
|---|---|---|---|
| 864 | 2.9.3 | 16–32 plus 25.1 | 16–20 are people; 21 onwards are currency. New `ct25_1` prints `[25.1]`. Header checkbox `[15]` is `ct15`. |
| 395 | 2.4.2 | 21–46 | `NVuKhauTruThue/ct21..41`, `NVuQToanThay/ct42..46`. People 21–27 and 42. Includes conversion/merger checkbox and reason. |
| 07 | 2.4.1, 2.5.0 | 21–33 | `ct21` is a monetary amount spanning five rows, not a checkbox. `ct32` and `ct33` appear below the main table. |
| 847 | 2.5.1, 2.6.8, 2.7.4 | 21–37 | Main amounts are nested under `KhaiThueTPPTTTDT`. Section B repeats `KhoanThuHoCTGTGT` with `ct33..35`, followed by `ct36/37` totals. |

The 847 registry points to **XSLT 2.5.2**, even for XML 2.7.4. A newer, unselected
2.8.3 template exists locally and has changed administrative labels; it was deliberately
excluded from this spec. The 07 2.1.2 template has a different header call and a fixed 2%
rate where 2.4.1 uses `hoatDongThuHo` to choose 10% or 2%. These versions have not been
treated as identical layouts.

`headerFacts` records actual field expressions from the selected shared header template;
`headerFields` contains direct root/path mappings suitable for an independently authored
header. Period/filing status formatting is retained as an expression in `headerFacts`.
The individual contract date accompanying a contract number must also be displayed.

Each form has minimal, empty and negative fixtures. All names/identifiers are invented;
the fixtures exercise field presence and number formatting, not tax calculation validity.
They contain no signatures. Minimal fixtures are mirrored in the Swift test resources as
`declaration_<code>_static.xml`. Empty 847 has no repeating records and explicit zero totals.

Executed validation on Windows:

```powershell
powershell -NoProfile -File iTaxViewerMac/scripts/validate_declaration_specs.ps1
```

This validates exact indicator coverage, nonempty traceable labels, all mapped paths in
all three fixtures, synthetic taxpayer identifiers, and repeating records/totals. It does
not execute Swift or prove visual/print parity.

Remaining work: capture original UI/PDF for each XML version; check per-version header,
checkboxes, legal text, rate selection, table row spans, footnotes, orientation, margins,
page breaks and all values on macOS. Earlier 864 and 395 versions require explicit
version comparison before reusing a layout.
