import Foundation

struct SharedRecipeCandidate: Identifiable {
    let id = UUID()
    let draft: RecipeDraft
    var photoURLs: [URL] = []
}

/// Selects explicit complete recipe sections; follow-up conversation stays separate.
enum ChatGPTRecipeExtractor {
    static func recipes(in messages: [String], sourceURL: URL) -> [SharedRecipeCandidate] {
        recipes(inSharedMessages: messages.map { SharedChatGPTMessage(text: $0) }, sourceURL: sourceURL)
    }

    static func recipes(inSharedMessages messages: [SharedChatGPTMessage], sourceURL: URL) -> [SharedRecipeCandidate] {
        var result: [SharedRecipeCandidate] = []
        for shared in messages.reversed() {
            let message = shared.text
            let cleaned = clean(message)
            let lines = cleaned.components(separatedBy: .newlines)
            // Each explicit ingredient heading marks a possible recipe, not a follow-up tip.
            let starts = lines.indices.filter { isIngredientHeading(lines[$0]) }
            for (offset, start) in starts.enumerated() {
                let lowerBound = offset == 0 ? 0 : starts[offset - 1] + 1
                let titleIndex = Self.titleIndex(in: lines, before: start, after: lowerBound)
                let nextStart = offset + 1 < starts.count ? starts[offset + 1] : lines.endIndex
                let end = nextStart < lines.endIndex
                    ? Self.titleIndex(in: lines, before: nextStart, after: start + 1) ?? nextStart
                    : lines.endIndex
                let prefix = lines[(titleIndex ?? lowerBound)..<start].joined(separator: "\n")
                let title = titleIndex.map { headingText(lines[$0]) }
                    ?? emphasizedTitle(in: prefix) ?? "Recipe from ChatGPT"
                // A recipe does not need a Markdown title to have explicit ingredients and steps.
                var recipeLines = ["# \(title)"]
                if let titleIndex { recipeLines.append(contentsOf: lines[(titleIndex + 1)..<start]) }
                recipeLines.append(contentsOf: lines[start..<end])
                let normalized = normalizeSteps(recipeLines)
                guard var draft = try? RecipeImportParser.parse(normalized),
                      !draft.ingredients.isEmpty, !draft.instructions.isEmpty else { continue }
                draft.title = stripTitleDecoration(draft.title)
                draft.description = draft.description.components(separatedBy: .newlines)
                    .filter { $0 != "Notes:" }
                    .map { $0.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: .regularExpression) }
                    .joined(separator: "\n")
                draft.sourceURL = sourceURL.absoluteString
                draft.sourcePlatform = .chatGPT
                if !result.contains(where: { $0.draft.title == draft.title && $0.draft.ingredients == draft.ingredients }) {
                    result.append(SharedRecipeCandidate(draft: draft,
                        photoURLs: coverURLs(in: shared, ingredientOrdinal: offset, title: title)))
                }
            }
        }
        return result
    }

    private static func coverURLs(in message: SharedChatGPTMessage, ingredientOrdinal: Int, title: String) -> [URL] {
        var offset = 0
        var headings: [Int] = []
        for line in message.text.components(separatedBy: "\n") {
            if isIngredientHeading(line) { headings.append(offset) }
            offset += line.unicodeScalars.count + 1
        }
        guard headings.indices.contains(ingredientOrdinal) else { return [] }
        let upper = headings[ingredientOrdinal]
        var lower = 0
        if ingredientOrdinal > 0 {
            // Be conservative when several recipes share a response: never borrow a step photo.
            guard let range = message.text.range(of: title, options: .backwards),
                  message.text.unicodeScalars[..<range.lowerBound].count < upper else { return [] }
            lower = message.text.unicodeScalars[..<range.lowerBound].count
        }
        return message.images.first { $0.offset >= lower && $0.offset < upper }?.urls ?? []
    }

    private static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: #"\uE200[^\uE201]*\uE201"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\uE200[^\uE202]*\uE202"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?s)<AsyncImage[^>]*>.*?</AsyncImage>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"<AsyncImage[^>]*/>"#, with: "", options: .regularExpression)
            // ChatGPT also renders recipe titles as styled text rather than Markdown headings.
            .replacingOccurrences(of: #"(?m)^\s*<text\b[^>]*weight="(?:medium|semibold|bold)"[^>]*>([^<\n]{1,120})</text>\s*$"#,
                                  with: "## $1", options: .regularExpression)
            .replacingOccurrences(of: #"</?[A-Za-z][^>]*>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "\\.", with: ".")
            .replacingOccurrences(of: "\\!", with: "!")
            .components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
    }

    private static func headingKey(_ line: String) -> String {
        stripTitleDecoration(headingText(line)).trimmingCharacters(in: CharacterSet(charactersIn: ": "))
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func headingText(_ line: String) -> String {
        line.trimmingCharacters(in: CharacterSet(charactersIn: "#* "))
    }

    private static func isIngredientHeading(_ line: String) -> Bool {
        headingKey(line).range(of: #"^(?:ingredients|ingredientes)(?:\s*\(\s*\d{1,3}\s*(?:personas?|porciones?|raciones?|servings?|people)\s*\))?$"#,
                               options: .regularExpression) != nil
    }

    private static func titleIndex(in lines: [String], before end: Int, after start: Int) -> Int? {
        lines[start..<end].indices.last {
            (lines[$0].hasPrefix("# ") || lines[$0].hasPrefix("## "))
                && !isIngredientHeading(lines[$0]) && !isMethodHeading(headingKey(lines[$0]))
        }
    }

    private static func emphasizedTitle(in prefix: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: #"\*\*([^*\n]{3,120})\*\*"#) else { return nil }
        return expression.matches(in: prefix, range: NSRange(prefix.startIndex..., in: prefix))
            .compactMap { Range($0.range(at: 1), in: prefix).map { String(prefix[$0]) } }
            .last { !$0.hasSuffix(":") && !$0.contains("?") }
    }

    private static func isMethodHeading(_ key: String) -> Bool {
        ["preparacion paso a paso", "step-by-step instructions", "method", "preparacion", "instructions", "directions", "steps", "instrucciones", "pasos", "elaboracion"].contains(key)
    }

    private static func normalizeSteps(_ lines: [String]) -> String {
        var output: [String] = []
        var inMethod = false
        var beforeIngredients = true
        var currentStep: String?
        func flushStep() {
            if let step = currentStep { output.append(step) }
            currentStep = nil
        }
        for originalLine in lines {
            let line = originalLine.replacingOccurrences(of: "**", with: "")
            let key = headingKey(line)
            if isIngredientHeading(line) {
                flushStep()
                beforeIngredients = false
                if let count = line.range(of: #"\d{1,3}"#, options: .regularExpression),
                   let servings = Int(line[count]), (1...999).contains(servings) {
                    output.append("Servings: \(servings)")
                }
                output.append("Ingredients:")
                inMethod = false
            } else if isMethodHeading(key) {
                flushStep()
                output.append("Instructions:")
                inMethod = true
            } else if inMethod, ["mi truco", "un truco", "tip", "tips", "consejo", "notas", "notes"]
                .contains(key.components(separatedBy: ":")[0]) {
                flushStep()
                output.append("Notes:")
                output.append(line)
                inMethod = false
            } else if line.hasPrefix("#") {
                flushStep()
                if inMethod {
                    // Unknown headings after the method begin notes, never additional cooking steps.
                    output.append("Notes:")
                    inMethod = false
                }
                output.append(line)
            } else if inMethod {
                if line.range(of: #"^\s*\d+[.)]\s+"#, options: .regularExpression) != nil {
                    flushStep()
                    currentStep = line.trimmingCharacters(in: .whitespaces)
                } else if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if let step = currentStep { currentStep = step + " " + line.trimmingCharacters(in: .whitespaces) }
                    else { output.append(line) }
                }
            } else {
                // Compact source metadata stays explicit; do not infer missing time or portions.
                let metadata = beforeIngredients ? compactMetadata(in: line) : []
                if !metadata.isEmpty { output.append(contentsOf: metadata) }
                else { output.append(line) }
            }
        }
        flushStep()
        return output.joined(separator: "\n")
    }

    private static func compactMetadata(in line: String) -> [String] {
        guard !line.hasPrefix("-"), !line.hasPrefix("#"), line.count < 120 else { return [] }
        if let match = line.range(of: #"^\d{1,5}\s*(?:minutes|minutos|min)$"#, options: [.regularExpression, .caseInsensitive]), match == line.startIndex..<line.endIndex {
            return ["Prep time: \(line.prefix(while: \.isNumber)) min"]
        }
        if let match = line.range(of: #"^\d{1,3}\s*(?:porci[oó]n(?:es)?|servings?)(?:\s+grande)?$"#, options: [.regularExpression, .caseInsensitive]), match == line.startIndex..<line.endIndex {
            return ["Servings: \(line.prefix(while: \.isNumber))"]
        }
        let pattern = #"^\s*(\d{1,5})\s*(?:minutes|minutos|min)\s+(?:[\p{L}\s]+?)\s+(\d{1,3})\s*(?:porci[oó]n(?:es)?|servings?)(?:\s+grande)?\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let minutes = Range(match.range(at: 1), in: line), let servings = Range(match.range(at: 2), in: line) else { return [] }
        return ["Prep time: \(line[minutes]) min", "Servings: \(line[servings])"]
    }

    private static func stripTitleDecoration(_ title: String) -> String {
        String(title.drop(while: { character in
            character.isWhitespace || character.unicodeScalars.contains { $0.properties.isEmojiPresentation }
        })).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
