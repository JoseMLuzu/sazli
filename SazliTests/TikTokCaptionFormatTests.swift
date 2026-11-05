import XCTest
@testable import Sazli

/// Constructed format controls; these samples are not claimed to be published captions.
final class TikTokCaptionFormatTests: XCTestCase {
    private struct Sample {
        let name: String
        let caption: String
        let ingredients: [String]
        let steps: [String]
        let notes: [String]
    }

    func testCaptionFormatMatrix() throws {
        for sample in samples {
            try XCTContext.runActivity(named: sample.name) { _ in
                let draft = try TikTokCaptionParser.parse(sample.caption)
                XCTAssertEqual(RecipeText.lines(in: draft.ingredients), sample.ingredients, sample.name)
                XCTAssertEqual(RecipeText.lines(in: draft.instructions), sample.steps, sample.name)
                for note in sample.notes {
                    XCTAssertTrue(draft.description.contains(note), sample.name + ": missing note " + note)
                    XCTAssertFalse(draft.instructions.contains(note), sample.name + ": note leaked into steps")
                    XCTAssertFalse(draft.ingredients.contains(note), sample.name + ": note leaked into ingredients")
                }
            }
        }
    }

    func testHeadingAndListCombinationMatrix() throws {
        let ingredients = ["Ingredients", "INGREDIENTS", "ingredients", "Ingredient list", "Ingredientes", "INGREDIENTES", "Lista de ingredientes", "Lo que necesitas"]
        let methods = ["Instructions", "METHOD", "Directions", "Preparation steps", "Pasos", "PREPARACIÓN", "Modo de preparación", "Cómo preparar"]
        let lists: [(String, String)] = [
            ("• Eggs • Salt", "1. Mix. 2. Cook."),
            ("*Eggs *Salt", "-Mix. -Cook."),
            ("– Eggs – Salt", "– Mix. – Cook."),
            ("— Eggs — Salt", "— Mix. — Cook."),
            ("▪ Eggs ▪ Salt", "1️⃣ Mix. 2️⃣ Cook."),
            ("a) Eggs b) Salt", "a) Mix. b) Cook."),
            ("(1) Eggs (2) Salt", "(1) Mix. (2) Cook."),
            ("1.Eggs 2.Salt", "1.Mix. 2.Cook."),
            ("A)Eggs B)Salt", "A)Mix. B)Cook."),
            ("1- Eggs 2- Salt", "1- Mix. 2- Cook.")
        ]
        for ingredientHeading in ingredients {
            for methodHeading in methods {
                for (index, list) in lists.enumerated() {
                    for delimiter in [":", ""] {
                        let name = "\(ingredientHeading)/\(methodHeading)/list-\(index)/delimiter-\(delimiter)"
                        try XCTContext.runActivity(named: name) { _ in
                            let draft = try TikTokCaptionParser.parse("\(ingredientHeading)\(delimiter) \(list.0) \(methodHeading)\(delimiter) \(list.1)")
                            XCTAssertEqual(RecipeText.lines(in: draft.ingredients), ["Eggs", "Salt"], name)
                            XCTAssertEqual(RecipeText.lines(in: draft.instructions), ["Mix.", "Cook."], name)
                        }
                    }
                }
            }
        }
    }

    func testPunctuationWhitespaceAndQuantityMatrix() throws {
        let punctuation = [":", "：", " -", " —", " –", " =", " |", ";", "..."]
        let spaces = [" ", "\t", "\u{00A0}", "\u{202F}"]
        for delimiter in punctuation {
            for space in spaces {
                let name = "delimiter=\(delimiter), space=\(space.unicodeScalars.first!.value)"
                try XCTContext.runActivity(named: name) { _ in
                    let draft = try TikTokCaptionParser.parse("Ingredientes\(delimiter)\(space)•\(space)1 onion, finely chopped\(space)•\(space)1,5 cups milk\(space)Preparación\(delimiter)\(space)1. Mix, then rest 1.5 minutes.\(space)2. Cook at -5°C.")
                    XCTAssertEqual(RecipeText.lines(in: draft.ingredients), ["1 onion, finely chopped", "1,5 cups milk"], name)
                    XCTAssertEqual(RecipeText.lines(in: draft.instructions), ["Mix, then rest 1.5 minutes.", "Cook at -5°C."], name)
                }
            }
        }
    }

