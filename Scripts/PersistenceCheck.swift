import Foundation
import SwiftData

// Uses the actual app model and store. Each command runs in a separate process.
@main
@MainActor
struct PersistenceCheck {
    struct Failure: LocalizedError {
        let errorDescription: String?
        init(_ message: String) { errorDescription = message }
    }

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw Failure(message) }
    }

    static func main() throws {
        guard CommandLine.arguments.count == 3 else { throw Failure("Expected a phase and store path.") }
        let phase = CommandLine.arguments[1]
        let container = try RecipeStore.container(at: URL(fileURLWithPath: CommandLine.arguments[2]))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let recipes = try context.fetch(FetchDescriptor<Recipe>())

        switch phase {
        case "create":
            try expect(recipes.isEmpty, "New store must be empty")
            try checkValidationAndLinks()
            var draft = RecipeDraft()
            draft.title = "  Sunday pasta  "
            draft.description = "A family favorite"
            draft.sourceURL = "https://youtu.be/recipe"
            draft.sourcePlatform = .youtube
            let recipe = try RecipeStore.save(draft, editing: nil, in: context)
            try expect(recipe.title == "Sunday pasta", "Title must be trimmed")
            try expect(recipe.ingredients.isEmpty && recipe.instructions.isEmpty, "Link imports must not invent content")
        case "verify-create":
            try expect(recipes.count == 1, "Created recipe must survive process exit")
            let recipe = recipes[0]
            try expect(recipe.title == "Sunday pasta", "Title must persist")
            try expect(recipe.recipeDescription == "A family favorite", "Description must persist")
            try expect(recipe.platform == .youtube, "Source platform must persist")
            try expect(recipe.sourceURL == "https://youtu.be/recipe", "Original URL must persist")
        case "edit":
            guard let recipe = recipes.first else { throw Failure("Recipe missing before edit") }
            var draft = RecipeDraft(recipe: recipe)
            draft.title = "Weeknight pasta"
            draft.ingredients = "200 g pasta\n2 tomatoes"
            draft.instructions = "Boil pasta\nAdd tomatoes"
            draft.category = .dinner
            draft.preparationTime = "25"
            draft.servings = "2"
            draft.imageData = Data(repeating: 0x42, count: 500_000)
            try RecipeStore.save(draft, editing: recipe, in: context)
            recipe.isFavorite = true
            recipe.rating = 4
            recipe.notes = "More basil next time"
            recipe.wouldCookAgain = true
            try RecipeStore.commit(in: context)
        case "verify-edit":
            try expect(recipes.count == 1, "Editing must not create a duplicate")
            let recipe = recipes[0]
            try expect(recipe.title == "Weeknight pasta", "Edited title must persist")
            try expect(recipe.ingredientLines == ["200 g pasta", "2 tomatoes"], "Ingredients must persist")
            try expect(recipe.instructionLines.count == 2, "Steps must persist")
            try expect(recipe.recipeCategory == .dinner && recipe.preparationTime == 25 && recipe.servings == 2, "Metadata must persist")
            try expect(recipe.imageData == Data(repeating: 0x42, count: 500_000), "External image data must persist")
            try expect(recipe.rating == 4 && recipe.notes == "More basil next time", "Rating and notes must persist")
            try expect(recipe.isFavorite && recipe.wouldCookAgain, "Preferences must persist")
            try expect(recipe.updatedAt >= recipe.createdAt, "Timestamps must be valid")
        case "delete":
            guard let recipe = recipes.first else { throw Failure("Recipe missing before delete") }
            try RecipeStore.delete(recipe, in: context)
        case "verify-delete":
            try expect(recipes.isEmpty, "Deletion must survive process exit")
        default: throw Failure("Unknown phase: \(phase)")
        }
        print("PASS: \(phase)")
    }

    static func checkValidationAndLinks() throws {
        let cases: [(String, SourcePlatform)] = [
            ("https://www.youtube.com/watch?v=1", .youtube),
            ("https://youtu.be/1", .youtube),
            ("https://m.tiktok.com/@cook/video/1", .tiktok),
            ("https://www.facebook.com/watch/1", .facebook),
            ("https://fb.watch/1", .facebook),
            ("https://chatgpt.com/share/1", .chatGPT),
            ("https://chat.openai.com/share/1", .chatGPT),
            ("https://youtube.com.evil.example/1", .web),
            ("https://example.com/?url=tiktok.com", .web),
            ("", .manual)
        ]
        for (url, platform) in cases {
            try expect(SourceLink.platform(for: url) == platform, "Wrong platform for \(url)")
        }
        for invalid in ["file:///tmp/test", "javascript:alert(1)", "not a url", "https://user:pass@example.com"] {
            try expect(SourceLink.url(from: invalid) == nil, "Invalid link accepted: \(invalid)")
        }
        try expect(SourceLink.url(from: " www.example.com/recipe ")?.absoluteString == "https://www.example.com/recipe", "Bare host normalization failed")
        try expect(RecipeText.lines(in: "  2 eggs\r\n\n1 cup flour  \n") == ["2 eggs", "1 cup flour"], "Line presentation failed")
        var draft = RecipeDraft()
        try expect(draft.validationMessage != nil, "Empty title must fail validation")
        draft.title = "Pasta"
        try expect(draft.validationMessage == nil, "Title-only recipe must be valid")
        draft.servings = "0"
        try expect(draft.validationMessage != nil, "Zero servings must fail validation")
        draft.servings = "2"
        draft.preparationTime = "-1"
        try expect(draft.validationMessage != nil, "Negative time must fail validation")
    }
}
