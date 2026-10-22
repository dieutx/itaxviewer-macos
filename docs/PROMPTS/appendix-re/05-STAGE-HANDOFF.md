# Stage 5 — Handoff và tích hợp macOS

**Mục tiêu:** đội macOS có thể implement từ spec + fixture mà không cần mở Windows.

**Đầu ra:**

- `docs/reverse-engineering/APPENDIX_HANDOFF.md`
- danh sách file cần thêm;
- gợi ý code Swift + test;
- cập nhật `PROGRESS.md` + `progress.json` (status `handoff-done`).

**Điều kiện vào:** Stage 4 đã `fixture-done` cho ít nhất một ID ưu tiên.

---

## 5.1. Nội dung handoff

```markdown
# Appendix handoff

## Summary
- Inventory: N plucID, M thấy trong corpus
- Đã spec: …
- Còn thiếu: …

## Trạng thái từng ID
| plucID | Form | Version | Orientation | PDF pages | Rows | Status | Evidence |
|---|---|---|---|---|---|---|---|

## File cần thêm
- docs/reverse-engineering/appendices/<plucID>.json
- docs/reverse-engineering/appendices/<plucID>.md
- fixtures/...

## Tích hợp Swift
1. Thêm `Resources/appendix-specs.json`.
2. Decode `AppendixSpec` tương tự `FormSpec`.
3. Thêm `renderSpecAppendix` trong `HTMLRenderer`.
4. Giữ `renderRawAppendix` cho ID chưa có spec.
5. Test theo fixture.

## Unknown/blocker
- …

## Acceptance checklist
- [ ] ...
```

## 5.2. Gợi ý cấu trúc Swift

```swift
public struct AppendixSpec: Codable {
    public struct HeaderField: Codable {
        public let code: String
        public let label: String
        public let source: String
        public let format: String
    }
    public struct Column: Codable {
        public let key: String
        public let title: String
        public let source: String?
        public let format: String
        public let align: String
    }
    public struct Total: Codable {
        public let code: String?
        public let label: String
        public let source: String
        public let format: String
        public let formula: String?
    }
    public struct Section: Codable {
        public let id: String
        public let title: String
        public let kind: String
        public let recordPath: String?
        public let columns: [Column]?
        public let totals: [Total]?
        public let emptyBehaviour: String?
    }
    public let id: String
    public let title: String
    public let citation: String
    public let orientation: String
    public let sections: [Section]
}
```

Renderer:

- tìm spec theo `plucID`;
- nếu có: `renderSpecAppendix`;
- nếu không: `renderRawAppendix`;
- giữ warning rõ ràng cho ID chưa có spec.

## 5.3. Test gợi ý

```swift
func testAppendixSpecsDecode() throws {
    let specs = try AppendixRegistry.bundled()
    XCTAssertNotNil(specs.spec(for: "PL01_KHBS"))
}

func testPL01KHBSRows() throws {
    let (_, _, rendered) = try render("pl01_khbs_minimal")
    XCTAssertTrue(rendered.html.contains("Tổng cộng"))
    XCTAssertTrue(rendered.html.contains("[10]"))
}
```

## 5.4. Chạy kiểm tra trên macOS

```bash
cd iTaxViewerMac
swift test
python3 scripts/validate_fixtures.py
```

Nếu có PDF:

```bash
# dùng Chrome headless cho HTML/CSS pipeline
```

Ghi số trang, khổ giấy, orientation.

## 5.5. Acceptance

- [ ] `APPENDIX_HANDOFF.md` có bảng trạng thái + file list.
- [ ] Spec JSON validate được.
- [ ] Fixture + test name rõ ràng.
- [ ] Không có vendor asset/dữ liệu thật.
- [ ] `progress.json` cập nhật `handoff-done`.
- [ ] Ghi rõ phần nào đã `verified` và phần nào còn `pending`.
