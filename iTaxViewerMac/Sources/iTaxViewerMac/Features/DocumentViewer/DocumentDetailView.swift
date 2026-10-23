import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers
import iTaxViewerCore

struct DocumentDetailView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showInfo = false
    @State private var showSignatures = false
    @State private var isDropTarget = false

    var body: some View {
        Group {
            if let doc = model.selectedDocument {
                VStack(spacing: 0) {
                    DocumentSummaryBar(document: doc,
                                       onInfo: { showInfo = true },
                                       onSignatures: { showSignatures = true })
                    Divider()
                    ZStack(alignment: .bottomTrailing) {
                        DocumentWebView(html: doc.rendered.html, zoom: model.zoom,
                                        sourceName: doc.document.sourceName)
                        ZoomControls()
                            .padding(14)
                    }
                }
                .sheet(isPresented: $showInfo) {
                    DocumentInfoView(document: doc)
                }
                .sheet(isPresented: $showSignatures) {
                    SignatureListView(document: doc)
                }
                .onReceive(NotificationCenter.default.publisher(for: .itaxPrint)) { _ in
                    PrintExportService.print(orientation: doc.classification.orientation)
                }
                .onReceive(NotificationCenter.default.publisher(for: .itaxExportPDF)) { _ in
                    PrintExportService.exportPDF(suggestedName: doc.document.sourceName,
                                                 orientation: doc.classification.orientation)
                }
                .onReceive(NotificationCenter.default.publisher(for: .itaxShowInfo)) { _ in
                    showInfo = true
                }
                .onReceive(NotificationCenter.default.publisher(for: .itaxShowSignatures)) { _ in
                    showSignatures = true
                }
            } else {
                EmptyDropView(isTargeted: isDropTarget)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    model.showOpenPanel()
                } label: {
                    Label("Mở", systemImage: "folder")
                }
                .help("Mở tệp hồ sơ (⌘O)")
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    model.zoomOut()
                } label: {
                    Label("Thu nhỏ", systemImage: "minus.magnifyingglass")
                }
                .keyboardShortcut("-", modifiers: .command)
                .help("Thu nhỏ (⌘−)")

                Menu {
                    Button("50%") { model.zoom = 0.5 }
                    Button("75%") { model.zoom = 0.75 }
                    Button("100%") { model.zoomReset() }
                    Button("125%") { model.zoom = 1.25 }
                    Button("150%") { model.zoom = 1.5 }
                    Button("200%") { model.zoom = 2.0 }
                } label: {
                    Text("\(Int((model.zoom * 100).rounded()))%")
                        .monospacedDigit()
                        .frame(minWidth: 44)
                }
                .help("Tỷ lệ hiển thị")

                Button {
                    model.zoomIn()
                } label: {
                    Label("Phóng to", systemImage: "plus.magnifyingglass")
                }
                .keyboardShortcut("+", modifiers: .command)
                .help("Phóng to (⌘+)")

                Divider()

                Button {
                    model.requestSignatures()
                } label: {
                    Label("Chữ ký", systemImage: signatureIcon)
                }
                .disabled(model.selectedDocument == nil)
                .help("Thông tin chữ ký điện tử")

                Button {
                    model.requestInfo()
                } label: {
                    Label("Thông tin", systemImage: "info.circle")
                }
                .disabled(model.selectedDocument == nil)

                Button {
                    revealSelectedInFinder()
                } label: {
                    Label("Hiện trong Finder", systemImage: "folder.badge.questionmark")
                }
                .disabled(model.selectedDocument?.url == nil)
                .help("Hiện tệp trong Finder")

                Divider()

                Button {
                    model.requestExport()
                } label: {
                    Label("Xuất PDF", systemImage: "square.and.arrow.down")
                }
                .disabled(model.selectedDocument == nil)
                .help("Xuất PDF (⌘S)")

                Button {
                    model.requestPrint()
                } label: {
                    Label("In", systemImage: "printer")
                }
                .disabled(model.selectedDocument == nil)
                .help("In hồ sơ (⌘P)")

                Button {
                    if let doc = model.selectedDocument { model.close(doc) }
                } label: {
                    Label("Đóng", systemImage: "xmark.circle")
                }
                .disabled(model.selectedDocument == nil)
                .help("Đóng tài liệu đang mở")
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTarget) { providers in
            handleDrop(providers)
        }
    }

    private var signatureIcon: String {
        guard let doc = model.selectedDocument else { return "signature" }
        return doc.document.signatures.isEmpty ? "signature" : "checkmark.seal"
    }

    private func revealSelectedInFinder() {
        guard let url = model.selectedDocument?.url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var accepted = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            accepted = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                var url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else if let nsurl = item as? NSURL {
                    url = nsurl as URL
                }
                guard let url, url.pathExtension.lowercased() == "xml" else { return }
                Task { @MainActor in
                    AppModel.shared.open(url: url)
                }
            }
        }
        return accepted
    }
}

