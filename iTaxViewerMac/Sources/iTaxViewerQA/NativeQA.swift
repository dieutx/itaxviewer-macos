import AppKit
@preconcurrency import WebKit
import PDFKit
import iTaxViewerCore

// This tool intentionally reads ONLY the repository's synthetic/anonymised
// XCTest fixtures. Never point CI artifact collection at real taxpayer data.
@main
enum NativeQA {
    @MainActor static func main() {
        setbuf(stdout, nil)
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        Task { @MainActor in
            do {
                let success = try await FixtureRunner().run()
                exit(success ? 0 : 1)
            } catch {
                // Parser/system error descriptions can contain document content.
                print("FAIL native-qa setup")
                exit(1)
            }
        }
        application.run()
    }
}

private struct QAError: Error { let stage: String }

private struct FixtureResult: Codable {
    let fixture: String
    let status: String
    let pages: Int
    let numericCellsChecked: Int
    let snapshot: Bool
    let stage: String?
}

@MainActor
private final class FixtureRunner {
    private let files = FileManager.default
    private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    private var output: URL { root.appendingPathComponent("build/native-qa", isDirectory: true) }

    func run() async throws -> Bool {
        let fixtures = root.appendingPathComponent("Tests/iTaxViewerCoreTests/Fixtures", isDirectory: true)
        let inputs = try files.contentsOfDirectory(at: fixtures, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension.lowercased() == "xml" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard !inputs.isEmpty else { throw QAError(stage: "fixture-directory") }
        // Repeated runs must not mix failed current renders with old evidence.
        if files.fileExists(atPath: output.path) { try files.removeItem(at: output) }
        try files.createDirectory(at: output, withIntermediateDirectories: true)
        let registry = try FormRegistry.bundled()
        let renderer = HTMLRenderer(registry: registry)
        var results: [FixtureResult] = []
        for input in inputs {
            let fixture = input.lastPathComponent
            print("CHECK \(fixture)")
            do {
                if fixture == "xxe_attack.xml" {
                    do {
                        _ = try TaxDocument.load(url: input)
                        throw QAError(stage: "xxe-accepted")
                    } catch XMLInspectionError.doctypeForbidden {
                        results.append(FixtureResult(fixture: fixture, status: "rejected-as-required",
                                                     pages: 0, numericCellsChecked: 0, snapshot: false, stage: nil))
                        print("PASS \(fixture) rejected-as-required")
                        continue
                    }
                }
                let document = try TaxDocument.load(url: input)
                let classification = try DocumentClassifier.classify(document, registry: registry)
                let rendered = renderer.render(document: document, classification: classification)
                let result = try await check(rendered, fixture: fixture)
                results.append(result)
                print("PASS \(fixture) pages=\(result.pages) numeric-cells=\(result.numericCellsChecked)")
            } catch {
                let stage = (error as? QAError)?.stage ?? "parse-classify-render"
                results.append(FixtureResult(fixture: fixture, status: "failed", pages: 0,
                                             numericCellsChecked: 0, snapshot: false, stage: stage))
                print("FAIL \(fixture) stage=\(stage)")
            }
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(results).write(to: output.appendingPathComponent("report.json"), options: .atomic)
        let success = results.allSatisfy { $0.status != "failed" }
        print("Native QA fixtures=\(results.count) result=\(success ? "passed" : "failed"); visual parity remains pending")
        return success
    }

    private func check(_ rendered: RenderedDocument, fixture: String) async throws -> FixtureResult {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: CGFloat(rendered.pageWidthPixels), height: 1123),
                            configuration: configuration)
        let navigation = LocalNavigation()
        web.navigationDelegate = navigation
        let window = NSWindow(contentRect: web.bounds, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = web
        window.orderFront(nil)
        defer { web.navigationDelegate = nil; window.orderOut(nil); window.contentView = nil }
        try await navigation.load(rendered.html, in: web)
        print("STAGE \(fixture) loaded")
        // Allow the native view's layout/display cycle to settle after didFinish.
        try await Task.sleep(nanoseconds: 250_000_000)
        let base = output.appendingPathComponent((fixture as NSString).deletingPathExtension)
        // Synthetic fixtures only: retain the independently authored HTML so
        // Windows can compare cell text with a local MSXML oracle output.
        try rendered.html.write(to: base.appendingPathExtension("html"), atomically: true, encoding: .utf8)
        let pdfURL = base.appendingPathExtension("pdf")
        if files.fileExists(atPath: pdfURL.path) { try files.removeItem(at: pdfURL) }
        let info = NSPrintInfo(dictionary: [:])
        let mm = 72.0 / 25.4
        info.paperSize = NSSize(width: 210 * mm, height: 297 * mm)
        info.orientation = rendered.orientation == .landscape ? .landscape : .portrait
        info.topMargin = 20 * mm
        info.leftMargin = 20 * mm
        info.rightMargin = 20 * mm
        info.bottomMargin = 10 * mm
        info.horizontalPagination = .fit
        info.verticalPagination = .automatic
        info.isHorizontallyCentered = true
        info.isVerticallyCentered = false
        info.jobDisposition = .save
        info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = pdfURL
        let operation = web.printOperation(with: info)
        operation.showsPrintPanel = false
        operation.showsProgressPanel = false
        print("STAGE \(fixture) native-print")
        // Suspend the Swift task before entering AppKit's nested print loop.
        // WebKit may schedule main-actor work while preparing print pages.
        let printed = await NativePrintJob.run(operation, for: window)
        guard printed else { throw QAError(stage: "native-print") }
        print("STAGE \(fixture) pdf-check")
        guard let pdf = PDFDocument(url: pdfURL), pdf.pageCount > 0 else { throw QAError(stage: "pdf-read") }
        var text = ""
        for index in 0..<pdf.pageCount {
            guard let page = pdf.page(at: index) else { throw QAError(stage: "pdf-page") }
            let box = page.bounds(for: .mediaBox)
            let portrait = rendered.orientation != .landscape
            let expectedWidth = (portrait ? 210.0 : 297.0) * mm
            let expectedHeight = (portrait ? 297.0 : 210.0) * mm
            guard abs(box.width - expectedWidth) < 2, abs(box.height - expectedHeight) < 2 else {
                throw QAError(stage: "pdf-a4-size")
            }
            guard let pageText = page.string, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw QAError(stage: "pdf-empty-page")
            }
            text += pageText
        }
        let normalized = compact(text)
        // Compare each distinct numeric table-cell value in the HTML to native
        // PDF text, so pagination cannot silently omit a later table section.
        let numeric = try numericCells(in: rendered.html)
        guard numeric.allSatisfy({ normalized.contains(compact($0)) }) else {
            throw QAError(stage: "pdf-missing-numeric-cell")
        }
        for expected in markers[fixture] ?? [] {
            guard normalized.contains(compact(expected)) else { throw QAError(stage: "pdf-missing-fixture-marker") }
        }
        var snapshotSaved = false
        if let snapshot = try? await snapshot(web),
           let tiff = snapshot.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let png = bitmap.representation(using: .png, properties: [:]) {
            try png.write(to: base.appendingPathExtension("png"), options: .atomic)
            snapshotSaved = true
        }
        return FixtureResult(fixture: fixture, status: "passed", pages: pdf.pageCount,
                             numericCellsChecked: numeric.count, snapshot: snapshotSaved, stage: nil)
    }

