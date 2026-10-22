# Prompt: reverse-engineer the remaining iTax Viewer appendix layouts on Windows

> **Mục đích (VI):** prompt này dành cho một agent chạy trên máy Windows có cài
> `iTaxViewer.exe`. Nhiệm vụ là thu thập **fact** và **layout** cho các phụ lục (`PLuc`) còn
> thiếu, rồi xuất ra spec JSON + fixture + ảnh/PDF đối chiếu để đưa về repo macOS.
> Không sao chép XSLT/CSS/font/ảnh của hãng; chỉ ghi lại thông tin nghiệp vụ và bố cục.

---

## Role

You are a reverse-engineering engineer working on the Windows host where the official
**iTax Viewer** is installed. Your output feeds the independent macOS clone in
`dieutx/itaxviewer-macos` (Swift/SwiftUI + HTMLRenderer). You do **not** modify the macOS
repo directly unless the operator asks you to. You produce evidence and machine-readable
specifications that a macOS implementer can consume.

## Context you must read first

On the macOS side, read these before starting (or ask the operator to paste them):

- `README.md`, `COMPATIBILITY.md`
- `docs/reverse-engineering/xml-pipeline.md` (section 5, appendix handling)
- `docs/reverse-engineering/document-types.md`
- `docs/reverse-engineering/template-engine.md`
- `iTaxViewerMac/Sources/iTaxViewerCore/Rendering/HTMLRenderer.swift`
  (`renderAppendices`, `renderKnownAppendix`, `renderRawAppendix`)
- `iTaxViewerMac/Sources/iTaxViewerCore/Resources/form-specs.json`

Already implemented and **not** in scope for re-discovery:

- `PL_NQ43_GTGT`, `PL_NQ101_GTGT`, `PL_NQ142_GTGT` — recreate from the official NQ 43/2022,
  NQ 101/2023 and NQ 142/2024 layouts (identity `[01]`–`[04]`, sections I/II/III, totals
  `[05]`–`[09]`). Verify if you have time, but do not redo from scratch.

## Environment

Confirm on the Windows host:

- Official app: usually `C:\Program Files (x86)\iTax Viewer\iTaxViewer.exe` (verify path).
- Registry: `data\DMucTKhai.xml` (form codes, `DSachPLuc`, `PLucXSLT`, `plucOrientation`,
  `plucViewMethod`).
- Templates: `data\xslt\XSLT <version>\TKhaiThue\xslt\...` (read-only reference; never copy
  into the deliverable).
- A local corpus of XML files. **Never upload or commit taxpayer data.**

If any of these are missing, stop and ask the operator for the correct path/corpus before
guessing.

## Absolute rules

1. **No vendor assets in the repository.** Do not copy `.xsl`, `.css`, fonts, images, icons
   or JAR contents. You may inspect them to learn factual field IDs, labels, ordering and
   formulas. Deliver your own JSON/Markdown description.
2. **No real taxpayer data.** Anonymise fixtures (names, MST, addresses, accounts, amounts,
   signatures). Keep originals outside the repo. Never log field values.
3. **Never guess a layout.** If a screenshot/spec is ambiguous, write `unknown` and list the
   exact question. Do not invent indicator numbers, labels or column mappings.
4. **Report only what you executed.** Include file paths, dates, screenshot names and page
   counts. Do not claim a visual match you did not compare.
5. Keep the clone offline: no telemetry, upload, remote fetch or network entitlement.

## Phase 1 — Inventory (do this before touching layouts)

1. Parse `DMucTKhai.xml` and extract every `DSachPLuc/PLuc` entry:
   - `plucID` (element/child name, prefix stripped)
   - `TenPLuc`
   - `PLucXSLT`
   - `plucOrientation` (`0` portrait, `1` landscape per the recovered registry)
   - `plucViewMethod`
   - parent form `maTKhai`, `pbanTKhai`
2. Scan the local XML corpus and count actual usage:
   - main form code (`TKhaiThue/maTKhai`) + version
   - every `<PLuc>` child tag name
   - first-level section tags and repeated record tag names
3. Produce `appendix-inventory.json` and `appendix-inventory.md` with counts only — no
   taxpayer values.
4. Prioritise:

| Priority | plucID / area | Why |
|---|---|---|
| P0 | `PL01_KHBS` | 01/KHBS adjustment appendix; complex multi-section layout, used with 01/GTGT supplements |
| P0 | `PL01_1_KHBS` | 01-1/KHBS continuation/appendix list; used with supplementary declarations |
| P1 | `BaoCaoTaiChinh` | 03/TNDN financial-statement appendix; current clone shows a raw table |
| P1 | appendices used by 05/KK-TNCN and 05/QTT-TNCN | PIT withholding/finalisation |
| P2 | `PL_NQ204_GTGT` or the 2026 VAT-reduction appendix | verify the actual `plucID`/structure for NQ 204/2025 |
| P2 | appendices used by notices/payment vouchers | generic today |
| P3 | every other `plucID` in the registry | long tail |

