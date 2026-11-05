import Foundation

/// Supports explicit all-caps ingredient groups when the caption omits an Ingredients heading.
enum RecipeGroupedCaption {
    static func normalized(_ text: String, quantity: String) -> String? {
        uppercaseGroups(text, quantity: quantity) ?? RecipeBulletedCaption.normalized(text, quantity: quantity)
    }

    private static func uppercaseGroups(_ text: String, quantity: String) -> String? {
        guard text.range(of: #"\b(?:ingredients|ingredientes)[ \t]*[:\n]"#,
                         options: [.regularExpression, .caseInsensitive]) == nil,
              let method = text.range(
                of: #"\b(?:instructions|method|directions|instrucciones|preparaci[oó]n|procedimiento)(?:[ \t]*[:：][ \t\n]*|[ \t\n]+)(?=[\p{L}\p{N}])"#,
                options: [.regularExpression, .caseInsensitive]) else { return nil }
        let prefix = String(text[..<method.lowerBound])
        guard let expression = try? NSRegularExpression(
            pattern: #"(?<![\p{L}\p{N}])((?:[\p{Lu}][\p{Lu} &/-]{2,50}?|(?:\p{Lu}[\p{L}&/-]*[ \t]+){0,5}\p{Lu}[\p{L}&/-]*[:：]))[ \t\n]+(?="# + quantity + #"[ \t]*\p{L})"#) else { return nil }
        let groups = expression.matches(in: prefix, range: NSRange(prefix.startIndex..., in: prefix))
        guard groups.count >= 2, groups.count <= 30,
              let first = groups.first, let firstRange = Range(first.range, in: prefix) else { return nil }
        var lines = [String(prefix[..<firstRange.lowerBound]), "Ingredients:"]
        for (index, group) in groups.enumerated() {
            guard let range = Range(group.range, in: prefix), let nameRange = Range(group.range(at: 1), in: prefix) else { return nil }
            let end: String.Index
            if index + 1 < groups.count {
                guard let next = Range(groups[index + 1].range, in: prefix) else { return nil }
                end = next.lowerBound
            } else { end = prefix.endIndex }
            let body = String(prefix[range.upperBound..<end]).replacingOccurrences(
                of: #"(?<=\))[ \t]+(?=\p{Lu}\p{Ll})"#, with: "\n", options: .regularExpression)
            let ingredients = RecipeText.lines(in: RecipeCaptionParser.splitFlattenedQuantities(body))
            guard !ingredients.isEmpty else { return nil }
            // An explicit marker keeps arbitrary group names separate from checklist ingredients.
            lines.append("# " + prefix[nameRange].trimmingCharacters(in: .whitespaces))
            lines.append(contentsOf: ingredients.map { "• " + $0 })
        }
        lines.append("Instructions:")
        lines.append(String(text[method.upperBound...]))
        return lines.joined(separator: "\n")
    }

    static func methodLines(_ text: String) -> String {
        if let ordered = RecipeMethodMarkers.canonicalized(text) { return ordered }
        // Retain an author's explicit numbered/bulleted steps. Otherwise use written sentence
        // boundaries, preserving measurements, decimals and abbreviations through Foundation.
        guard text.range(of: #"(?m)^[ \t]*(?:\d+[.)]|[-*•])\s+"#,
                         options: .regularExpression) == nil else { return text }
        var sentences: [String] = []
        text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { sentence, _, _, _ in
            if let sentence {
                let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { sentences.append(trimmed) }
            }
        }
        guard !sentences.isEmpty else { return text }
        return sentences.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
    }
}
