import Foundation

/// Separates explicit caption sections without inferring missing recipe content.
enum RecipeCaptionParser {
    static func parse(_ caption: String, title: String) throws -> RecipeDraft {
        try RecipeImportParser.parse(title + "\n" + normalize(caption))
    }

    private static func normalize(_ caption: String) -> String {
        var text = caption.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
        // Decorations belong to the heading, not the preceding ingredient or step.
        let decoration = #"(?:#{1,6}[ \t]*)?(?:[\p{So}\uFE0F\u200D]+[ \t]*)?\b"#
        // Without a colon, require a list marker or a standalone heading line.
        let headingEnd = #"[ \t]*(?::|(?=[ \t]*(?:[-*•◦▪✅]\uFE0F?\s+|[0-9]\uFE0F?\u20E3|\d+[.)]\s+|\n|$)))"#
        text = text.replacingOccurrences(
            of: #"\b(?:serves|servings|porciones|raciones)\s*:\s*(\d{1,3})(?!\d|\s*[-–])"#,
            with: "\nServings: $1\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(
            of: #"(?m)^[ \t]*\([ \t]*(\d{1,3})[ \t]+(?:personas?|servings?)[ \t]*\)[ \t]*$"#,
            with: "\nServings: $1\n", options: [.regularExpression, .caseInsensitive])
        text = replacingFirst(in: text,
            pattern: decoration + #"(?:what you['’]ll need|ingredients|ingredientes)"# + headingEnd,
            with: "\nIngredients:\n")
        text = replacingFirst(in: text,
            pattern: decoration + #"(?:step[- ]by[- ]step instructions(?: for[^:\n]{1,100})?|method|instructions|instrucciones(?: paso a paso)?|directions|preparation|preparaci[oó]n(?: paso a paso)?|pasos|procedimiento|elaboraci[oó]n|paso a paso)"# + headingEnd,
            with: "\nInstructions:\n")
        text = text.replacingOccurrences(
            of: decoration + #"(?:per serving|nutrition(?: per serving)?|macros(?: per serving)?|notes|tips?|por porci[oó]n|notas?|consejos|nutrici[oó]n|informaci[oó]n nutricional|utensilios|utensils|equipment|kitchen tools)[ \t]*(?::|(?=\n|$))"#,
            with: "\nNotes:\n", options: [.regularExpression, .caseInsensitive])
        if let tags = text.range(
            of: #"\s+(#[\p{L}\p{N}_]+(?:\s+#[\p{L}\p{N}_]+)*(?:\s+[\p{So}\p{P}\uFE0F\u200D]+)*\s*)$"#,
            options: .regularExpression) {
            let hashtags = text[tags].trimmingCharacters(in: .whitespacesAndNewlines)
            text.replaceSubrange(tags, with: "\nNotes:\n" + hashtags)
        }
        text = normalizeList(text, heading: "Ingredients", stoppingAt: ["Instructions", "Notes"], isMethod: false)
        return normalizeList(text, heading: "Instructions", stoppingAt: ["Notes"], isMethod: true)
    }

    private static func replacingFirst(in text: String, pattern: String, with replacement: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return text }
        return text.replacingCharacters(in: range, with: replacement)
    }

    private static func normalizeList(_ text: String, heading: String, stoppingAt boundaries: [String], isMethod: Bool) -> String {
        guard let headingRange = text.range(of: heading + ":\n") else { return text }
        let tail = text[headingRange.upperBound...]
        let end = boundaries.compactMap { tail.range(of: "\n" + $0 + ":")?.lowerBound }.min() ?? text.endIndex
        var list = String(text[headingRange.upperBound..<end])
        if isMethod {
            list = list.replacingOccurrences(of: #"([0-9])\uFE0F?\u20E3"#, with: "\n$1. ", options: .regularExpression)
        }
        list = list.replacingOccurrences(of: #"(?<!\S)[*•◦▪✅-]\uFE0F?(?:\s+|(?=[\p{L}\p{N}]))"#, with: "\n- ", options: .regularExpression)
            .replacingOccurrences(of: #"(?<![\d.])(\d{1,2})[.)]\s+"#, with: "\n$1. ", options: .regularExpression)
        var result = text
        result.replaceSubrange(headingRange.upperBound..<end, with: list)
        return result
    }
}
