## Mục tiêu

<!-- Vấn đề nào được giải quyết? Liên kết Issue nếu có. -->

## Thay đổi chính

<!-- Liệt kê ngắn gọn thay đổi có ý nghĩa với người dùng hoặc maintainer. -->

## Kiểm thử đã chạy

<!-- Ghi lệnh và kết quả thực tế. Không đánh dấu mục bạn chưa chạy. -->

- [ ] `swift test`
- [ ] `python3 iTaxViewerMac/scripts/validate_fixtures.py`
- [ ] `python3 .github/scripts/check_public_safety.py`
- [ ] Build/launch app (nếu liên quan)
- [ ] Kiểm tra in/PDF native (nếu liên quan)
- [ ] Kiểm tra thủ công khác: <!-- mô tả -->

## Bằng chứng và giới hạn

<!-- Với renderer/form mapping, nêu mã + phiên bản + nguồn. Ghi rõ phần còn PENDING. -->

## Checklist an toàn

- [ ] Tôi không thêm hồ sơ thuế thật, dữ liệu nhận dạng, secret, private key hoặc chữ ký/chứng thư lấy từ tài liệu thật.
- [ ] Fixture/ảnh/PDF mới chỉ dùng dữ liệu tổng hợp hoặc đã được rà soát ẩn danh thủ công.
- [ ] Tôi không sao chép XSLT, CSS, font, icon, ảnh hoặc tài sản khác từ bộ cài iTax Viewer gốc.
- [ ] Tôi không đoán field mapping; mọi mapping/nhãn mới có nguồn truy vết.
- [ ] Tôi không làm yếu test và không ghi `PASS` cho thao tác chưa thực thi.
- [ ] Tôi không thêm upload, telemetry, analytics, cloud processing hoặc network entitlement.
- [ ] Trạng thái chữ ký vẫn là `.notVerified` nếu chưa có xác minh XMLDSig đầy đủ.
- [ ] Tôi đã cập nhật tài liệu/compatibility khi hành vi người dùng thay đổi.
- [ ] Tôi có quyền chia sẻ thay đổi và đồng ý phát hành phần đóng góp theo MIT License.
