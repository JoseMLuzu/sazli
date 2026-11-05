import Foundation

struct PendingRecipeImport: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let createdAt: Date
}

/// Only pending user-shared text crosses the App Group; the SwiftData store stays private.
struct SharedRecipeInbox: Sendable {
    static let groupIdentifier = "group.com.sazli.app.imports"
    static let maximumBytes = 200_000
    static let maximumPending = 20
    let directory: URL

    static var groupDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier)?
            .appendingPathComponent("SharedRecipeImports", isDirectory: true)
    }

    static func validate(_ text: String) throws {
        guard text.utf8.count <= maximumBytes else { throw InboxError.tooLarge }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw InboxError.empty }
    }

    @discardableResult
    func enqueue(_ text: String) throws -> PendingRecipeImport {
        try Self.validate(text)
        return try coordinated { directory in
            let existing = try Self.read(in: directory)
            guard existing.count < Self.maximumPending else { throw InboxError.full }
            let request = PendingRecipeImport(id: UUID(), text: text, createdAt: Date())
            try JSONEncoder().encode(request).write(to: Self.path(for: request.id, in: directory),
                options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return request
        }
    }

    func pending() throws -> [PendingRecipeImport] {
        try coordinated { try Self.read(in: $0) }
    }

    func remove(_ id: UUID) throws {
        try coordinated { directory in
            let path = Self.path(for: id, in: directory)
            if FileManager.default.fileExists(atPath: path.path) { try FileManager.default.removeItem(at: path) }
        }
    }

    private func coordinated<T>(_ operation: (URL) throws -> T) throws -> T {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        var coordinationError: NSError?
        var result: Result<T, Error>?
        NSFileCoordinator(filePresenter: nil).coordinate(writingItemAt: directory, options: .forMerging,
                                                        error: &coordinationError) { url in
            result = Result { try operation(url) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw InboxError.unavailable }
        return try result.get()
    }

    private static func read(in directory: URL) throws -> [PendingRecipeImport] {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])
            .filter { $0.pathExtension == "json" }
        guard files.count <= maximumPending else { throw InboxError.full }
        return try files.map { url in
            guard (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= maximumBytes * 6 + 1024 else {
                throw InboxError.unreadable
            }
            let request = try JSONDecoder().decode(PendingRecipeImport.self, from: Data(contentsOf: url))
            guard url.deletingPathExtension().lastPathComponent == request.id.uuidString else { throw InboxError.unreadable }
            try validate(request.text)
            return request
        }.sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
    }

    private static func path(for id: UUID, in directory: URL) -> URL {
        directory.appendingPathComponent(id.uuidString).appendingPathExtension("json")
    }

    enum InboxError: LocalizedError {
        case unavailable, empty, tooLarge, full, unreadable
        var errorDescription: String? {
            switch self {
            case .unavailable: "Sazli's shared inbox isn't available. Open Sazli once and try sharing again."
            case .empty: "This app didn't provide recipe text or a link. Try its system Share option."
            case .tooLarge: "Share one recipe at a time, up to 200 KB."
            case .full: "Your import inbox is full. Review pending recipes in Sazli before sharing more."
            case .unreadable: "A pending shared recipe couldn't be read. It has been kept for recovery."
            }
        }
    }
}
