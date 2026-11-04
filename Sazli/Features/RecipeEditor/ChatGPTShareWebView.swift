import SwiftUI
import WebKit

/// A temporary browser reads only the public share page, with an isolated cookie store.
struct ChatGPTShareWebView: UIViewRepresentable {
    let url: URL
    let onRead: (Result<[SharedChatGPTMessage], Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(url: url, onRead: onRead) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30))
        context.coordinator.startTimeout()
        return webView
    }

    func updateUIView(_ view: WKWebView, context: Context) {}

    static func dismantleUIView(_ view: WKWebView, coordinator: Coordinator) {
        coordinator.cancel()
        view.stopLoading()
        view.navigationDelegate = nil
    }

    @MainActor final class Coordinator: NSObject, WKNavigationDelegate {
        private let url: URL
        private let onRead: (Result<[SharedChatGPTMessage], Error>) -> Void
        private var reading: Task<Void, Never>?
        private var timeout: Task<Void, Never>?
        private var finished = false

        init(url: URL, onRead: @escaping (Result<[SharedChatGPTMessage], Error>) -> Void) {
            self.url = url
            self.onRead = onRead
        }

        func startTimeout() {
            timeout = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(35)) } catch { return }
                self?.finish(.failure(ChatGPTShareDocument.ReadError.unavailable))
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !finished else { return }
            reading?.cancel()
            reading = Task { [weak self, weak webView] in
                for _ in 0..<12 {
                    guard let self, let webView, !Task.isCancelled, !self.finished else { return }
                    do {
                        // Return inert HTML, not script objects. Decode only finalized assistant text.
                        if let html = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String {
                            let messages = try ChatGPTShareDocument.messages(in: html)
                            self.finish(.success(messages))
                            return
                        }
                    } catch ChatGPTShareDocument.ReadError.tooLarge {
                        self.finish(.failure(ChatGPTShareDocument.ReadError.tooLarge))
                        return
                    } catch { /* Hydration may still be loading the public conversation. */ }
                    do { try await Task.sleep(for: .seconds(1)) } catch { return }
                }
                self?.finish(.failure(ChatGPTShareDocument.ReadError.unavailable))
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard action.targetFrame?.isMainFrame == true else { return .allow }
            guard let target = action.request.url,
                  SourceLink.chatGPTShareURL(from: target.absoluteString)?.path == url.path else {
                finish(.failure(ChatGPTShareDocument.ReadError.unavailable))
                return .cancel
            }
            return .allow
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code != NSURLErrorCancelled { finish(.failure(error)) }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if (error as NSError).code != NSURLErrorCancelled { finish(.failure(error)) }
        }

        private func finish(_ result: Result<[SharedChatGPTMessage], Error>) {
            guard !finished else { return }
            finished = true
            timeout?.cancel()
            onRead(result)
        }

        func cancel() {
            finished = true
            reading?.cancel()
            timeout?.cancel()
        }
    }
}
