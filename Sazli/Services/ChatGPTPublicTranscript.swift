import Foundation

/// Adapter for the public mobile transcript. Reads data only; component code is never executed.
enum ChatGPTPublicTranscript {
    static func messages(in html: String) -> [SharedChatGPTMessage]? {
        guard let expression = try? NSRegularExpression(
            pattern: #"<script\b[^>]*\bid=["']octane-conversation-transcript["'][^>]*>(.*?)</script>"#,
            options: [.dotMatchesLineSeparators, .caseInsensitive]),
              let match = expression.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html),
              let object = try? JSONSerialization.jsonObject(with: Data(html[range].utf8)) as? [String: Any],
              object["streaming"] as? Bool == false,
              let rows = object["rows"] as? [[String: Any]], rows.count <= 50_000 else { return nil }
        var result: [SharedChatGPTMessage] = []
        var shareID: UUID?
        for row in rows {
            guard row["origin"] as? String == "server",
                  let frame = row["frame"] as? [String: Any], frame["role"] as? String == "assistant",
                  frame["isStreaming"] as? Bool == false,
                  frame["hidden"] as? Bool != true,
                  frame["isVisuallyHidden"] as? Bool != true,
                  let id = frame["id"] as? String,
                  let source = row["source"] as? [String: Any], source["messageId"] as? String == id,
                  source["status"] as? String == "complete",
                  source["hidden"] as? Bool != true,
                  source["channel"] as? String == nil || source["channel"] as? String == "final",
                  let publicID = source["publicShareId"] as? String, let uuid = UUID(uuidString: publicID),
                  shareID == nil || shareID == uuid else { continue }
            let dil = source["dil"] as? [String: Any]
            let markdown = source["markdown"] as? String ?? ""
            let text = markdown.isEmpty ? dil?["fallbackMarkdown"] as? String ?? "" : markdown
            guard !text.isEmpty, text.utf8.count <= RecipeImportParser.maximumBytes,
                  !result.contains(where: { $0.text == text }) else { continue }
            shareID = uuid
            result.append(SharedChatGPTMessage(text: text, images: coverImages(in: dil, text: text)))
        }
        return result.isEmpty ? nil : result
    }

    private static func coverImages(in dil: [String: Any]?, text: String) -> [SharedChatGPTImage] {
        let headings = RecipeText.lines(in: text).filter {
            let key = $0.trimmingCharacters(in: CharacterSet(charactersIn: "#* ")).lowercased()
            return key.hasPrefix("ingredients") || key.hasPrefix("ingredientes")
        }
        guard headings.count == 1,
              let data = dil?["appData"] as? [String: Any], let genui = data["opGenui"] as? [String: Any],
              let components = genui["componentResults"] as? [String: [String: Any]] else { return [] }
        let images = components.values.filter { $0["componentName"] as? String == "AsyncImage" }
        let wide = images.filter {
            guard let state = $0["state"] as? [String: Any],
                  let ratio = state["frame_aspect_ratio"] as? String else { return false }
            let parts = ratio.split(separator: ":").compactMap { Double($0) }
            return parts.count == 2 && parts[1] > 0 && parts[0] / parts[1] > 1.3
        }
        let candidates = wide.count == 1 ? wide : images.count == 1 ? images : []
        guard candidates.count == 1, let component = candidates.first,
              let state = component["state"] as? [String: Any],
              let resolved = state["images"] as? [[String: Any]], let first = resolved.first,
              let approved = component["safe_urls"] as? [String] else { return [] }
        let urls = ["content_url", "thumbnail_url"].compactMap { key -> URL? in
            guard let value = first[key] as? String, approved.contains(value) else { return nil }
            return ChatGPTRecipePhoto.publicURL(from: value)
        }
        return urls.isEmpty ? [] : [SharedChatGPTImage(offset: 0, urls: urls)]
    }
}
