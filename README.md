# iTax Viewer cho macOS

Ứng dụng đọc hồ sơ thuế XML trên Mac, chạy hoàn toàn ngoại tuyến, hỗ trợ Apple Silicon và Intel.
Đây là dự án độc lập, **không phải phần mềm chính thức của cơ quan thuế**.

## Tải và sử dụng

1. Tải tệp **DMG** tại [bản phát hành mới nhất](https://github.com/dieutx/itaxviewer-macos/releases/latest).
2. Mở DMG, kéo ứng dụng vào thư mục **Applications**.
3. Mở ứng dụng, nhấn `⌘O` để chọn hồ sơ XML.

Yêu cầu **macOS 13 trở lên**. Bản hiện tại chưa có chữ ký Developer ID và chưa được Apple notarize,
nên macOS có thể chặn khi mở lần đầu. Chỉ mở khi bạn tin cậy nguồn tải; xem mục **Quyền riêng tư & Bảo mật** trong Cài đặt hệ thống.

| Thao tác | Phím tắt |
|---|---|
| Mở XML | `⌘O` |
| In | `⌘P` |
| Xuất PDF | `⌘S` |
| Phóng to / thu nhỏ | `⌘+` / `⌘−` |
| Xem thông tin hồ sơ | `⌘I` |
| Xem thông tin chữ ký | `⇧⌘Y` |

## Hỗ trợ những gì?

- Xem tờ khai GTGT, TNCN, TNDN; một số báo cáo tài chính, thông báo, giấy nộp tiền và phụ lục.
- Nhận diện 410 mã biểu mẫu; 14 bố cục tờ khai/báo cáo đã được rà soát, kèm bố cục thông báo và phụ lục.
- In và xuất PDF nhiều trang A4. Mẫu hoặc phiên bản chưa có bố cục riêng được hiển thị dưới dạng bảng dữ liệu.
- Không tải hồ sơ lên mạng, không thu thập dữ liệu, không tự kiểm tra cập nhật.

**Giới hạn:** một số bảng còn bị ngắt hàng hoặc thiếu tiêu đề khi sang trang; bố cục chưa hoàn toàn giống bản Windows.
Chữ ký số hiện chỉ hiển thị thông tin, **chưa xác minh tính hợp lệ**.

## Kết quả kiểm thử

Đã chạy trên macOS 14 Apple Silicon và macOS 15 Intel: mỗi máy **98 test đạt, 1 test tùy chọn bỏ qua**;
mở đủ 29 hồ sơ mẫu và xuất 29 PDF, tổng 55 trang A4. Thao tác Finder, kéo thả và máy in thật còn cần kiểm tra thủ công.

Chi tiết mẫu/phiên bản và bằng chứng thực thi: [COMPATIBILITY.md](COMPATIBILITY.md).

## Tự build

Cần Xcode 15+ và Swift 5.9+ trên Mac:

```bash
cd iTaxViewerMac
swift test
scripts/build_app.sh --universal --dmg
open build/iTaxViewerMac.app
```

Từ Windows, có thể yêu cầu build qua GitHub Actions:

```powershell
powershell -File iTaxViewerMac/scripts/Build-MacOS.ps1 -Ref main
```

[Hướng dẫn phát triển](docs/MACOS_HANDOFF.md) · [Tài liệu phân tích tương thích](docs/reverse-engineering/)

Không đưa hồ sơ thuế thật vào Git. Dự án không đóng gói XSLT, CSS, phông chữ hay biểu tượng của phần mềm gốc.