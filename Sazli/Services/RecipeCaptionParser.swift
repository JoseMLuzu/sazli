import Foundation

/// Separates explicit caption sections without inferring missing recipe content.
enum RecipeCaptionParser {
    static let quantity = #"(?:\d+(?:[.,]\d+)?(?:[ \t]+(?:\d+[ \t]*/[ \t]*\d+|[¼½¾⅓⅔⅛⅜⅝⅞])|[ \t]*/[ \t]*\d+|[¼½¾⅓⅔⅛⅜⅝⅞])?|[¼½¾⅓⅔⅛⅜⅝⅞])"#
    static func parse(_ caption: String, title: String) throws -> RecipeDraft {
        guard caption.utf8.count <= RecipeImportParser.maximumBytes else { throw RecipeImportParser.ImportError.tooLarge }
        return try RecipeImportParser.parse(title + "\n" + normalize(caption))
    }

    static func containsSectionHeading(_ text: String) -> Bool {
        let normalized = normalize(text)
        return ["Ingredients", "Instructions", "Notes"].contains { normalized.contains("\n" + $0 + ":\n") }
    }

    private static func normalize(_ caption: String) -> String {
        var text = caption.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
            .replacingOccurrences(of: #"\p{Zs}"#, with: " ", options: .regularExpression)
            .precomposedStringWithCanonicalMapping
        text = normalizeGroupedHeadings(text)
        // Decorations belong to the heading, not the preceding ingredient or step.
        let decoration = #"(?:#{1,6}[ \t]*)?(?:[\p{So}\uFE0F\u200D]+[ \t]*)?\b"#
        // Without a colon, require a list marker or a standalone heading line.
        let headingEnd = #"[ \t]*(?:[:：;|=–—-]+|\.{2,3}|(?=[ \t]*(?:[-*•◦▪✅]\uFE0F?(?:\s+|(?=[\p{L}\p{N}]))|[0-9]\uFE0F?\u20E3|(?:\d+[.)]|[a-z]\)|\(\d+\))(?:\s+|(?=\p{L}))|\d+[-–]\s+|\n|$)))"#
        let ingredientHeading = #"(?:ingredient list|lista de ingredientes|lo que necesitas|what you['’]ll need|ingredients|ingredientes)"#
        let portions = #"[ \t]*\([ \t]*(\d{1,3})(?:[ \t]*[-–][ \t]*\d{1,3})?[ \t]+(?:personas?|servings?|porciones|raciones)[ \t]*\)"#
        if let expression = try? NSRegularExpression(pattern: ingredientHeading + portions, options: .caseInsensitive),
           let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text), let countRange = Range(match.range(at: 1), in: text) {
            let label = String(text[range])
            let count = String(text[countRange])
            let hasRange = label.range(of: #"\d[ \t]*[-–][ \t]*\d"#, options: .regularExpression) != nil
            text.replaceSubrange(range, with: hasRange ? "\nNotes:\n\(label)\nIngredients" : "\nServings: \(count)\nIngredients")
        }
        text = text.replacingOccurrences(
            of: #"\b(?:serves|servings|porciones|raciones)\s*:\s*(\d{1,3})(?!\d|\s*[-–])"#,
            with: "\nServings: $1\n", options: [.regularExpression, .caseInsensitive])
        text = text.replacingOccurrences(
            of: #"(?m)^[ \t]*\([ \t]*(\d{1,3})[ \t]+(?:personas?|servings?)[ \t]*\)[ \t]*$"#,
            with: "\nServings: $1\n", options: [.regularExpression, .caseInsensitive])
        text = replacingFirst(in: text,
            pattern: decoration + ingredientHeading + headingEnd,
            with: "\nIngredients:\n")
        text = replacingFirst(in: text,
            pattern: decoration + #"(?:step[- ]by[- ]step instructions(?: for[^:\n]{1,100})?|preparation steps|modo de preparaci[oó]n|c[oó]mo preparar|method|instructions|instrucciones(?: paso a paso)?|directions|preparation|preparaci[oó]n(?: paso a paso)?|steps|pasos|procedimiento|elaboraci[oó]n|paso a paso)"# + headingEnd,
            with: "\nInstructions:\n")
        var hasQuantifiedHeading = false
        if !text.contains("\nIngredients:\n"), let method = text.range(of: "\nInstructions:\n") {
            let prefix = String(text[..<method.lowerBound])
            let normalized = replacingFirst(in: prefix,
                pattern: decoration + ingredientHeading + #"[ \t]+(?=\d+(?:[.,]\d+)?[ \t]*\p{L})"#,
                with: "\nIngredients:\n")
            if normalized != prefix {
                text.replaceSubrange(text.startIndex..<method.lowerBound, with: normalized)
                hasQuantifiedHeading = true
            }
        }
        text = text.replacingOccurrences(
            of: decoration + #"(?:per serving|nutrition(?: per serving)?|macros(?: per serving)?|notes|tips?|por porci[oó]n|notas?|consejos|nutrici[oó]n|informaci[oó]n nutricional|utensilios|utensils|equipment|kitchen tools)"# + headingEnd,
            with: "\nNotes:\n", options: [.regularExpression, .caseInsensitive])
        if let tags = text.range(
            of: #"\s+(#[\p{L}\p{N}_]+(?:\s+#[\p{L}\p{N}_]+)*(?:\s+[\p{So}\p{P}\uFE0F\u200D]+)*\s*)$"#,
            options: .regularExpression) {
            let hashtags = text[tags].trimmingCharacters(in: .whitespacesAndNewlines)
            text.replaceSubrange(tags, with: "\nNotes:\n" + hashtags)
        }
        text = normalizeList(text, heading: "Ingredients", stoppingAt: ["Instructions", "Notes"], isMethod: false,
                             splitQuantities: hasQuantifiedHeading)
        return normalizeList(text, heading: "Instructions", stoppingAt: ["Notes"], isMethod: true)
    }

    private static func replacingFirst(in text: String, pattern: String, with replacement: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range, in: text) else { return text }
        return text.replacingCharacters(in: range, with: replacement)
    }

