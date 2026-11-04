import Foundation

enum RecipeText {
    static func matchesSearch(_ query: String, title: String, ingredients: String) -> Bool {
        matchesNormalizedSearch(query.trimmingCharacters(in: .whitespacesAndNewlines),
                                title: title, ingredients: ingredients)
    }

    // Callers filtering a collection normalize the query once for the whole collection.
    static func matchesNormalizedSearch(_ query: String, title: String, ingredients: String) -> Bool {
        query.isEmpty
            || title.localizedStandardContains(query)
            || ingredients.localizedStandardContains(query)
    }

    static func lines(in text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
