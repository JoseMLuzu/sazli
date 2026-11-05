import Foundation

/// Recognizes a written quantity-led list followed by a consecutive numbered method,
/// even when a creator omits both Ingredients and Instructions labels.
enum RecipeBulletedCaption {
    static func normalized(_ text: String, quantity: String) -> String? {
        for method in RecipeMethodMarkers.candidates(in: text) {
            if let result = normalized(text, quantity: quantity, candidate: method) { return result }
        }
        return nil
    }

    private static func normalized(_ text: String, quantity: String, candidate: RecipeMethodMarkers.Candidate) -> String? {
        guard let method = Range(candidate.first, in: text) else { return nil }
        let rawPrefix = String(text[..<method.lowerBound])
        let prefix = rawPrefix.replacingOccurrences(
            of: #"(?:^|[ \t\n])(?:#{1,6}[ \t]*)?(?:instructions|method|directions|steps|preparation steps|modo de preparaci[oó]n|instrucciones|preparaci[oó]n|procedimiento|pasos)[ \t]*[:：]?[ \t\n]*$"#,
            with: "", options: [.regularExpression, .caseInsensitive])
        // This prefix ends before the first numbered marker, so checking its headings cannot
        // recursively recognize another numbered recipe.
        guard !RecipeCaptionParser.containsIngredientHeading(prefix),
              let bullets = try? NSRegularExpression(
                pattern: #"(?<!\S)[*•◦▪✅–—-]\uFE0F?(?:\s+|(?=[\p{L}\p{N}]))"#) else { return nil }
        let allItems = bullets.matches(in: prefix, range: NSRange(prefix.startIndex..., in: prefix))
        var votes: [Character: Int] = [:]
        for match in allItems {
            guard let range = Range(match.range, in: prefix),
                  prefix[range.upperBound...].range(of: "^" + quantity + #"[ \t]*\p{L}"#,
                                                  options: .regularExpression) != nil else { continue }
            votes[Character(String(prefix[range.lowerBound].unicodeScalars.first!)), default: 0] += 1
        }
        guard let marker = votes.filter({ $0.value >= 2 }).sorted(by: {
            let leftPriority = "*•◦▪✅".contains($0.key) ? 1 : 0
            let rightPriority = "*•◦▪✅".contains($1.key) ? 1 : 0
            return leftPriority == rightPriority ? $0.value > $1.value : leftPriority > rightPriority
        }).first?.key else { return nil }
        let items = allItems.filter { match in
            guard let range = Range(match.range, in: prefix) else { return false }
            return Character(String(prefix[range.lowerBound].unicodeScalars.first!)) == marker
        }
        guard items.count >= 2, let first = items.first, let firstRange = Range(first.range, in: prefix) else { return nil }
        var bodies: [String] = []
        for (index, item) in items.enumerated() {
            guard let range = Range(item.range, in: prefix) else { return nil }
            let end: String.Index
            if index + 1 < items.count {
                guard let next = Range(items[index + 1].range, in: prefix) else { return nil }
                end = next.lowerBound
            } else { end = prefix.endIndex }
            let body = prefix[range.upperBound..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            if !bodies.isEmpty, RecipeIngredientMeasure.isContinuation(body) {
                bodies[bodies.count - 1] += " " + String(marker) + " " + body
            } else { bodies.append(body) }
        }
        guard bodies.filter({ $0.range(of: "^" + quantity + #"[ \t]*\p{L}"#,
                                      options: .regularExpression) != nil }).count >= 2 else { return nil }
        var lines = [String(prefix[..<firstRange.lowerBound]), "Ingredients:"]
        for body in bodies {
            if let heading = trailingGroup(in: body) {
                let ingredient = body[..<heading.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                lines.append("• " + ingredient)
                lines.append("# " + body[heading].trimmingCharacters(in: .whitespacesAndNewlines))
            } else { lines.append("• " + body) }
        }
        lines.append("Instructions:")
        guard let methodText = candidate.methodText(in: text) else { return nil }
        if let footer = methodText.range(
            of: #"\b(?:the full (?:detailed )?recipe (?:will be|is|can be)|full recipe (?:on|in)|recipe link in (?:my )?bio)\b"#,
            options: [.regularExpression, .caseInsensitive]) {
            lines.append(String(methodText[..<footer.lowerBound]))
            lines.append("Notes:")
            lines.append(String(methodText[footer.lowerBound...]))
        } else { lines.append(methodText) }
        return lines.joined(separator: "\n")
    }

    private static func trailingGroup(in item: String) -> Range<String.Index>? {
        guard let range = item.range(
            of: #"(?:\b\p{Lu}[\p{L}'’&-]*[ \t]+){1,6}(?:Sauce|Filling|Dough|Crust|Topping|Marinade|Wraps|Meatballs|Salsa|Relleno|Masa|Cobertura)[ \t]*$"#,
            options: .regularExpression) else { return nil }
        let prefix = item[..<range.lowerBound].trimmingCharacters(in: .whitespaces)
        // A secondary metric measure plus an already named food prevents a capitalized food
        // such as 'Monterey Jack' or 'Sour Cream Sauce' from being mistaken for a group.
        guard prefix.range(of: #"(?:\b(?:g|ml|oz|lb)|\))$"#, options: .regularExpression) != nil,
              prefix.components(separatedBy: CharacterSet.letters.inverted).filter({ !$0.isEmpty }).count >= 3 else { return nil }
        return range
    }
}
