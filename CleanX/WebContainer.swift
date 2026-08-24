import SwiftUI
import UIKit
import WebKit

struct WebContainer: UIViewRepresentable {
    @ObservedObject var settings: AppSettings
    static weak var sharedWebView: WKWebView?

    func makeCoordinator() -> Coordinator {
        Coordinator(settings: settings)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController.add(context.coordinator, name: "cleanx")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        context.coordinator.webView = webView
        Self.sharedWebView = webView

        inject(into: config.userContentController)

        if let url = URL(string: "https://x.com/home") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let script = settings.settingsPayload()
            + "\nif (window.__CLEANX_applySettings) window.__CLEANX_applySettings();"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func inject(into controller: WKUserContentController) {
        controller.addUserScript(WKUserScript(source: settings.settingsPayload(),
                                              injectionTime: .atDocumentEnd,
                                              forMainFrameOnly: true))

        if let js = InjectionScripts.mainJS {
            controller.addUserScript(WKUserScript(source: js,
                                                  injectionTime: .atDocumentEnd,
                                                  forMainFrameOnly: true))
        }
        if let css = InjectionScripts.mainCSS {
            let escaped = InjectionScripts.jsStringLiteral(css)
            let cssJS = "(() => { var s = document.getElementById('cleanx-style'); if (!s) { s = document.createElement('style'); s.id = 'cleanx-style'; (document.head || document.documentElement).appendChild(s); } s.textContent = \"" + escaped + "\"; })();"
            controller.addUserScript(WKUserScript(source: cssJS,
                                                  injectionTime: .atDocumentEnd,
                                                  forMainFrameOnly: true))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        private let settings: AppSettings

        init(settings: AppSettings) {
            self.settings = settings
        }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "cleanx",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }

            switch type {
            case "translate":
                let id = body["id"] as? String ?? ""
                let text = body["text"] as? String ?? ""
                DeepSeekService.translate(text: text,
                                          apiKey: settings.apiKey,
                                          targetLanguage: settings.targetLanguage) { [weak self] result in
                    DispatchQueue.main.async {
                        guard let self = self, let webView = self.webView else { return }
                        switch result {
                        case .success(let translated):
                            let safe = InjectionScripts.jsStringLiteral(translated)
                            let js = "window.__CLEANX_showTranslation && window.__CLEANX_showTranslation(\"\(id)\", \"\(safe)\", true)"
                            webView.evaluateJavaScript(js, completionHandler: nil)
                        case .failure(let error):
                            let msg = InjectionScripts.jsStringLiteral(error.localizedDescription)
                            let js = "window.__CLEANX_showTranslation && window.__CLEANX_showTranslation(\"\(id)\", \"\(msg)\", false)"
                            webView.evaluateJavaScript(js, completionHandler: nil)
                        }
                    }
                }
            default:
                break
            }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            let host = url.host?.lowercased() ?? ""
            let isX = host == "x.com" || host.hasSuffix(".x.com")
                || host == "twitter.com" || host.hasSuffix(".twitter.com")
                || host == "t.co"

            if navigationAction.navigationType == .linkActivated && !isX {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
