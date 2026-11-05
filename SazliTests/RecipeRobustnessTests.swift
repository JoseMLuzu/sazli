import XCTest
@testable import Sazli

/// Deterministic synthetic format controls, not a claim of thousands of downloaded videos.
@MainActor
final class RecipeRobustnessTests: XCTestCase {
    private let markers = ["*", "•", "◦", "▪", "✅", "-", "–", "—"]
    private let separators = [" ", "\n", "\t", "\u{00A0}"]
    private let quantities = ["1", "½", "1½", "1 1/2", "0.5", "1,5"]
    private let methods = ["1. Mix gently. 2. Cook until set.", "1) Mix gently. 2) Cook until set.",
        "(1) Mix gently. (2) Cook until set.", "a) Mix gently. b) Cook until set.",
        "A) Mix gently. B) Cook until set.", "1️⃣ Mix gently. 2️⃣ Cook until set.",
        "Step 1: Mix gently. Step 2: Cook until set.", "Paso 1: Mix gently. Paso 2: Cook until set."]

    func testHeaderlessCombinationMatrix() throws {
        for marker in markers {
            for (spaceIndex, separator) in separators.enumerated() {
                for quantity in quantities {
                    for (methodIndex, method) in methods.enumerated() {
                        for compact in [false, true] {
                            let gap = compact ? "" : " "
                            for methodHeading in ["", "Instructions: "] {
                                let caption = ["Family dinner", marker + gap + quantity + " cup milk (120 ml), chilled",
                                    marker + gap + "2 eggs", methodHeading + method].joined(separator: separator)
                                let name = "headerless/\(marker)/space-\(spaceIndex)/\(quantity)/method-\(methodIndex)/compact-\(compact)/heading-\(methodHeading)"
                                try XCTContext.runActivity(named: name) { _ in
                                    let draft = try TikTokCaptionParser.parse(caption)
                                    XCTAssertEqual(RecipeText.ingredientLines(in: draft.ingredients),
                                        [quantity + " cup milk (120 ml), chilled", "2 eggs"], name)
                                    XCTAssertEqual(RecipeText.lines(in: draft.instructions), ["Mix gently.", "Cook until set."], name)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func testGroupedCombinationMatrix() throws {
        let labels = [("BASE", "SAUCE"), ("BASE:", "SAUCE:"), ("Base:", "Sauce:"), ("MASA:", "SALSA:")]
        let proseMethods = ["Instructions Cook for 1.5 minutes. Rest briefly.",
                            "Method: Cook for 1.5 minutes. Rest briefly.",
                            "Preparación\nCook for 1.5 minutes. Rest briefly."]
        for (labelIndex, label) in labels.enumerated() {
            for (spaceIndex, separator) in separators.enumerated() {
                for quantity in quantities {
                    for (methodIndex, method) in proseMethods.enumerated() {
                        let caption = ["Family dinner", label.0, quantity + " cup milk (120 ml) 2 eggs",
                                       label.1, "3 tbsp oil 1 tsp salt", method].joined(separator: separator)
                        let name = "groups/\(labelIndex)/\(spaceIndex)/\(quantity)/\(methodIndex)"
                        try XCTContext.runActivity(named: name) { _ in
                            let draft = try TikTokCaptionParser.parse(caption)
                            XCTAssertEqual(RecipeText.ingredientLines(in: draft.ingredients),
                                [quantity + " cup milk (120 ml)", "2 eggs", "3 tbsp oil", "1 tsp salt"], name)
                            XCTAssertEqual(RecipeText.lines(in: draft.instructions),
                                ["Cook for 1.5 minutes.", "Rest briefly."], name)
                        }
                    }
                }
            }
        }
    }

    func testEquivalentMeasurementMatrix() throws {
        for marker in markers {
            for dash in ["—", "–", "-"] {
                for equivalent in ["120 ml", "about 120 ml", "2–2.5 g", "1,5 g", "(120 ml)", "2.5 oz"] {
                    let first = "1 cup milk " + dash + " " + equivalent
                    let caption = "Ingredients: \(marker) \(first) \(marker) 2 eggs Method: 1. Mix. 2. Cook."
                    let name = "measure/\(marker)/\(dash)/\(equivalent)"
                    try XCTContext.runActivity(named: name) { _ in
                        let draft = try TikTokCaptionParser.parse(caption)
                        XCTAssertEqual(RecipeText.ingredientLines(in: draft.ingredients), [first, "2 eggs"], name)
                    }
                }
            }
        }
    }

    func testCapitalizedFoodsAndQualifiersAreNeverRemovedAsGroups() throws {
        let foods = ["1 cup Monterey Jack", "1 cup Sour Cream Sauce", "1 cup Fresh Lemon Juice",
            "1 egg (50 g)", "1 tbsp oil, 15 g", "1 cup milk (120 ml), chilled", "1 cup 35% cream",
            "1 tsp 7-spice mix", "1 tsp Vitamin B12 seasoning", "1 egg, beaten", "1 cup sauce (hot; optional)", "1 cup lemon zest",
            "1 cup Sour Cream (fresh) Sauce", "1 onion - finely chopped", "1 cup milk - optional"]
        for marker in ["*", "•", "✅", "-"] {
            for food in foods {
                let draft = try TikTokCaptionParser.parse("Ingredients: \(marker) \(food) \(marker) 2 eggs Method: 1. Cook.")
                XCTAssertEqual(RecipeText.ingredientLines(in: draft.ingredients), [food, "2 eggs"])
            }
        }
    }

    func testAmbiguousInputsKeepTheirOriginalRecipeTextForReview() throws {
        for text in ["Weekend ideas * Friends * Shopping 1. Plan. 2. Rest.",
            "A dinner * 1 egg * 2 cups milk. No written preparation is available.",
            "A dinner * 1 egg * 2 cups milk 1. Mix. 3. Serve.",
            "A dinner * 1 egg * 2 cups milk 2. Cook. 3. Serve.",
            "SAUCE with milk and BASE with eggs. Instructions are in the video.",
            "BASE 1 cup milk. Find the method in the video.",
            "Family dinner. Steps will be posted later. #recipe",
            "For the sauce: use what you like. Ingredients vary."] {
            let draft = try TikTokCaptionParser.parse(text)
            XCTAssertTrue(draft.ingredients.isEmpty, text)
            XCTAssertFalse(draft.description.isEmpty, text)
        }
    }

    func testAFirstIngredientLineIsNotDiscardedAsARecipeTitle() throws {
        for marker in ["*", "•", "✅", "-"] {
            let text = "\(marker) 1 cup milk\n\(marker) 2 eggs\n1. Mix gently.\n2. Cook until set."
            guard case .draft(let draft) = try RecipeImportRouter.route(text) else { return XCTFail("Wrong route") }
            XCTAssertEqual(RecipeText.ingredientLines(in: draft.ingredients), ["1 cup milk", "2 eggs"], marker)
            XCTAssertEqual(RecipeText.lines(in: draft.instructions), ["Mix gently.", "Cook until set."], marker)
            XCTAssertEqual(draft.title, "Imported recipe")
        }
    }

    func testPublicAssistantRecipesCanUseStrongImplicitStructure() throws {
        let source = URL(string: "https://chatgpt.com/share/01234567-89ab-cdef-0123-456789abcdef")!
        let messages = ["Eggs * 1 cup milk * 2 eggs 1. Mix gently. 2. Cook until set.",
            "Eggs BASE 1 cup milk 2 eggs SAUCE 3 tbsp oil 1 tsp salt Instructions Cook gently. Serve warm."]
        for (index, message) in messages.enumerated() {
            let candidate = try XCTUnwrap(ChatGPTRecipeExtractor.recipes(in: [message], sourceURL: source).first)
            XCTAssertEqual(RecipeText.ingredientLines(in: candidate.draft.ingredients).count, index == 0 ? 2 : 4)
            XCTAssertEqual(RecipeText.lines(in: candidate.draft.instructions).count, 2)
            XCTAssertEqual(candidate.draft.sourceURL, source.absoluteString)
        }
    }
}
