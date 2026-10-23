import SwiftUI
import AppKit

@main
struct iTaxViewerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 980, minHeight: 680)
        }
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Kiểm tra cập nhật…") { model.checkForUpdates() }
                    .disabled(model.isCheckingForUpdates)
                Toggle("Tự động kiểm tra cập nhật", isOn: $model.automaticUpdateCheck)
                Divider()
            }
            CommandGroup(replacing: .newItem) {
                Button("Mở tệp hồ sơ…") { model.showOpenPanel() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .printItem) {
                Button("In hồ sơ…") { model.requestPrint() }
                    .keyboardShortcut("p", modifiers: .command)
                    .disabled(model.documents.isEmpty)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Xuất PDF…") { model.requestExport() }
                    .keyboardShortcut("s", modifiers: .command)
                    .disabled(model.documents.isEmpty)
            }
            CommandMenu("Hiển thị") {
                Button("Phóng to") { model.zoomIn() }
                    .keyboardShortcut("+", modifiers: .command)
                Button("Thu nhỏ") { model.zoomOut() }
                    .keyboardShortcut("-", modifiers: .command)
                Button("Kích thước thực") { model.zoomReset() }
                    .keyboardShortcut("0", modifiers: .command)
                Divider()
                Button("Thông tin tài liệu") { model.requestInfo() }
                    .keyboardShortcut("i", modifiers: .command)
                    .disabled(model.documents.isEmpty)
                Button("Chữ ký điện tử…") { model.requestSignatures() }
                    .keyboardShortcut("y", modifiers: [.command, .shift])
                    .disabled(model.documents.isEmpty)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            for url in urls where url.pathExtension.lowercased() == "xml" {
                AppModel.shared.open(url: url)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
