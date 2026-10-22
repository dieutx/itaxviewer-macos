# Test Data

This folder contains data for exercising the macOS viewer. It has two kinds of samples:

```
test-data/
├── declarations/            synthetic declarations (priority forms)
│   ├── gtgt_842_return.xml          01/GTGT  (maTKhai 842, v2.8.3)
│   ├── tncn_394_05kk_tt92.xml       05/KK-TNCN (394, v2.1.6)
│   ├── tncn_953_05qtt.xml           05/QTT-TNCN (953, v2.9.3)
│   └── tndn_892_03tndn_v2.9.4.xml   03/TNDN (892, v2.9.4)
└── anonymized/
    ├── gnt/                 real payment-voucher structure, redacted
    │   ├── sample-01.xml … sample-03.xml
    │   └── manifest.json
    └── notices/             real tax-authority notice structure, redacted
        ├── sample-01.xml, sample-02.xml
        └── manifest.json
```

## Declarations

These are the same anonymised/synthetic fixtures used by `swift test`. They contain no real
taxpayer data. They cover the four forms with a full renderer.

## Anonymised real-structure samples

`anonymized/gnt` and `anonymized/notices` were produced from real GNT/notice XML files with
`scripts/anonymize_samples.py`. The original files are **not** in this repository and never
will be.

Redacted:

- taxpayer/company names, addresses, wards, districts, provinces;
- tax codes (`MST_*`, `maNNhan`, `maCQT`);
- bank account numbers;
- document numbers/IDs (`SO_GNT`, `SO_CTU`, `ID_CTU`, `soTBao`, `maGiaoDichDTu`, …);
- amounts (replaced by `1000000`);
- email, hotline, URLs;
- all `ds:Signature` elements (signatures removed, not forged).

Preserved: root elements, form/voucher codes (`MA_CTU`, `maTBao`, `pbanTBao`,
`PBAN_TLIEU_XML`), dates, structure and table rows. This is enough to exercise parsing,
classification, layout and print/PDF without exposing taxpayer identity.

`manifest.json` records how many signatures were removed and which tags were redacted. It
does not contain source file names, source paths or source hashes.

## How to use on macOS

```bash
cd iTaxViewerMac

# classification report, no taxpayer values printed
python3 scripts/validate_directory.py ../test-data

# through the real Swift core
ITAX_FIXTURE_DIR=../test-data swift test --filter ExternalFixturesTests

# or open them in the app
open build/iTaxViewerMac.app
# then ⌘O and choose test-data/declarations or test-data/anonymized
```

## Re-running the anonymiser

```bash
python3 scripts/anonymize_samples.py \
  --input  /path/to/real/xml \
  --output /tmp/anonymized \
  --limit  5
```

Review the output before committing. Never commit the input directory. `samples/`,
`itax-samples/`, `external-fixtures/` and `*.local.xml` are gitignored for this reason.

## Legal note

The anonymised files are test fixtures, not valid tax documents. They must not be used for
filing, legal evidence or signature validation.