    func testCommaSemicolonAndUnicodeControls() throws {
        let controls: [(String, [String], [String])] = [
            ("Ingredients: 2 eggs, 200 g flour, 1 tsp salt Method: Mix, rest, then cook.", ["2 eggs", "200 g flour", "1 tsp salt"], ["Mix, rest, then cook."]),
            ("Ingredients: eggs, salt, pepper Method: Mix, cook.", ["eggs, salt, pepper"], ["Mix, cook."]),
            ("Ingredients: 1 onion, chopped; 1,5 cups milk; cheese (cheddar; mozzarella) Method: Mix; Cook.", ["1 onion, chopped", "1,5 cups milk", "cheese (cheddar; mozzarella)"], ["Mix", "Cook."]),
            ("Ingredientes (2 personas): • Huevos • Sal Preparación: 1. Mezclar. 2. Cocinar.", ["Huevos", "Sal"], ["Mezclar.", "Cocinar."]),
            ("Ingredients (2–3 servings): • Eggs Method: 1. Cook.", ["Eggs"], ["Cook."]),
            ("\u{FEFF}Ingredients:\r• Eggs\r• Salt\rMethod:\r1. Mix.\r2. Cook.", ["Eggs", "Salt"], ["Mix.", "Cook."]),
            ("Ingredients:\u{2028}Eggs\u{2028}Salt\u{2029}Method:\u{2028}Mix.\u{2028}Cook.", ["Eggs", "Salt"], ["Mix.", "Cook."]),
            ("Ingredients: • -5°C frozen stock • 1.5 cups milk Method: 1. Mix. 2. Rest 1,5 minutes.", ["-5°C frozen stock", "1.5 cups milk"], ["Mix.", "Rest 1,5 minutes."]),
            ("Ingredients: • Salt Method: 1. Mix the following ingredients: salt and water. 2. Serve.", ["Salt"], ["Mix the following ingredients: salt and water.", "Serve."]),
            ("Ingredients: • Eggs Method: 1. Cook. Tips: Rest before serving.", ["Eggs"], ["Cook."]),
            ("Ingredients: • Eggs • Salt Method: (1)Mix. (2)Cook.", ["Eggs", "Salt"], ["Mix.", "Cook."]),
            ("Ingredientes: • Huevos Preparacio\u{0301}n: 1. Cocinar. Notas： Servir caliente.", ["Huevos"], ["Cocinar."]),
            ("Ingredients:\u{2009}•\u{2009}Eggs Method:\u{2009}1. Cook.", ["Eggs"], ["Cook."])
        ]
        for (index, sample) in controls.enumerated() {
            try XCTContext.runActivity(named: "punctuation-control-\(index)") { _ in
                let draft = try TikTokCaptionParser.parse(sample.0)
                XCTAssertEqual(RecipeText.lines(in: draft.ingredients), sample.1)
                XCTAssertEqual(RecipeText.lines(in: draft.instructions), sample.2)
            }
        }
        let portions = try TikTokCaptionParser.parse("Ingredientes (2 personas): • Huevos Preparación: 1. Cocinar.")
        XCTAssertEqual(portions.servings, "2")
        let range = try TikTokCaptionParser.parse("Ingredients (2–3 servings): • Eggs Method: 1. Cook.")
        XCTAssertEqual(range.servings, "1")
        XCTAssertTrue(range.description.contains("2–3 servings"))
        XCTAssertThrowsError(try TikTokCaptionParser.parse(String(repeating: "x", count: RecipeImportParser.maximumBytes + 1)))
        for caption in ["These ingredients are great. Instructions are in the video!", "My method is easy, ingredients vary.", "Ingredients Chicken - a favorite without written preparation.", "Primero cocina, después sirve. Mira el video."] {
            let draft = try TikTokCaptionParser.parse(caption)
            XCTAssertTrue(draft.ingredients.isEmpty, caption)
            XCTAssertTrue(draft.instructions.isEmpty, caption)
            XCTAssertTrue(draft.description.contains(caption), caption)
        }
    }

    func testSpacedQuantityAndTimeRangesStayInsideTheirItems() throws {
        for dash in ["-", "–", "—"] {
            let draft = try TikTokCaptionParser.parse("Ingredients: • 1 \(dash) 2 eggs • 2 tbsp salt Method: 1. Rest 4 \(dash) 5 minutes. 2. Cook.")
            XCTAssertEqual(RecipeText.lines(in: draft.ingredients), ["1 \(dash) 2 eggs", "2 tbsp salt"])
            XCTAssertEqual(RecipeText.lines(in: draft.instructions), ["Rest 4 \(dash) 5 minutes.", "Cook."])
        }
    }

    func testExplicitBulletItemsKeepTheirWeightQualifiersAndAlternatives() throws {
        let draft = try TikTokCaptionParser.parse("Ingredients: • 1 onion, 150 g total • Milk (whole; or oat), 200 ml • Salt Method: 1. Mix.")
        XCTAssertEqual(RecipeText.lines(in: draft.ingredients), ["1 onion, 150 g total", "Milk (whole; or oat), 200 ml", "Salt"])
    }

