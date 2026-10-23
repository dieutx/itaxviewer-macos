# Continuation handoff

Read `AGENTS.md`, `docs/MACOS_HANDOFF.md`, `README.md`, `COMPATIBILITY.md` and
`GAP-REGISTER.md` first. Work on the current checkout; do not assume an older branch.

The Windows installation is read-only. Do not copy vendor assets or real taxpayer XML.
Raw transforms, decompiled sources and extracted archives stay in gitignored `_re/`.
The installed macOS viewer must remain offline and signatures remain `.notVerified`.

Completed groundwork: `oracle_batch.py`, `html_diff.py`, registry reference resolution,
outside-table indicator extraction, pinned template paths/hashes and synthetic regression
tests. The expanded fourteen-spec extraction comparison passed 14/14. Code 864/2.9.3
uses `TKhai_05_KK_TNCN_TT80.xslt` and flat fields; the older nested
`TKhai_TNCN_05KK.xslt` is a different registry selection. Do not regress that correction.

Use `COMPATIBILITY.md` for the latest executed CI run and remaining gaps. Windows can
orchestrate macOS builds with `iTaxViewerMac/scripts/Build-MacOS.ps1`; Swift/AppKit tests
cannot execute locally on Windows. CI opens every safe bundled fixture in the actual
app and separately exports PDFs through native WebKit/AppKit, then renders every page
through PDFKit. This proves those checks only, not Finder gestures, hardware printing,
Intel runtime, notarization or full Windows visual parity.

Before adding another layout, select the exact registry version, pin source SHA-256,
record factual labels/paths in a reviewed spec, create synthetic fixtures with distinct
values, compare with the Windows oracle and execute macOS tests/PDF checks. Preserve
unknown fields explicitly. Do not weaken tests or call extracted template counts app
coverage. Read the matching prompt in `docs/PROMPTS/windows-re/` before new forms.

Remaining priorities include visual/page-break parity, unsupported versions and forms,
official appendix layouts, XMLDSig verification and signed/notarized distribution.
