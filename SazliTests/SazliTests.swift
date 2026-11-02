import XCTest
import SwiftData
import UIKit
@testable import Sazli

final class SazliTests: XCTestCase {
    @MainActor func testImportIntentQueuesOriginalTextForReview() async throws {
        let text = "Intent test \(UUID().uuidString)\nIngredients:\n2 eggs\nInstructions:\nBeat the eggs."
        let intent = ImportRecipeIntent()
        intent.content = text
        _ = try await intent.perform()
        let request = try XCTUnwrap(RecipeImportInbox.shared.pending.first { $0.text == text })
        defer { try? RecipeImportInbox.shared.remove(request.id) }
        XCTAssertEqual(request.text, text)
        let reopened = RecipeImportInbox()
        XCTAssertTrue(reopened.pending.contains { $0.id == request.id && $0.text == text })
    }

    func testImportSeparatesEnglishMarkdownWithoutInventingContent() throws {
        let draft = try RecipeImportParser.parse("""
        # Lemon pasta
        A quick dinner.
        Prep time: 25 min
        Servings: 2
        ## Ingredients
        - 200 g pasta
        - 1 lemon
        ## Instructions
        1. Boil the pasta.
        2. Stir in the lemon.
        ## Notes
        Keep some cooking water.
        """)
        XCTAssertEqual(draft.title, "Lemon pasta")
        XCTAssertEqual(draft.ingredients, "200 g pasta\n1 lemon")
        XCTAssertEqual(draft.instructions, "Boil the pasta.\nStir in the lemon.")
        XCTAssertEqual(draft.preparationTime, "25")
        XCTAssertEqual(draft.servings, "2")
        XCTAssertTrue(draft.description.contains("A quick dinner."))
        XCTAssertTrue(draft.description.contains("Keep some cooking water."))
        XCTAssertEqual(draft.sourcePlatform, .manual)
    }

    func testSpanishImportPreservesUnrecognizedText() throws {
        let draft = try RecipeImportParser.parse("""
        **Tortilla**
        Tiempo de preparación: 15 minutos
        Porciones: 2
        **Ingredientes:**
        • 2 huevos
        • Sal al gusto
        **Preparación:**
        1) Batir los huevos.
        2) Cocinar en la sartén.
        Notas: Ajustar la sal.
        """)
        XCTAssertEqual(draft.title, "Tortilla")
        XCTAssertEqual(draft.ingredients, "2 huevos\nSal al gusto")
        XCTAssertEqual(draft.instructions, "Batir los huevos.\nCocinar en la sartén.")
        XCTAssertEqual(draft.description, "Notas: Ajustar la sal.")
        XCTAssertEqual(draft.preparationTime, "15")
        XCTAssertEqual(draft.servings, "2")
        let unstructured = try RecipeImportParser.parse("Soup\nUse what you have.\nCooking time: about an hour")
        XCTAssertEqual(unstructured.description, "Use what you have.\nCooking time: about an hour")
        XCTAssertTrue(unstructured.ingredients.isEmpty)
        XCTAssertTrue(unstructured.instructions.isEmpty)
        XCTAssertTrue(unstructured.preparationTime.isEmpty)
    }

    func testLinkImportsKeepSourceAndLeaveRecipeContentEmpty() throws {
        let cases: [(String, SourcePlatform)] = [
            ("https://chatgpt.com/share/recipe", .chatGPT),
            ("https://youtu.be/recipe?t=20", .youtube),
            ("https://www.tiktok.com/@cook/video/123", .tiktok),
            ("https://www.facebook.com/reel/123", .facebook),
            ("https://example.com/recipe", .web)
        ]
        for (link, platform) in cases {
            let draft = try RecipeImportParser.parse(link)
            XCTAssertEqual(draft.sourceURL, link)
            XCTAssertEqual(draft.sourcePlatform, platform)
            XCTAssertTrue(draft.ingredients.isEmpty)
            XCTAssertTrue(draft.instructions.isEmpty)
            XCTAssertNil(draft.validationMessage)
        }
        let caption = try RecipeImportParser.parse("My pasta\nSee https://youtu.be/recipe?t=20")
        XCTAssertEqual(caption.title, "My pasta")
        XCTAssertEqual(caption.sourceURL, "https://youtu.be/recipe?t=20")
        XCTAssertEqual(caption.sourcePlatform, .youtube)
        XCTAssertEqual(caption.description, "See https://youtu.be/recipe?t=20")
        let unsafe = try RecipeImportParser.parse("Recipe\nfile:///tmp/private\njavascript:alert(1)")
        XCTAssertTrue(unsafe.sourceURL.isEmpty)
        XCTAssertTrue(unsafe.description.contains("file:///tmp/private"))
    }

