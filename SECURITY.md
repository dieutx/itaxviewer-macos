# Chính sách bảo mật

## Phiên bản được hỗ trợ

| Phiên bản | Trạng thái |
|---|---|
| Release mới nhất | Nhận bản vá bảo mật |
| Nhánh `main` | Đang phát triển, vẫn nhận báo cáo |
| Release cũ hơn | Chỉ xử lý theo khả năng; nên nâng cấp |

## Báo cáo lỗ hổng riêng tư

Không mở Issue/Discussion công khai cho lỗ hổng chưa được xử lý. Hãy dùng [GitHub Private Vulnerability Reporting](https://github.com/dieutx/itaxviewer-macos/security/advisories/new).

Trong báo cáo, vui lòng cung cấp:

- phiên bản app, phiên bản macOS và kiến trúc máy;
- loại tài liệu/root element cần để tái hiện;
- các bước tái hiện và tác động dự kiến;
- bản tái hiện tối thiểu bằng dữ liệu tổng hợp nếu thực sự cần.

**Không đính kèm hồ sơ thuế thật, dữ liệu người nộp thuế, private key hoặc chứng thư/chữ ký lấy từ tài liệu thật.** Nếu cần trao đổi dữ liệu để tái hiện, hãy chờ maintainer thống nhất một phương án an toàn trước.

Maintainer sẽ cố gắng xác nhận báo cáo trong vòng 7 ngày làm việc, trao đổi mức độ ảnh hưởng và phối hợp thời điểm công bố sau khi có bản vá. Không có cam kết bounty ở thời điểm hiện tại.

## Phạm vi đặc biệt của dự án

- Parser, WebView, export/print, đường dẫn tệp, cache và rò rỉ dữ liệu là các khu vực cần ưu tiên báo cáo.
- Việc chữ ký XML luôn hiển thị **“Chưa xác minh”** là giới hạn đã biết, không phải tuyên bố rằng chữ ký hợp lệ.
- Ứng dụng phải tiếp tục ngoại tuyến; mọi network request ngoài quy trình GitHub CI/release là thay đổi cần xem xét bảo mật.

Thiết kế và threat model chi tiết: [docs/security.md](docs/security.md).
