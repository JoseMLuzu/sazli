import XCTest
@testable import Sazli

final class ChatGPTShareTests: XCTestCase {
    private let shareURL = URL(string: "https://chatgpt.com/share/01234567-89ab-cdef-0123-456789abcdef")!

    func testOnlyPublicShareURLsAreRead() {
        XCTAssertNotNil(SourceLink.chatGPTShareURL(from: shareURL.absoluteString))
        XCTAssertNotNil(SourceLink.chatGPTShareURL(from: shareURL.absoluteString.replacingOccurrences(of: "https:", with: "HTTPS:")))
        XCTAssertNotNil(SourceLink.chatGPTShareURL(from: "https://chat.openai.com/share/01234567-89ab-cdef-0123-456789abcdef"))
        for value in [
            "https://chatgpt.com/c/01234567-89ab-cdef-0123-456789abcdef",
            "https://chatgpt.com/share/not-a-share-id",
            "https://chatgpt.com.example.org/share/01234567-89ab-cdef-0123-456789abcdef",
            "https://chatgpt.com:444/share/01234567-89ab-cdef-0123-456789abcdef",
            "http://chatgpt.com/share/01234567-89ab-cdef-0123-456789abcdef",
            "https://user:password@chatgpt.com/share/01234567-89ab-cdef-0123-456789abcdef"
        ] { XCTAssertNil(SourceLink.chatGPTShareURL(from: value), value) }
    }

    func testDocumentReadsOnlyPublicFinalAssistantText() throws {
        let messages: [(String, String, String, Bool)] = [
            ("user", "final", "My question", false),
            ("assistant", "analysis", "Do not import reasoning", false),
            ("tool", "final", "Do not import tool output", false),
            ("assistant", "final", "Do not import hidden messages", true),
            ("assistant", "final", "Visible recipe text", false)
        ]
        let html = try makeDocument(messages)
        XCTAssertEqual(try ChatGPTShareDocument.assistantMessages(in: html), ["Visible recipe text"])
    }

    func testDocumentRejectsUnreadableAndMalformedTables() throws {
        XCTAssertThrowsError(try ChatGPTShareDocument.assistantMessages(in: "<html>Log in</html>"))
        XCTAssertThrowsError(try ChatGPTShareDocument.assistantMessages(in: try makeDocument([("assistant", "analysis", "Only reasoning", false)])))
        let malformed = "<script>window.__reactRouterContext.streamController.enqueue(\"[{\\\"_9\\\":999999}]\")</script>"
        XCTAssertThrowsError(try ChatGPTShareDocument.assistantMessages(in: malformed))
        XCTAssertThrowsError(try ChatGPTShareDocument.assistantMessages(in: String(repeating: "a", count: ChatGPTShareDocument.maximumHTMLBytes + 1)))
    }

    func testRecipeMarkupImportsFourStepsAndExplicitMetadata() throws {
        let html = try makeDocument([("assistant", "final", recipeMarkup, false)])
        let messages = try ChatGPTShareDocument.assistantMessages(in: html)
        let candidate = try XCTUnwrap(ChatGPTRecipeExtractor.recipes(in: messages, sourceURL: shareURL).first)
        let draft = candidate.draft
        XCTAssertEqual(draft.title, "Tagliatelle con atún y salsa napolitana")
        XCTAssertEqual(draft.preparationTime, "15")
        XCTAssertEqual(draft.servings, "1")
        XCTAssertEqual(RecipeText.lines(in: draft.ingredients).count, 7)
        XCTAssertEqual(RecipeText.lines(in: draft.instructions).count, 4)
        XCTAssertTrue(draft.instructions.contains("Cocina la pasta Hierve agua con sal"))
        XCTAssertFalse(draft.instructions.contains("Mi truco"))
        XCTAssertFalse(draft.instructions.contains("<box"))
        XCTAssertFalse(draft.instructions.contains("image query"))
        XCTAssertTrue(draft.description.contains("Un poco de limón"))
        XCTAssertFalse(draft.description.contains("###"))
        XCTAssertFalse(draft.description.contains("Notes:"))
        XCTAssertEqual(draft.sourceURL, shareURL.absoluteString)
        XCTAssertEqual(draft.sourcePlatform, .chatGPT)
        XCTAssertNil(draft.imageData)
        XCTAssertNil(draft.validationMessage)
    }

