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
