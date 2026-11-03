import Foundation

enum RecipeText {
    static func matchesSearch(_ query: String, title: String, ingredients: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty
            || title.localizedStandardContains(query)
            || ingredients.localizedStandardContains(query)
    }

    static func lines(in text: String) -> [String] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
