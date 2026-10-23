import SwiftUI
import AppKit
import iTaxViewerCore

@MainActor
struct DocumentInfoView: View {
    let document: OpenDocument
    @Environment(\.dismiss) private var dismiss

    private var meta: DocumentMetadata { document.document.metadata }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                DocumentKindBadge(symbol: document.kindSymbol,
                                  tint: document.kindTint,
                                  size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thông tin tài liệu")
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 6) {
                        MetaChip(text: document.formLabel, symbol: "number", tint: document.kindTint)
                        MetaChip(text: document.shortKindLabel, symbol: "tag")
                    }
                }
                Spacer()
                Button("Đóng") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(16)
            Divider()

            ScrollView {
                Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 18, verticalSpacing: 9) {
                    row("Tên tệp", document.document.sourceName)
                    row("Đường dẫn", document.url?.path ?? "—")
                    row("Kích thước", ByteCountFormatter.string(fromByteCount: Int64(document.document.byteCount), countStyle: .file))
                    row("Loại hồ sơ", document.classification.kind.rawValue)
                    row("Mẫu số / mã hiển thị", document.classification.displayCode ?? "—")
                    row("Mã hồ sơ (maTKhai/maTBao)", document.classification.registryCode ?? meta.formCode ?? meta.noticeCode ?? "—")
                    row("Phiên bản XML", document.classification.formVersion ?? "—")
                    row("Loại tờ khai", filingTypeText)
                    row("Kỳ tính thuế", periodText)
                    row("Người nộp thuế", meta.taxpayerName ?? "—")
                    row("Mã số thuế", meta.taxpayerTaxCode ?? "—")
                    row("Địa chỉ", meta.taxpayerAddress ?? "—")
                    row("Phần mềm tạo lập", softwareText)
                    row("Hỗ trợ hiển thị", document.classification.support.label)
                    row("Khổ in", document.classification.orientation == .landscape ? "A4 ngang" : "A4 dọc")
                    row("Chữ ký điện tử", document.document.signatures.isEmpty ? "Không có" : "\(document.document.signatures.count) chữ ký — Chưa xác minh")
                }
                .padding(20)

                if !document.rendered.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cảnh báo tương thích")
                            .font(.headline)
                        ForEach(document.rendered.warnings, id: \.self) { warning in
                            Text("• \(warning)")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    .padding([.horizontal, .bottom], 20)
                }
            }

            Divider()
            HStack {
                Text("Danh mục biểu mẫu: \(catalogSummary)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(document.url?.path ?? "", forType: .string)
                } label: {
                    Label("Sao chép đường dẫn", systemImage: "doc.on.doc")
                }
                .disabled(document.url == nil)
            }
            .padding(12)
        }
        .frame(width: 640, height: 560)
    }

    private var catalogSummary: String {
        let registry = AppModel.shared.registry
        return "\(registry.source.entries) mục, \(registry.source.formCodes) mã biểu mẫu (từ \(registry.source.registryFile))"
    }

    private var filingTypeText: String {
        switch meta.filingType {
        case "C": return "Lần đầu"
        case "B": return "Bổ sung lần thứ \(meta.supplementNumber ?? "?")"
        default: return "—"
        }
    }

    private var periodText: String {
        let value = VietnameseFormat.period(type: meta.periodType, period: meta.period,
                                            from: meta.periodFrom, to: meta.periodTo)
        return value.isEmpty ? "—" : value
    }

    private var softwareText: String {
        [meta.softwareName, meta.softwareVersion].compactMap { $0 }.joined(separator: " ")
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .gridColumnAlignment(.trailing)
            Text(value)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
