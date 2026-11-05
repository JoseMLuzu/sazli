import Foundation

/// Reads only a public post's exposed caption and cover, never private feeds or video content.
enum InstagramRecipeDocument {
    static let maximumHTMLBytes = 4_000_000

    static func read(from url: URL) async throws -> VideoRecipeImport {
        guard let source = SourceLink.instagramPostURL(from: url.absoluteString) else { throw ReadError.unavailable }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 25
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: URLRequest(url: source), delegate: Redirects(source: source))
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              let resolved = response.url, samePost(source, resolved),
              response.expectedContentLength <= maximumHTMLBytes else { throw ReadError.unavailable }
        var data = Data()
        for try await byte in bytes {
            guard data.count < maximumHTMLBytes else { throw ReadError.tooLarge }
            data.append(byte)
        }
        try Task.checkCancellation()
        return try recipe(in: String(decoding: data, as: UTF8.self), sourceURL: source)
    }

    static func recipe(in html: String, sourceURL: URL) throws -> VideoRecipeImport {
        guard html.utf8.count <= maximumHTMLBytes else { throw ReadError.tooLarge }
        guard SourceLink.instagramPostURL(from: sourceURL.absoluteString) != nil else { throw ReadError.unavailable }
        let tags = try NSRegularExpression(pattern: #"<(?:meta|link)\b[^>]*>"#, options: .caseInsensitive)
        var metadata: [String: String] = [:]
        var canonical: URL?
        for match in tags.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(match.range, in: html) else { continue }
            let attributes = attributes(in: String(html[range]))
            if attributes["rel"]?.lowercased() == "canonical", let href = attributes["href"] {
                canonical = URL(string: href)
            }
            if let key = attributes["property"] ?? attributes["name"], let value = attributes["content"] {
                metadata[key.lowercased()] = value
            }
        }
        guard let canonical, samePost(sourceURL, canonical),
              let raw = metadata["description"] ?? metadata["og:description"],
              !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              raw.utf8.count <= RecipeImportParser.maximumBytes else { throw ReadError.unavailable }
        let caption = unwrapCaption(raw)
        var draft = try RecipeCaptionParser.parse(caption, title: "Recipe from Instagram")
        draft.sourceURL = sourceURL.absoluteString
        draft.sourcePlatform = .instagram
        let photo = metadata["og:image"].flatMap { RecipeRemotePhoto.publicURL(from: $0, source: .instagram) }
        let incomplete = draft.ingredients.isEmpty || draft.instructions.isEmpty
            || caption.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("…")
        return VideoRecipeImport(draft: draft, photoURLs: photo.map { [$0] } ?? [], photoSource: .instagram,
            notice: incomplete ? "Instagram didn't expose complete supported recipe sections. Review the available caption or paste the full recipe text." : nil)
    }

    private static func samePost(_ first: URL, _ second: URL) -> Bool {
        guard let first = SourceLink.instagramPostURL(from: first.absoluteString),
              let second = SourceLink.instagramPostURL(from: second.absoluteString) else { return false }
        return first.lastPathComponent == second.lastPathComponent
    }

    private static func attributes(in tag: String) -> [String: String] {
        guard let expression = try? NSRegularExpression(pattern: #"([A-Za-z_:][A-Za-z0-9_:.-]*)\s*=\s*(["'])(.*?)\2"#,
                                                       options: .dotMatchesLineSeparators) else { return [:] }
        var attributes: [String: String] = [:]
        for match in expression.matches(in: tag, range: NSRange(tag.startIndex..., in: tag)) {
            guard let key = Range(match.range(at: 1), in: tag), let value = Range(match.range(at: 3), in: tag) else { continue }
            attributes[String(tag[key]).lowercased()] = decodeEntities(String(tag[value]))
        }
        return attributes
    }

    private static func decodeEntities(_ text: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: #"&(#x[0-9a-fA-F]+|#[0-9]+|amp|quot|apos|lt|gt|nbsp);"#) else { return text }
        var result = text
        let named = ["amp": "&", "quot": "\"", "apos": "'", "lt": "<", "gt": ">", "nbsp": " "]
        for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            guard let range = Range(match.range, in: result), let keyRange = Range(match.range(at: 1), in: result) else { continue }
            let key = String(result[keyRange])
            let number = key.hasPrefix("#x") ? UInt32(key.dropFirst(2), radix: 16) : key.hasPrefix("#") ? UInt32(key.dropFirst()) : nil
            let replacement = named[key] ?? number.flatMap { UnicodeScalar($0) }.map(String.init)
            if let replacement { result.replaceSubrange(range, with: replacement) }
        }
        return result
    }

    private static func unwrapCaption(_ text: String) -> String {
        guard let expression = try? NSRegularExpression(
            pattern: #"^[0-9.,KMBkmb]+ likes?, [0-9.,KMBkmb]+ comments? - [^\n]+?: "(.*)"[. \t]*$"#,
            options: .dotMatchesLineSeparators),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return text }
        return String(text[range])
    }

    private final class Redirects: NSObject, URLSessionTaskDelegate {
        let source: URL
        init(source: URL) { self.source = source }
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest) async -> URLRequest? {
            guard let url = request.url, samePost(source, url) else { return nil }
            return request
        }
    }

    enum ReadError: LocalizedError {
        case unavailable, tooLarge
        var errorDescription: String? {
            switch self {
            case .unavailable: "Instagram's public caption couldn't be read. Keep the link or paste the recipe text. Private, removed, and sign-in pages cannot be imported."
            case .tooLarge: "This Instagram page is too large. Paste the recipe caption instead."
            }
        }
    }
}
