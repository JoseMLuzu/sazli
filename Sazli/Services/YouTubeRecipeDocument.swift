import Foundation

/// Reads only public video descriptions and thumbnails, without a key or transcript extraction.
enum YouTubeRecipeDocument {
    static let maximumHTMLBytes = 4_000_000

    static func read(from url: URL) async throws -> VideoRecipeImport {
        guard let id = SourceLink.youTubeVideoID(from: url.absoluteString),
              let canonical = URL(string: "https://www.youtube.com/watch?v=\(id)") else { throw ReadError.unavailable }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 25
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: URLRequest(url: canonical), delegate: Redirects(id: id))
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              let resolved = response.url, SourceLink.youTubeVideoID(from: resolved.absoluteString) == id,
              response.expectedContentLength <= maximumHTMLBytes else { throw ReadError.unavailable }
        var data = Data()
        for try await byte in bytes {
            guard data.count < maximumHTMLBytes else { throw ReadError.tooLarge }
            data.append(byte)
        }
        try Task.checkCancellation()
        return try recipe(in: String(decoding: data, as: UTF8.self), sourceURL: url)
    }

    static func recipe(in html: String, sourceURL: URL) throws -> VideoRecipeImport {
        guard html.utf8.count <= maximumHTMLBytes else { throw ReadError.tooLarge }
        guard let expectedID = SourceLink.youTubeVideoID(from: sourceURL.absoluteString) else { throw ReadError.unavailable }
        let pattern = try NSRegularExpression(pattern: #"(?:var\s+)?(?:ytInitialPlayerResponse|window\["ytInitialPlayerResponse"\])\s*=\s*"#)
        for match in pattern.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(match.range, in: html),
                  let object = jsonObject(in: html, startingAt: range.upperBound),
                  let playability = object["playabilityStatus"] as? [String: Any], playability["status"] as? String == "OK",
                  let details = object["videoDetails"] as? [String: Any], details["videoId"] as? String == expectedID,
                  let title = details["title"] as? String, !title.isEmpty else { continue }
            let caption = details["shortDescription"] as? String ?? ""
            guard caption.utf8.count <= RecipeImportParser.maximumBytes else { throw ReadError.tooLarge }
            var draft = try RecipeCaptionParser.parse(caption, title: title.replacingOccurrences(of: "\n", with: " "))
            var notice: String?
            // Unlabeled cooking directions inside an ingredient section are not a reliable ingredient list.
            let mixedLines = RecipeText.lines(in: draft.ingredients).filter {
                $0.range(of: #"^(?:add|bake|cook|fry|heat|repeat|sprinkle|serve|bring|stir|añade|agrega|cocina|hornea|sirve)\b"#,
                         options: [.regularExpression, .caseInsensitive]) != nil
            }
            if draft.instructions.isEmpty, mixedLines.count >= 2 {
                draft.ingredients = ""
                draft.description = caption
                notice = "This description mixes ingredients and cooking directions. Its original text is available for you to organize."
            } else if draft.ingredients.isEmpty || draft.instructions.isEmpty {
                notice = "The description doesn't contain complete supported ingredient and method sections. Review the available text before saving."
            }
            draft.sourceURL = sourceURL.absoluteString
            draft.sourcePlatform = .youtube
            let thumbnail = details["thumbnail"] as? [String: Any]
            let images = thumbnail?["thumbnails"] as? [[String: Any]] ?? []
            let urls = images.reversed().compactMap { ($0["url"] as? String).flatMap {
                RecipeRemotePhoto.publicURL(from: $0, source: .youtube)
            } }
            return VideoRecipeImport(draft: draft, photoURLs: Array(urls.prefix(2)), photoSource: .youtube, notice: notice)
        }
        throw ReadError.unavailable
    }

    private static func jsonObject(in html: String, startingAt start: String.Index) -> [String: Any]? {
        guard start < html.endIndex, html[start] == "{" else { return nil }
        var depth = 0
        var quoted = false
        var escaped = false
        for index in html.indices[start...] {
            let character = html[index]
            if quoted {
                if escaped { escaped = false }
                else if character == "\\" { escaped = true }
                else if character == "\"" { quoted = false }
            } else if character == "\"" { quoted = true }
            else if character == "{" { depth += 1 }
            else if character == "}" {
                depth -= 1
                if depth == 0 {
                    return (try? JSONSerialization.jsonObject(with: Data(html[start...index].utf8))) as? [String: Any]
                }
            }
        }
        return nil
    }

    private final class Redirects: NSObject, URLSessionTaskDelegate {
        let id: String
        init(id: String) { self.id = id }
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest) async -> URLRequest? {
            guard let url = request.url, SourceLink.youTubeVideoID(from: url.absoluteString) == id else { return nil }
            return request
        }
    }

    enum ReadError: LocalizedError {
        case unavailable, tooLarge
        var errorDescription: String? {
            switch self {
            case .unavailable: "YouTube's public description couldn't be read. Keep the link or paste its description instead."
            case .tooLarge: "This YouTube page is too large. Paste the recipe description instead."
            }
        }
    }
}
