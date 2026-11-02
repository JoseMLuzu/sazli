import Foundation
import SwiftData

@MainActor
enum RecipeStore {
    static func container(at url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([Recipe.self])
        let configuration: ModelConfiguration
        if let url {
            configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        }
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @discardableResult
    static func save(_ draft: RecipeDraft, editing recipe: Recipe?, in context: ModelContext, importIdentifier: UUID? = nil) throws -> Recipe {
        if let message = draft.validationMessage { throw ValidationError(message: message) }
        // Retrying an inbox item after an interrupted acknowledgement cannot duplicate it.
        if recipe == nil, let importIdentifier {
            let descriptor = FetchDescriptor<Recipe>(predicate: #Predicate { $0.id == importIdentifier })
            if let existing = try context.fetch(descriptor).first { return existing }
        }
        let savedRecipe = recipe ?? Recipe(title: "")
        if recipe == nil {
            if let importIdentifier { savedRecipe.id = importIdentifier }
            context.insert(savedRecipe)
        }
        draft.apply(to: savedRecipe)
        try commit(in: context)
        return savedRecipe
    }

    static func commit(in context: ModelContext) throws {
        do { try context.save() }
        catch {
            context.rollback()
            throw error
        }
    }

    static func delete(_ recipe: Recipe, in context: ModelContext) throws {
        context.delete(recipe)
        try commit(in: context)
    }

    struct ValidationError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
}
