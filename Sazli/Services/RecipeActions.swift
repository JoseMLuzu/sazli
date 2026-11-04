import Foundation

enum RecipeSort: String, CaseIterable, Identifiable {
  case newest, alphabetical, rating, quickest
  var id: Self { self }
  var title: String {
    switch self {
    case .newest: "Recently added"
    case .alphabetical: "Name A–Z"
    case .rating: "Highest rated"
    case .quickest: "Quickest first"
    }
  }

  func ordered(_ recipes: [Recipe]) -> [Recipe] {
    recipes.sorted { lhs, rhs in
      switch self {
      case .newest:
        if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
      case .alphabetical: break
      case .rating:
        if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
      case .quickest:
        let left = lhs.preparationTime > 0 ? lhs.preparationTime : Int.max
        let right = rhs.preparationTime > 0 ? rhs.preparationTime : Int.max
        if left != right { return left < right }
      }
      let comparison = lhs.title.localizedStandardCompare(rhs.title)
      if comparison != .orderedSame { return comparison == .orderedAscending }
      if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
      return lhs.id.uuidString < rhs.id.uuidString
    }
  }
}

enum RecipeSharing {
  static func text(for recipe: Recipe) -> String {
    var sections = [recipe.title]
    if !recipe.recipeDescription.isEmpty { sections.append(recipe.recipeDescription) }
    var details = [recipe.recipeCategory.title]
    if recipe.preparationTime > 0 { details.append("\(recipe.preparationTime) min") }
    details.append("\(recipe.servings) \(recipe.servings == 1 ? "serving" : "servings")")
    sections.append(details.joined(separator: " · "))
    if !recipe.ingredientLines.isEmpty {
      sections.append("Ingredients\n" + recipe.ingredientLines.map { "• \($0)" }.joined(separator: "\n"))
    }
    if !recipe.instructionLines.isEmpty {
      sections.append("Instructions\n" + recipe.instructionLines.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
    }
    if let url = SourceLink.url(from: recipe.sourceURL) {
      sections.append("Source · \(recipe.platform.title)\n\(url.absoluteString)")
    }
    return sections.joined(separator: "\n\n")
  }
}
