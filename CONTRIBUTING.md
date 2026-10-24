# Đóng góp cho iTax Viewer cho macOS

Cảm ơn bạn muốn giúp dự án tốt hơn. Đóng góp có thể là báo lỗi, xác minh một biểu mẫu, cải thiện tài liệu, viết test hoặc gửi code.

## Trước khi bắt đầu

- Dùng [Discussions](https://github.com/dieutx/itaxviewer-macos/discussions) cho câu hỏi sử dụng và trao đổi ý tưởng ban đầu.
- Dùng đúng [mẫu Issue](https://github.com/dieutx/itaxviewer-macos/issues/new/choose) cho lỗi, tính năng hoặc biểu mẫu mới.
- Với thay đổi lớn, hãy mở Issue trước để thống nhất phạm vi và nguồn bằng chứng.
- Không báo công khai lỗ hổng bảo mật; làm theo [SECURITY.md](SECURITY.md).

## Quy tắc dữ liệu và bản quyền

Đây là yêu cầu bắt buộc cho mọi Issue, Discussion và Pull Request:

1. **Không gửi hồ sơ thuế thật** hoặc dữ liệu có thể nhận dạng người nộp thuế: tên, MST, địa chỉ, số tài khoản, số hồ sơ, số điện thoại, email, chữ ký/chứng thư số.
2. Chỉ dùng fixture tổng hợp hoặc bản sao đã ẩn danh, với MST `0000000000`, tên/địa chỉ giả và chữ ký đã xóa. Công cụ `iTaxViewerMac/scripts/anonymize_samples.py` chỉ là bước hỗ trợ; luôn rà soát đầu ra thủ công.
3. Không đưa XSLT, CSS, font, icon, ảnh hoặc tài nguyên khác từ bộ cài iTax Viewer gốc vào repo.
4. Không đoán field mapping. Mọi nhãn/chỉ tiêu phải truy được về `form-specs.json`, tài liệu reverse-engineering đã ghi nhận hoặc biểu mẫu công khai chính thức có dẫn nguồn.
5. Không tuyên bố chữ ký số hợp lệ. Trạng thái phải giữ `.notVerified` cho đến khi có xác minh XMLDSig đầy đủ.
6. Không thêm upload, telemetry, analytics, cloud processing hoặc network entitlement. Ứng dụng xem tài liệu phải tiếp tục hoạt động ngoại tuyến.

## Chuẩn bị môi trường

- macOS 13+
- Xcode 15+ / Swift 5.9+
- Python 3.10+

```bash
git clone https://github.com/dieutx/itaxviewer-macos.git
cd itaxviewer-macos/iTaxViewerMac
swift test
python3 scripts/validate_fixtures.py
```

Đọc thêm [docs/MACOS_HANDOFF.md](docs/MACOS_HANDOFF.md), [COMPATIBILITY.md](COMPATIBILITY.md) và `AGENTS.md` trước khi thay đổi renderer hoặc pipeline in/PDF.

## Quy trình đề xuất

1. Fork repo và tạo branch ngắn gọn từ `main`, ví dụ `fix/pdf-page-range` hoặc `feat/form-864`.
2. Giữ commit tập trung vào một vấn đề, với thông điệp mô tả rõ kết quả.
3. Thêm hoặc cập nhật test cho hành vi thay đổi; không xóa hay làm yếu assertion để CI qua.
4. Chạy các kiểm tra phù hợp bên dưới.
5. Mở Pull Request và điền đầy đủ checklist, bằng chứng và giới hạn còn lại.

### Kiểm tra tối thiểu

```bash
cd iTaxViewerMac
swift test
python3 scripts/validate_fixtures.py
python3 ../.github/scripts/check_public_safety.py
```

Nếu thay đổi app bundle, renderer hoặc in/PDF:

```bash
ITAX_FIXTURE_DIR=../test-data swift test --filter ExternalFixturesTests
scripts/build_app.sh --universal --dmg
bash scripts/run_app_qa.sh
python3 scripts/run_native_qa.py
```

Chỉ ghi `PASS` trong `COMPATIBILITY.md` cho thao tác bạn thực sự đã chạy. Kiểm tra thủ công chưa làm phải ghi `PENDING`.

## Thêm hoặc sửa biểu mẫu

- Đọc `docs/reverse-engineering/COVERAGE-REVIEW.md` và prompt tương ứng trong `docs/PROMPTS/windows-re/`.
- Ghi rõ mã biểu mẫu, phiên bản XML, root element, nguồn nhãn/chỉ tiêu và hành vi fallback.
- Thêm fixture tổng hợp tối thiểu, test classification/mapping/rendering và ghi provenance.
- Phiên bản chưa được rà soát phải dùng structured view có cảnh báo, không được gắn nhãn “hỗ trợ đầy đủ”.
- Ảnh/PDF bằng chứng chỉ được commit khi chắc chắn không chứa dữ liệu thật hoặc metadata nhạy cảm.

## Tiêu chí Pull Request

Một PR sẵn sàng review khi:

- CI và kiểm tra cục bộ liên quan đều qua;
- thay đổi có test hoặc giải thích hợp lý vì sao không cần test;
- không có secret, dữ liệu người nộp thuế hoặc tài sản vendor;
- tài liệu/compatibility được cập nhật đúng với kết quả đã thực thi;
- ảnh chụp dùng dữ liệu tổng hợp và có mô tả thay thế (`alt text`);
- PR tập trung, không trộn refactor không liên quan.

Mọi đóng góp được gửi với giả định người đóng góp có quyền chia sẻ và đồng ý cấp phép phần đóng góp theo [MIT License](LICENSE).
