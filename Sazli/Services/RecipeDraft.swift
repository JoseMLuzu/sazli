import Foundation

struct RecipeDraft: Equatable {
    var title = ""
    var description = ""
    var ingredients = ""
    var instructions = ""
    var preparationTime = ""
    var servings = "1"
    var category: RecipeCategory = .other
    var imageData: Data?
    var sourceURL = ""
    var sourcePlatform: SourcePlatform = .manual

    init() {}

    init(recipe: Recipe) {
        title = recipe.title
        description = recipe.recipeDescription
        ingredients = recipe.ingredients
        instructions = recipe.instructions
        preparationTime = recipe.preparationTime == 0 ? "" : String(recipe.preparationTime)
        servings = String(recipe.servings)
        category = recipe.recipeCategory
        imageData = recipe.imageData
        sourceURL = recipe.sourceURL
        sourcePlatform = recipe.platform
    }

    var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Give your recipe a name before saving."
        }
        if !preparationTime.isEmpty && (Int(preparationTime).map { $0 >= 0 && $0 <= 10_080 } != true) {
            return "Enter a preparation time between 0 and 10,080 minutes, or leave it empty."
        }
        if Int(servings).map({ $0 > 0 && $0 <= 999 }) != true {
            return "Enter a number of servings between 1 and 999."
        }
        if !sourceURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           SourceLink.url(from: sourceURL) == nil {
            return "Enter a valid website link using http or https."
        }
        return nil
    }

    func apply(to recipe: Recipe) {
        recipe.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.recipeDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.ingredients = ingredients.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.instructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.preparationTime = Int(preparationTime) ?? 0
        recipe.servings = Int(servings) ?? 1
        recipe.category = category.rawValue
        recipe.imageData = imageData
        recipe.sourceURL = SourceLink.url(from: sourceURL)?.absoluteString ?? ""
        recipe.sourcePlatform = sourcePlatform.rawValue
        recipe.updatedAt = Date()
    }
}
