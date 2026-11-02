import Foundation

/// Interprets explicit recipe sections only. Never downloads or generates content.
enum RecipeImportParser {
    static let maximumBytes = 200_000

    static func parse(_ input: String) throws -> RecipeDraft {
        guard input.utf8.count <= maximumBytes else { throw ImportError.tooLarge }
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw ImportError.empty }
        var draft = RecipeDraft()
        draft.title = "Imported recipe"
        if let url = SourceLink.url(from: text) {
            draft.sourceURL = url.absoluteString
            draft.sourcePlatform = SourceLink.platform(for: draft.sourceURL)
            draft.title = "Recipe from \(draft.sourcePlatform.title)"
            return draft
        }

        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue),
           let url = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap(\.url).first(where: { SourceLink.url(from: $0.absoluteString) != nil }) {
            draft.sourceURL = url.absoluteString
            draft.sourcePlatform = SourceLink.platform(for: draft.sourceURL)
        }

        enum Section { case description, ingredients, instructions }
        var section = Section.description
        var descriptions: [String] = []
        var ingredients: [String] = []
        var instructions: [String] = []
        var canUseTitle = true
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }
            let clean = line.trimmingCharacters(in: CharacterSet(charactersIn: "#*_ "))
            let parts = clean.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let heading = key(String(parts[0]))
            let inline = parts.count == 2 ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines) : ""
            if ["ingredients", "ingredientes"].contains(heading) {
                section = .ingredients
                canUseTitle = false
                if !inline.isEmpty { ingredients.append(item(inline)) }
                continue
            }
            if ["instructions", "directions", "method", "preparation", "steps", "instrucciones", "preparacion", "pasos", "elaboracion"].contains(heading) {
                section = .instructions
                canUseTitle = false
                if !inline.isEmpty { instructions.append(item(inline)) }
                continue
            }
            if ["notes", "notas", "tips", "consejos", "description", "descripcion"].contains(heading) {
                section = .description
                canUseTitle = false
                descriptions.append(line)
                continue
            }
            // Read metadata only when units and a complete, supported value are explicit.
            if ["prep time", "preparation time", "tiempo", "tiempo de preparacion"].contains(heading),
               let match = inline.range(of: #"^\d{1,5}\s*(min|mins|minutes|minutos)\.?$"#, options: [.regularExpression, .caseInsensitive]),
               match == inline.startIndex..<inline.endIndex,
               let minutes = Int(inline.prefix(while: \.isNumber)), minutes <= 10_080 {
                draft.preparationTime = String(minutes)
                continue
            }
            if ["servings", "porciones", "raciones"].contains(heading),
               let count = Int(inline), (1...999).contains(count) {
                draft.servings = String(count)
                continue
            }
            if line == draft.sourceURL { continue }
            if canUseTitle, clean.count <= 120, !clean.hasPrefix("http"), !clean.hasPrefix("-") {
                draft.title = clean
                canUseTitle = false
                continue
            }
            canUseTitle = false
            switch section {
            case .description: descriptions.append(line)
            case .ingredients: ingredients.append(item(line))
            case .instructions: instructions.append(item(line))
            }
        }
        draft.description = descriptions.joined(separator: "\n")
        draft.ingredients = ingredients.joined(separator: "\n")
        draft.instructions = instructions.joined(separator: "\n")
        return draft
    }

    private static func key(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: "#*_: "))
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func item(_ line: String) -> String {
        line.replacingOccurrences(of: #"^(?:[-*•]\s+|\d+[.)]\s+)"#, with: "", options: .regularExpression)
    }

    enum ImportError: LocalizedError {
        case empty, tooLarge
        var errorDescription: String? {
            switch self {
            case .empty: "Paste a recipe or a website link first."
            case .tooLarge: "This text is too long. Share one recipe at a time (up to 200 KB)."
            }
        }
    }
}