    func testCompleteRecipesStaySeparateFromFollowUpAdviceAndDuplicates() {
        let original = "## Tomato pasta\nIngredients:\n- Pasta\nInstructions:\n1. Boil."
        let followUp = "Use less oil next time.\n### Steps\n1. Remove excess oil."
        let candidates = ChatGPTRecipeExtractor.recipes(in: [original, recipeMarkup, recipeMarkup, followUp], sourceURL: shareURL)
        XCTAssertEqual(candidates.count, 2)
        XCTAssertEqual(candidates[0].draft.title, "Tagliatelle con atún y salsa napolitana")
        XCTAssertEqual(candidates[1].draft.title, "Tomato pasta")
        XCTAssertFalse(candidates[0].draft.instructions.contains("Remove excess oil"))
        XCTAssertTrue(candidates[1].draft.preparationTime.isEmpty)
        XCTAssertTrue(ChatGPTRecipeExtractor.recipes(in: ["## A title\nIngredients:\n- Eggs"], sourceURL: shareURL).isEmpty)
    }

    /// A reduced fixture matching the component-markup structure observed in a public share page.
    private var recipeMarkup: String {
        """
        Some introduction before the recipe.
        <AsyncImage query="image query" aspectRatio="5:3"/>
        ## 🍝 Tagliatelle con atún y salsa napolitana
        <row align="center" gap={3}>
          <text><icon name="clock" inline/> 15 minutos</text>
          <text>Fácil</text>
          <text>1 porción grande</text>
        </row>
        ### Ingredientes
        - 125–150 g de tagliatelle.
        - 150–200 g de salsa napolitana.
        - 1 lata de atún escurrido.
        - 1 diente de ajo.
        - 1 cucharada de aceite de oliva.
        - Pimienta negra y sal.
        - Opcional: cebolla y limón.
        ### Preparación paso a paso
        <box gap={3}>
          <row>
            <AsyncImage query="image query"/>
            <box>**1. Cocina la pasta**

              Hierve agua con sal y cocina la pasta durante 7 minutos.
            </box>
          </row>
          <divider/>
          <row><box>**2. Prepara la base**
            Sofríe el ajo.
          </box></row>
          <row><box>**3. Añade la salsa y el atún**
            Cocina la salsa y añade el atún.
          </box></row>
          <row><box>**4. Mezcla la pasta**
            Remueve con agua de cocción.
          </box></row>
        </box>
        ### Mi truco para que quede especialmente rica
        Un poco de limón al final.
        """
    }

    private func makeDocument(_ messages: [(role: String, channel: String, text: String, hidden: Bool)]) throws -> String {
        var table: [Any] = []
        func store(_ value: Any) -> Int { table.append(value); return table.count - 1 }
        func object(_ fields: [(String, Int)]) -> Int {
            var result: [String: Int] = [:]
            for (key, value) in fields { result["_\(store(key))"] = value }
            return store(result)
        }
        var nodes: [Int] = []
        for item in messages {
            let author = object([("role", store(item.role))])
            let content = object([("content_type", store("text")), ("parts", store([store(item.text)]))])
            let metadata = object([("is_visually_hidden_from_conversation", store(item.hidden))])
            let message = object([("author", author), ("content", content), ("channel", store(item.channel)),
                                  ("recipient", store("all")), ("metadata", metadata)])
            nodes.append(object([("message", message)]))
        }
        _ = object([("linear_conversation", store(nodes))])
        let payload = String(decoding: try JSONSerialization.data(withJSONObject: table), as: UTF8.self)
        let literal = String(decoding: try JSONSerialization.data(withJSONObject: payload, options: .fragmentsAllowed), as: UTF8.self)
        return "<script>window.__reactRouterContext.streamController.enqueue(\(literal))</script>"
    }
}
