# Additional 2.1.0 notice layouts

Implemented independent layouts for `01/TB-NSD`, `01/TB-BSTT-NNT` and
`01/TB-SSĐT`, from installed registry and template facts. No vendor XSLT,
CSS, JavaScript, image or font is redistributed. The exact source identities
and field mappings are recorded in `../notices/additional-2.1.0.json`.

Dedicated rendering requires unprefixed exact root and `PBan=2.1.0`:

| MSo | Root | Installed template | Fixture |
|---|---|---|---|
| `01/TB-NSD` | `TBao` | `TBao_108_TB_NSD.xslt` | `notice_01_tb_nsd.xml` |
| `01/TB-BSTT-NNT` | `TBao` | `TBao_107_TB_BSTT_NNT.xslt` | `notice_01_tb_bstt_nnt.xml` |
| `01/TB-SSĐT` | `TBTNhan` | `TBao_01_TB_SSDT.xslt` | `notice_01_tb_ssdt.xml` |

All template paths are below installed `data/xslt/XSLT 2.8.1/TBaoThue/xslt/`.
The registry is `data/DMucTbao.xml`; included mastheads are in
`../include/TBaoHeader.xsl` at lines 903–967 (SSĐT), 1247–1313 (BSTT-NNT),
and 1395–1453 (NSD). The registry's misleading shared TBao root does not
justify rendering each code as BSTT. In particular, the SSĐT template reads
`TBTNhan` paths; a `TBao` document with the same code remains structured data.

NSD repeats `DSLDo/LDo` records and reads the nested `LDo` field, including
both reasons in the synthetic fixture. Its effective timestamp comes from
`STBao/NTBao`, at midnight. BSTT-NNT repeats the same records in both a
five-column summary and six-column detail table; `TTTLieu` appears in the
second table only. SSĐT prints the original taxpayer notice date `NTBNNT`
in its body, independently from the issuing date in `STBao/NTBao`.

Each renderer preserves every unconsumed nonempty leaf in a clearly labelled
supplementary XML table, without assigning inferred labels. Signature subtrees
are excluded and no signature is claimed valid. HTML values are escaped;
there is no network access or added executable content.

The root agent executed the local MSXML oracle batch and recorded all three
successful transforms in
`../../evidence/oracle-batch-expanded-2026-10-23.json`. This agent inspected the
result index and source SHA-256 values. Oracle outputs remain in ignored `_re/`:

| Fixture | Exit | Output SHA-256 | Tables / rows / cells |
|---|---:|---|---|
| BSTT-NNT | 0 | `1111f7cae26d91512591e0c0d8d9fde0d95fae5971dca2e34add82e75a3e69af` | 5 / 14 / 44 |
| NSD | 0 | `52feb4cbb58dd11e088d5f00b5bfe2e0b666984b7f08d2f67ddeb3e15b26b863` | 4 / 8 / 13 |
| SSĐT | 0 | `d31b7240e73db440326463fe42f4d56e14932253ff64afb0e3e9d94501fe06e6` | 2 / 5 / 6 |

MSXML execution establishes the installed XSLT output for these fixtures; it
does not establish a Windows GUI capture or original PD4ML print result.
Those comparisons remain pending. The macOS build, focused tests and native
PDF execution are owned by the parent integration run; this report does not
claim those pending results. Five focused XCTest cases cover repeated rows,
layout selection boundaries, dates, extension preservation beyond 800 fields
and HTML escaping. `01/TB-TNĐT` and `01/TB-ĐKĐT` remain outside this batch.
