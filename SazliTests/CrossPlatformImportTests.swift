import XCTest
@testable import Sazli

/// Synthetic documents isolate format failures from network availability and private accounts.
final class CrossPlatformImportTests: XCTestCase {
    private let instagram = URL(string: "https://www.instagram.com/reel/C3DxXB-KVno/?igsh=test")!
    private let youtube = URL(string: "https://youtu.be/o-jXn6P-4rM")!
    private let tiktok = URL(string: "https://vt.tiktok.com/ZSpFyLctE/")!
    private let share = URL(string: "https://chatgpt.com/share/01234567-89ab-cdef-0123-456789abcdef")!

    @MainActor func testDescriptionFormatsAcrossThreePlatformDocuments() throws {
        let samples: [(String, [String], [String])] = [
            ("Ingredients (serves 2): • Eggs • Salt Method: 1. Mix. 2. Cook.", ["Eggs", "Salt"], ["Mix.", "Cook."]),
            ("Ingredients ½ cup milk 2 eggs  ¼ tsp salt Method 1. Mix. 2. Cook.", ["½ cup milk", "2 eggs", "¼ tsp salt"], ["Mix.", "Cook."]),
            ("Ingredients 1 1/2 cups milk 2 eggs  1½ tsp salt Method 1. Mix. 2. Cook.", ["1 1/2 cups milk", "2 eggs", "1½ tsp salt"], ["Mix.", "Cook."]),
            ("Ingredients:\n| Ingredient | Quantity |\n| --- | --- |\n| Eggs | 2 |\n| Salt | 1 tsp |\nMethod:\n1. Mix.\n2. Cook.", ["2 Eggs", "1 tsp Salt"], ["Mix.", "Cook."]),
            ("Ingredientes:\n| Cantidad | Ingrediente | Notas |\n| --- | --- | --- |\n| 2 | Huevos | batidos |\n| 1,5 tazas | Leche | |\nPreparación:\n1. Mezclar.\n2. Cocinar.", ["2 Huevos — batidos", "1,5 tazas Leche"], ["Mezclar.", "Cocinar."]),
            ("Ingredients: • Eggs Method: 1. Cook. Neven's Top Tip: Keep warm.", ["Eggs"], ["Cook."]),
            ("Ingredients: • Eggs Method: 1. Mix — gently, keeping the sauce smooth. 2. Serve.", ["Eggs"], ["Mix — gently, keeping the sauce smooth.", "Serve."])
        ]
        for (index, sample) in samples.enumerated() {
            for platform in [SourcePlatform.tiktok, .youtube, .instagram] {
                try XCTContext.runActivity(named: "document-\(platform.rawValue)-\(index)") { _ in
                    let imported = try document(sample.0, platform: platform)
                    XCTAssertEqual(RecipeText.lines(in: imported.ingredients), sample.1)
                    XCTAssertEqual(RecipeText.lines(in: imported.instructions), sample.2)
                    XCTAssertEqual(imported.sourcePlatform, platform)
                }
            }
        }
    }

    @MainActor func testHeaderlessVariantsThroughEachPublicDocumentAdapter() throws {
        let variants = ["1. Mix gently. 2. Cook until set.", "1) Mix gently. 2) Cook until set.",
            "(1) Mix gently. (2) Cook until set.", "a) Mix gently. b) Cook until set.",
            "A) Mix gently. B) Cook until set.", "1️⃣ Mix gently. 2️⃣ Cook until set.",
            "Step 1: Mix gently. Step 2: Cook until set.", "Paso 1: Mix gently. Paso 2: Cook until set."]
        for method in variants {
            for platform in [SourcePlatform.tiktok, .youtube, .instagram] {
                let draft = try document("Family eggs * 1 cup milk * 2 eggs " + method, platform: platform)
                XCTAssertEqual(RecipeText.ingredientLines(in: draft.ingredients), ["1 cup milk", "2 eggs"])
                XCTAssertEqual(RecipeText.lines(in: draft.instructions), ["Mix gently.", "Cook until set."])
                XCTAssertEqual(draft.sourcePlatform, platform)
            }
        }
    }

    func testChatGPTEmojiHeadingsTablesAndPortionVariants() throws {
        for heading in ["Ingredients 🥣", "🥣 Ingredients (serves 2)", "Ingredients (2–3 servings)", "Lista de ingredientes"] {
            let message = "## Eggs\n### \(heading)\n| Ingredient | Quantity |\n| --- | --- |\n| Eggs | 2 |\n| Salt | 1 tsp |\n### Method 👩‍🍳\n1. Mix.\n2. Cook."
            let candidate = try XCTUnwrap(ChatGPTRecipeExtractor.recipes(in: [message], sourceURL: share).first, heading)
            XCTAssertEqual(RecipeText.lines(in: candidate.draft.ingredients), ["2 Eggs", "1 tsp Salt"])
            XCTAssertEqual(RecipeText.lines(in: candidate.draft.instructions), ["Mix.", "Cook."])
            if heading.contains("serves 2") { XCTAssertEqual(candidate.draft.servings, "2") }
            if heading.contains("2–3") {
                XCTAssertEqual(candidate.draft.servings, "1")
                XCTAssertTrue(candidate.draft.description.contains("2–3"))
            }
        }
    }

