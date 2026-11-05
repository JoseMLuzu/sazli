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

    /// Presentation only: keep the editable source intact, but omit explicit group labels.
    static func ingredientLines(in text: String) -> [String] {
        let trailing = CharacterSet.whitespacesAndNewlines
            .union(CharacterSet(charactersIn: ":：,，.。;；!?！？…"))
        return lines(in: text).compactMap { line in
            if line.range(of: #"^#{1,6}[ \t]+"#, options: .regularExpression) != nil { return nil }
            var cleaned = line
            while let last = cleaned.unicodeScalars.last, trailing.contains(last) {
                cleaned.removeLast()
            }
            guard !cleaned.isEmpty else { return nil }
            if line.hasSuffix(":") || line.hasSuffix("：") {
                let key = cleaned.folding(options: [.diacriticInsensitive, .caseInsensitive],
                    locale: Locale(identifier: "en_US_POSIX"))
                let groups: Set<String> = ["pasta", "chicken", "pollo", "sauce", "salsa", "sauce & pasta",
                    "garnish", "guarnicion", "topping", "toppings", "marinade", "marinada",
                    "dough", "masa", "filling", "relleno", "base", "dry ingredients", "wet ingredients",
                    "ingredientes secos", "ingredientes humedos"]
                let isGroup = groups.contains(key) || key.hasPrefix("for the ")
                    || key.hasPrefix("para la ") || key.hasPrefix("para el ") || key.hasPrefix("para las ")
                    || key.hasPrefix("para los ")
                if isGroup, !key.contains(":"), !key.contains("："), !key.contains(where: \.isNumber) { return nil }
            }
            return cleaned
        }
    }
}
