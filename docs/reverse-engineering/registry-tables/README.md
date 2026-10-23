# Registry gốc — dump đầy đủ và đối chiếu

Sinh bằng [`../tools/extract_registries.py`](../tools/extract_registries.py):

```bash
python3 docs/reverse-engineering/tools/extract_registries.py \
  --data "C:/Program Files (x86)/iTax Viewer/data" \
  --out _re/registry \
  --csv docs/reverse-engineering/registry-tables/all-entries.csv
```

- [`all-entries.csv`](all-entries.csv): **1.917 dòng** — mọi entry của 16 registry, kèm
  `xslt`, `xsd`, số phụ lục.
- `_re/registry/*.json`: bản **lossless** từng registry (mọi attribute + phần tử con), không
  bị cắt như CSV.

## Vì sao phải làm lại

`documents/document-registry.csv` (bản cũ) có **1.512 dòng**, thiếu **405 dòng** so với
registry gốc — chủ yếu ở `DMucTKhai.xml` (1.149 entry nhưng chỉ 757 dòng được đưa vào CSV).
Nguyên nhân: bản cũ gộp theo cặp mã + phiên bản và bỏ các entry không dựng được khoá.

| Registry | Entry trong XML | Dòng trong CSV cũ |
|---|---:|---:|
| `DMucTKhai.xml` | 1.149 | 757 |
| `DMucTbao.xml` | 132 | 126 |
| `DMucHquanNew.xml` | 174 | 173 |
| `DMucHquan.xml` | 173 | 172 |
| `DMucHquan1.xml` | 170 | 170 |
| `DMucTBaoNtdt.xml` | 46 | 46 |
| `DMucTBaoNtdt22.xml` | 27 | 27 |
| `DMucTbao_InCDoi.xml` | 11 | 10 |
| `DMucHSoDky.xml` | 11 | 10 |
| `DMucCTu.xml` | 5 | 5 |
| `DMucBKeKDTT.xml` | 5 | 5 |
| `DMucTBaoKDTT.xml` | 5 | 2 |
| `DMucXNhanCTuNtdt.xml` | 4 | 4 |
| `DmucTSoatNtdt.xml` | 3 | 3 |
| `DMucDMuc.xml` | 1 | 1 |
| `DmucBtruNtdt.xml` | 1 | 1 |

Lưu ý: `DMucTKhai.xml` có 1.149 entry nhưng chỉ **410 mã `maTKhai`** khác nhau — nhiều entry
là biến thể theo `pbanTKhai`. Khi đếm "410 mã tờ khai" (tài liệu cũ) con số 410 là *số mã*, còn
số *entry* là 1.149.

## Trường trong CSV

`registry, kind, tag, maTKhai, pbanTKhai, viewMethod, loaiTKhai, kieuKyKKhai, orientation,
maTBao, pbanTBao, xslt, xsd, plucCount`

- `kind`: `declaration` / `notice` / `voucher` / `registration` / `catalog` / `customs`.
- `xslt`, `xsd`: đường dẫn tương đối trong bản cài (giữ nguyên dấu `\` của vendor).
- `DMucBKeKDTT.xml` có root `DMucBKeTDTT` (vendor viết thiếu chữ K) — vẫn map `notice`.

## Giới hạn

- Chưa chuẩn hoá `DSachPLuc` thành danh sách có cấu trúc; `plucCount` chỉ là số phần tử tách
  theo dấu `;`.
- `DMucHquan*.xml` (517 entry) là hải quan — ngoài phạm vi thuế nội địa, giữ nguyên để tham chiếu.
