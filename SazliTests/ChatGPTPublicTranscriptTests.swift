import XCTest
@testable import Sazli

final class ChatGPTPublicTranscriptTests: XCTestCase {
    private let shareID = "6ae9a2ef-d8ec-83e9-8417-ab10621b8705"
    private let text = "# Soup\nIngredients:\n- Water\nInstructions:\n1. Simmer."

    func testPublicTranscriptReadsOnlyCompleteVisibleAssistantRows() throws {
        let visible = row("good")
        var user = row("user"); var frame = user["frame"] as! [String: Any]; frame["role"] = "user"; user["frame"] = frame
        var streaming = row("streaming"); frame = streaming["frame"] as! [String: Any]; frame["isStreaming"] = true; streaming["frame"] = frame
        var hidden = row("hidden"); frame = hidden["frame"] as! [String: Any]; frame["hidden"] = true; hidden["frame"] = frame
        var reasoning = row("analysis"); var source = reasoning["source"] as! [String: Any]; source["channel"] = "analysis"; reasoning["source"] = source
        var privateRow = row("private"); source = privateRow["source"] as! [String: Any]; source.removeValue(forKey: "publicShareId"); privateRow["source"] = source
        var mismatched = row("mismatch"); source = mismatched["source"] as! [String: Any]; source["messageId"] = "other"; mismatched["source"] = source
        let html = try document([user, streaming, hidden, reasoning, privateRow, mismatched, visible])
        XCTAssertEqual(try ChatGPTShareDocument.assistantMessages(in: html), [text])
        XCTAssertThrowsError(try ChatGPTShareDocument.messages(in: document([streaming, privateRow])))
    }

    func testPublicTranscriptKeepsEachRecipePhotoWithItsOwnMessage() throws {
        let first = row("one", photo: "https://images.openai.com/static-rsc-4/soup")
        let second = row("two", text: "# Toast\nIngredients:\n- Bread\nInstructions:\n1. Toast.",
                         photo: "https://images.openai.com/static-rsc-4/toast")
        let messages = try ChatGPTShareDocument.messages(in: document([first, second]))
        let recipes = ChatGPTRecipeExtractor.recipes(inSharedMessages: messages, sourceURL: URL(string: "https://chatgpt.com/share/\(shareID)")!)
        XCTAssertEqual(recipes.map { $0.draft.title }, ["Toast", "Soup"])
        XCTAssertEqual(recipes[0].photoURLs.first?.lastPathComponent, "toast")
        XCTAssertEqual(recipes[1].photoURLs.first?.lastPathComponent, "soup")
        XCTAssertEqual(recipes[0].draft.instructions, "Toast.")
    }

    func testMalformedOrUnrelatedJSONCannotBeUsedAsATranscript() throws {
        let data = try JSONSerialization.data(withJSONObject: ["streaming": false, "rows": [row("one")]])
        let json = String(decoding: data, as: UTF8.self)
        XCTAssertThrowsError(try ChatGPTShareDocument.messages(in: "<script type='application/json'>\(json)</script>"))
        XCTAssertThrowsError(try ChatGPTShareDocument.messages(in: "<script id='octane-conversation-transcript' type='application/json'>{bad}</script>"))
    }

    private func row(_ id: String, text override: String? = nil, photo: String? = nil) -> [String: Any] {
        var dil: [String: Any] = ["fallbackMarkdown": override ?? text]
        if let photo {
            dil["appData"] = ["opGenui": ["componentResults": ["cover": [
                "componentName": "AsyncImage", "safe_urls": [photo],
                "state": ["frame_aspect_ratio": "16:9", "images": [["content_url": photo]]]]]]]
        }
        return ["origin": "server", "frame": ["id": id, "role": "assistant", "isStreaming": false],
                "source": ["messageId": id, "status": "complete", "publicShareId": shareID, "dil": dil]]
    }

    private func document(_ rows: [[String: Any]]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: ["streaming": false, "rows": rows])
        return "<script type='application/json' id='octane-conversation-transcript'>\(String(decoding: data, as: UTF8.self))</script>"
    }
}
