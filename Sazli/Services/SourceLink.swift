import Foundation

enum SourceLink {
    /// Only public ChatGPT share pages are read automatically; private chat URLs stay references.
    static func chatGPTShareURL(from text: String) -> URL? {
        guard let url = url(from: text), url.scheme?.lowercased() == "https",
              ["chatgpt.com", "www.chatgpt.com", "chat.openai.com"].contains(url.host?.lowercased() ?? ""),
              url.port == nil || url.port == 443 else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        guard path.count == 2, path[0] == "share", UUID(uuidString: path[1]) != nil else { return nil }
        return url
    }

    static func url(from text: String) -> URL? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, !value.contains(where: \.isWhitespace) else { return nil }
        let normalized = value.contains("://") ? value : "https://" + value
        guard let components = URLComponents(string: normalized),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host, host.contains("."),
              components.user == nil, components.password == nil else { return nil }
        return components.url
    }

    static func platform(for text: String) -> SourcePlatform {
        guard let host = url(from: text)?.host?.lowercased() else { return .manual }
        func matches(_ domain: String) -> Bool { host == domain || host.hasSuffix("." + domain) }
        if matches("chatgpt.com") || matches("chat.openai.com") { return .chatGPT }
        if matches("youtube.com") || matches("youtu.be") { return .youtube }
        if matches("tiktok.com") { return .tiktok }
        if matches("facebook.com") || matches("fb.watch") { return .facebook }
        return .web
    }
}
