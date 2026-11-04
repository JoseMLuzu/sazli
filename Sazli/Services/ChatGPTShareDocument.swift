import Foundation
import CoreFoundation

struct SharedChatGPTMessage {
    let text: String
    var images: [SharedChatGPTImage] = []
}

struct SharedChatGPTImage {
    let offset: Int
    let urls: [URL]
}

/// Reads the public share page's embedded data, without executing it or accessing an account.
/// This is a best-effort website adapter, not a supported ChatGPT conversation API.
enum ChatGPTShareDocument {
    static let maximumHTMLBytes = 4_000_000

    static func assistantMessages(in html: String) throws -> [String] {
        try messages(in: html).map(\.text)
    }

    static func messages(in html: String) throws -> [SharedChatGPTMessage] {
        guard html.utf8.count <= maximumHTMLBytes else { throw ReadError.tooLarge }
        let expression = try NSRegularExpression(
            pattern: #"streamController\.enqueue\(\s*("(?:\\.|[^"\\])*")\s*\)"#,
            options: [.dotMatchesLineSeparators])
        for match in expression.matches(in: html, range: NSRange(html.startIndex..., in: html)) {
            guard let range = Range(match.range(at: 1), in: html),
                  let payload = try? JSONSerialization.jsonObject(with: Data(html[range].utf8), options: .fragmentsAllowed) as? String,
                  let table = try? JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [Any],
                  table.count <= 50_000 else { continue }
            let reader = ReferenceTable(values: table)
            for case let object as [String: Any] in table {
                guard let nodes = reader.field("linear_conversation", in: object) as? [Any] else { continue }
                var messages: [SharedChatGPTMessage] = []
                for reference in nodes {
                    guard let node = reader.resolve(reference) as? [String: Any],
                          let message = reader.field("message", in: node) as? [String: Any],
                          let author = reader.field("author", in: message) as? [String: Any],
                          reader.field("role", in: author) as? String == "assistant",
                          reader.field("recipient", in: message) as? String == "all",
                          reader.field("channel", in: message) as? String == "final",
                          let content = reader.field("content", in: message) as? [String: Any],
                          reader.field("content_type", in: content) as? String == "text",
                          let parts = reader.field("parts", in: content) as? [Any] else { continue }
                    if let metadata = reader.field("metadata", in: message) as? [String: Any],
                       reader.field("is_visually_hidden_from_conversation", in: metadata) as? Bool == true { continue }
                    let text = parts.compactMap { reader.resolve($0) as? String }.joined(separator: "\n")
                    if !text.isEmpty, text.utf8.count <= RecipeImportParser.maximumBytes,
                       !messages.contains(where: { $0.text == text }) {
                        var images: [SharedChatGPTImage] = []
                        if let metadata = reader.field("metadata", in: message) as? [String: Any],
                           let components = reader.field("genui_components", in: metadata) as? [Any] {
                            for reference in components {
                                guard let component = reader.resolve(reference) as? [String: Any],
                                      reader.field("type", in: component) as? String == "async_image",
                                      let offset = reader.field("start_index", in: component) as? Int,
                                      offset >= 0,
                                      let links = reader.field("safe_urls", in: component) as? [Any] else { continue }
                                let urls = links.compactMap { link -> URL? in
                                    guard let object = reader.resolve(link) as? [String: Any],
                                          let value = reader.field("url", in: object) as? String else { return nil }
                                    return ChatGPTRecipePhoto.publicURL(from: value)
                                }
                                if !urls.isEmpty { images.append(SharedChatGPTImage(offset: offset, urls: Array(urls.prefix(2)))) }
                            }
                        }
                        messages.append(SharedChatGPTMessage(text: text, images: images.sorted { $0.offset < $1.offset }))
                    }
                }
                if !messages.isEmpty { return messages }
            }
        }
        throw ReadError.unavailable
    }

    private struct ReferenceTable {
        let values: [Any]

        func resolve(_ reference: Any) -> Any? {
            guard let number = reference as? NSNumber,
                  CFGetTypeID(number) != CFBooleanGetTypeID(),
                  number.doubleValue == Double(number.intValue),
                  values.indices.contains(number.intValue) else { return nil }
            return values[number.intValue]
        }

        func field(_ name: String, in object: [String: Any]) -> Any? {
            for (key, value) in object {
                guard key.hasPrefix("_"), let index = Int(key.dropFirst()), values.indices.contains(index),
                      values[index] as? String == name else { continue }
                return resolve(value)
            }
            return nil
        }
    }

    enum ReadError: LocalizedError {
        case tooLarge, unavailable
        var errorDescription: String? {
            switch self {
            case .tooLarge: "This shared conversation is too large. Share just the recipe text instead."
            case .unavailable: "The public conversation could not be read. It may require sign-in, have been removed, or use a page format Sazli doesn't recognize. You can keep the link or import the recipe text."
            }
        }
    }
}
