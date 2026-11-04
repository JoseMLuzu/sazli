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