    func testInstagramRoutesEntitiesIdentityAndFallbacks() throws {
        for value in [instagram.absoluteString, "https://instagram.com/p/DbyCp--A0sF/", "https://www.instagram.com/tv/C3DxXB-KVno/", "https://www.instagram.com/reels/C3DxXB-KVno/"] {
            XCTAssertNotNil(SourceLink.instagramPostURL(from: value))
            XCTAssertEqual(SourceLink.platform(for: value), .instagram)
            guard case .video = try RecipeImportRouter.route(value) else { return XCTFail("No public reader") }
        }
        for value in ["https://instagram.com.evil.test/reel/C3DxXB-KVno/", "http://instagram.com/reel/C3DxXB-KVno/", "https://instagram.com/accounts/login/", "https://instagram.com/stories/user/123", "https://user:pass@instagram.com/p/C3DxXB-KVno/"] {
            XCTAssertNil(SourceLink.instagramPostURL(from: value))
        }
        guard case .video = try RecipeImportRouter.route("Instagram\n" + instagram.absoluteString) else {
            return XCTFail("Instagram share wrapper stayed unstructured")
        }
        let html = "<link href='https://www.instagram.com/p/C3DxXB-KVno/' rel='canonical'><meta content='Ingredients: • Cr&#xe8;me • &#189; cup milk Method: 1. Mix &amp; cook.' name='description'><meta content='https://scontent.cdninstagram.com/dish.jpg' property='og:image'>"
        let result = try InstagramRecipeDocument.recipe(in: html, sourceURL: instagram)
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), ["Crème", "½ cup milk"])
        XCTAssertEqual(result.draft.instructions, "Mix & cook.")
        XCTAssertEqual(result.draft.sourceURL, instagram.absoluteString)
        XCTAssertEqual(result.photoURLs.count, 1)
        for invalid in ["<html>Log in</html>", html.replacingOccurrences(of: "p/C3DxXB-KVno", with: "p/OTHER_POST"), String(repeating: "x", count: InstagramRecipeDocument.maximumHTMLBytes + 1)] {
            XCTAssertThrowsError(try InstagramRecipeDocument.recipe(in: invalid, sourceURL: instagram))
        }
        let partial = try document("A meal for tonight…", platform: .instagram)
        XCTAssertTrue(partial.ingredients.isEmpty)
        XCTAssertTrue(partial.instructions.isEmpty)
        XCTAssertTrue(partial.description.contains("A meal for tonight"))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://scontent.cdninstagram.com.evil.test/dish", source: .instagram))
    }

    func testUnsupportedOrMalformedTablesStayEditableInsteadOfLosingCells() throws {
        let text = "Ingredients:\n| Product | Cost |\n| --- | --- |\n| Eggs | $2 |\nMethod:\n1. Cook."
        let draft = try RecipeImportParser.parse(text)
        XCTAssertTrue(draft.ingredients.contains("Product"))
        XCTAssertTrue(draft.ingredients.contains("$2"))
        let malformed = try RecipeImportParser.parse("Ingredients:\n| Ingredient | Quantity |\n| --- | --- |\n| Eggs | 2 | extra |\nMethod:\n1. Cook.")
        XCTAssertTrue(malformed.ingredients.contains("extra"))
    }

    private func document(_ caption: String, platform: SourcePlatform) throws -> RecipeDraft {
        switch platform {
        case .instagram:
            let escaped = ("12 likes, 3 comments - cook on November 4, 2026: \"" + caption + "\". ")
                .replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "\"", with: "&quot;")
            let html = "<link rel=\"canonical\" href=\"https://www.instagram.com/reel/C3DxXB-KVno/\"><meta name=\"description\" content=\"\(escaped)\">"
            return try InstagramRecipeDocument.recipe(in: html, sourceURL: instagram).draft
        case .youtube:
            let object: [String: Any] = ["playabilityStatus": ["status": "OK"], "videoDetails": ["videoId": "o-jXn6P-4rM", "title": "Eggs", "shortDescription": caption]]
            let json = String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
            return try YouTubeRecipeDocument.recipe(in: "var ytInitialPlayerResponse = \(json);", sourceURL: youtube).draft
        default:
            let object: [String: Any] = ["__DEFAULT_SCOPE__": ["webapp.video-detail": ["itemInfo": ["itemStruct": ["desc": caption]]]]]
            let json = String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
            return try TikTokRecipeDocument.recipe(in: "<script id='__UNIVERSAL_DATA_FOR_REHYDRATION__'>\(json)</script>", sourceURL: tiktok).draft
        }
    }
}
