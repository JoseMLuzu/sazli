import Foundation

/// Supported photo URLs exposed by a public ChatGPT recipe response.
enum ChatGPTRecipePhoto {
    static let maximumBytes = RecipeRemotePhoto.maximumBytes
    static func publicURL(from text: String) -> URL? {
        RecipeRemotePhoto.publicURL(from: text, source: .chatGPT)
    }
    static func load(from urls: [URL]) async -> Data? {
        await RecipeRemotePhoto.load(from: urls, source: .chatGPT)
    }
    static func validate(_ response: URLResponse) throws {
        try RecipeRemotePhoto.validate(response, source: .chatGPT)
    }
}
