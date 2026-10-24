# Expanded layout evidence — 2026-10-23

Implemented independent, exact-version layouts for TT89 2002/2003/2004 (3.0.9),
BCTC 701/702 (2.3.5), BCTC 1254 (2.9.0), and notices NSD/BSTT-NNT/SSĐT (2.1.0).
Specs record selected source paths and SHA-256. No vendor asset or real taxpayer XML
was added. New unknown fields are preserved in explicit source-data sections.

Executed on Windows:

```
py -X utf8 iTaxViewerMac/scripts/import_static_specs.py
py -X utf8 iTaxViewerMac/scripts/validate_fixtures.py
py -X utf8 docs/reverse-engineering/tools/test_extract_xslt_specs.py
py -X utf8 docs/reverse-engineering/tools/extract_xslt_specs.py --xslt-root "C:/Program Files (x86)/iTax Viewer/data/xslt" --out _re/extractor-14 --verify iTaxViewerMac/Sources/iTaxViewerCore/Resources/form-specs.json
py -X utf8 docs/reverse-engineering/tools/oracle_batch.py
```

The mapping harness passed. Five extractor regressions passed. Exact-source comparison
passed 14/14 reviewed specs with unchanged label/code/column assertions. Bulk extraction
has 15,469 rows and 3,448 indicators, including 253 outside-table fields. Seven malformed
vendor templates remain recorded parse errors; extracted counts are not app coverage.

Oracle batch: 27 rendered, one transform failure (`gnt_chungtu`, minimal old voucher),
one missing registry selection (`tbao_107_bstt`), one DTD rejected. The command correctly
returns exit 1 for that retained failure. Public evidence contains counts/hashes/status
only in [the batch index](../../evidence/oracle-batch-expanded-2026-10-23.json).
Raw vendor output stays in ignored `_re/`.

Distinct mapped amounts present in the selected MSXML output: TT89 8/8, 10/10 and 4/4;
BCTC 68/68, 36/36 and 132/132. All three added notices transformed successfully. These
are content-presence checks, not cell positions, Windows GUI execution or PD4ML prints.

The native run and downloadable artifact are recorded in `COMPATIBILITY.md`. Remaining
work includes Windows visual comparisons, row/page-break parity, other registry versions,
official appendices, Finder/drag-drop manual checks, printer hardware, Intel execution of
this binary, signing/notarization and actual cryptographic XMLDSig verification.
