import AppKit
@preconcurrency import WebKit
import UniformTypeIdentifiers
import iTaxViewerCore

@MainActor
enum PrintExportService {

    static func print(orientation: PageOrientation) {
        guard let webView = WebViewStore.shared.webView, let window = webView.window else { return }
        let info = NativePrintSettings.make(orientation: orientation)
        let operation = webView.printOperation(with: info)
        operation.showsPrintPanel = true
        operation.showsProgressPanel = true
        Task { _ = await NativePrintJob.run(operation, for: window) }
    }

    /// Exports the whole document through the native print pipeline (all pages).
    static func exportPDF(suggestedName: String, orientation: PageOrientation) {
        guard let webView = WebViewStore.shared.webView, let window = webView.window else { return }

        let panel = NSSavePanel()
        panel.title = "Xuất tài liệu ra PDF"
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        let base = (suggestedName as NSString).deletingPathExtension
        panel.nameFieldStringValue = base.isEmpty ? "ho-so-thue.pdf" : "\(base).pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let info = NativePrintSettings.make(orientation: orientation, savingTo: url)

        let operation = webView.printOperation(with: info)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        Task { if !(await NativePrintJob.run(operation, for: window)) {
            let alert = NSAlert()
            alert.messageText = "Không xuất được PDF"
            alert.informativeText = "Không thể ghi tệp PDF vào vị trí đã chọn."
            alert.runModal()
        } }
    }

}
