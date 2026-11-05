import Foundation

enum RecipeImportRoute {
    case draft(RecipeDraft)
    case chatGPT(URL)
    case video(URL)
}

/// Shared by pasted links and the pending share inbox; full recipe text takes priority over links in it.
enum RecipeImportRouter {
    static func route(_ input: String, platform: SourcePlatform = .manual) throws -> RecipeImportRoute {
        var fallback = try RecipeImportParser.parse(input)
        if let url = SourceLink.url(from: input) { return route(url, fallback: fallback) }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = text.components(separatedBy: .newlines).first ?? ""
        let startsWithList = firstLine.range(of: #"^[ \t]*[-*•◦▪✅–—]\uFE0F?(?:\s+|(?=\p{N}))"#,
                                             options: .regularExpression) != nil
        let hasTitleLine = text.rangeOfCharacter(from: .newlines) != nil
            && firstLine.trimmingCharacters(in: CharacterSet(charactersIn: "#*_ ")) == fallback.title
            && !startsWithList && !RecipeCaptionParser.containsSectionHeading(firstLine)
        let title = hasTitleLine ? fallback.title : "Imported recipe"
        let caption = hasTitleLine ? String(text.dropFirst(firstLine.count)).trimmingCharacters(in: .newlines) : text
        var structured = try RecipeCaptionParser.parse(caption, title: title)
        if !structured.ingredients.isEmpty || !structured.instructions.isEmpty {
            structured.sourceURL = fallback.sourceURL
            structured.sourcePlatform = fallback.sourceURL.isEmpty ? platform : fallback.sourcePlatform
            return .draft(structured)
        }
        if let url = sharedLink(in: text) { return route(url, fallback: fallback) }
        if fallback.sourceURL.isEmpty { fallback.sourcePlatform = platform }
        return .draft(fallback)
    }

    private static func route(_ url: URL, fallback: RecipeDraft) -> RecipeImportRoute {
        if let share = SourceLink.chatGPTShareURL(from: url.absoluteString) { return .chatGPT(share) }
        if let video = SourceLink.videoRecipeURL(from: url.absoluteString) { return .video(video) }
        return .draft(fallback)
    }

    private static func sharedLink(in text: String) -> URL? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return nil }
        let matches = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard matches.count == 1, let match = matches.first, let url = match.url,
              SourceLink.videoRecipeURL(from: url.absoluteString) != nil || SourceLink.chatGPTShareURL(from: url.absoluteString) != nil,
              let range = Range(match.range, in: text) else { return nil }
        let rest = text.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard rest.count < 160 else { return nil }
        let prefix = rest.lowercased()
        guard rest.isEmpty || ["watch", "check out", "mira", "mira este", "tiktok", "youtube", "instagram", "chatgpt"]
            .contains(where: { prefix.hasPrefix($0) }) else { return nil }
        return url
    }
}
