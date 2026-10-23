# 03 — Phụ lục (appendices)

Dùng cùng `00-MASTER.md`. Inventory: `docs/reverse-engineering/inventory/appendices.csv`.
Đây là **khoảng trống lớn nhất**: 210 phụ lục, chỉ 3 cái có layout.

## 1. Hiện trạng

| Trạng thái | Số lượng | Ghi chú |
|---|---:|---|
| Đã có layout | 3 | `PL_NQ43_GTGT`, `PL_NQ101_GTGT`, `PL_NQ142_GTGT` |
| P0 | 2 | `PL01_KHBS`, `PL01_1_KHBS` |
| P1 | 134 | GTGT/TNDN/TNCN/đăng ký/hộ kinh doanh/BCTC |
| P2 | 71 | phụ lục của tờ khai ít dùng |

Mỗi phụ lục có thể được dùng bởi nhiều tờ khai cha (`parentCodes` trong CSV). Khi capture,
chọn **tờ khai cha có nhiều dòng dữ liệu nhất** để thấy đủ cột.

## 2. P0 — bắt buộc (2 phụ lục)

### 2.1 `PL01_KHBS` — Phụ lục 01/KHBS (34 tờ khai cha)

Cấu trúc XML đã quan sát (từ file thật, đã ẩn danh):

```text
PL01_KHBS
  Header (maTKhai, tenTKhai, maGiaoDich, KyKKhaiThue, soLan, mst, tenNNT,
          mstDLyThue, tenDLyThue, soHDongDLyThue, ngayKyHDDLyThue)
  ma_DonViTien, ten_DonViTien
  Muc_A
    Muc_I
      Muc_1  (ChiTiet, tongCong_ct10)
      Muc_2  (DSachPLuc/BKePLuc/CTietPLuc/ChiTiet/ct7, tongCong_ct11)
      Muc_3  (ct3a_1, ct3a_2, ct3b)
    Muc_II (ChiTiet: ct2_ma, ct2_ten, ct3; tongCong_ct12)
    Muc_III (ChiTiet: ct2_ma, ct2_ten, ct3; tongCong_ct13)
  Muc_B
    Muc_I  (ct_1, ct_2_so, ct_2_ngay, ct_2_CQT_ma, ct_2_CQT_ten, ct_3_so, ct_3_ngay)
    Muc_II (ct_1, ct_2)
```

**Không được suy nhãn từ tên tag.** Cần capture để trả lời:

- [ ] Tiêu đề chính xác + căn cứ pháp lý (mẫu số in trên đầu trang).
- [ ] Khối `[01]–[04]` của Header: nhãn, thứ tự, nguồn.
- [ ] `Muc_A/Muc_I` in thành mấy mục con; `Muc_1/2/3` là bảng hay text?
- [ ] `ChiTiet` của `Muc_II`, `Muc_III`: cột `ct2_ma`, `ct2_ten`, `ct3`; tiêu đề cột;
      `ct2_ma` là mã chỉ tiêu hay số thứ tự?
- [ ] `tongCong_ct10/11/12/13`: tổng của bảng nào, công thức, nhãn `[10]`/`[12]`/`[13]`?
- [ ] `DSachPLuc`: in danh sách phụ lục con hay chỉ một dòng?
- [ ] `Muc_3` (`ct3a_1`, `ct3a_2`, `ct3b`): checkbox/số/text? Điều kiện hiện?
- [ ] `Muc_B/Muc_I`: bảng hay các dòng label/value? `ct_2_so`/`ct_2_ngay` là gì?
- [ ] `Muc_B/Muc_II`: `ct_1`, `ct_2` là số tiền hay số ngày?
- [ ] Thứ tự mục, ngắt trang trước `Muc_B`, empty state.
- [ ] PDF: số trang, orientation, lề, header lặp.
- [ ] Có chữ ký/footer riêng không.

Capture tối thiểu:

1. 01/GTGT khai bổ sung có đủ `Muc_A` và `Muc_B`.
2. Trường hợp `Muc_II`/`Muc_III` rỗng.
3. Trường hợp nhiều dòng `ChiTiet` (≥ 10).
4. File có số âm (nếu có).

Output: `appendices/PL01_KHBS.json`, `appendices/results/PL01_KHBS.md`,
`appendices/fixtures/pl01_khbs_*.xml`, evidence.

