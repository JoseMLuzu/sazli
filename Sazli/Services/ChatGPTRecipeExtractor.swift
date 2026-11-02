import Foundation

struct SharedRecipeCandidate: Identifiable {
    let id = UUID()
    let draft: RecipeDraft
}

/// Selects explicit complete recipe sections; follow-up conversation stays separate.
enum ChatGPTRecipeExtractor {
    static func recipes(in messages: [String], sourceURL: URL) -> [SharedRecipeCandidate] {
        var result: [SharedRecipeCandidate] = []
        for message in messages.reversed() {
            let cleaned = clean(message)
            let lines = cleaned.components(separatedBy: .newlines)
            // Each explicit ingredient heading marks a possible recipe, not a follow-up tip.
            let starts = lines.indices.filter { headingKey(lines[$0]) == "ingredients" || headingKey(lines[$0]) == "ingredientes" }
            for (offset, start) in starts.enumerated() {
                let end = offset + 1 < starts.count ? starts[offset + 1] : lines.endIndex
                let titleIndex = lines[..<start].lastIndex { line in
                    line.hasPrefix("# ") || line.hasPrefix("## ")
                }
                guard let titleIndex else { continue }
                let recipeLines = Array(lines[titleIndex..<end])
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
                    result.append(SharedRecipeCandidate(draft: draft))
                }
            }
        }
        return result
    }

    private static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: #"\uE200[^\uE201]*\uE201"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\uE200[^\uE202]*\uE202"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"(?s)<AsyncImage[^>]*>.*?</AsyncImage>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"<AsyncImage[^>]*/>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"</?[A-Za-z][^>]*>"#, with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "\\.", with: ".")
            .replacingOccurrences(of: "\\!", with: "!")
            .components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
    }

    private static func headingKey(_ line: String) -> String {
        line.trimmingCharacters(in: CharacterSet(charactersIn: "#*: "))
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
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
        for line in lines {
            let key = headingKey(line)
            if key == "ingredients" || key == "ingredientes" { beforeIngredients = false }
            if ["preparacion paso a paso", "step-by-step instructions", "method", "preparacion", "instructions", "directions", "steps", "instrucciones", "pasos", "elaboracion"].contains(key) {
                flushStep()
                output.append("Instructions:")
                inMethod = true
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
