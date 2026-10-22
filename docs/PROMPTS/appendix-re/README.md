# Appendix reverse-engineering kit — hướng dẫn sử dụng

Bộ prompt này chia công việc RE phụ lục (`PLuc`) của iTax Viewer Windows thành **5 stage**
và **các nhóm loại phụ lục**. Mỗi stage có đầu vào, đầu ra, acceptance criteria và chỗ ghi
kết quả. Mục tiêu là để một agent làm việc có thể dừng giữa chừng, bàn giao và tiếp tục mà
không mất tiến độ.

## Cấu trúc

```text
docs/PROMPTS/
  WINDOWS_APPENDIX_RE.md          ← entry point (file này)
  appendix-re/
    README.md                     ← tổng quan + cách dùng + status
    00-RULES.md                   ← quy tắc chung, an toàn, evidence
    01-STAGE-INVENTORY.md         ← Stage 1: inventory registry + corpus
    02-STAGE-CAPTURE.md           ← Stage 2: chụp ảnh/PDF bản gốc
    03-STAGE-SPEC.md              ← Stage 3: viết spec JSON
    04-STAGE-FIXTURES.md          ← Stage 4: fixture ẩn danh
    05-STAGE-HANDOFF.md           ← Stage 5: bàn giao + tích hợp macOS
    types/
      PL01_KHBS.md
      PL01_1_KHBS.md
      BaoCaoTaiChinh.md
      NQ_GTGT.md                  ← 43/101/142/204, GTGT 2026
      05_TNCN.md                  ← 05/KK-TNCN, 05/QTT-TNCN
      OTHER.md                    ← quy trình cho mọi plucID còn lại
docs/reverse-engineering/appendices/
  PROGRESS.md                     ← bảng tiến độ cho người đọc
  progress.json                   ← tiến độ + kết quả dạng máy đọc
  RESULTS_TEMPLATE.md             ← mẫu ghi kết quả từng phụ lục
  results/                        ← kết quả thực tế, mỗi plucID một file
```

## Cách chạy

1. Đọc `00-RULES.md` và xác nhận môi trường.
2. Làm `01-STAGE-INVENTORY.md` → cập nhật `PROGRESS.md` + `progress.json`.
3. Chốt priority với operator.
4. Với từng `plucID` theo priority: mở file trong `types/`, làm lần lượt Stage 2 → 3 → 4.
5. Làm `05-STAGE-HANDOFF.md` cho các ID đã xong.
6. Sau mỗi stage: cập nhật **cả** `PROGRESS.md` và `progress.json`; ghi đường dẫn evidence.

Không chuyển stage khi stage trước còn `BLOCKED` hoặc `unknown` chưa được ghi lại.

## Trạng thái chuẩn

Dùng đúng các giá trị sau trong `progress.json`:

| Status | Nghĩa |
|---|---|
| `not-started` | chưa làm |
| `in-progress` | đang làm |
| `blocked` | thiếu app/mẫu/quyền, ghi rõ lý do |
| `captured` | đã có ảnh/PDF, chưa viết spec |
| `spec-done` | spec JSON đã validate |
| `fixture-done` | đã có fixture ẩn danh + test |
| `handoff-done` | đã bàn giao cho macOS |
| `implemented-macos` | clone đã render, chờ verify |
| `verified` | đã so ảnh/PDF với bản gốc, có bằng chứng |
| `n/a` | không áp dụng (ví dụ form không có phụ lục) |

## Kết quả cần lưu

Mỗi `plucID` có một file `results/<plucID>.md` theo mẫu `RESULTS_TEMPLATE.md`. Tối thiểu
phải có:

- app version + ngày capture;
- orientation + số trang PDF;
- số section, số dòng từng bảng;
- danh sách mã chỉ tiêu + công thức;
- ảnh/PDF đã chụp;
- test đã chạy (Swift/Python) và kết quả;
- `unknown`/`blocked` còn lại.

## Quy tắc bất di bất dịch

- Không copy XSLT/CSS/font/ảnh của hãng vào repo.
- Không commit dữ liệu người nộp thuế thật.
- Không đoán nhãn/mã/công thức.
- Chỉ ghi `PASS` khi đã thực sự chạy và so sánh.

Xem chi tiết ở `00-RULES.md`.