private struct DocumentSummaryBar: View {
    let document: OpenDocument
    let onInfo: () -> Void
    let onSignatures: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            DocumentKindBadge(symbol: document.kindSymbol, tint: document.kindTint, size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text(document.displayTitle)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    MetaChip(text: document.formLabel, symbol: "number", tint: document.kindTint)
                    if let version = document.document.metadata.formVersion {
                        MetaChip(text: "phiên bản \(version)")
                    }
                    if let period = document.document.metadata.period {
                        MetaChip(text: "kỳ \(period)", symbol: "calendar")
                    }
                    MetaChip(text: document.shortKindLabel, symbol: "tag")
                }
            }

            Spacer(minLength: 8)

            if document.document.signatures.isEmpty {
                Label("Không có chữ ký", systemImage: "signature")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button(action: onSignatures) {
                    Label("\(document.document.signatures.count) chữ ký — Chưa xác minh",
                          systemImage: "exclamationmark.shield.fill")
                        .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            Button(action: onInfo) {
                Label("Thông tin", systemImage: "info.circle")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct ZoomControls: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 2) {
            Button { model.zoomOut() } label: { Image(systemName: "minus") }
            Divider().frame(height: 16)
            Button { model.zoomReset() } label: {
                Text("\(Int((model.zoom * 100).rounded()))%")
                    .font(.caption.monospacedDigit())
                    .frame(minWidth: 40)
            }
            Divider().frame(height: 16)
            Button { model.zoomIn() } label: { Image(systemName: "plus") }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.regularMaterial, in: Capsule())
        .shadow(radius: 4)
        .overlay(Capsule().strokeBorder(.separator))
    }
}

private struct EmptyDropView: View {
    @EnvironmentObject private var model: AppModel
    let isTargeted: Bool

    private struct SupportedKind: Identifiable {
        let id: String
        let symbol: String
    }

    private let supportedKinds: [SupportedKind] = [
        SupportedKind(id: "Tờ khai", symbol: "doc.text.fill"),
        SupportedKind(id: "Thông báo", symbol: "bell.badge.fill"),
        SupportedKind(id: "Chứng từ", symbol: "banknote.fill"),
        SupportedKind(id: "Đăng ký thuế", symbol: "person.text.rectangle.fill"),
        SupportedKind(id: "Hải quan", symbol: "shippingbox.fill"),
        SupportedKind(id: "Hóa đơn", symbol: "doc.richtext.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: isTargeted ? "arrow.down.doc.fill" : "doc.text.magnifyingglass")
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
                    .symbolRenderingMode(.hierarchical)

                VStack(spacing: 6) {
                    Text("Mở hồ sơ thuế XML")
                        .font(.title2.weight(.semibold))
                    Text("Kéo tệp XML vào đây, hoặc chọn tệp từ máy.\nTài liệu được xử lý hoàn toàn trên máy — không tải lên máy chủ.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 10) {
                    Button {
                        model.showOpenPanel()
                    } label: {
                        Label("Mở tệp hồ sơ…", systemImage: "folder.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut("o", modifiers: .command)
                }

                HStack(spacing: 6) {
                    ForEach(supportedKinds) { kind in
                        MetaChip(text: kind.id, symbol: kind.symbol, tint: .secondary)
                    }
                }

                if !model.recent.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Label("Mở gần đây", systemImage: "clock.arrow.circlepath")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        ForEach(model.recent.prefix(3)) { item in
                            Button {
                                model.openRecent(item)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "doc.text.fill")
                                        .foregroundStyle(.tint)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name)
                                            .font(.callout)
                                            .lineLimit(1)
                                        Text([item.form, item.kind].compactMap { $0 }.joined(separator: " · "))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor),
                                            in: RoundedRectangle(cornerRadius: 9))
                                .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.separator))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: 460)
                }

                Spacer(minLength: 0)
            }
            .padding(36)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
    }
}
