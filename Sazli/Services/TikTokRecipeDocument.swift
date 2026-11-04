import Foundation

struct TikTokRecipeImport {
    let draft: RecipeDraft
    let photoURLs: [URL]
}

/// Reads explicit public caption text; never transcribes or guesses video content.
enum TikTokRecipeDocument {
    static let maximumHTMLBytes = 4_000_000

    static func read(from url: URL) async throws -> TikTokRecipeImport {
        guard SourceLink.tikTokVideoURL(from: url.absoluteString) != nil else { throw ReadError.unavailable }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 25
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let (bytes, response) = try await session.bytes(for: URLRequest(url: url), delegate: VideoRedirects())
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              let resolved = response.url, SourceLink.tikTokVideoURL(from: resolved.absoluteString) != nil,
              response.expectedContentLength <= maximumHTMLBytes else { throw ReadError.unavailable }
        var data = Data()
        for try await byte in bytes {
            guard data.count < maximumHTMLBytes else { throw ReadError.tooLarge }
            data.append(byte)
        }
        try Task.checkCancellation()
        return try recipe(in: String(decoding: data, as: UTF8.self), sourceURL: url)
    }

    static func recipe(in html: String, sourceURL: URL) throws -> TikTokRecipeImport {
        guard html.utf8.count <= maximumHTMLBytes else { throw ReadError.tooLarge }
        let expression = try NSRegularExpression(
            pattern: #"<script\b[^>]*\bid=["']__UNIVERSAL_DATA_FOR_REHYDRATION__["'][^>]*>(.*?)</script>"#,
            options: [.dotMatchesLineSeparators, .caseInsensitive])
        guard let match = expression.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html),
              let root = try? JSONSerialization.jsonObject(with: Data(html[range].utf8)) as? [String: Any],
              let scope = root["__DEFAULT_SCOPE__"] as? [String: Any],
              let detail = scope["webapp.video-detail"] as? [String: Any],
              let info = detail["itemInfo"] as? [String: Any],
              let item = info["itemStruct"] as? [String: Any],
              let caption = item["desc"] as? String,
              !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              caption.utf8.count <= RecipeImportParser.maximumBytes else { throw ReadError.unavailable }
        var draft = try TikTokCaptionParser.parse(caption)
        draft.sourceURL = sourceURL.absoluteString
        draft.sourcePlatform = .tiktok
        if let author = item["author"] as? [String: Any], let name = author["nickname"] as? String, !name.isEmpty {
            draft.description += "\n\nCreator: \(name)"
        }
        let video = item["video"] as? [String: Any] ?? [:]
        var urls: [URL] = []
        for key in ["originCover", "cover"] {
            if let value = video[key] as? String,
               let url = RecipeRemotePhoto.publicURL(from: value, source: .tikTok), !urls.contains(url) {
                urls.append(url)
            }
        }
        return TikTokRecipeImport(draft: draft, photoURLs: urls)
    }

    private final class VideoRedirects: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask,
                        willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest) async -> URLRequest? {
            guard let url = request.url, SourceLink.tikTokVideoURL(from: url.absoluteString) != nil else { return nil }
            return request
        }
    }

    enum ReadError: LocalizedError {
        case unavailable, tooLarge
        var errorDescription: String? {
            switch self {
            case .unavailable: "TikTok's public description couldn't be read. The video may be private, unavailable, or blocked. You can keep the link or paste its description."
            case .tooLarge: "This TikTok page is too large. Paste the recipe description instead."
            }
        }
    }
}
