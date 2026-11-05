import Foundation
import SwiftData

@Model
final class Recipe {
    // Defaults and the absence of uniqueness constraints allow a future CloudKit migration.
    var id: UUID = UUID()
    var title: String = ""
    // SwiftData reserves `description`; this stores the recipe's description field.
    var recipeDescription: String = ""
    var ingredients: String = ""
    var instructions: String = ""
    var preparationTime: Int = 0
    var servings: Int = 1
    var category: String = RecipeCategory.other.rawValue
    @Attribute(.externalStorage) var imageData: Data?
    var sourceURL: String = ""
    var sourcePlatform: String = SourcePlatform.manual.rawValue
    var rating: Int = 0
    var notes: String = ""
    var wouldCookAgain: Bool = false
    var isFavorite: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    init(title: String) {
        self.title = title
    }

    var recipeCategory: RecipeCategory { RecipeCategory(rawValue: category) ?? .other }
    var platform: SourcePlatform { SourcePlatform(rawValue: sourcePlatform) ?? .web }
    var ingredientLines: [String] { RecipeText.ingredientLines(in: ingredients) }
    var instructionLines: [String] { RecipeText.lines(in: instructions) }
}
