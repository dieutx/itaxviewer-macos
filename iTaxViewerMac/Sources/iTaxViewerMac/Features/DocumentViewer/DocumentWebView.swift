import SwiftUI
@preconcurrency import WebKit

@MainActor
final class WebViewStore: ObservableObject {
    static let shared = WebViewStore()
    weak var webView: WKWebView?
    private init() {}
}

/// A local-only WKWebView. JavaScript is disabled, persistence is disabled,
/// and every navigation away from the generated document is cancelled.
struct DocumentWebView: NSViewRepresentable {
    let html: String
    let zoom: Double
    let sourceName: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsMagnification = true
        webView.allowsBackForwardNavigationGestures = false

        context.coordinator.lastHTML = html
        context.coordinator.sourceName = sourceName
        webView.loadHTMLString(html, baseURL: nil)
        WebViewStore.shared.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.sourceName = sourceName
        if context.coordinator.lastHTML != html {
            context.coordinator.lastHTML = html
            webView.loadHTMLString(html, baseURL: nil)
        }
        if abs(webView.pageZoom - zoom) > 0.001 {
            webView.pageZoom = zoom
        }
        WebViewStore.shared.webView = webView
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?
        var sourceName = ""

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            LocalQAReport.record(file: sourceName, stage: "webview-loaded")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            LocalQAReport.record(file: sourceName, stage: "webview-failed")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            LocalQAReport.record(file: sourceName, stage: "webview-failed")
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            // The preview is a single in-memory document. Never allow it to
            // navigate to a file, network location or script URL.
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }
            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "about" || scheme == "data" || scheme.isEmpty {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }

    }
}
