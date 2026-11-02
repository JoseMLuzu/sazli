import Foundation
import Observation

struct PendingRecipeImport: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let createdAt: Date
}

/// A private, durable inbox for foreground App Intents. The recipe store stays in place.
@MainActor @Observable
final class RecipeImportInbox {
    static let shared = RecipeImportInbox()
    private(set) var pending: [PendingRecipeImport] = []
    private(set) var errorMessage: String?
    private let directory: URL

    init(directory: URL? = nil) {
        self.directory = directory ?? URL.applicationSupportDirectory.appendingPathComponent("RecipeImports", isDirectory: true)
        reload()
    }

    @discardableResult
    func enqueue(_ text: String) throws -> PendingRecipeImport {
        _ = try RecipeImportParser.parse(text)
        reload()
        if let errorMessage { throw InboxError.message(errorMessage) }
        guard pending.count < 20 else {
            throw InboxError.message("Your import inbox is full. Review or discard a pending recipe in Sazli first.")
        }
        let request = PendingRecipeImport(id: UUID(), text: text, createdAt: Date())
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(request).write(to: url(for: request.id), options: .atomic)
        pending.append(request)
        return request
    }

    func reload() {
        do {
            guard FileManager.default.fileExists(atPath: directory.path) else {
                pending = []
                errorMessage = nil
                return
            }
            let urls = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
                .filter { $0.pathExtension == "json" }
            var loaded: [PendingRecipeImport] = []
            for url in urls {
                guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= RecipeImportParser.maximumBytes * 6 + 1024 else {
                    throw InboxError.message("A pending import could not be read. Its file has been kept.")
                }
                let request = try JSONDecoder().decode(PendingRecipeImport.self, from: Data(contentsOf: url))
                guard url.deletingPathExtension().lastPathComponent == request.id.uuidString else {
                    throw InboxError.message("A pending import has an invalid identifier. Its file has been kept.")
                }
                _ = try RecipeImportParser.parse(request.text)
                loaded.append(request)
            }
            pending = loaded.sorted { $0.createdAt < $1.createdAt }
            errorMessage = nil
        } catch { errorMessage = "Couldn't open the import inbox: \(error.localizedDescription)" }
    }

    /// Called only after a successful recipe save, or an explicit discard.
    func remove(_ id: UUID) throws {
        let path = url(for: id)
        if FileManager.default.fileExists(atPath: path.path) { try FileManager.default.removeItem(at: path) }
        pending.removeAll { $0.id == id }
    }

    private func url(for id: UUID) -> URL { directory.appendingPathComponent(id.uuidString).appendingPathExtension("json") }

    enum InboxError: LocalizedError {
        case message(String)
        var errorDescription: String? { if case .message(let message) = self { message } else { nil } }
    }
}
