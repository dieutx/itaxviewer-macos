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
                        DocumentWebView(html: doc.rendered.html, zoom: model.zoom)
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
            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(document.formLabel, systemImage: "doc.text")
                    if let version = document.document.metadata.formVersion {
                        Text("phiên bản \(version)")
                    }
                    if let period = document.document.metadata.period {
                        Text("kỳ \(period)")
                    }
                    Text(document.classification.support.label)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if document.document.signatures.isEmpty {
                Label("Không có chữ ký", systemImage: "signature")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Button(action: onSignatures) {
                    Label("\(document.document.signatures.count) chữ ký — Chưa xác minh",
                          systemImage: "exclamationmark.shield")
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
        .padding(.vertical, 8)
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
    let isTargeted: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary)
            Text("Mở hồ sơ thuế XML")
                .font(.title2.weight(.semibold))
            Text("Kéo tệp XML vào đây, hoặc nhấn ⌘O để chọn tệp.\nHỗ trợ tờ khai 01/GTGT, 05/KK-TNCN, 05/QTT-TNCN, 03/TNDN và các hồ sơ khác ở dạng dữ liệu có cấu trúc.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 460)
            Text("Tài liệu được xử lý hoàn toàn trên máy. Không tải lên máy chủ.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
    }
}
