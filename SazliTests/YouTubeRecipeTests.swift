import XCTest
@testable import Sazli

final class YouTubeRecipeTests: XCTestCase {
    private let id = "o-jXn6P-4rM"
    private var source: URL { URL(string: "https://youtu.be/\(id)?t=30")! }

    func testSupportedVideoRoutesKeepTheSameVideoIdentity() {
        for value in ["https://www.youtube.com/watch?v=\(id)&t=30", "https://youtu.be/\(id)?si=abc",
                      "https://m.youtube.com/watch?v=\(id)", "https://music.youtube.com/watch?v=\(id)",
                      "https://www.youtube.com/shorts/\(id)", "https://www.youtube.com/live/\(id)",
                      "https://www.youtube.com/embed/\(id)"] {
            XCTAssertEqual(SourceLink.youTubeVideoID(from: value), id, value)
            XCTAssertNotNil(SourceLink.videoRecipeURL(from: value))
        }
        for value in ["http://youtu.be/\(id)", "https://youtube.com.evil.test/watch?v=\(id)",
                      "https://www.youtube.com/playlist?list=abc", "https://www.youtube.com/watch?v=\(id)&v=POENEyhCmaA",
                      "https://www.youtube.com/watch?v=short", "https://user:pass@youtu.be/\(id)",
                      "https://youtu.be:444/\(id)"] {
            XCTAssertNil(SourceLink.youTubeVideoID(from: value), value)
        }
    }

    func testDescriptionImportsExplicitSectionsAndKeepsOriginalLink() throws {
        let caption = "Ingredients: • Eggs • Salt Instructions: 1. Mix. 2. Cook. Notes: Use a {warm} plate."
        let result = try YouTubeRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertEqual(result.draft.title, "Eggs {easy} \"recipe\"")
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), ["Eggs", "Salt"])
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions), ["Mix.", "Cook."])
        XCTAssertTrue(result.draft.description.contains("{warm}"))
        XCTAssertEqual(result.draft.sourceURL, source.absoluteString)
        XCTAssertEqual(result.draft.sourcePlatform, .youtube)
        XCTAssertEqual(result.photoURLs.map(\.host), ["i.ytimg.com"])
        XCTAssertNil(result.draft.validationMessage)
    }

    func testIngredientsOnlyExcludeUtensilsAndReadExplicitPortions() throws {
        let caption = "(2 Personas)\nINGREDIENTES:\n*400 g pollo\n*Sal\n*1 ajo\nUTENSILIOS:\n*Sartén\n*Cuchillo"
        let result = try YouTubeRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), ["400 g pollo", "Sal", "1 ajo"])
        XCTAssertEqual(result.draft.servings, "2")
        XCTAssertTrue(result.draft.instructions.isEmpty)
        XCTAssertTrue(result.draft.description.contains("Sartén"))
        XCTAssertFalse(result.draft.ingredients.contains("Cuchillo"))
    }

    func testMixedUnlabeledDirectionsStayAvailableForManualReview() throws {
        let caption = "Ingredients:\nChicken\nSalt\nBake at 180°C for 20 minutes.\nAdd pasta.\nFry for 3 minutes."
        let result = try YouTubeRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertTrue(result.draft.ingredients.isEmpty)
        XCTAssertTrue(result.draft.instructions.isEmpty)
        XCTAssertEqual(result.draft.description, caption)
        XCTAssertNotNil(result.notice)
        let empty = try YouTubeRecipeDocument.recipe(in: document(""), sourceURL: source)
        XCTAssertTrue(empty.draft.ingredients.isEmpty)
        XCTAssertTrue(empty.draft.instructions.isEmpty)
        XCTAssertEqual(empty.draft.sourceURL, source.absoluteString)
    }

    func testLongStepByStepHeadingSeparatesWrittenMethod() throws {
        let caption = "Ingredients\nEggs\nSalt\nStep by step instructions for making the recipe\n1. Mix.\n2. Cook."
        let result = try YouTubeRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), ["Eggs", "Salt"])
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions), ["Mix.", "Cook."])
    }

    func testIngredientWordInsideAStepCannotSwitchBackToIngredientFields() throws {
        let caption = "Ingredients: • Eggs • Salt Instructions: 1. Mix the following ingredients: eggs and salt. 2. Cook."
        let result = try YouTubeRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), ["Eggs", "Salt"])
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions), ["Mix the following ingredients: eggs and salt.", "Cook."])
    }

    func testBlockedMismatchedMalformedAndOversizedPagesDoNotProduceRecipes() throws {
        for html in [try document("Ingredients: • Eggs", status: "LOGIN_REQUIRED"),
                     try document("Ingredients: • Eggs", videoID: "POENEyhCmaA"),
                     "<html>Consent required</html>", "var ytInitialPlayerResponse = {broken};",
                     String(repeating: "x", count: YouTubeRecipeDocument.maximumHTMLBytes + 1)] {
            XCTAssertThrowsError(try YouTubeRecipeDocument.recipe(in: html, sourceURL: source))
        }
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://i.ytimg.com.evil.test/image.jpg", source: .youtube))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://images.openai.com/static-rsc-4/image", source: .youtube))
    }

    private func document(_ caption: String, status: String = "OK", videoID: String? = nil) throws -> String {
        let object: [String: Any] = ["playabilityStatus": ["status": status], "videoDetails": [
            "videoId": videoID ?? id, "title": "Eggs {easy} \"recipe\"", "shortDescription": caption,
            "thumbnail": ["thumbnails": [["url": "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"],
                                          ["url": "https://evil.test/image.jpg"]]]]]
        let json = String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
        return "<script>var ytInitialPlayerResponse = \(json);</script>"
    }
}
