import XCTest
import SwiftData
@testable import Sazli

final class TikTokRecipeTests: XCTestCase {
    private let link = URL(string: "https://vt.tiktok.com/ZSpRSQuyw/")!

    func testOnlySupportedPublicTikTokVideosAreRead() {
        XCTAssertNotNil(SourceLink.tikTokVideoURL(from: link.absoluteString))
        XCTAssertNotNil(SourceLink.tikTokVideoURL(from: "https://vm.tiktok.com/abc/"))
        XCTAssertNotNil(SourceLink.tikTokVideoURL(from: "https://www.tiktok.com/@chef/video/123?lang=en"))
        for value in ["http://vt.tiktok.com/abc/", "https://www.tiktok.com/login", "https://www.tiktok.com/@chef",
                      "https://vt.tiktok.com.evil.test/abc/", "https://vt.tiktok.com:444/abc/",
                      "https://user:password@vt.tiktok.com/abc/", "https://www.tiktok.com/@chef/video/invalid"] {
            XCTAssertNil(SourceLink.tikTokVideoURL(from: value))
        }
    }

    func testPublicCaptionImportsExplicitIngredientsStepsAndPortions() throws {
        let caption = """
        Decent! I'd give it a 7.8/10. SERVES: 4 WHAT YOU’LL NEED: • 400g potato gnocchi • 640g chicken breast, diced • 190g reduced-fat green pesto • 1 red onion, chopped • 1 green pepper, chopped • 100g peas • 100g sundried tomatoes, chopped • 100g baby spinach • 150ml chicken stock • 150g fat-free Greek yoghurt • 15g garlic, minced • 75g light mozzarella METHOD: 1. Add everything to a large baking dish and mix well. 2. Bake at 200°C for around 40 minutes, until the chicken is cooked through and the cheese is golden. 3. Divide into 4 servings and enjoy. PER SERVING: 531 calories | 49g protein | 41g carbs | 18g fat Original recipe by @gymtrav
        """
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: link)
        XCTAssertEqual(result.draft.title, "Recipe from TikTok")
        XCTAssertEqual(result.draft.servings, "4")
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients).count, 12)
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions).count, 3)
        XCTAssertTrue(result.draft.instructions.contains("200°C"))
        XCTAssertFalse(result.draft.instructions.contains("531 calories"))
        XCTAssertTrue(result.draft.description.contains("7.8/10"))
        XCTAssertTrue(result.draft.description.contains("@gymtrav"))
        XCTAssertTrue(result.draft.description.contains("Creator: Louis Howard"))
        XCTAssertTrue(result.draft.preparationTime.isEmpty) // Cooking time isn't assumed to be total prep time.
        XCTAssertEqual(result.draft.sourceURL, link.absoluteString)
        XCTAssertEqual(result.draft.sourcePlatform, .tiktok)
        XCTAssertNil(result.draft.validationMessage)
        XCTAssertEqual(result.photoURLs.count, 1)
        XCTAssertNil(result.draft.imageData)
    }

    func testIncompleteDescriptionAndRangesStayUninvented() throws {
        let result = try TikTokRecipeDocument.recipe(in: document("Try this meal! SERVES: 2–3 #dinner"), sourceURL: link)
        XCTAssertTrue(result.draft.ingredients.isEmpty)
        XCTAssertTrue(result.draft.instructions.isEmpty)
        XCTAssertTrue(result.draft.preparationTime.isEmpty)
        XCTAssertEqual(result.draft.servings, "1")
        XCTAssertTrue(result.draft.description.contains("2–3"))
        let spanish = try TikTokRecipeDocument.recipe(in: document("PORCIONES: 2 INGREDIENTES: • Huevos • Sal PREPARACIÓN: 1. Cocinar. 2. Servir. NOTAS: Sin aceite."), sourceURL: link)
        XCTAssertEqual(spanish.draft.servings, "2")
        XCTAssertEqual(RecipeText.lines(in: spanish.draft.instructions).count, 2)
        XCTAssertFalse(spanish.draft.instructions.contains("Sin aceite"))
    }

    func testUnreadablePagesAndUnrelatedCoverHostsAreRejected() throws {
        for html in ["<html>Log in</html>", "<script id='__UNIVERSAL_DATA_FOR_REHYDRATION__'>{broken}</script>",
                     String(repeating: "x", count: TikTokRecipeDocument.maximumHTMLBytes + 1)] {
            XCTAssertThrowsError(try TikTokRecipeDocument.recipe(in: html, sourceURL: link))
        }
        XCTAssertNotNil(RecipeRemotePhoto.publicURL(from: "https://p19-common-sign.tiktokcdn.com/dish.image", source: .tikTok))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://p19-common-sign.tiktokcdn.com.evil.test/dish", source: .tikTok))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://images.openai.com/static-rsc-4/dish", source: .tikTok))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://p19-common-sign.tiktokcdn.com/dish", source: .chatGPT))
    }

    func testTacoMacCaptionWithoutColonsSeparatesNineIngredientsAndSevenSteps() throws {
        let caption = tacoMacCaption
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: link)
        let ingredients = RecipeText.lines(in: result.draft.ingredients)
        let steps = RecipeText.lines(in: result.draft.instructions)
        XCTAssertEqual(ingredients.count, 9)
        XCTAssertEqual(ingredients.first, "1 lb ground beef")
        XCTAssertTrue(ingredients.contains("½ cup salsa"))
        XCTAssertTrue(ingredients.contains("1½ cups Mexican blend cheese, divided"))
        XCTAssertEqual(ingredients.last, "Optional: parsley for topping")
        XCTAssertEqual(steps.count, 7)
        XCTAssertTrue(result.draft.instructions.contains("1¼ cups of mexican cheese"))
        XCTAssertEqual(steps.last, "Top with parsley if desired and serve warm!")
        XCTAssertFalse(result.draft.ingredients.contains("In a large skillet"))
        XCTAssertFalse(result.draft.instructions.contains("#easydinnerideas"))
        XCTAssertTrue(result.draft.description.contains("#easydinnerideas"))
        XCTAssertTrue(result.draft.description.contains("one pan taco mac"))
        XCTAssertTrue(result.draft.preparationTime.isEmpty)
    }

    func testNoColonHeadingsSupportBilingualListsWithoutChangingDecimalQuantities() throws {
        let caption = "Ingredientes * ½ taza de leche * Sal Preparación 1. Mezclar con 0.5 litros de agua. 2. Cocinar. #receta"
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: link)
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), ["½ taza de leche", "Sal"])
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions), ["Mezclar con 0.5 litros de agua.", "Cocinar."])
        XCTAssertTrue(result.draft.description.contains("#receta"))
    }

    func testOrdinaryMentionsOfIngredientsAndInstructionsStayInDescription() throws {
        let result = try TikTokRecipeDocument.recipe(in: document("These ingredients are delicious. Follow the instructions in the video! #dinner"), sourceURL: link)
        XCTAssertTrue(result.draft.ingredients.isEmpty)
        XCTAssertTrue(result.draft.instructions.isEmpty)
        XCTAssertTrue(result.draft.description.contains("These ingredients are delicious"))
    }

    @MainActor func testRecoverStoredTikTokDescriptionOnlyAfterExplicitSave() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy-tiktok.store")
        let originalText = tacoMacCaption + "\n\nCreator: alexis"
        let id: UUID
        do {
            let container = try RecipeStore.container(at: url)
            var original = RecipeDraft()
            original.title = "My taco mac"
            original.description = originalText
            original.sourceURL = "https://www.tiktok.com/@thesimplecravings/video/7694085059602550030"
            original.sourcePlatform = .tiktok
            original.preparationTime = "25"
            original.servings = "3"
            original.imageData = Data([1, 2, 3])
            let recipe = try RecipeStore.save(original, editing: nil, in: container.mainContext)
            recipe.notes = "Less salt next time"
            recipe.isFavorite = true
            try RecipeStore.commit(in: container.mainContext)
            id = recipe.id
            var review = RecipeDraft(recipe: recipe)
            XCTAssertTrue(review.recoverTikTokSectionsIfNeeded())
            XCTAssertEqual(RecipeText.lines(in: review.ingredients).count, 9)
            XCTAssertEqual(RecipeText.lines(in: review.instructions).count, 7)
            XCTAssertEqual(review.title, original.title)
            XCTAssertEqual(review.preparationTime, "25")
            XCTAssertEqual(review.servings, "3")
            XCTAssertEqual(review.imageData, original.imageData)
            XCTAssertTrue(review.description.contains("Creator: alexis"))
            XCTAssertFalse(review.instructions.contains("#easydinnerideas"))
            // Opening/canceling the review cannot mutate the persisted recipe.
            XCTAssertEqual(recipe.recipeDescription, originalText)
            XCTAssertTrue(recipe.ingredients.isEmpty)
            XCTAssertTrue(recipe.instructions.isEmpty)
            try RecipeStore.save(review, editing: recipe, in: container.mainContext)
        }
        let reopened = try RecipeStore.container(at: url)
        let recipes = try reopened.mainContext.fetch(FetchDescriptor<Recipe>())
        XCTAssertEqual(recipes.count, 1)
        let saved = try XCTUnwrap(recipes.first)
        XCTAssertEqual(saved.id, id)
        XCTAssertEqual(saved.ingredientLines.count, 9)
        XCTAssertEqual(saved.instructionLines.count, 7)
        XCTAssertEqual(saved.notes, "Less salt next time")
        XCTAssertTrue(saved.isFavorite)
    }

    func testSectionRecoveryPreservesManualPartialAndAlreadyStructuredDrafts() throws {
        var source = RecipeDraft()
        source.sourceURL = link.absoluteString
        source.sourcePlatform = .tiktok
        source.description = tacoMacCaption
        var manual = source
        manual.sourcePlatform = .manual
        XCTAssertFalse(manual.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(manual.description, tacoMacCaption)
        var partial = source
        partial.description = "Ingredients: • Eggs"
        let untouched = partial
        XCTAssertFalse(partial.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(partial, untouched)
        var edited = source
        edited.ingredients = "My edited ingredients"
        let edits = edited
        XCTAssertFalse(edited.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(edited, edits)
        XCTAssertTrue(source.recoverTikTokSectionsIfNeeded())
        let recovered = source
        XCTAssertFalse(source.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(source, recovered)
    }

    func testSourceDetailsFillEmptyFieldsAndPreserveExistingEdits() throws {
        let imported = try TikTokCaptionParser.parse(tacoMacCaption)
        var edited = RecipeDraft()
        edited.title = "Family taco mac"
        edited.description = "My own version"
        edited.ingredients = "Keep my quantities"
        edited.preparationTime = "35"
        edited.servings = "2"
        edited.category = .dinner
        edited.imageData = Data([1, 2, 3])
        edited.sourceURL = link.absoluteString
        edited.sourcePlatform = .tiktok
        edited.fillEmptyDetails(from: imported, useDefaultServings: true)
        XCTAssertEqual(edited.title, "Family taco mac")
        XCTAssertEqual(edited.description, "My own version")
        XCTAssertEqual(edited.ingredients, "Keep my quantities")
        XCTAssertEqual(RecipeText.lines(in: edited.instructions).count, 7)
        XCTAssertEqual(edited.preparationTime, "35")
        XCTAssertEqual(edited.servings, "2")
        XCTAssertEqual(edited.category, .dinner)
        XCTAssertEqual(edited.imageData, Data([1, 2, 3]))
        XCTAssertEqual(edited.sourceURL, link.absoluteString)
        XCTAssertEqual(edited.sourcePlatform, .tiktok)
    }

    func testSourceDetailsPopulateNewDraftAndKeepExistingDefaultPortions() throws {
        let imported = try TikTokCaptionParser.parse("SERVES: 4 Ingredients: • Eggs Instructions: 1. Cook.")
        var fresh = RecipeDraft()
        fresh.sourceURL = link.absoluteString
        fresh.fillEmptyDetails(from: imported, useDefaultServings: true)
        XCTAssertEqual(fresh.title, "Recipe from TikTok")
        XCTAssertEqual(fresh.ingredients, "Eggs")
        XCTAssertEqual(fresh.instructions, "Cook.")
        XCTAssertEqual(fresh.servings, "4")
        XCTAssertEqual(fresh.sourceURL, link.absoluteString)
        var existing = RecipeDraft()
        existing.fillEmptyDetails(from: imported)
        XCTAssertEqual(existing.servings, "1")
        XCTAssertEqual(existing.ingredients, "Eggs")
    }

    private var tacoMacCaption: String {
        """
        one pan taco mac & cheese 🤗 recipe is below! Taco Mac & Cheese Ingredients * 1 lb ground beef * 1 packet taco seasoning * 4 oz tomato sauce * ½ cup salsa * 16 oz shell pasta * 1 cup beef broth * 1 cup milk * 1½ cups Mexican blend cheese, divided * Optional: parsley for topping Instructions 1. In a large skillet over medium high heat, cook the ground beef with the taco seasoning until browned and fully cooked. 2. Add the tomato sauce and salsa, and stir until combined. 3. Add the uncooked shell pasta, beef broth, and milk. Mix well. 4. Bring to a simmer, reduce the heat to low, cover, and cook for about 10 minutes, stirring occasionally, until the pasta is tender. If the pasta needs more time, continue cooking and add a splash of broth or milk as needed. 5. Once pasta is cooked, stir in 1¼ cups of mexican cheese until melted. 6. Sprinkle the remaining ¼ cup cheese over the top, cover, and let it melt. 7. Top with parsley if desired and serve warm! #easydinnerideas #dinnerideas #mealideas #dinner #onepanmeal
        """
    }

    private func document(_ caption: String) throws -> String {
        let item: [String: Any] = ["desc": caption, "author": ["nickname": "Louis Howard"],
                                  "video": ["cover": "https://p19-common-sign.tiktokcdn.com/dish.image"]]
        let root: [String: Any] = ["__DEFAULT_SCOPE__": ["webapp.video-detail": ["itemInfo": ["itemStruct": item]]]]
        let json = String(decoding: try JSONSerialization.data(withJSONObject: root), as: UTF8.self)
        return "<script id='__UNIVERSAL_DATA_FOR_REHYDRATION__' type='application/json'>\(json)</script>"
    }
}