### 2.2 `PL01_1_KHBS` — Phụ lục 01-1/KHBS (12 tờ khai cha)

Cấu trúc đã quan sát:

```text
PL01_1_KHBS
  Header …
  Muc_A
    DSachHSo/BKeHSo (ma_HSo, ten_HSo, CTietHSo)
    TongCong (tongCong_7, tongCong_8, tongCong_9)
  Muc_B
    CTietTaiLieu (ma_TLieu, ten_TLieu)
```

Cần trả lời:

- [ ] Tiêu đề, căn cứ pháp lý, khối `[01]–[04]`.
- [ ] `BKeHSo` lặp thế nào; `CTietHSo` là chuỗi hay bảng con?
- [ ] Cột bảng hồ sơ: `ma_HSo`, `ten_HSo`, `CTietHSo` — nhãn chính xác.
- [ ] `TongCong` in 3 dòng `[7]`, `[8]`, `[9]` hay một bảng; công thức.
- [ ] `Muc_B/CTietTaiLieu`: bảng danh sách tài liệu, có lặp không?
- [ ] Empty state, page break, số trang.

Output: `appendices/PL01_1_KHBS.json` + results + 3 fixture.

## 3. P1 — 134 phụ lục, gom theo họ

Lấy danh sách đầy đủ từ `appendices.csv` (`wave=P1`). Các họ chính:

### 3.1 GTGT (ưu tiên cao)

`PL01_1_GTGT`, `PL01_2_GTGT`, `PL01_3_GTGT`, `PL01_4A_GTGT`, `PL01_4B_GTGT`,
`PL01_5_GTGT`, `PL01_6_GTGT`, `PL01_7_GTGT`,
`PL01_2_1_GTGT` … `PL01_2_9_GTGT`,
`PL_01_1_TD_GTGT`, `PL_01_2_TD_GTGT`, `PL_ND92_GTGT`, `PL_ND15_GTGT`,
`PL02_1_HT`, `Pluc_01_2_GTGT`, `Pluc_01_3_GTGT`, `Pluc_01_6_GTGT_CSSX`,
`Pluc_01_6_GTGT_DVVT`, `PL04_1_GTGT`.

Capture cùng tờ khai 01/GTGT/02/GTGT; ghi rõ phụ lục nào in kèm trang nào.

### 3.2 TNDN

`PL03_1A_TNDN` … `PL03_8_TNDN`, các biến thể `PLuc_03_*_TNDN`,
`PL01_1_TNDN`, `PL05_TNDN`, `Pluc_02_1_TNDN`.

### 3.3 TNCN

`PLuc_05_1_BK_QTT`, `PLuc_05_2_BK_QTT`, `PLuc_05_3_BK_QTT`,
`PLuc_02_1_BK_QTT_TNCN`, `PL05A_BK-TNCN`, `PL05B_BK-TNCN`,
`PLuc_06_BK-TNCN`, `Pluc_06_1_BK_TNCN`, `Pluc_06_2_BK_TNCN`,
`PL27MGT-TNCN`, `PL26MGT-TNCN`, `PL09-1_TNCN` … `PL09-4_TNCN`,
`Pluc_04_1_CNV_TNCN`, `Pluc_04_1_DTV_TNCN`, `PLuc-13BK-TNCN`.

### 3.4 Đăng ký thuế / khai lần đầu

`PL_01_*_DK_TCT`, `PL_02_01_DK_TCT` … `PL_06_01_DK_TCT`,
`PLuc_01_DK`, `PLuc_02_1_PL_DK`, `PLuc_04_PTHU_DK`, `PLuc_05_PTHU_DK`,
`PL_07_DKT`, `PL_01_1/2/3_TTDB`, `Pluc_01_1/2/3_TTDB`,
`PL_01_1/2/3_VTNN`.

### 3.5 Hộ kinh doanh / đặc thù

`PLuc_01_1_BK_CNKD`, `PLuc_01_1_PL_CNKD`, `PLuc_01_1_BK_CNKD_TMDT`,
`PLuc_HKD_CNKD`, `Pluc_01_BK_TTS`, `PLuc_02_BK_TTS`, `PLuc_CANHAN_TTS`,
`PL_01_XSDT`, `PL_02_XSDT`, `PL_GDLK2-01` … `PL_GDLK2-04`,
`PL_CDTK`, `Pluc_01_TT146`, `PL_ND114`, `PL_01/02/03/04_ND20`.

