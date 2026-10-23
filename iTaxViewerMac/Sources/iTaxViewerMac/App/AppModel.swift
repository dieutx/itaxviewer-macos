import Foundation
import SwiftUI
import Combine
import UniformTypeIdentifiers
import iTaxViewerCore

extension Notification.Name {
    static let itaxPrint = Notification.Name("itax.print")
    static let itaxExportPDF = Notification.Name("itax.exportPDF")
    static let itaxZoomIn = Notification.Name("itax.zoomIn")
    static let itaxZoomOut = Notification.Name("itax.zoomOut")
    static let itaxZoomReset = Notification.Name("itax.zoomReset")
    static let itaxShowInfo = Notification.Name("itax.showInfo")
    static let itaxShowSignatures = Notification.Name("itax.showSignatures")
}

struct OpenDocument: Identifiable {
    let id = UUID()
    let url: URL?
    let document: TaxDocument
    let classification: Classification
    let rendered: RenderedDocument

    var displayTitle: String {
        if let title = document.metadata.title, !title.isEmpty { return title }
        if let code = classification.displayCode { return code }
        return document.sourceName
    }

    var subtitle: String {
        [classification.displayCode, document.metadata.period]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    var formLabel: String {
        classification.displayCode ?? classification.kind.rawValue
    }
}

struct RecentFile: Codable, Identifiable {
    var id: String { path }
    let path: String
    let name: String
    let openedAt: Date
    let form: String?
    let kind: String

    var url: URL { URL(fileURLWithPath: path) }
}

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var documents: [OpenDocument] = []
    @Published var selection: OpenDocument.ID?
    @Published private(set) var recent: [RecentFile] = []
    @Published private(set) var isLoading = false
    @Published var lastError: String? = nil
    @Published var zoom: Double = 1.0

    // MARK: - Update check
    @Published private(set) var availableUpdate: AppRelease? = nil
    @Published private(set) var isCheckingForUpdates = false
    @Published var updateNotice: String? = nil
    @Published var automaticUpdateCheck: Bool {
        didSet {
            UserDefaults.standard.set(automaticUpdateCheck, forKey: "itax.updateCheck.auto")
        }
    }

    let registry: FormRegistry
    private let renderer: HTMLRenderer
    private let recentKey = "itax.recentFiles.v1"
    private let lastUpdateCheckKey = "itax.updateCheck.last"
    private let dismissedUpdateKey = "itax.updateCheck.dismissed"
    private let updateCheckDisabledKey = "itax.updateCheck.auto"
    private let releaseClient = GitHubReleaseClient()

    private init() {
        automaticUpdateCheck = false
        do {
            let registry = try FormRegistry.bundled()
            self.registry = registry
            self.renderer = HTMLRenderer(registry: registry)
        } catch {
            // The registry is bundled and covered by tests; failing here means a
            // corrupt build, so surface a deterministic error instead of crashing.
            let empty = try! JSONDecoder().decode(FormRegistry.self, from: Data("""
            {"schemaVersion":1,"source":{"application":"iTax Viewer","registryFile":"","entries":0,"formCodes":0},"supported":[],"codes":{}}
            """.utf8))
            self.registry = empty
            self.renderer = HTMLRenderer(registry: empty)
            self.lastError = "Không nạp được danh mục biểu mẫu: \(error.localizedDescription)"
        }
        loadRecent()
    }

    var selectedDocument: OpenDocument? {
        documents.first { $0.id == selection } ?? documents.first
    }

