import XCTest
@testable import Sazli

final class RecipeImportRoutingTests: XCTestCase {
    private let tikTok = "https://www.tiktok.com/@thesimplecravings/video/7694085059602550030"
    private let share = "https://chatgpt.com/share/6ae9a2ef-d8ec-83e9-8417-ab10621b8705"

    func testBareAndSharedVideoLinksUseTheSameReaderRoute() throws {
        for text in [tikTok, "https://vt.tiktok.com/ZSpRSQuyw/", "https://www.tiktok.com/t/ZSpRSQuyw/",
                     "https://m.tiktok.com/v/7694085059602550030.html", "https://youtu.be/o-jXn6P-4rM?t=30",
                     "https://www.youtube.com/shorts/o-jXn6P-4rM", "Mira este TikTok\n" + tikTok,
                     "Watch this video: https://youtu.be/o-jXn6P-4rM", "\u{200E}<" + tikTok + ">\u{200B}"] {
            guard case .video(let url) = try RecipeImportRouter.route(text) else {
                return XCTFail("Not routed to video reader: \(text)")
            }
            XCTAssertNotNil(SourceLink.videoRecipeURL(from: url.absoluteString))
        }
    }

    func testChatGPTAliasesAndTrailingSlashStayTheSamePublicShare() throws {
        guard case .chatGPT(let url) = try RecipeImportRouter.route("ChatGPT\n" + share) else {
            return XCTFail("Share wrapper was not recognized")
        }
        let alias = URL(string: share.replacingOccurrences(of: "chatgpt.com", with: "chat.openai.com") + "/?source=share")!
        XCTAssertTrue(SourceLink.sameChatGPTShare(url, alias))
        XCTAssertFalse(SourceLink.sameChatGPTShare(url, URL(string: "https://chatgpt.com/share/01234567-89ab-cdef-0123-456789abcdef")!))
    }

    func testFullRecipeTextTakesPriorityOverEmbeddedLink() throws {
        let text = "My eggs\nIngredients * Eggs * Salt Instructions 1. Mix. 2. Cook.\n" + tikTok
        guard case .draft(let draft) = try RecipeImportRouter.route(text) else {
            return XCTFail("Recipe text was discarded in favor of its source link")
        }
        XCTAssertEqual(draft.title, "My eggs")
        XCTAssertEqual(RecipeText.lines(in: draft.ingredients), ["Eggs", "Salt"])
        XCTAssertEqual(RecipeText.lines(in: draft.instructions), ["Mix.", "Cook."])
        XCTAssertEqual(draft.sourceURL, tikTok)
        XCTAssertEqual(draft.sourcePlatform, .tiktok)
    }

    func testAmbiguousPrivateAndUnsupportedLinksRemainEditableReferences() throws {
        for text in ["My private note\n" + share, tikTok + "\nhttps://youtu.be/o-jXn6P-4rM",
                     "https://chatgpt.com/c/6ae9a2ef-d8ec-83e9-8417-ab10621b8705",
                     "https://www.youtube.com/playlist?list=abc", "https://www.youtube.com.evil.test/watch?v=o-jXn6P-4rM"] {
            guard case .draft = try RecipeImportRouter.route(text) else {
                return XCTFail("Ambiguous/unsupported input triggered a remote reader: \(text)")
            }
        }
        XCTAssertThrowsError(try RecipeImportRouter.route("  "))
        XCTAssertThrowsError(try RecipeImportRouter.route(String(repeating: "x", count: RecipeImportParser.maximumBytes + 1)))
    }
}
