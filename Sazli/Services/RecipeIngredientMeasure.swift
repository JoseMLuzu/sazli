import Foundation

/// A bare equivalent measure is a qualifier, not another named ingredient.
enum RecipeIngredientMeasure {
    private static let expression: NSRegularExpression? = {
        let quantity = RecipeCaptionParser.quantity
        let approximate = #"(?:(?:about|approx(?:\.|imately)?|aprox\.?|aproximadamente)[ \t]+)?"#
        let amount = approximate + quantity + "(?:[ \\t]*[-–—][ \\t]*" + quantity + #")?[ \t]*(?:ml|l|mg|g|kg|oz|lbs?|tsp|tbsp|cups?)\b"#
        return try? NSRegularExpression(pattern: #"^\(?"# + amount + #"\)?(?:[ \t]*/[ \t]*"# + amount
            + #")?(?:,[ \t]*(?:or to taste|al gusto))?$"#, options: .caseInsensitive)
    }()

    static func isEquivalent(_ text: String) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let expression else { return false }
        return expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil
    }

    static func isContinuation(_ text: String) -> Bool {
        if isEquivalent(text) { return true }
        return text.trimmingCharacters(in: .whitespacesAndNewlines).range(
            of: #"^(?:(?:(?:finely|roughly|freshly|thinly|coarsely)\s+)?(?:chopped|minced|diced|sliced|grated)|optional|al gusto|(?:finamente\s+)?(?:picad[oa]s?|rallad[oa]s?))$"#,
            options: [.regularExpression, .caseInsensitive]) != nil
    }
}
