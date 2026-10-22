import SwiftUI
import iTaxViewerCore

/// Visual language for the document kinds supported by the viewer.
/// Icons use SF Symbols so the app ships without bitmap assets.
enum DocumentKindStyle {
    static func symbolName(for kind: DocumentKind) -> String {
        switch kind {
        case .declaration: return "doc.text.fill"
        case .notice: return "bell.badge.fill"
        case .paymentVoucher: return "banknote.fill"
        case .registration: return "person.text.rectangle.fill"
        case .catalog: return "list.bullet.rectangle.fill"
        case .customs: return "shippingbox.fill"
        case .invoice: return "doc.richtext.fill"
        case .unsupported: return "questionmark.folder.fill"
        }
    }

    static func tint(for kind: DocumentKind) -> Color {
        switch kind {
        case .declaration: return .blue
        case .notice: return .orange
        case .paymentVoucher: return .green
        case .registration: return .purple
        case .catalog: return .teal
        case .customs: return .brown
        case .invoice: return .indigo
        case .unsupported: return .gray
        }
    }

    static func shortLabel(for kind: DocumentKind) -> String {
        switch kind {
        case .declaration: return "Tờ khai"
        case .notice: return "Thông báo"
        case .paymentVoucher: return "Chứng từ"
        case .registration: return "Đăng ký thuế"
        case .catalog: return "Danh mục"
        case .customs: return "Hải quan"
        case .invoice: return "Hóa đơn"
        case .unsupported: return "Không xác định"
        }
    }

    static func supportSymbol(for support: RenderSupport) -> String {
        switch support {
        case .full: return "checkmark.circle.fill"
        case .generic: return "tablecells"
        case .none: return "slash.circle"
        }
    }
}

extension OpenDocument {
    var kindSymbol: String { DocumentKindStyle.symbolName(for: classification.kind) }
    var kindTint: Color { DocumentKindStyle.tint(for: classification.kind) }
    var shortKindLabel: String { DocumentKindStyle.shortLabel(for: classification.kind) }
    var hasSignature: Bool { !document.signatures.isEmpty }
}

/// Rounded, tinted icon used in the sidebar, the summary bar and empty states.
struct DocumentKindBadge: View {
    let symbol: String
    let tint: Color
    var size: CGFloat = 30

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(tint.opacity(0.18))
            )
            .accessibilityHidden(true)
    }
}

/// Small capsule used for form codes, versions and periods.
struct MetaChip: View {
    let text: String
    var symbol: String? = nil
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .semibold))
            }
            Text(text)
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 7)
        .padding(.vertical, 2)
        .background(tint.opacity(0.12), in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.18)))
    }
}