### 3.6 BCTC

`PL_LCTT`, `PL_LCTTGT`, `PL_LCTTTT`, `PL_KQHDSXKD`, `PL_KQHDXSKD`,
`PL_BCKQHD`, `PL_BCKQHDKD`, `PL_BCKQHDSXKD`, `PL_BCKQHDGND`, `PL_BCKQHDR`,
`PL_BCKQHDHN`, `PL_THVCSH`, `PL_THNV`, `PL_BCTHBDVCSH`, `PL_BCLCTT`,
`PL_BCDTK`, `PL_KQHD`, `PL_KQHDKD`.

## 4. P2 — 71 phụ lục còn lại

Xem `appendices.csv`, `wave=P2`. Chỉ làm khi corpus thực tế có; mỗi nhóm chọn 1 đại diện
theo template.

## 5. Quy trình capture phụ lục

1. Mở **tờ khai cha** trong iTax Viewer (không mở file phụ lục riêng), chọn kỳ/version
   tương ứng.
2. Chụp trang tờ khai + từng trang phụ lục (đánh số trang).
3. In PDF toàn bộ; ghi trang nào là phụ lục, có ngắt trang không.
4. So sánh với XML: xác định `PLuc/<id>` và path từng giá trị.
5. Đọc XSLT của phụ lục (nếu có) để lấy nhãn/công thức; không copy file.
6. Tạo fixture bằng cách sửa file thật đã ẩn danh hoặc dựng synthetic từ XSD.

## 6. Spec JSON cho phụ lục

Xem mục 6.3 của `00-MASTER.md`. Bắt buộc:

- `id`, `parentForms`, `title`, `formNumber`, `legalReference`
- `page`: size/margins/orientation
- `header`: label/source/format
- `sections`: mỗi mục có `kind` (`table`/`fields`/`prose`), `recordPath`, `columns`,
  `totals`, `emptyBehaviour`, `pageBreakBefore`
- `verifiedAgainst`
- `unknowns`

Với mỗi cột bảng phải ghi `label` chính thức + `source` (path tương đối trong record) +
`format` (`text`/`number`/`date`/`index`) + `align`.

## 7. Checklist riêng cho phụ lục

- [ ] Đúng mẫu số in trên đầu trang (có thể khác mã XML).
- [ ] Đúng thứ tự mục A/B/I/II/1/2.
- [ ] Đúng cột, thứ tự, canh lề, độ rộng tương đối.
- [ ] Dòng tổng có nhãn `[n]` đúng.
- [ ] Bảng rỗng vẫn in header + dòng tổng (hoặc ẩn đúng như bản gốc).
- [ ] Số âm/0/thập phân đúng.
- [ ] Ngắt trang trước mục lớn.
- [ ] Header/footer/số trang.
- [ ] Chữ ký/footer riêng của phụ lục.

## 8. Batch plan

| Batch | Nội dung |
|---|---|
| APP-0A | `PL01_KHBS` (đủ nhánh) |
| APP-0B | `PL01_1_KHBS` |
| APP-1A | 8 phụ lục GTGT chính (`PL01_1..7_GTGT`, `PL04_1_GTGT`) |
| APP-1B | `PL01_2_*_GTGT` |
| APP-1C | TNDN (`PL03_*`) |
| APP-1D | TNCN (`PLuc_05*`, `PL05A/B`, `PLuc_06*`) |
| APP-1E | Đăng ký (`PL_*_DK_TCT`, `PLuc_01_DK`, `TTDB`, `VTNN`) |
| APP-1F | Hộ kinh doanh + XSDT + GDLK + TT146 + ND20 |
| APP-1G | BCTC (`PL_LCTT*`, `PL_KQHD*`, `PL_BC*`) |

## 9. Handoff

```text
BATCH: APP-<...>
PHỤ LỤC: <id> — tờ khai cha <mã>/<version> — PDF <n> trang (trang <a-b>)
ĐÃ TẠO: appendices/<id>.json, appendices/results/<id>.md,
        appendices/fixtures/<id>_*.xml, evidence/appendices/<id>/*
PHÁT HIỆN: <cấu trúc mục, cột, công thức, khác biệt version>
UNKNOWNS: ...
```