    func testImportRejectsEmptyAndOversizedInput() {
        XCTAssertThrowsError(try RecipeImportParser.parse(" \n "))
        XCTAssertThrowsError(try RecipeImportParser.parse(String(repeating: "a", count: RecipeImportParser.maximumBytes + 1)))
    }

    @MainActor func testImportInboxSurvivesReopenAndAcknowledgesOnlyAfterSave() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = RecipeImportInbox(directory: directory)
        let request = try first.enqueue("Test pasta\nIngredients:\n200 g pasta\nInstructions:\nBoil.")
        let reopened = RecipeImportInbox(directory: directory)
        XCTAssertEqual(reopened.pending, [request])
        XCTAssertNil(reopened.errorMessage)

        let storeURL = directory.appendingPathComponent("test.store")
        do {
            let container = try RecipeStore.container(at: storeURL)
            var draft = try RecipeImportParser.parse(request.text)
            draft.title = ""
            XCTAssertThrowsError(try RecipeStore.save(draft, editing: nil, in: container.mainContext, importIdentifier: request.id))
            XCTAssertEqual(RecipeImportInbox(directory: directory).pending, [request])
            draft.title = "My reviewed pasta"
            try RecipeStore.save(draft, editing: nil, in: container.mainContext, importIdentifier: request.id)
        }
        // Simulate the app stopping after saving but before removing the inbox file.
        let container = try RecipeStore.container(at: storeURL)
        let repeated = try RecipeStore.save(RecipeImportParser.parse(request.text), editing: nil, in: container.mainContext, importIdentifier: request.id)
        XCTAssertEqual(repeated.id, request.id)
        XCTAssertEqual(repeated.title, "My reviewed pasta")
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Recipe>()), 1)
        try reopened.remove(request.id)
        XCTAssertTrue(RecipeImportInbox(directory: directory).pending.isEmpty)
    }

    @MainActor func testUnreadableImportIsRetainedAndReported() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent(UUID().uuidString).appendingPathExtension("json")
        try Data("invalid import".utf8).write(to: url)
        let inbox = RecipeImportInbox(directory: directory)
        XCTAssertNotNil(inbox.errorMessage)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertThrowsError(try inbox.enqueue("Another recipe"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    #if DEBUG
    @MainActor func testSampleImportHasPhotosAndPreservesExistingEdits() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Recipe.self, configurations: configuration)
        let context = ModelContext(container)
        let existing = Recipe(title: "My own soup")
        existing.notes = "Keep my notes"
        context.insert(existing)
        try context.save()

        XCTAssertEqual(try SampleRecipeImporter.importRecipes(in: context), SampleRecipeImporter.recipeCount)
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        let samples = recipes.filter { $0.id != existing.id }
        XCTAssertEqual(recipes.count, 5)
        XCTAssertEqual(Set(samples.map(\.category)), Set(["breakfast", "lunch", "dinner", "dessert"]))
        for recipe in samples {
            let data = try XCTUnwrap(recipe.imageData)
            let image = try XCTUnwrap(UIImage(data: data))
            XCTAssertGreaterThan(image.cgImage?.width ?? 0, 500)
            XCTAssertGreaterThan(recipe.ingredientLines.count, 3)
            XCTAssertGreaterThanOrEqual(recipe.instructionLines.count, 4)
            XCTAssertEqual(recipe.servings, 2)
            XCTAssertTrue(recipe.notes.contains("AI-generated"))
        }
        let edited = try XCTUnwrap(samples.first)
        edited.title = "My edited sample"
        edited.notes = "My adjustments"
        try context.save()
        XCTAssertEqual(try SampleRecipeImporter.importRecipes(in: context), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Recipe>()), 5)
        XCTAssertEqual(edited.title, "My edited sample")
        XCTAssertEqual(edited.notes, "My adjustments")
        XCTAssertEqual(existing.title, "My own soup")
        XCTAssertEqual(existing.notes, "Keep my notes")
    }

    @MainActor func testSamplePhotoFailureDoesNotInsertAPartialBatch() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(for: Recipe.self, configurations: configuration)
        let context = ModelContext(container)
        context.insert(Recipe(title: "Existing recipe"))
        try context.save()
        XCTAssertThrowsError(try SampleRecipeImporter.importRecipes(in: context, imageLoader: { name in
            if name == "SampleLemonPasta" { throw SampleRecipeImporter.ImportError.missingPhoto(name) }
            return Data([1, 2, 3])
        }))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Recipe>()), 1)
        XCTAssertFalse(context.hasChanges)
    }
    #endif

    func testPlatformDetectionUsesDomainBoundaries() {
        let cases: [(String, SourcePlatform)] = [
            ("https://www.youtube.com/watch?v=123", .youtube),
            ("https://youtu.be/123", .youtube),
            ("https://m.tiktok.com/@cook/video/1", .tiktok),
            ("https://fb.watch/123", .facebook),
            ("https://chatgpt.com/share/123", .chatGPT),
            ("https://chat.openai.com/share/123", .chatGPT),
            ("https://youtube.com.example.org/recipe", .web),
            ("https://example.org/?next=tiktok.com", .web),
            ("", .manual)
        ]
        for (url, expected) in cases { XCTAssertEqual(SourceLink.platform(for: url), expected, url) }
    }

    func testSourceValidation() {
        XCTAssertNotNil(SourceLink.url(from: " www.example.com/recipe "))
        XCTAssertNil(SourceLink.url(from: "javascript:alert(1)"))
        XCTAssertNil(SourceLink.url(from: "file:///tmp/recipe"))
        XCTAssertNil(SourceLink.url(from: "https://user:pass@example.com"))
        XCTAssertNil(SourceLink.url(from: "not a link"))
    }

    func testLinePresentationPreservesTextAndRemovesEmptyLines() {
        XCTAssertEqual(RecipeText.lines(in: "  2 eggs\r\n\n1 cup flour  \n"), ["2 eggs", "1 cup flour"])
    }

    func testDraftValidatesMinimalAndInvalidRecipes() {
        var draft = RecipeDraft()
        XCTAssertNotNil(draft.validationMessage)
        draft.title = "Weekend pasta"
        draft.sourceURL = "https://youtu.be/recipe"
        XCTAssertNil(draft.validationMessage)
        XCTAssertTrue(draft.ingredients.isEmpty)
        XCTAssertTrue(draft.instructions.isEmpty)
        draft.servings = "0"
        XCTAssertNotNil(draft.validationMessage)
        draft.servings = "2"
        draft.preparationTime = "-5"
        XCTAssertNotNil(draft.validationMessage)
        draft.preparationTime = "25"
        XCTAssertNil(draft.validationMessage)
    }

    @MainActor func testDiskStoreReopensAfterCreateEditRateAndDelete() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("recipes.store")
        var identifier: UUID?
        do {
            let container = try RecipeStore.container(at: url)
            let context = ModelContext(container)
            context.autosaveEnabled = false
            var draft = RecipeDraft()
            draft.title = "Pasta"
            draft.sourceURL = "https://youtu.be/pasta"
            draft.sourcePlatform = .youtube
            let recipe = try RecipeStore.save(draft, editing: nil, in: context)
            identifier = recipe.id
        }
        do {
            let container = try RecipeStore.container(at: url)
            let context = ModelContext(container)
            let recipe = try XCTUnwrap(context.fetch(FetchDescriptor<Recipe>()).first)
            XCTAssertEqual(recipe.id, identifier)
            XCTAssertEqual(recipe.title, "Pasta")
            XCTAssertEqual(recipe.platform, .youtube)
            XCTAssertTrue(recipe.ingredients.isEmpty)
            var draft = RecipeDraft(recipe: recipe)
            draft.title = "Sunday pasta"
            draft.ingredients = "Pasta\nTomatoes"
            draft.instructions = "Boil pasta\nAdd sauce"
            draft.imageData = Data([1, 2, 3])
            try RecipeStore.save(draft, editing: recipe, in: context)
            recipe.rating = 5
            recipe.notes = "Less salt next time"
            recipe.isFavorite = true
            recipe.wouldCookAgain = true
            try RecipeStore.commit(in: context)
        }
        do {
            let container = try RecipeStore.container(at: url)
            let context = ModelContext(container)
            let recipes = try context.fetch(FetchDescriptor<Recipe>())
            XCTAssertEqual(recipes.count, 1)
            let recipe = try XCTUnwrap(recipes.first)
            XCTAssertEqual(recipe.title, "Sunday pasta")
            XCTAssertEqual(recipe.instructionLines, ["Boil pasta", "Add sauce"])
            XCTAssertEqual(recipe.rating, 5)
            XCTAssertEqual(recipe.notes, "Less salt next time")
            XCTAssertEqual(recipe.imageData, Data([1, 2, 3]))
            XCTAssertTrue(recipe.isFavorite)
            XCTAssertTrue(recipe.wouldCookAgain)
            try RecipeStore.delete(recipe, in: context)
        }
        let container = try RecipeStore.container(at: url)
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<Recipe>()), 0)
    }
}
