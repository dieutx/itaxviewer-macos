import SwiftUI
import AppKit
import iTaxViewerCore

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 240, ideal: 290, max: 380)
        } detail: {
            DocumentDetailView()
        }
        .navigationTitle(model.selectedDocument?.document.sourceName ?? "iTax Viewer for macOS")
        .alert("Không mở được tài liệu", isPresented: Binding(
            get: { model.lastError != nil },
            set: { if !$0 { model.lastError = nil } }
        )) {
            Button("Đóng", role: .cancel) { model.lastError = nil }
        } message: {
            Text(model.lastError ?? "")
        }
        .overlay(alignment: .center) {
            if model.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Đang đọc tệp hồ sơ…")
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 8)
            }
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""

    private var filteredDocuments: [OpenDocument] {
        guard !query.isEmpty else { return model.documents }
        let needle = query.lowercased()
        return model.documents.filter { doc in
            doc.document.sourceName.lowercased().contains(needle)
                || doc.displayTitle.lowercased().contains(needle)
                || doc.formLabel.lowercased().contains(needle)
                || doc.shortKindLabel.lowercased().contains(needle)
        }
    }

    private var filteredRecent: [RecentFile] {
        guard !query.isEmpty else { return model.recent }
        let needle = query.lowercased()
        return model.recent.filter { item in
            item.name.lowercased().contains(needle)
                || (item.form ?? "").lowercased().contains(needle)
                || item.kind.lowercased().contains(needle)
        }
    }

    var body: some View {
        List(selection: $model.selection) {
            Section {
                if filteredDocuments.isEmpty {
                    emptyOpenSection
                }
                ForEach(filteredDocuments) { doc in
                    DocumentRow(document: doc)
                        .tag(doc.id)
                        .contextMenu {
                            Button("Hiện trong Finder") { reveal(doc) }
                                .disabled(doc.url == nil)
                            Divider()
                            Button("Đóng", role: .destructive) { model.close(doc) }
                        }
                }
            } header: {
                HStack(spacing: 6) {
                    Label("Đang mở", systemImage: "square.stack.3d.up.fill")
                    Spacer()
                    Text("\(model.documents.count)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if filteredRecent.isEmpty {
                    Text(query.isEmpty ? "Các tệp đã mở sẽ xuất hiện ở đây"
                                       : "Không tìm thấy tệp phù hợp")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 2)
                }
                ForEach(filteredRecent) { item in
                    Button {
                        model.openRecent(item)
                    } label: {
                        RecentRow(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Mở lại") { model.openRecent(item) }
                        Button("Hiện trong Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([item.url])
                        }
                        Divider()
                        Button("Xóa khỏi danh sách", role: .destructive) { model.removeRecent(item) }
                    }
                }
            } header: {
                HStack(spacing: 6) {
                    Label("Gần đây", systemImage: "clock.arrow.circlepath")
                    Spacer()
                    if !model.recent.isEmpty {
                        Button("Xóa") { model.clearRecent() }
                            .buttonStyle(.link)
                            .font(.caption)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $query, prompt: "Tìm tệp, mẫu số, loại hồ sơ…")
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.green)
                    Text("Ngoại tuyến · dữ liệu chỉ ở trên máy")
                        .font(.caption2.weight(.medium))
                }
                Text("iTax Viewer for macOS — ứng dụng độc lập, không phải sản phẩm chính thức của cơ quan thuế.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
        }
    }

    private var emptyOpenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "tray")
                    .foregroundStyle(.secondary)
                Text(query.isEmpty ? "Chưa có tài liệu nào" : "Không tìm thấy tài liệu")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Button {
                model.showOpenPanel()
            } label: {
                Label("Mở tệp hồ sơ…", systemImage: "folder.badge.plus")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private func reveal(_ doc: OpenDocument) {
        guard let url = doc.url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

private struct DocumentRow: View {
    let document: OpenDocument

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            DocumentKindBadge(symbol: document.kindSymbol, tint: document.kindTint, size: 30)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(document.document.sourceName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    MetaChip(text: document.formLabel, symbol: "number", tint: document.kindTint)
                    if let version = document.document.metadata.formVersion {
                        MetaChip(text: "v\(version)")
                    }
                    if let period = document.document.metadata.period {
                        MetaChip(text: period, symbol: "calendar")
                    }
                }

                Text(document.shortKindLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if document.hasSignature {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .help("Có chữ ký điện tử — chưa xác minh")
            }
        }
        .padding(.vertical, 3)
    }
}

private struct RecentRow: View {
    let item: RecentFile

    private var symbol: String {
        if let form = item.form, form.hasPrefix("CT") { return "banknote.fill" }
        if item.kind.localizedCaseInsensitiveContains("thông báo") { return "bell.badge.fill" }
        if item.kind.localizedCaseInsensitiveContains("chứng từ") { return "banknote.fill" }
        return "doc.text.fill"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            DocumentKindBadge(symbol: symbol, tint: .secondary, size: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.callout)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text([item.form, item.kind].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(item.openedAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 1)
    }
}
