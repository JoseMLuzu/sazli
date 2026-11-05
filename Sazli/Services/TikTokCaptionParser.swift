import Foundation

enum TikTokCaptionParser {
    static func parse(_ caption: String) throws -> RecipeDraft {
        try RecipeCaptionParser.parse(caption, title: "Recipe from TikTok")
    }
}
