import SwiftUI
import AppKit
import iTaxViewerCore

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 360)
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

    var body: some View {
        List(selection: $model.selection) {
            Section("Đang mở") {
                if model.documents.isEmpty {
                    Text("Chưa có tài liệu nào")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                ForEach(model.documents) { doc in
                    DocumentRow(document: doc)
                        .tag(doc.id)
                        .contextMenu {
                            Button("Đóng") { model.close(doc) }
                        }
                }
            }

            Section {
                if model.recent.isEmpty {
                    Text("Các tệp đã mở sẽ xuất hiện ở đây")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(model.recent) { item in
                    Button {
                        model.openRecent(item)
                    } label: {
                        RecentRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                HStack {
                    Text("Gần đây")
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
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("iTax Viewer for macOS")
                    .font(.caption2.weight(.semibold))
                Text("Ứng dụng độc lập, không phải sản phẩm chính thức của cơ quan thuế.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
        }
    }
}

private struct DocumentRow: View {
    let document: OpenDocument

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "doc.text")
                .foregroundStyle(.tint)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(document.document.sourceName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text(document.subtitle.isEmpty ? document.formLabel : document.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct RecentRow: View {
    let item: RecentFile

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.callout)
                    .lineLimit(1)
                Text([item.form, item.kind].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
    }
}