    // MARK: - Opening

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = "Mở tệp hồ sơ thuế"
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.xml]
        panel.allowsOtherFileTypes = true
        if panel.runModal() == .OK {
            for url in panel.urls { open(url: url) }
        }
    }

    func open(url: URL) {
        isLoading = true
        let registry = self.registry
        let renderer = self.renderer
        let scoped = url.startAccessingSecurityScopedResource()
        Task.detached(priority: .userInitiated) {
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let document = try TaxDocument.load(url: url)
                let classification = try DocumentClassifier.classify(document, registry: registry)
                let rendered = renderer.render(document: document, classification: classification)
                let opened = OpenDocument(url: url,
                                          document: document,
                                          classification: classification,
                                          rendered: rendered)
                await MainActor.run {
                    self.documents.removeAll { $0.url?.standardizedFileURL == url.standardizedFileURL }
                    self.documents.insert(opened, at: 0)
                    self.selection = opened.id
                    self.isLoading = false
                    self.zoom = 1.0
                    self.remember(url: url, document: document, classification: classification)
                    LocalQAReport.record(file: document.sourceName, stage: "opened")
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.lastError = error.localizedDescription
                    LocalQAReport.record(file: url.lastPathComponent, stage: "open-failed")
                }
            }
        }
    }

    func close(_ document: OpenDocument) {
        documents.removeAll { $0.id == document.id }
        if selection == document.id {
            selection = documents.first?.id
        }
    }

    func select(_ document: OpenDocument) {
        selection = document.id
        zoom = 1.0
    }

    func openRecent(_ item: RecentFile) {
        open(url: item.url)
    }

    func clearRecent() {
        recent = []
        persistRecent()
    }

    func removeRecent(_ item: RecentFile) {
        recent.removeAll { $0.path == item.path }
        persistRecent()
    }

    // MARK: - Zoom / actions

    func zoomIn() { zoom = min(3.0, zoom + 0.1) }
    func zoomOut() { zoom = max(0.4, zoom - 0.1) }
    func zoomReset() { zoom = 1.0 }

    func requestPrint() { NotificationCenter.default.post(name: .itaxPrint, object: nil) }
    func requestExport() { NotificationCenter.default.post(name: .itaxExportPDF, object: nil) }
    func requestInfo() { NotificationCenter.default.post(name: .itaxShowInfo, object: nil) }
    func requestSignatures() { NotificationCenter.default.post(name: .itaxShowSignatures, object: nil) }

    // MARK: - Updates

    var currentAppVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    /// Checks at most once per day, silently. The user can turn this off from
    /// the app menu.
    func autoCheckForUpdates() {
        guard automaticUpdateCheck else { return }
        if let last = UserDefaults.standard.object(forKey: lastUpdateCheckKey) as? Date,
           Date().timeIntervalSince(last) < 24 * 60 * 60 {
            return
        }
        Task { await performUpdateCheck(manual: false) }
    }

    func checkForUpdates() {
        Task { await performUpdateCheck(manual: true) }
    }

    private func performUpdateCheck(manual: Bool) async {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        defer { isCheckingForUpdates = false }
        do {
            let release = try await releaseClient.latestRelease(currentVersion: currentAppVersion)
            UserDefaults.standard.set(Date(), forKey: lastUpdateCheckKey)
            if let release,
               UserDefaults.standard.string(forKey: dismissedUpdateKey) != release.version {
                availableUpdate = release
                updateNotice = nil
            } else if manual {
                availableUpdate = nil
                updateNotice = "Bạn đang dùng phiên bản mới nhất (\(currentAppVersion))."
            }
        } catch {
            if manual {
                updateNotice = "Không kiểm tra được bản cập nhật: \(error.localizedDescription)"
            }
        }
    }

    func openUpdatePage() {
        guard let availableUpdate else { return }
        NSWorkspace.shared.open(availableUpdate.pageURL)
    }

    func dismissAvailableUpdate() {
        if let version = availableUpdate?.version {
            UserDefaults.standard.set(version, forKey: dismissedUpdateKey)
        }
        availableUpdate = nil
    }

    // MARK: - Recent files

    private func remember(url: URL, document: TaxDocument, classification: Classification) {
        let item = RecentFile(path: url.path,
                              name: url.lastPathComponent,
                              openedAt: Date(),
                              form: classification.displayCode ?? document.metadata.formCode,
                              kind: classification.kind.rawValue)
        recent.removeAll { $0.path == url.path }
        recent.insert(item, at: 0)
        recent = Array(recent.prefix(12))
        persistRecent()
    }

    private func loadRecent() {
        guard let data = UserDefaults.standard.data(forKey: recentKey),
              let items = try? JSONDecoder().decode([RecentFile].self, from: data) else { return }
        recent = items.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func persistRecent() {
        if let data = try? JSONEncoder().encode(recent) {
            UserDefaults.standard.set(data, forKey: recentKey)
        }
    }
}
