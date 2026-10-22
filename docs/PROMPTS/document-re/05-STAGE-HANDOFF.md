# Stage 5 — Handoff cho macOS

**Mục tiêu:** đội macOS implement từ spec + fixture mà không cần Windows.

**Đầu ra:** `docs/reverse-engineering/DOCUMENT_HANDOFF.md`, cập nhật `progress.json`
(`handoff-done`).

---

## 5.1. Nội dung handoff

```markdown
# Document rendering handoff

## Inventory
- Declarations: …
- Notices: …
- Payment vouchers: …
- Registration/catalog/e-invoice/customs: …
- Appendices: …

## Status
| kind | id | spec | fixtures | evidence | status |
|---|---|---|---|---|---|

## Files
- documents/<kind>/<id>.json
- documents/fixtures/...
- evidence/documents/...

## Integration
1. Thêm `document-specs.json` hoặc mở rộng registry.
2. Decode `DocumentSpec` theo `kind`.
3. Renderer: `renderNotice`, `renderVoucher`, `renderSpecDocument`.
4. Giữ fallback structured table cho kind chưa có spec.
5. Test theo fixture.

## Unknown/blockers
- …
```

## 5.2. Gợi ý kiến trúc Swift

```swift
enum DocumentSpecKind: String, Codable {
    case declaration, notice, paymentVoucher, registration, catalog, eInvoice, customs
}

struct DocumentSpec: Codable {
    let id: String
    let kind: DocumentSpecKind
    let root: String
    let detect: [String: String]
    let title: String
    let orientation: String
    let headerFields: [HeaderField]
    let sections: [Section]
}
```

Renderer:

- declaration: dùng `FormSpec` hiện có + appendix specs;
- notice: `renderNoticeSpec`;
- voucher: `renderVoucherSpec`;
- kind khác: `renderStructured` fallback.

## 5.3. Test/validation

```bash
cd iTaxViewerMac
swift test
python3 scripts/validate_fixtures.py
```

PDF: dùng Chrome headless cho HTML/CSS; ghi page count/orientation.

## 5.4. Acceptance

- [ ] `DOCUMENT_HANDOFF.md` có bảng trạng thái + file list.
- [ ] Spec JSON validate.
- [ ] Fixture + test name rõ.
- [ ] Không vendor asset/dữ liệu thật.
- [ ] `progress.json` cập nhật `handoff-done`.
- [ ] Ghi rõ `verified`/`pending`.