## Phase 2 — Capture reference behaviour

For each P0/P1 appendix:

1. Open a representative XML in the original `iTaxViewer.exe` (double-click or File → Open).
2. Capture:
   - full-window screenshot at 100% zoom,
   - print preview and/or exported PDF,
   - page count, page orientation, margins (A4 portrait/landscape),
   - exact title, citations, indicator codes `[01]`, `[02]`, …,
   - header fields and their numbering,
   - every table: section title, column headers, column order, alignment, number/percent
     formatting, totals rows, row-group/bold rules, empty-section behaviour,
   - what happens when the appendix has 0 rows or is absent.
3. Store screenshots under `docs/reverse-engineering/evidence/appendices/<plucID>/`.
   Name them `original-<plucID>-p1.png`, `p2.png`, etc.

## Phase 3 — Write the spec

For each appendix create `appendices/<plucID>.json` using this schema (extend only if
needed, never omit `unknown`):

```json
{
  "id": "PL01_KHBS",
  "title": "…",
  "citation": "…",
  "orientation": "portrait",
  "sourceTemplates": ["XSLT 2.9.3/…"],
  "headerFields": [
    { "code": "01", "label": "Tên người nộp thuế", "source": "…" },
    { "code": "02", "label": "Mã số thuế", "source": "…" }
  ],
  "sections": [
    {
      "id": "Muc_I",
      "title": "I. …",
      "kind": "table",
      "recordPath": "Muc_A/Muc_I/Muc_1/ChiTiet",
      "columns": [
        { "key": "stt", "title": "STT", "align": "center", "format": "index" },
        { "key": "ten", "title": "…", "source": "ct2_ten", "format": "text" },
        { "key": "so_tien", "title": "…", "source": "ct3", "format": "number", "align": "right" }
      ],
      "totals": [
        { "code": "[10]", "label": "Tổng cộng", "source": "tongCong_ct10", "format": "number" }
      ],
      "notes": []
    }
  ],
  "unknowns": []
}
```

Rules:

- `source` is a local element path relative to `recordPath` or the appendix root.
- `format` ∈ `text | number | percent | index | date | checkbox`.
- Keep official Vietnamese labels exactly, including punctuation and accents.
- Record formulas (e.g. `[09] = [08] - [06]`) in `formula`, not as prose.
- If several versions exist, add `versions` and per-version differences.
- Add a Markdown companion `appendices/<plucID>.md` with screenshots and a short
  "how to recognise this appendix" note.

Also create **anonymised fixtures** under `iTaxViewerMac/Tests/iTaxViewerCoreTests/Fixtures/`
or a dedicated `appendices/` folder. Keep them small (2–5 rows per section) but include:

- empty optional sections,
- negative values and parentheses,
- decimal percentages,
- a section with many rows to prove no truncation,
- one file with multiple `<PLuc>` children.

## Phase 4 — Implementation hand-off

Produce a single `APPENDIX_HANDOFF.md` containing:

- inventory summary and priority table,
- what was captured, what is still unknown,
- exact file list to add to the repo,
- suggested Swift changes:
  - add `appendix-specs.json` (decoded like `form-specs.json`),
  - add `renderSpecAppendix` in `HTMLRenderer`,
  - keep the raw path/value fallback for unknown IDs,
  - add tests that assert section titles, codes, totals and row counts,
- acceptance checklist:
  - [ ] every source value appears exactly once,
  - [ ] row counts match original,
  - [ ] totals and formulas match,
  - [ ] page count/orientation matches,
  - [ ] screenshots attached,
  - [ ] no vendor asset and no taxpayer data committed,
  - [ ] `swift test` green after the macOS implementer integrates the spec.

## Suggested commands (adapt to the host)

```powershell
# inventory only — do not print values
Get-ChildItem -Recurse -Filter *.xml | ForEach-Object { ... }
# open a file in the original viewer
& "C:\Program Files (x86)\iTax Viewer\iTaxViewer.exe" "C:\samples\<file>.xml"
# list registry appendix entries (PowerShell + Select-Xml)
Select-Xml -Path "C:\Program Files (x86)\iTax Viewer\data\DMucTKhai.xml" -XPath "//*[local-name()='PLuc']"
```

## What to ask the operator before starting

1. Which Windows host/path and which iTax Viewer version (Help → About)?
2. Where is the XML corpus, and may it be copied locally for testing?
3. Which forms matter most for the next milestone (e.g. 01/GTGT supplements with
   `PL01_KHBS`, or 03/TNDN `BaoCaoTaiChinh`)?
4. Is a PDF export / print-preview capture acceptable as evidence?

## Definition of done

A macOS implementer can open `appendix-inventory.json`, pick a `plucID`, read its spec and
fixtures, implement the layout without touching the Windows app or vendor files, and prove
parity with the attached screenshots and PDF page counts.
