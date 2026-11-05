import XCTest
import UniformTypeIdentifiers
@testable import Sazli

@MainActor
final class ShareImportTests: XCTestCase {
    private let share = "https://chatgpt.com/share/6ae9a2ef-d8ec-83e9-8417-ab10621b8705"

    func testReceivesPublicURLAndRecipeTextWithoutReadingAccounts() async throws {
        let item = NSExtensionItem()
        item.attachments = [NSItemProvider(object: URL(string: share)! as NSURL)]
        let received = try await ShareContentReader.read(items: [item])
        XCTAssertEqual(received, share)
        guard case .chatGPT = try RecipeImportRouter.route(received) else { return XCTFail("Wrong reader") }
        let text = "Eggs\nIngredients: • Eggs • Salt\nMethod: 1. Mix. 2. Cook."
        item.attachments = [NSItemProvider(object: text as NSString), NSItemProvider(object: text as NSString)]
        let receivedText = try await ShareContentReader.read(items: [item])
        XCTAssertEqual(receivedText, text)
    }

    func testUnsupportedFilesEmptyAndOversizedContentAreRejected() async throws {
        let item = NSExtensionItem()
        item.attachments = [NSItemProvider(object: URL(fileURLWithPath: "/private/document.txt") as NSURL)]
        do { _ = try await ShareContentReader.read(items: [item]); XCTFail("File URL accepted") } catch {}
        item.attachments = [NSItemProvider(object: String(repeating: "x", count: SharedRecipeInbox.maximumBytes + 1) as NSString)]
        do { _ = try await ShareContentReader.read(items: [item]); XCTFail("Oversized text accepted") } catch {}
        do { _ = try await ShareContentReader.read(items: []); XCTFail("Empty share accepted") } catch {}
    }

    func testSharedDeliveryIsDurableAndMovesToPrivateReviewWithTheSameUUID() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let shared = SharedRecipeInbox(directory: root.appendingPathComponent("shared"))
        let request = try shared.enqueue(share)
        XCTAssertEqual(try SharedRecipeInbox(directory: shared.directory).pending(), [request])
        let privateDirectory = root.appendingPathComponent("private")
        let inbox = RecipeImportInbox(directory: privateDirectory, sharedDirectory: shared.directory)
        XCTAssertEqual(inbox.pending, [request])
        XCTAssertTrue(try shared.pending().isEmpty)
        XCTAssertNil(inbox.errorMessage)
        let reopened = RecipeImportInbox(directory: privateDirectory, sharedDirectory: shared.directory)
        XCTAssertEqual(reopened.pending, [request])
        try reopened.remove(request.id)
        XCTAssertTrue(reopened.pending.isEmpty)
    }

    func testInterruptedCopyAcknowledgesTheVerifiedUUIDWithoutAnotherImport() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let shared = SharedRecipeInbox(directory: root.appendingPathComponent("shared"))
        let request = try shared.enqueue(share)
        let directory = root.appendingPathComponent("private")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(request).write(to: directory.appendingPathComponent(request.id.uuidString + ".json"))
        let inbox = RecipeImportInbox(directory: directory, sharedDirectory: shared.directory)
        inbox.reload()
        XCTAssertEqual(inbox.pending, [request])
        XCTAssertTrue(try shared.pending().isEmpty)
        XCTAssertNil(inbox.errorMessage)
    }

    func testMalformedSharedFilesRemainAvailableWithoutHidingPrivateImports() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("private")
        let originalInbox = RecipeImportInbox(directory: directory)
        let request = try originalInbox.enqueue(share)
        let shared = SharedRecipeInbox(directory: root.appendingPathComponent("shared"))
        _ = try shared.pending()
        let malformed = shared.directory.appendingPathComponent(UUID().uuidString + ".json")
        try Data("broken JSON".utf8).write(to: malformed)
        let inbox = RecipeImportInbox(directory: directory, sharedDirectory: shared.directory)
        XCTAssertEqual(inbox.pending, [request])
        XCTAssertNotNil(inbox.errorMessage)
        XCTAssertTrue(FileManager.default.fileExists(atPath: malformed.path))
    }

    func testFullPrivateInboxKeepsSharedRequestsUntilThereIsRoom() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let directory = root.appendingPathComponent("private")
        let initial = RecipeImportInbox(directory: directory)
        for index in 0..<20 { try initial.enqueue("Recipe \(index)") }
        let shared = SharedRecipeInbox(directory: root.appendingPathComponent("shared"))
        let incoming = try shared.enqueue(share)
        let inbox = RecipeImportInbox(directory: directory, sharedDirectory: shared.directory)
        XCTAssertEqual(inbox.pending.count, 20)
        XCTAssertEqual(try shared.pending(), [incoming])
        try inbox.remove(try XCTUnwrap(inbox.pending.first).id)
        XCTAssertEqual(inbox.pending.count, 20)
        XCTAssertTrue(inbox.pending.contains(incoming))
        XCTAssertTrue(try shared.pending().isEmpty)
    }

    func testSharedInboxBoundsAndIdentifierValidationKeepOriginalFiles() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let store = SharedRecipeInbox(directory: root)
        XCTAssertThrowsError(try store.enqueue(" \n"))
        XCTAssertThrowsError(try store.enqueue(String(repeating: "x", count: SharedRecipeInbox.maximumBytes + 1)))
        for index in 0..<20 { try store.enqueue("Recipe \(index)") }
        XCTAssertThrowsError(try store.enqueue("Overflow"))
        XCTAssertEqual(try store.pending().count, 20)
        let first = try XCTUnwrap(store.pending().first)
        try store.remove(first.id)
        let invalid = root.appendingPathComponent(UUID().uuidString + ".json")
        try JSONEncoder().encode(first).write(to: invalid)
        XCTAssertThrowsError(try store.pending())
        XCTAssertTrue(FileManager.default.fileExists(atPath: invalid.path))
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("SazliShareTests-" + UUID().uuidString)
    }
}
