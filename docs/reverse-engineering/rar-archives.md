# 10 tệp `.rar` trong `data/xslt` — đã mở, còn gì đáng chú ý

Cập nhật 2026-10-23. Đóng gap #8 trong [`GAP-REGISTER.md`](GAP-REGISTER.md).

## Cách mở

Không cần `unrar`: **7-Zip 26.05** đọc được cả RAR (cũ) và RAR5.

```bash
cd "/c/Program Files (x86)/iTax Viewer/data/xslt"
find . -name "*.rar" -print0 | while IFS= read -r -d '' f; do
  slug=$(echo "${f#./}" | sed 's#/#__#g; s#\.rar$##')
  mkdir -p "/c/path/to/itaxviewer-macos/_re/rar/$slug"
  "/c/Program Files/7-Zip/7z.exe" x -y -o"/c/path/to/itaxviewer-macos/_re/rar/$slug" "$f"
done
```

Kết quả: **10 tệp → 145 tệp** (2,6 MB) trong `_re/rar/` (gitignored). Không tệp nào lỗi CRC.

## Từng archive

| Archive | Tệp | XSLT/XSL | Nội dung không có ở bản nào trên đĩa |
|---|---:|---:|---:|
| `XSLT 2.0.9/TBaoKDTT/common/common_trcthayHamDocSoTien.rar` | 1 | 1 | 1 |
| `XSLT 2.0.9/TBaoKDTT/include/LenhHoanHeader.rar` | 1 | 1 | 0 |
| `XSLT 2.0.9/TBaoKDTT/xslt/TBao_07_QLN.rar` | 1 | 1 | 1 |
| `XSLT 2.0.9/TBaoKDTT_InCDoi/include/LenhHoanHeader.rar` | 1 | 1 | 1 |
| `XSLT 2.0.9/TBaoKDTT_InCDoi/xslt/LenhHoan.rar` | 1 | 1 | 1 |
| `XSLT 2.0.9/TBaoKDTT_InCDoi/xslt/LenhHoan_in.rar` | 1 | 1 | 0 |
| `XSLT 2.0.9/TBaoKDTT_InCDoi/xslt/TBao_07_QLN.rar` | 1 | 1 | 0 |
| `XSLT 2.2.2/TKhaiThue/xslt/HoanThue.rar` | 1 | 1 | 1 |
| `XSLT 2.2.3/XSLT 2.5.2/TKhaiThue.rar` | 17 | 17 | 3 |
| `XSLT 2.8.4/TKhaiThue/xslt.rar` | 120 | 110 | 2 |

Tổng: 135 tệp XSLT/XSL, trong đó **125 tệp trùng nội dung (SHA-256) với một tệp bất kỳ trên đĩa**,
**10 tệp là duy nhất**.

## 10 tệp duy nhất

| Tệp | Kích thước | Từ archive | Ghi chú |
|---|---:|---|---|
| `common.xsl` | 150.527 B | 2.0.9/TBaoKDTT/common | bản "trước khi thay hàm đọc số tiền" |
| `TBao_07_QLN.xslt` | 12.698 B | 2.0.9/TBaoKDTT/xslt | thông báo 07/QLN |
| `LenhHoanHeader.xsl` | 3.230 B | 2.0.9/TBaoKDTT_InCDoi/include | header lệnh hoàn |
| `LenhHoan.xslt` | 40.491 B | 2.0.9/TBaoKDTT_InCDoi/xslt | lệnh hoàn (bản in cứng) |
| `TKhai_01_DNHT.xslt` | 10.172 B | 2.2.2/TKhaiThue/xslt | 01/DNHT |
| `TKhaiHeader.xsl` | 464.572 B | 2.2.3/XSLT 2.5.2/TKhaiThue | header tờ khai bản 2.2.3 |
| `Pluc_04_1_CNV_TNCN.xslt` | 11.400 B | 2.2.3/XSLT 2.5.2/TKhaiThue | phụ lục 04-1/CNV-TNCN |
| `TKhai_04_CNV_TNCN.xslt` | 9.607 B | 2.2.3/XSLT 2.5.2/TKhaiThue | 04/CNV-TNCN |
| `TKhai_01_CNKD_TT40.xslt` | 14.094 B | 2.8.4/TKhaiThue/xslt | **01/CNKD theo TT40 (2025)** — mới nhất |
| `PLuc_04_1_DK_TCT_BK01.xslt` | 3.800 B | 2.8.4/TKhaiThue/xslt | phụ lục đăng ký |

Hai tệp cuối là mẫu **mới hơn mọi bản trên đĩa** (TT40/2025). Nếu clone cần hỗ trợ 01/CNKD
theo TT40 thì đây là nguồn duy nhất hiện có trên máy.

## Điều chỉnh nhận thức quan trọng

`XSLT 2.8.4/TKhaiThue/` trên đĩa có **53** tệp XSLT, còn `xslt.rar` cùng thư mục có **110**.
Nói cách khác:

- Thư mục `data/xslt/XSLT x.y.z/` là **lớp thay đổi** của bản phát hành đó, không phải cây đầy đủ
  (2.9.4 chỉ 6 tệp, 3.0.9 có 70 tệp).
- `.rar` đi kèm là **cây đầy đủ tại thời điểm đóng gói**.

Vì vậy muốn dựng "template hiệu dụng" cho một `pbanTKhai` phải **ghép lớp** (gap #11,
`TOOLING.md` mục 3). Bản trích `xslt-specs` hiện tại đọc trên đĩa nên **không** thấy các mẫu chỉ
có trong RAR.

## Không làm

- Không copy các tệp này vào repo hay vào app macOS (asset của vendor).
- Không sửa nội dung RAR để "cho hợp lệ"; nếu mẫu hỏng XML là lỗi vendor (gap #9), ghi nhận.
