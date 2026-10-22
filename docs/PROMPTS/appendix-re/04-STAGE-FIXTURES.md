# Stage 4 — Fixture ẩn danh và test

**Mục tiêu:** có file mẫu nhỏ, an toàn, đủ bao phủ case biên; dùng được trong XCTest và
Python harness.

**Đầu ra:**

- `docs/reverse-engineering/appendices/fixtures/<plucID>-*.xml`
- test Swift/Python tương ứng;
- `results/<plucID>.md` ghi kết quả;
- cập nhật `PROGRESS.md` + `progress.json` (status `fixture-done`).

**Điều kiện vào:** Stage 3 đã `spec-done`.

---

## 4.1. Quy tắc ẩn danh

Bắt buộc thay:

- [ ] `tenNNT`, `tenDLyThue`, `ten_HSo`, `ten_TLieu` → tên mẫu.
- [ ] `mst`, `mstDLyThue` → `0000000000`.
- [ ] `dchiNNT`, `tenXaNNT`, `tenHuyenNNT`, `tenTinhNNT` → địa chỉ mẫu.
- [ ] `dthoaiNNT`, `faxNNT`, `emailNNT` → `0000000000` / `mau@example.invalid`.
- [ ] số tài khoản/ngân hàng → `000000000`.
- [ ] số hóa đơn/chứng từ/hợp đồng → dãy `000001`, `000002`, …
- [ ] tên hàng hóa/dịch vụ thật → `Hàng hóa mẫu A/B/…`.
- [ ] số tiền thật → giá trị nhỏ, có case âm.
- [ ] chữ ký/X509 → xóa hoặc dùng fixture `signed_demo.xml` riêng.
- [ ] metadata/tên file → không chứa MST/tên thật.

Kiểm tra tự động:

```powershell
Select-String -Path ".\fixtures\*.xml" -Pattern "mst|tenNNT|dchiNNT|email|dthoai|soTK|ten_HSo"
```

Mọi match phải là dữ liệu giả; nếu không, sửa.

## 4.2. Ma trận fixture

| Fixture | Nội dung | Mục đích |
|---|---|---|
| `<id>-minimal.xml` | 1–2 dòng/section | nhãn, mã, thứ tự cột |
| `<id>-empty.xml` | section rỗng | hành vi empty |
| `<id>-negative.xml` | số âm, chênh lệch âm | ngoặc đơn |
| `<id>-decimal.xml` | 10,5 / 8 | dấu phẩy |
| `<id>-large.xml` | ≥ 200 dòng | phân trang, không cắt |
| `<id>-multi.xml` | 2–3 `<PLuc>` | thứ tự, page break |
| `<id>-v<version>.xml` | version khác | override layout |

Không cần tạo đủ mọi file cho mọi ID; tối thiểu `minimal` + một case biên + `large` cho ID
có bảng dài.

## 4.3. Tên file và vị trí

Đặt trong repo macOS:

```text
iTaxViewerMac/Tests/iTaxViewerCoreTests/Fixtures/
  pl01_khbs_minimal.xml
  pl01_khbs_negative.xml
  pl01_khbs_large.xml
```

Hoặc giữ trong `docs/reverse-engineering/appendices/fixtures/` và copy sang test bundle khi
tích hợp. Ghi rõ trong handoff.

## 4.4. Test tối thiểu

Swift:

```swift
func testPL01KHBSLayout() throws {
    let (_, _, rendered) = try render("pl01_khbs_minimal")
    XCTAssertTrue(rendered.html.contains("I. …"))
    XCTAssertTrue(rendered.html.contains("[10]"))
    XCTAssertFalse(rendered.html.contains("Muc_A/Muc_I/Muc_1/ChiTiet"))
}
```

Bắt buộc:

- [ ] tiêu đề + căn cứ pháp lý;
- [ ] đủ section đúng thứ tự;
- [ ] đủ mã chỉ tiêu;
- [ ] tổng + công thức;
- [ ] số âm/thập phân;
- [ ] section rỗng;
- [ ] ≥ 200 dòng không bị cắt;
- [ ] multi-PLuc;
- [ ] không còn raw path cho ID đã có spec.

## 4.5. Chạy test

Trên macOS:

```bash
cd iTaxViewerMac
swift test --filter PL01KHBS
```

Trên Windows (nếu chỉ có Python):

```powershell
python validate_appendix_fixture.py fixtures\pl01_khbs_minimal.xml
```

Nếu chưa có renderer, chỉ cần validate XML + spec mapping (mọi `source` tồn tại).

## 4.6. Acceptance

- [ ] Fixture parse được bằng XML parser.
- [ ] Không có dữ liệu thật.
- [ ] Có ít nhất minimal + một case biên.
- [ ] Test chạy và pass (hoặc ghi rõ `BLOCKED` nếu chưa có renderer).
- [ ] `results/<plucID>.md` ghi test name + kết quả.
- [ ] `progress.json` cập nhật `fixture-done`.
