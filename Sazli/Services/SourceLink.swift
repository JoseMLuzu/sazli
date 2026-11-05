import Foundation

enum SourceLink {
    static func instagramPostURL(from text: String) -> URL? {
        guard let url = url(from: text), url.scheme?.lowercased() == "https",
              url.port == nil || url.port == 443,
              ["instagram.com", "www.instagram.com", "m.instagram.com"].contains(url.host?.lowercased() ?? ""),
              url.path.range(of: #"^/(?:p|reel|reels|tv)/[A-Za-z0-9_-]{5,64}/?$"#,
                             options: .regularExpression) != nil else { return nil }
        return url
    }
    static func tikTokVideoURL(from text: String) -> URL? {
        guard let url = url(from: text), url.scheme?.lowercased() == "https",
              url.port == nil || url.port == 443, let host = url.host?.lowercased() else { return nil }
        if ["vt.tiktok.com", "vm.tiktok.com"].contains(host),
           url.pathComponents.filter({ $0 != "/" }).count == 1 { return url }
        guard ["www.tiktok.com", "tiktok.com", "m.tiktok.com"].contains(host),
              url.path.range(of: #"^(?:/@[^/]+/video/\d+/?|/t/[A-Za-z0-9]+/?|/v/\d+\.html)$"#,
                             options: .regularExpression) != nil else { return nil }
        return url
    }

    static func youTubeVideoID(from text: String) -> String? {
        guard let url = url(from: text), url.scheme?.lowercased() == "https",
              url.port == nil || url.port == 443, let host = url.host?.lowercased() else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        let id: String?
        if host == "youtu.be", parts.count == 1 { id = parts[0] }
        else if ["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com"].contains(host) {
            if url.path == "/watch" {
                let values = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.filter { $0.name == "v" }
                id = values?.count == 1 ? values?.first?.value : nil
            } else if parts.count == 2, ["shorts", "live", "embed"].contains(parts[0]) { id = parts[1] }
            else { id = nil }
        } else { id = nil }
        guard let id, id.range(of: #"^[A-Za-z0-9_-]{11}$"#, options: .regularExpression) != nil else { return nil }
        return id
    }

    static func videoRecipeURL(from text: String) -> URL? {
        if let url = instagramPostURL(from: text) { return url }
        if let url = tikTokVideoURL(from: text) { return url }
        guard youTubeVideoID(from: text) != nil else { return nil }
        return url(from: text)
    }

    static func sameChatGPTShare(_ first: URL, _ second: URL) -> Bool {
        guard let first = chatGPTShareURL(from: first.absoluteString),
              let second = chatGPTShareURL(from: second.absoluteString) else { return false }
        return UUID(uuidString: first.lastPathComponent) == UUID(uuidString: second.lastPathComponent)
    }

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
        let edges = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\u{200B}\u{200E}\u{200F}\u{FEFF}"))
        var value = text.trimmingCharacters(in: edges)
        if value.hasPrefix("<"), value.hasSuffix(">") { value = String(value.dropFirst().dropLast()) }
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
        if matches("instagram.com") { return .instagram }
        if matches("facebook.com") || matches("fb.watch") { return .facebook }
        return .web
    }
}