    private var samples: [Sample] { [
        Sample(name: "colon / inline bullets", caption: "Ingredients: • Eggs • Salt Method: 1. Mix. 2. Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "no colon / asterisks", caption: "Ingredients * Eggs * Salt Instructions 1. Mix. 2. Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "line breaks / unbulleted", caption: "Ingredients\nEggs\nSalt\nDirections\nMix.\nCook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "emoji section headings", caption: "🥣 Ingredients: • Eggs • Salt 👩‍🍳 Instructions: 1. Mix. 2. Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "bold Markdown headings", caption: "**Ingredients:** * Eggs * Salt **Instructions:** 1. Mix. 2. Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "inline Markdown heading markers", caption: "## Ingredients: • Eggs • Salt ## Method: 1. Mix. 2. Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "emoji numbered steps", caption: "Ingredients: • Eggs • Salt Instructions: 1️⃣ Mix. 2️⃣ Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "asterisk method bullets", caption: "Ingredients: * Eggs * Salt Method: * Mix. * Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "numbered ingredients", caption: "Ingredients: 1. Eggs 2. Salt Instructions: 1. Mix. 2. Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "checkmark bullets", caption: "Ingredients: ✅ Eggs ✅ Salt Method: 1. Mix. 2. Cook.", ingredients: ["Eggs", "Salt"], steps: ["Mix.", "Cook."], notes: []),
        Sample(name: "Spanish procedimiento", caption: "Ingredientes: • Huevos • Sal Procedimiento: 1. Mezclar. 2. Cocinar.", ingredients: ["Huevos", "Sal"], steps: ["Mezclar.", "Cocinar."], notes: []),
        Sample(name: "Spanish elaboracion heading", caption: "Ingredientes\nHuevos\nSal\nElaboración\n1. Mezclar.\n2. Cocinar.", ingredients: ["Huevos", "Sal"], steps: ["Mezclar.", "Cocinar."], notes: []),
        Sample(name: "Spanish paso a paso", caption: "Ingredientes: • Huevos • Sal Paso a paso: 1. Mezclar. 2. Cocinar.", ingredients: ["Huevos", "Sal"], steps: ["Mezclar.", "Cocinar."], notes: []),
        Sample(name: "nutrition footer", caption: "Ingredients: • Eggs Method: 1. Cook. Macros per serving: 300 kcal, 20g protein.", ingredients: ["Eggs"], steps: ["Cook."], notes: ["300 kcal"]),
        Sample(name: "tip footer", caption: "Ingredients: • Eggs Method: 1. Cook. Tips: Use a warm plate.", ingredients: ["Eggs"], steps: ["Cook."], notes: ["Use a warm plate."]),
        Sample(name: "hashtags followed by emoji", caption: "Ingredients: • Eggs Method: 1. Cook. #dinner #food 😋", ingredients: ["Eggs"], steps: ["Cook."], notes: ["#dinner", "😋"]),
        Sample(name: "partial recipe without method", caption: "Ingredients: • Eggs • Salt #dinner", ingredients: ["Eggs", "Salt"], steps: [], notes: ["#dinner"]),
        Sample(name: "ordinary prose / no recipe", caption: "These ingredients are great. Instructions are in the video! #food", ingredients: [], steps: [], notes: ["These ingredients are great."]),
        Sample(name: "comma is part of an ingredient", caption: "Ingredients: • 1 onion, finely chopped • Salt Method: 1. Cook.", ingredients: ["1 onion, finely chopped", "Salt"], steps: ["Cook."], notes: []),
        Sample(name: "multiline ingredient group labels", caption: "Ingredients:\nFor the sauce:\n- Soy sauce\n- Honey\nFor the chicken:\n- Chicken\nMethod:\n1. Combine.", ingredients: ["For the sauce:", "Soy sauce", "Honey", "For the chicken:", "Chicken"], steps: ["Combine."], notes: []),
        Sample(name: "decimal and fractional quantities", caption: "Ingredients: * 0.5 cup milk * 1½ cups flour Method: 1. Add 1¼ cups water. 2. Rest 1.5 minutes.", ingredients: ["0.5 cup milk", "1½ cups flour"], steps: ["Add 1¼ cups water.", "Rest 1.5 minutes."], notes: []),
        Sample(name: "narrative without headings", caption: "Primero mezcla los huevos con sal. Luego cocina y sirve. La receta está en el video.", ingredients: [], steps: [], notes: ["Primero mezcla los huevos"])
    ] }
}