    private func snapshot(_ web: WKWebView) async throws -> NSImage {
        try await withCheckedThrowingContinuation { continuation in
            let config = WKSnapshotConfiguration()
            config.rect = web.bounds
            web.takeSnapshot(with: config) { image, _ in
                if let image { continuation.resume(returning: image) }
                else { continuation.resume(throwing: QAError(stage: "snapshot")) }
            }
        }
    }

    private func compact(_ text: String) -> String {
        text.components(separatedBy: .whitespacesAndNewlines).joined()
    }

    private func numericCells(in html: String) throws -> Set<String> {
        let cells = try NSRegularExpression(pattern: #"<td\b[^>]*>(.*?)</td>"#, options: [.dotMatchesLineSeparators, .caseInsensitive])
        let tags = try NSRegularExpression(pattern: "<[^>]*>")
        let numeric = try NSRegularExpression(pattern: #"^\(?-?[0-9][0-9.,]*\)?$"#)
        let source = html as NSString
        var values: Set<String> = []
        for match in cells.matches(in: html, range: NSRange(location: 0, length: source.length)) {
            let cell = source.substring(with: match.range(at: 1))
            let plain = tags.stringByReplacingMatches(in: cell, range: NSRange(location: 0, length: (cell as NSString).length), withTemplate: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let range = NSRange(location: 0, length: (plain as NSString).length)
            if numeric.firstMatch(in: plain, range: range) != nil { values.insert(plain) }
        }
        return values
    }

    // Independent fixed expectations from the bundled, anonymised fixtures.
    private let markers: [String: [String]] = [
        "correction_tt80.xml": ["(1.234.567)", "2.345.678", "901.234", "Tài liệu bổ sung mẫu"],
        "gtgt_842_return.xml": ["1.000.000.000", "80.000.000", "160.000.000"],
        "gtgt_842_return_utf16.xml": ["1.000.000.000", "80.000.000"],
        "gtgt_01_legacy_212.xml": ["1.000.000.000", "(115.000.000)"],
        "tncn_394_05kk_tt92.xml": ["1.200.000", "5.000"],
        "tncn_953_05qtt.xml": ["1.500.000.000", "95.000.000"],
        "tndn_892_03tndn_v2.9.4.xml": ["(1.000)", "250"],
        "declaration_07_static.xml": ["1.000.001", "1.000.013"],
        "declaration_847_static.xml": ["1.000.001", "120.000"],
        "declaration_864_static.xml": ["1.000.006", "1.000.018"],
        "declaration_395_static.xml": ["1.000.008", "1.000.014"],
        "voucher_ct01.xml": ["1.234.580.235", "PHẦN KBNN GHI"],
        "notice_843.xml": ["01-01/TB-TĐT", "CÔNG TY MẪU"],
        "notice_843_rejected.xml": ["01-01/TB-TĐT", "CÔNG TY MẪU"],
        "notice_844.xml": ["01-2/TB-TĐT", "1.000.000"],
        "notice_01_tb_bstt.xml": ["THÔNG BÁO", "CÔNG TY TNHH DỮ LIỆU MẪU"]
    ]
}

@MainActor
private final class LocalNavigation: NSObject, WKNavigationDelegate {
    private var pending: CheckedContinuation<Void, Error>?
    private var timeout: Task<Void, Never>?

    func load(_ html: String, in web: WKWebView) async throws {
        try await withCheckedThrowingContinuation { continuation in
            pending = continuation
            timeout = Task { @MainActor [weak self] in
                do { try await Task.sleep(nanoseconds: 20_000_000_000) } catch { return }
                self?.finish(.failure(QAError(stage: "webview-timeout")))
            }
            web.loadHTMLString(html, baseURL: nil)
        }
    }

    private func finish(_ result: Result<Void, Error>) {
        timeout?.cancel()
        timeout = nil
        let continuation = pending
        pending = nil
        continuation?.resume(with: result)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { finish(.success(())) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(QAError(stage: "webview-load")))
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(.failure(QAError(stage: "webview-load")))
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        finish(.failure(QAError(stage: "webview-process")))
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let scheme = action.request.url?.scheme?.lowercased() ?? ""
        let local = scheme == "about" || scheme == "data" || scheme.isEmpty
        decisionHandler(local && action.navigationType != .linkActivated ? .allow : .cancel)
    }
}
