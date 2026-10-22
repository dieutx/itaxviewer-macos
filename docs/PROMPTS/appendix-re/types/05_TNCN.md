# Type: phụ lục của 05/KK-TNCN và 05/QTT-TNCN

**Ưu tiên:** P1 (sau P0 KHBS)  
**Trạng thái:** chưa xác nhận hai form này có `PLuc` hay không.

## 1. Inventory trước

- [ ] Kiểm tra `DMucTKhai.xml` cho `maTKhai=394` (05/KK) và `953`/`395` (05/QTT).
- [ ] Quét corpus xem có `<PLuc>` không.
- [ ] Nếu không có: ghi `n/a` trong `progress.json` và không tạo spec.
- [ ] Nếu có: liệt kê `plucID`, cấu trúc, số bản ghi.

## 2. Nếu có phụ lục

Áp dụng cùng schema Stage 3. Cần xác định:

- tiêu đề, căn cứ pháp lý;
- khối `[01]`–`[04]`;
- bảng chi tiết (cột, mã, tổng);
- orientation;
- quan hệ với tờ khai chính (số liệu có kết xuất sang chỉ tiêu chính không).

## 3. Capture / fixture / test

Theo `02-STAGE-CAPTURE.md`, `03-STAGE-SPEC.md`, `04-STAGE-FIXTURES.md`.

Fixture gợi ý:

- `tncn_394_appendix_minimal.xml`
- `tncn_953_appendix_minimal.xml`

## 4. Kết quả

Ghi `results/<plucID>.md` hoặc `results/05_TNCN.md` nếu không có phụ lục (`n/a`).
