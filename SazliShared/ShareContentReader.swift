import Foundation
import UniformTypeIdentifiers

/// Receives only representations supplied by the sharing app, never files or account content.
@MainActor
enum ShareContentReader {
    static func read(items: [NSExtensionItem]) async throws -> String {
        let providers = items.flatMap { $0.attachments ?? [] }
        guard providers.count <= 8 else { throw SharedRecipeInbox.InboxError.tooLarge }
        var parts: [String] = []
        for provider in providers {
            try Task.checkCancellation()
            var text: String?
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                text = try await representation(provider, type: UTType.url.identifier, urlOnly: true)
            }
            if text == nil, provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                text = try await representation(provider, type: UTType.plainText.identifier, urlOnly: false)
            }
            if text == nil, provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                text = try await representation(provider, type: UTType.text.identifier, urlOnly: false)
            }
            if let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !parts.contains(text) {
                parts.append(text)
            }
        }
        let text = parts.joined(separator: "\n")
        try SharedRecipeInbox.validate(text)
        return text
    }

    private static func representation(_ provider: NSItemProvider, type: String, urlOnly: Bool) async throws -> String? {
        if urlOnly, provider.canLoadObject(ofClass: NSURL.self) {
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadObject(ofClass: NSURL.self) { value, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: validURL((value as? URL)?.absoluteString))
                }
            }
        }
        if !urlOnly, provider.canLoadObject(ofClass: NSString.self) {
            return try await withCheckedThrowingContinuation { continuation in
                provider.loadObject(ofClass: NSString.self) { value, error in
                    if let error { continuation.resume(throwing: error); return }
                    continuation.resume(returning: value as? String)
                }
            }
        }
        return try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type, options: nil) { value, error in
                if let error { continuation.resume(throwing: error); return }
                let text: String?
                if let url = value as? URL { text = url.absoluteString }
                else if let string = value as? String { text = string }
                else if let data = value as? Data, data.count <= SharedRecipeInbox.maximumBytes {
                    text = String(data: data, encoding: .utf8)
                } else { text = nil }
                continuation.resume(returning: urlOnly ? validURL(text) : text)
            }
        }
    }

    private nonisolated static func validURL(_ text: String?) -> String? {
        guard let text, let url = URLComponents(string: text),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              url.host != nil, url.user == nil, url.password == nil else { return nil }
        return text
    }
}
