import Foundation

/// Canonicalizes only complete, consecutive ordered lists; never supplies missing actions.
enum RecipeMethodMarkers {
    struct Candidate {
        let ranges: [NSRange]
        var first: NSRange { ranges[0] }

        func methodText(in text: String) -> String? {
            guard let firstRange = Range(first, in: text) else { return nil }
            var result = String(text[firstRange.lowerBound...])
            for (index, marker) in ranges.enumerated().reversed() {
                let relative = NSRange(location: marker.location - first.location, length: marker.length)
                guard let range = Range(relative, in: result) else { return nil }
                var lower = range.lowerBound
                while lower > result.startIndex {
                    let previous = result.index(before: lower)
                    guard result[previous].isWhitespace else { break }
                    lower = previous
                }
                result.replaceSubrange(lower..<range.upperBound,
                    with: (lower == result.startIndex ? "" : "\n") + "\(index + 1). ")
            }
            return result
        }
    }

    static func candidates(in text: String) -> [Candidate] {
        let formats: [(String, Bool)] = [
            (#"(?<![\p{L}\p{N}.,])([1-9]\d?)[.)](?:\s+|(?=\p{L}))"#, false),
            (#"(?<![\p{L}\p{N}])\(([1-9]\d?)\)(?:\s+|(?=\p{L}))"#, false),
            (#"(?<![\p{L}\p{N}])([a-z])\)(?:\s+|(?=\p{L}))"#, true),
            (#"(?<![\p{L}\p{N}])([1-9])\uFE0F?\u20E3\s*(?=\p{L})"#, false),
            (#"\b(?:step|paso)[ \t]*([1-9]\d?)[ \t]*[:.)-][ \t]*(?=\p{L})"#, false)
        ]
        return formats.compactMap { pattern, letters -> Candidate? in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            guard (2...99).contains(matches.count) else { return nil }
            for (index, match) in matches.enumerated() {
                guard let range = Range(match.range(at: 1), in: text) else { return nil }
                let value = String(text[range]).lowercased()
                let ordinal = letters ? value.unicodeScalars.first.map { Int($0.value) - 96 } : Int(value)
                guard ordinal == index + 1 else { return nil }
            }
            return Candidate(ranges: matches.map(\.range))
        }.sorted { $0.first.location < $1.first.location }
    }

    static func canonicalized(_ text: String) -> String? {
        candidates(in: text).first { candidate in
            guard let range = Range(candidate.first, in: text) else { return false }
            return text[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }?.methodText(in: text)
    }
}
