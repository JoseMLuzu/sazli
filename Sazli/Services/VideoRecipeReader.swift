import Foundation

struct VideoRecipeImport {
    let draft: RecipeDraft
    let photoURLs: [URL]
    let photoSource: RecipeRemotePhoto.Source
    var notice: String?
}

enum VideoRecipeReader {
    static func platform(for url: URL) -> SourcePlatform {
        if SourceLink.instagramPostURL(from: url.absoluteString) != nil { return .instagram }
        return SourceLink.youTubeVideoID(from: url.absoluteString) != nil ? .youtube : .tiktok
    }

    static func read(from url: URL) async throws -> VideoRecipeImport {
        if SourceLink.instagramPostURL(from: url.absoluteString) != nil {
            return try await InstagramRecipeDocument.read(from: url)
        }
        if SourceLink.youTubeVideoID(from: url.absoluteString) != nil {
            return try await YouTubeRecipeDocument.read(from: url)
        }
        let result = try await TikTokRecipeDocument.read(from: url)
        let notice = result.draft.ingredients.isEmpty || result.draft.instructions.isEmpty
            ? "The public description doesn't contain complete ingredient and method sections. Review the available text before saving." : nil
        return VideoRecipeImport(draft: result.draft, photoURLs: result.photoURLs, photoSource: .tikTok, notice: notice)
    }
}
