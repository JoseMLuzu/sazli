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

    func testSharedRecipeWithInlineTitleAndServingHeading() throws {
        // Reduced from the public share that reported "No complete recipe" on November 3.
        let message = """
        ¡Perfecto! Puedes hacer unos **pappardelle con pollo en salsa cremosa de queso holandés**, sin necesidad de crema de leche.
        <AsyncImage query="pasta photo" aspectRatio="16:9"/>
        ## Ingredientes (2 personas)
        - 250 g de pappardelle o tagliatelle.
        - 250 g de pollo.
        - 3–4 lonchas de queso holandés.
        - 100–150 ml de leche (si tienes).
        - 1 cucharada de mantequilla.
        - 2 dientes de ajo.
        - Sal, pimienta y paprika.
        - Agua de cocción de la pasta.
        ## Preparación
        1. **Prepara el pollo.** Córtalo y dóralo hasta que esté completamente cocido.
        2. **Prepara la base.** Añade la mantequilla y el ajo.
        3. **Haz la salsa.** Agrega leche y queso suavemente.
        4. **Cocina la pasta.** Reserva agua antes de escurrir.
        5. **Mezcla todo.** Añade la pasta y el pollo a la salsa.
        **Mi truco:** añade una cucharadita de harina para espesar.
        ### ¿Y si tampoco tienes leche?
        Utiliza agua de cocción de la pasta.
        """
        let html = try makeDocument([("assistant", "final", message, false)])
        let messages = try ChatGPTShareDocument.assistantMessages(in: html)
        let candidate = try XCTUnwrap(ChatGPTRecipeExtractor.recipes(in: messages, sourceURL: shareURL).first)
        XCTAssertEqual(candidate.draft.title, "pappardelle con pollo en salsa cremosa de queso holandés")
        XCTAssertEqual(candidate.draft.servings, "2")
        XCTAssertEqual(RecipeText.lines(in: candidate.draft.ingredients).count, 8)
        XCTAssertEqual(RecipeText.lines(in: candidate.draft.instructions).count, 5)
        XCTAssertFalse(candidate.draft.instructions.contains("Mi truco"))
        XCTAssertFalse(candidate.draft.instructions.contains("tampoco tienes leche"))
        XCTAssertTrue(candidate.draft.description.contains("cucharadita de harina"))
        XCTAssertTrue(candidate.draft.preparationTime.isEmpty)
        XCTAssertEqual(candidate.draft.sourceURL, shareURL.absoluteString)
    }

    func testStyledAndMissingTitlesDoNotRejectCompleteRecipes() throws {
        let styled = """
        <text weight="medium">Pappardelle cremoso con pollo al ajo</text>
        <text>25–30 min</text>
        <text>2–3 porciones</text>
        ## Ingredientes
        - Pasta
        - Pollo
        ## Preparación
        **1. Dora el pollo**
        Cocina hasta que esté completamente cocido.
        **2. Cocina la pasta**
        Hierve y mezcla.
        **Un truco:** reserva agua de cocción.
        """
        let recipe = try XCTUnwrap(ChatGPTRecipeExtractor.recipes(in: [styled], sourceURL: shareURL).first)
        XCTAssertEqual(recipe.draft.title, "Pappardelle cremoso con pollo al ajo")
        XCTAssertEqual(RecipeText.lines(in: recipe.draft.instructions).count, 2)
        XCTAssertFalse(recipe.draft.instructions.contains("Un truco"))
        // Ranges remain unguessed; only single explicit values populate numeric fields.
        XCTAssertTrue(recipe.draft.preparationTime.isEmpty)
        XCTAssertEqual(recipe.draft.servings, "1")
        let untitled = "Ingredients:\n- Eggs\nInstructions:\n1. Cook eggs."
        let fallback = try XCTUnwrap(ChatGPTRecipeExtractor.recipes(in: [untitled], sourceURL: shareURL).first)
        XCTAssertEqual(fallback.draft.title, "Recipe from ChatGPT")
        XCTAssertTrue(ChatGPTRecipeExtractor.recipes(in: ["Ingredients (2 people):\n- Eggs"], sourceURL: shareURL).isEmpty)
    }

    func testMultipleRecipesInOneMessageKeepTheirOwnTitlesAndSteps() {
        let message = """
        # Soup
        Ingredients:
        - Water
        Instructions:
        1. Simmer.
        # Toast
        Ingredients (2 servings):
        - Bread
        Instructions:
        1. Toast bread.
        """
        let recipes = ChatGPTRecipeExtractor.recipes(in: [message], sourceURL: shareURL)
        XCTAssertEqual(recipes.map { $0.draft.title }, ["Soup", "Toast"])
        XCTAssertEqual(recipes.map { $0.draft.instructions }, ["Simmer.", "Toast bread."])
        XCTAssertEqual(recipes.last?.draft.servings, "2")
    }

    func testCoverPhotosStayWithTheirVisibleRecipeMessage() throws {
        let cover = "https://images.openai.com/static-rsc-4/cover?purpose=fullsize"
        let stepPhoto = "https://images.openai.com/static-rsc-4/step"
        let otherCover = "https://images.openai.com/static-rsc-4/other"
        let first = "<AsyncImage query=\"soup\"/>\n# Soup\nIngredients:\n- Water\nInstructions:\n1. Simmer."
        let second = "<AsyncImage query=\"toast\"/>\n# Toast\nIngredients:\n- Bread\nInstructions:\n1. Toast."
        let html = try makeDocument([
            ("user", "final", first, false),
            ("assistant", "final", first, true),
            ("assistant", "final", first, false),
            ("assistant", "final", second, false)
        ], photos: [0: [(0, [otherCover])], 1: [(0, [otherCover])],
                    2: [(0, ["https://example.com/recipe", cover]), (first.unicodeScalars.count - 2, [stepPhoto])],
                    3: [(0, [otherCover])]])
        let messages = try ChatGPTShareDocument.messages(in: html)
        XCTAssertEqual(messages.count, 2)
        let recipes = ChatGPTRecipeExtractor.recipes(inSharedMessages: messages, sourceURL: shareURL)
        XCTAssertEqual(recipes.map { $0.draft.title }, ["Toast", "Soup"])
        XCTAssertEqual(recipes[0].photoURLs.map(\.absoluteString), [otherCover])
        XCTAssertEqual(recipes[1].photoURLs.map(\.absoluteString), [cover])
        XCTAssertNil(recipes[0].draft.imageData) // Download happens only when reviewing the chosen recipe.
        let noCover = SharedChatGPTMessage(text: first, images: [SharedChatGPTImage(offset: first.unicodeScalars.count - 2, urls: [URL(string: stepPhoto)!])])
        XCTAssertTrue(ChatGPTRecipeExtractor.recipes(inSharedMessages: [noCover], sourceURL: shareURL)[0].photoURLs.isEmpty)
    }

    func testPhotoDownloadsRejectUnrelatedURLsAndInvalidResponses() async throws {
        let image = try XCTUnwrap(URL(string: "https://images.openai.com/static-rsc-4/dish"))
        XCTAssertNotNil(ChatGPTRecipePhoto.publicURL(from: image.absoluteString))
        for value in ["http://images.openai.com/static-rsc-4/dish", "https://images.openai.com.evil.test/static-rsc-4/dish",
                      "https://images.openai.com:444/static-rsc-4/dish", "https://user:password@images.openai.com/static-rsc-4/dish",
                      "https://chatgpt.com/backend-api/files/secret", "https://ogimg.chatgpt.com/title.png",
                      "https://127.0.0.1/dish.jpg"] {
            XCTAssertNil(ChatGPTRecipePhoto.publicURL(from: value))
        }
        func response(_ status: Int, _ type: String, _ length: Int) -> HTTPURLResponse {
            HTTPURLResponse(url: image, statusCode: status, httpVersion: nil,
                            headerFields: ["Content-Type": type, "Content-Length": String(length)])!
        }
        XCTAssertNoThrow(try ChatGPTRecipePhoto.validate(response(200, "image/jpeg", 1000)))
        XCTAssertThrowsError(try ChatGPTRecipePhoto.validate(response(403, "image/jpeg", 1000)))
        XCTAssertThrowsError(try ChatGPTRecipePhoto.validate(response(200, "text/html", 1000)))
        XCTAssertThrowsError(try ChatGPTRecipePhoto.validate(response(200, "image/jpeg", ChatGPTRecipePhoto.maximumBytes + 1)))
        let absent = await ChatGPTRecipePhoto.load(from: [])
        XCTAssertNil(absent)
        let unsupported = await ChatGPTRecipePhoto.load(from: [URL(string: "https://example.com/dish.jpg")!])
        XCTAssertNil(unsupported)
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

    private func makeDocument(_ messages: [(role: String, channel: String, text: String, hidden: Bool)],
                              photos: [Int: [(offset: Int, urls: [String])]] = [:]) throws -> String {
        var table: [Any] = []
        func store(_ value: Any) -> Int { table.append(value); return table.count - 1 }
        func object(_ fields: [(String, Int)]) -> Int {
            var result: [String: Int] = [:]
            for (key, value) in fields { result["_\(store(key))"] = value }
            return store(result)
        }
        var nodes: [Int] = []
        for (index, item) in messages.enumerated() {
            let author = object([("role", store(item.role))])
            let content = object([("content_type", store("text")), ("parts", store([store(item.text)]))])
            let components = (photos[index] ?? []).map { photo in
                let links = photo.urls.map { object([("url", store($0))]) }
                return object([("type", store("async_image")), ("start_index", store(photo.offset)),
                               ("safe_urls", store(links))])
            }
            let metadata = object([("is_visually_hidden_from_conversation", store(item.hidden)),
                                   ("genui_components", store(components))])
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
