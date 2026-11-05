import Foundation

/// Downloads explicitly exposed recipe images without account cookies or credentials.
enum RecipeRemotePhoto {
    enum Source: Sendable { case chatGPT, tikTok, youtube, instagram }
    static let maximumBytes = 12_000_000

    static func publicURL(from text: String, source: Source) -> URL? {
        guard let url = SourceLink.url(from: text), url.scheme?.lowercased() == "https",
              url.port == nil || url.port == 443, let host = url.host?.lowercased() else { return nil }
        switch source {
        case .chatGPT:
            guard (host == "images.openai.com" && url.path.hasPrefix("/static-rsc-"))
                    || host == "files.oaiusercontent.com" else { return nil }
        case .tikTok:
            guard host == "tiktokcdn.com" || host.hasSuffix(".tiktokcdn.com")
                    || host == "tiktokcdn-us.com" || host.hasSuffix(".tiktokcdn-us.com") else { return nil }
        case .youtube:
            guard ["i.ytimg.com", "img.youtube.com"].contains(host) else { return nil }
        case .instagram:
            guard host.hasPrefix("scontent"),
                  host.hasSuffix(".cdninstagram.com") || host.hasSuffix(".fbcdn.net") else { return nil }
        }
        return url
    }

    static func load(from urls: [URL], source: Source) async -> Data? {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 12
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        for url in urls.prefix(2) {
            guard !Task.isCancelled else { return nil }
            guard publicURL(from: url.absoluteString, source: source) != nil else { continue }
            do {
                let (bytes, response) = try await session.bytes(
                    for: URLRequest(url: url), delegate: ImageRedirects(source: source))
                try validate(response, source: source)
                var data = Data()
                for try await byte in bytes {
                    guard data.count < maximumBytes else { throw PhotoError.unavailable }
                    data.append(byte)
                }
                let prepared = try await Task.detached(priority: .utility) {
                    try RecipePhoto.prepare(data)
                }.value
                guard !Task.isCancelled else { return nil }
                return prepared
            } catch { continue } // A photo must never prevent importing the recipe text.
        }
        return nil
    }

    static func validate(_ response: URLResponse, source: Source) throws {
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              let url = response.url, publicURL(from: url.absoluteString, source: source) != nil,
              response.mimeType?.lowercased().hasPrefix("image/") == true,
              response.expectedContentLength <= maximumBytes else { throw PhotoError.unavailable }
    }

    private final class ImageRedirects: NSObject, URLSessionTaskDelegate {
        let source: Source
        init(source: Source) { self.source = source }
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest) async -> URLRequest? {
            guard let url = request.url, publicURL(from: url.absoluteString, source: source) != nil else { return nil }
            return request
        }
    }

    private enum PhotoError: Error { case unavailable }
}
