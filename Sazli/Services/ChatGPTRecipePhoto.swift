import Foundation

/// Downloads only an image explicitly attached to a public assistant response.
enum ChatGPTRecipePhoto {
    static let maximumBytes = 12_000_000

    static func publicURL(from text: String) -> URL? {
        guard let url = SourceLink.url(from: text), url.scheme?.lowercased() == "https",
              url.port == nil || url.port == 443,
              let host = url.host?.lowercased(),
              (host == "images.openai.com" && url.path.hasPrefix("/static-rsc-"))
                || host == "files.oaiusercontent.com" else { return nil }
        return url
    }

}
