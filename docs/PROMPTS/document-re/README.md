# Document RE kit — tất cả loại hồ sơ, không chỉ 01/GTGT

Bộ prompt này dành cho việc reverse-engineer **toàn bộ** các loại tài liệu mà iTax Viewer
Windows hiển thị, gồm:

- tờ khai thuế (declarations) và phụ lục;
- thông báo/văn bản của cơ quan thuế (notices);
- giấy nộp tiền/chứng từ (payment vouchers);
- hồ sơ đăng ký thuế (registration);
- danh mục (catalogs);
- hóa đơn điện tử (e-invoices);
- hồ sơ hải quan (customs);
- các loại khác mà `DocumentClassifier` nhận diện.

Mục tiêu: mỗi loại có **inventory, ảnh/PDF đối chiếu, spec JSON, fixture ẩn danh và tiến độ
được lưu lại**, để clone macOS render giống bản gốc.

## Cấu trúc

```text
docs/PROMPTS/
  WINDOWS_DOCUMENT_RE.md          ← entry point mới (dùng file này)
  document-re/
    README.md
    00-RULES.md
    01-STAGE-INVENTORY.md
    02-STAGE-CAPTURE.md
    03-STAGE-SPEC.md
    04-STAGE-FIXTURES.md
    05-STAGE-HANDOFF.md
    types/
      declarations.md
      notices.md
      payment-vouchers.md
      registration-catalog.md
      einvoices.md
      customs.md
      appendices.md               ← trỏ sang appendix-re/
  appendix-re/                    ← sub-kit chi tiết cho phụ lục
docs/reverse-engineering/documents/
  PROGRESS.md
  progress.json
  RESULTS_TEMPLATE.md
  results/
```

## Cách chạy

1. Đọc `00-RULES.md`.
2. Làm `01-STAGE-INVENTORY.md` cho **tất cả root types** và form codes.
3. Chốt priority theo loại tài liệu với operator.
4. Mở file trong `types/` tương ứng, làm Stage 2 → 3 → 4.
5. Phụ lục: dùng thêm `appendix-re/`.
6. Làm `05-STAGE-HANDOFF.md`.
7. Cập nhật `PROGRESS.md` + `progress.json` sau mỗi bước.

## Trạng thái

| Status | Nghĩa |
|---|---|
| `not-started` | chưa làm |
| `in-progress` | đang làm |
| `blocked` | thiếu app/mẫu/quyền |
| `captured` | có ảnh/PDF |
| `spec-done` | spec JSON validate |
| `fixture-done` | fixture + test |
| `handoff-done` | bàn giao macOS |
| `implemented-macos` | clone đã render |
| `verified` | đã so ảnh/PDF |
| `generic-only` | clone chỉ hiển thị bảng dữ liệu, chưa có layout gốc |
| `n/a` | không áp dụng |

## Nguyên tắc

- Không copy XSLT/CSS/font/ảnh của hãng.
- Không commit dữ liệu thật.
- Không đoán nhãn/mã/công thức.
- Chỉ ghi `verified` khi đã so ảnh/PDF thật.