    /// A flattened caption may put a short group name between both section headings and their lists.
    /// Require the paired, ordered sections so ordinary prose alone cannot start a recipe section.
    private static func normalizeGroupedHeadings(_ text: String) -> String {
        let group = #"[ \t]+([\p{L}][\p{L} &/]{0,40}?)[ \t]+(?=[-*•◦▪✅]\uFE0F?\s*\S)"#
        guard let ingredients = text.range(of: #"\b(?:ingredients|ingredientes)"# + group,
                                           options: [.regularExpression, .caseInsensitive]),
              let method = text.range(of: #"\b(?:instructions|method|directions|instrucciones|preparaci[oó]n|procedimiento)"# + group,
                                      options: [.regularExpression, .caseInsensitive],
                                      range: ingredients.upperBound..<text.endIndex) else { return text }
        var result = text
        let methodText = String(text[method])
        result.replaceSubrange(method, with: replacingFirst(in: methodText,
            pattern: #"^\S+[ \t]+"#, with: "\nInstructions:\n"))
        let ingredientText = String(text[ingredients])
        result.replaceSubrange(ingredients, with: replacingFirst(in: ingredientText,
            pattern: #"^\S+[ \t]+"#, with: "\nIngredients:\n"))
        return result
    }

    private static func normalizeList(_ text: String, heading: String, stoppingAt boundaries: [String], isMethod: Bool,
                                      splitQuantities: Bool = false) -> String {
        guard let headingRange = text.range(of: heading + ":\n") else { return text }
        let tail = text[headingRange.upperBound...]
        let end = boundaries.compactMap { tail.range(of: "\n" + $0 + ":")?.lowerBound }.min() ?? text.endIndex
        var list = String(text[headingRange.upperBound..<end])
        if splitQuantities { list = splitFlattenedQuantities(list) }
        // These explicit group labels precede a bullet; quantities and prose are left untouched.
        let groups = #"(?<!\S)(Sauce & Pasta|Chicken|Pasta|Garnish|Sauce|Pollo|Salsa|Guarnici[oó]n)[ \t]+[-*•◦▪✅]\uFE0F?\s*"#
        list = list.replacingOccurrences(of: groups,
            with: isMethod ? "\n- $1: " : "\n$1:\n- ", options: .regularExpression)
        list = list.replacingOccurrences(of: #"(?:\s+[•◦▪]){2,}\s*$"#, with: "", options: .regularExpression)
        if isMethod {
            list = list.replacingOccurrences(of: #"([0-9])\uFE0F?\u20E3"#, with: "\n$1. ", options: .regularExpression)
        }
        list = normalizeSequentialMarkers(list, pattern: #"(?<!\S)([a-z])\)(?:[ \t]+|(?=\p{L}))"#, expected: Array("abcdefghijklmnopqrstuvwxyz").map(String.init))
        list = normalizeSequentialMarkers(list, pattern: #"(?<!\S)\((\d{1,2})\)(?:[ \t]+|(?=\p{L}))"#, expected: (1...99).map(String.init))
        list = normalizeSequentialMarkers(list, pattern: #"(?<!\S)(\d{1,2})[-–][ \t]+"#, expected: (1...99).map(String.init))
        let explicitItems = list.range(of: #"(?<!\S)(?:[*•◦▪✅–—-]\s*|\d+[.)]\s+)"#,
                                       options: .regularExpression) != nil
        list = separatePunctuation(list, isMethod: isMethod || explicitItems)
        list = normalizeBullets(list)
            .replacingOccurrences(of: #"(?<![\d.])(\d{1,2})[.)](?:\s+|(?=\p{L}))"#, with: "\n$1. ", options: .regularExpression)
        var result = text
        result.replaceSubrange(headingRange.upperBound..<end, with: list)
        return result
    }

    private static func splitFlattenedQuantities(_ text: String) -> String {
        let blocks = text.replacingOccurrences(of: #"[ \t]{2,}"#, with: "\n", options: .regularExpression)
        guard let expression = try? NSRegularExpression(
            pattern: #"(?<![\p{L}\p{N}.,/])\d+(?:[.,]\d+)?(?:[ \t]*/[ \t]*\d+)?(?=[ \t]*\p{L})"#) else { return text }
        return blocks.components(separatedBy: .newlines).map { block in
            let line = block.trimmingCharacters(in: .whitespaces)
            let matches = expression.matches(in: line, range: NSRange(line.startIndex..., in: line))
            guard matches.count > 1, matches.first?.range.location == 0 else { return line }
            var result = line
            for match in matches.dropFirst().reversed() {
                guard let range = Range(match.range, in: result),
                      result[..<range.lowerBound].trimmingCharacters(in: .whitespaces).last != "," else { continue }
                result.insert("\n", at: range.lowerBound)
            }
            return result
        }.joined(separator: "\n")
    }

    private static func normalizeBullets(_ text: String) -> String {
        guard let expression = try? NSRegularExpression(
            pattern: #"(?<!\S)(?:[*•◦▪✅]\uFE0F?(?:\s+|(?=[\p{L}\p{N}]))|[-–—](?:\s+|(?=\p{L})))"#) else { return text }
        var result = text
        for match in expression.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            guard let range = Range(match.range, in: result) else { continue }
            if "-–—".contains(result[range.lowerBound]) {
                var preceding: Character?
                for character in result[..<range.lowerBound].reversed() {
                    if character == "\n" { break }
                    if !character.isWhitespace { preceding = character; break }
                }
                if preceding?.isNumber == true, result[range.upperBound...].first?.isNumber == true { continue }
            }
            result.replaceSubrange(range, with: "\n- ")
        }
        return result
    }

    private static func normalizeSequentialMarkers(_ text: String, pattern: String, expected: [String]) -> String {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return text }
        let matches = expression.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard matches.count >= 2, matches.count <= expected.count else { return text }
        for (index, match) in matches.enumerated() {
            guard let range = Range(match.range(at: 1), in: text), text[range].lowercased() == expected[index] else { return text }
        }
        var result = text
        for match in matches.reversed() {
            if let range = Range(match.range, in: result) { result.replaceSubrange(range, with: "\n- ") }
        }
        return result
    }

    /// A comma may qualify an ingredient or be a decimal separator. Split only before another
    /// explicit numeric quantity after whitespace. Semicolons separate items outside parentheses.
    private static func separatePunctuation(_ text: String, isMethod: Bool) -> String {
        var result = ""
        var depth = 0
        for index in text.indices {
            let character = text[index]
            if character == "(" || character == "[" { depth += 1 }
            if character == ")" || character == "]" { depth = max(0, depth - 1) }
            if depth == 0, character == ";" { result += "\n"; continue }
            if depth == 0, !isMethod, character == "," {
                let remainder = text[text.index(after: index)...]
                if remainder.first?.isWhitespace == true,
                   let first = remainder.first(where: { !$0.isWhitespace }),
                   first.isNumber {
                    result += "\n"; continue
                }
            }
            result.append(character)
        }
        return result
    }
}
