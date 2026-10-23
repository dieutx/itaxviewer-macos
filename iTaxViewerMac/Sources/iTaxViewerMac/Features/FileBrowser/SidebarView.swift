import SwiftUI
import AppKit
import iTaxViewerCore

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 420)
            Divider()
            DocumentDetailView()
                .frame(minWidth: 640, maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle(model.selectedDocument?.document.sourceName ?? "iTax Viewer for macOS")
        .safeAreaInset(edge: .top, spacing: 0) {
            if let update = model.availableUpdate {
                UpdateBanner(release: update,
                             onOpen: { model.openUpdatePage() },
                             onDismiss: { model.dismissAvailableUpdate() })
            }
        }
        .alert("Không mở được tài liệu", isPresented: Binding(
            get: { model.lastError != nil },
            set: { if !$0 { model.lastError = nil } }
        )) {
            Button("Đóng", role: .cancel) { model.lastError = nil }
        } message: {
            Text(model.lastError ?? "")
        }
        .alert("Kiểm tra cập nhật", isPresented: Binding(
            get: { model.updateNotice != nil },
            set: { if !$0 { model.updateNotice = nil } }
        )) {
            Button("Đóng", role: .cancel) { model.updateNotice = nil }
        } message: {
            Text(model.updateNotice ?? "")
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

private struct UpdateBanner: View {
    let release: AppRelease
    let onOpen: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 1) {
                Text("Đã có phiên bản \(release.version)")
                    .font(.callout.weight(.semibold))
                Text("Bản hiện tại sẽ tiếp tục dùng bình thường. Mở trang phát hành để tải bản mới.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button("Tải về", action: onOpen)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Bỏ qua phiên bản này")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) { Divider() }
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
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        Color.clear
                            .frame(height: 1)
                            .id("sidebar-top")
                        openSection
                        recentSection
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                    .padding(.bottom, 14)
                }
                .onAppear { scrollToTop(proxy) }
                .onChange(of: model.recent.count) { _ in scrollToTop(proxy) }
                .onChange(of: model.documents.count) { _ in scrollToTop(proxy) }
            }
            .safeAreaInset(edge: .bottom) {
                footer
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Tìm tệp, mẫu số, loại hồ sơ…", text: $query)
                .textFieldStyle(.plain)
                .font(.callout)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    // MARK: - Sections

    @ViewBuilder
    private var openSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SidebarSectionHeader(title: "Đang mở",
                                 systemImage: "square.stack.3d.up.fill",
                                 count: model.documents.count)

            if filteredDocuments.isEmpty {
                emptyOpenCard
            } else {
                ForEach(filteredDocuments) { doc in
                    OpenDocumentRow(document: doc,
                                    isSelected: model.selection == doc.id)
                        .onTapGesture { model.selection = doc.id }
                        .contextMenu {
                            Button("Hiện trong Finder") { reveal(doc) }
                                .disabled(doc.url == nil)
                            Divider()
                            Button("Đóng", role: .destructive) { model.close(doc) }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            SidebarSectionHeader(title: "Gần đây",
                                 systemImage: "clock.arrow.circlepath",
                                 count: filteredRecent.count,
                                 clearAction: model.recent.isEmpty ? nil : { model.clearRecent() })

            if filteredRecent.isEmpty {
                Text(query.isEmpty ? "Các tệp đã mở sẽ xuất hiện ở đây"
                                   : "Không tìm thấy tệp phù hợp")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
            } else {
                ForEach(filteredRecent) { item in
                    RecentRow(item: item)
                        .onTapGesture { model.openRecent(item) }
                        .contextMenu {
                            Button("Mở lại") { model.openRecent(item) }
                            Button("Hiện trong Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([item.url])
                            }
                            Divider()
                            Button("Xóa khỏi danh sách", role: .destructive) { model.removeRecent(item) }
                        }
                }
            }
        }
    }

    private var emptyOpenCard: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.12))
        )
    }

    private var footer: some View {
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

    private func scrollToTop(_ proxy: ScrollViewProxy) {
        // AppKit may restore an old scroll offset, and inserting the recent
        // list asynchronously makes SwiftUI keep the old visual anchor. Pin
        // the section headers after every content change.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            proxy.scrollTo("sidebar-top", anchor: .top)
        }
    }

    private func reveal(_ doc: OpenDocument) {
        guard let url = doc.url else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

private struct SidebarSectionHeader: View {
    let title: String
    let systemImage: String
    let count: Int?
    var clearAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if let count {
                Text("\(count)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            if let clearAction {
                Button("Xóa", action: clearAction)
                    .buttonStyle(.link)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .textCase(nil)
    }
}

private struct OpenDocumentRow: View {
    let document: OpenDocument
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            DocumentKindBadge(symbol: document.kindSymbol, tint: document.kindTint, size: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(document.document.sourceName)
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(document.document.sourceName)

                HStack(spacing: 5) {
                    Text(document.formLabel)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(document.kindTint)
                    Text("·").foregroundStyle(.tertiary)
                    Text(document.shortKindLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let period = document.document.metadata.period {
                        Text("·").foregroundStyle(.tertiary)
                        Text(period)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 2)
                    if document.hasSignature {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .help("Có chữ ký điện tử — chưa xác minh")
                    }
                }
            }
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 9)
        .background(isSelected ? document.kindTint.opacity(0.14) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(isSelected ? document.kindTint.opacity(0.25) : Color.clear)
        )
        .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
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
        HStack(alignment: .center, spacing: 10) {
            DocumentKindBadge(symbol: symbol, tint: .secondary, size: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 12.5))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help("\(item.name) — mở \(item.openedAt.formatted(date: .abbreviated, time: .shortened))")

                HStack(spacing: 5) {
                    if let form = item.form, !form.isEmpty {
                        Text(form)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                    }
                    Text(item.kind)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 9)
        .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}
