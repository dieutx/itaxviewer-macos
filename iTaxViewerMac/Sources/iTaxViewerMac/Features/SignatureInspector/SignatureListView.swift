import SwiftUI
import iTaxViewerCore

struct SignatureListView: View {
    let document: OpenDocument
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Chữ ký điện tử")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Đóng") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    verificationBanner
                    if document.document.signatures.isEmpty {
                        ContentUnavailableViewCompat(
                            title: "Không có chữ ký điện tử",
                            message: "Tệp XML không chứa phần tử ds:Signature."
                        )
                    } else {
                        ForEach(document.document.signatures.indices, id: \.self) { index in
                            signatureCard(index: index + 1,
                                          signature: document.document.signatures[index])
                        }
                    }
                    disclaimer
                }
                .padding(20)
            }
        }
        .frame(width: 680, height: 620)
    }

    private var verificationBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 3) {
                Text("Chưa xác minh chữ ký (Not verified)")
                    .font(.headline)
                Text("Ứng dụng đọc và hiển thị cấu trúc chữ ký cùng chứng thư số, nhưng chưa thực hiện kiểm tra mật mã XMLDSig (C14N, digest, SignatureValue) và không kiểm tra thu hồi trực tuyến. Không kết luận tài liệu là hợp lệ.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
    }

    private func signatureCard(index: Int, signature: SignatureInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Chữ ký #\(index)")
                    .font(.headline)
                Spacer()
                Text(signature.status.rawValue)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.15), in: Capsule())
            }
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 14, verticalSpacing: 6) {
                detail("Người ký (CN)", signature.signerName)
                detail("Nhà cấp chứng thư", signature.issuerName)
                detail("Số sê-ri", signature.serialNumber)
                detail("Hiệu lực", signature.validityText)
                detail("Tin cậy (macOS)", signature.certificateTrust.rawValue)
                detail("Thời điểm ký", signature.timestamp ?? signature.signingTime ?? "—")
                detail("Phương thức chữ ký", signature.signatureMethod ?? "—")
                detail("Phương thức băm", signature.digestMethod ?? "—")
                detail("Tham chiếu", signature.referenceURI?.isEmpty == false ? signature.referenceURI! : "(toàn tài liệu)")
                detail("Độ dài SignatureValue", "\(signature.signatureValueBytes) byte")
                detail("Ghi chú", signature.detail)
            }
            .font(.callout)
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.separator))
    }

    @ViewBuilder
    private func detail(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var disclaimer: some View {
        Text("Lưu ý: Chứng thư số được đối chiếu với kho tin cậy của macOS. Nhiều chứng thư của CA Việt Nam không có trong kho tin cậy mặc định của macOS; trạng thái \"Không tin cậy\" không đồng nghĩa với chữ ký giả. Chỉ kiểm tra mật mã độc lập mới xác định được tính toàn vẹn và hiệu lực của chữ ký.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct ContentUnavailableViewCompat: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "signature")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message).font(.callout).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }
}
