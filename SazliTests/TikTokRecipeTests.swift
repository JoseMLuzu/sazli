import XCTest
import SwiftData
@testable import Sazli

final class TikTokRecipeTests: XCTestCase {
    private let link = URL(string: "https://vt.tiktok.com/ZSpRSQuyw/")!

    func testOnlySupportedPublicTikTokVideosAreRead() {
        XCTAssertNotNil(SourceLink.tikTokVideoURL(from: link.absoluteString))
        XCTAssertNotNil(SourceLink.tikTokVideoURL(from: "https://vm.tiktok.com/abc/"))
        XCTAssertNotNil(SourceLink.tikTokVideoURL(from: "https://www.tiktok.com/@chef/video/123?lang=en"))
        for value in ["http://vt.tiktok.com/abc/", "https://www.tiktok.com/login", "https://www.tiktok.com/@chef",
                      "https://vt.tiktok.com.evil.test/abc/", "https://vt.tiktok.com:444/abc/",
                      "https://user:password@vt.tiktok.com/abc/", "https://www.tiktok.com/@chef/video/invalid"] {
            XCTAssertNil(SourceLink.tikTokVideoURL(from: value))
        }
    }

    func testPublicCaptionImportsExplicitIngredientsStepsAndPortions() throws {
        let caption = """
        Decent! I'd give it a 7.8/10. SERVES: 4 WHAT YOU’LL NEED: • 400g potato gnocchi • 640g chicken breast, diced • 190g reduced-fat green pesto • 1 red onion, chopped • 1 green pepper, chopped • 100g peas • 100g sundried tomatoes, chopped • 100g baby spinach • 150ml chicken stock • 150g fat-free Greek yoghurt • 15g garlic, minced • 75g light mozzarella METHOD: 1. Add everything to a large baking dish and mix well. 2. Bake at 200°C for around 40 minutes, until the chicken is cooked through and the cheese is golden. 3. Divide into 4 servings and enjoy. PER SERVING: 531 calories | 49g protein | 41g carbs | 18g fat Original recipe by @gymtrav
        """
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: link)
        XCTAssertEqual(result.draft.title, "Recipe from TikTok")
        XCTAssertEqual(result.draft.servings, "4")
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients).count, 12)
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions).count, 3)
        XCTAssertTrue(result.draft.instructions.contains("200°C"))
        XCTAssertFalse(result.draft.instructions.contains("531 calories"))
        XCTAssertTrue(result.draft.description.contains("7.8/10"))
        XCTAssertTrue(result.draft.description.contains("@gymtrav"))
        XCTAssertTrue(result.draft.description.contains("Creator: Louis Howard"))
        XCTAssertTrue(result.draft.preparationTime.isEmpty) // Cooking time isn't assumed to be total prep time.
        XCTAssertEqual(result.draft.sourceURL, link.absoluteString)
        XCTAssertEqual(result.draft.sourcePlatform, .tiktok)
        XCTAssertNil(result.draft.validationMessage)
        XCTAssertEqual(result.photoURLs.count, 1)
        XCTAssertNil(result.draft.imageData)
    }

    func testIncompleteDescriptionAndRangesStayUninvented() throws {
        let result = try TikTokRecipeDocument.recipe(in: document("Try this meal! SERVES: 2–3 #dinner"), sourceURL: link)
        XCTAssertTrue(result.draft.ingredients.isEmpty)
        XCTAssertTrue(result.draft.instructions.isEmpty)
        XCTAssertTrue(result.draft.preparationTime.isEmpty)
        XCTAssertEqual(result.draft.servings, "1")
        XCTAssertTrue(result.draft.description.contains("2–3"))
        let spanish = try TikTokRecipeDocument.recipe(in: document("PORCIONES: 2 INGREDIENTES: • Huevos • Sal PREPARACIÓN: 1. Cocinar. 2. Servir. NOTAS: Sin aceite."), sourceURL: link)
        XCTAssertEqual(spanish.draft.servings, "2")
        XCTAssertEqual(RecipeText.lines(in: spanish.draft.instructions).count, 2)
        XCTAssertFalse(spanish.draft.instructions.contains("Sin aceite"))
    }

    func testUnreadablePagesAndUnrelatedCoverHostsAreRejected() throws {
        for html in ["<html>Log in</html>", "<script id='__UNIVERSAL_DATA_FOR_REHYDRATION__'>{broken}</script>",
                     String(repeating: "x", count: TikTokRecipeDocument.maximumHTMLBytes + 1)] {
            XCTAssertThrowsError(try TikTokRecipeDocument.recipe(in: html, sourceURL: link))
        }
        XCTAssertNotNil(RecipeRemotePhoto.publicURL(from: "https://p19-common-sign.tiktokcdn.com/dish.image", source: .tikTok))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://p19-common-sign.tiktokcdn.com.evil.test/dish", source: .tikTok))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://images.openai.com/static-rsc-4/dish", source: .tikTok))
        XCTAssertNil(RecipeRemotePhoto.publicURL(from: "https://p19-common-sign.tiktokcdn.com/dish", source: .chatGPT))
    }

    func testTacoMacCaptionWithoutColonsSeparatesNineIngredientsAndSevenSteps() throws {
        let caption = tacoMacCaption
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: link)
        let ingredients = RecipeText.lines(in: result.draft.ingredients)
        let steps = RecipeText.lines(in: result.draft.instructions)
        XCTAssertEqual(ingredients.count, 9)
        XCTAssertEqual(ingredients.first, "1 lb ground beef")
        XCTAssertTrue(ingredients.contains("½ cup salsa"))
        XCTAssertTrue(ingredients.contains("1½ cups Mexican blend cheese, divided"))
        XCTAssertEqual(ingredients.last, "Optional: parsley for topping")
        XCTAssertEqual(steps.count, 7)
        XCTAssertTrue(result.draft.instructions.contains("1¼ cups of mexican cheese"))
        XCTAssertEqual(steps.last, "Top with parsley if desired and serve warm!")
        XCTAssertFalse(result.draft.ingredients.contains("In a large skillet"))
        XCTAssertFalse(result.draft.instructions.contains("#easydinnerideas"))
        XCTAssertTrue(result.draft.description.contains("#easydinnerideas"))
        XCTAssertTrue(result.draft.description.contains("one pan taco mac"))
        XCTAssertTrue(result.draft.preparationTime.isEmpty)
    }

    func testNoColonHeadingsSupportBilingualListsWithoutChangingDecimalQuantities() throws {
        let caption = "Ingredientes * ½ taza de leche * Sal Preparación 1. Mezclar con 0.5 litros de agua. 2. Cocinar. #receta"
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: link)
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), ["½ taza de leche", "Sal"])
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions), ["Mezclar con 0.5 litros de agua.", "Cocinar."])
        XCTAssertTrue(result.draft.description.contains("#receta"))
    }

    func testOrdinaryMentionsOfIngredientsAndInstructionsStayInDescription() throws {
        let result = try TikTokRecipeDocument.recipe(in: document("These ingredients are delicious. Follow the instructions in the video! #dinner"), sourceURL: link)
        XCTAssertTrue(result.draft.ingredients.isEmpty)
        XCTAssertTrue(result.draft.instructions.isEmpty)
        XCTAssertTrue(result.draft.description.contains("These ingredients are delicious"))
    }

    @MainActor func testRecoverStoredTikTokDescriptionOnlyAfterExplicitSave() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy-tiktok.store")
        let originalText = tacoMacCaption + "\n\nCreator: alexis"
        let id: UUID
        do {
            let container = try RecipeStore.container(at: url)
            var original = RecipeDraft()
            original.title = "My taco mac"
            original.description = originalText
            original.sourceURL = "https://www.tiktok.com/@thesimplecravings/video/7694085059602550030"
            original.sourcePlatform = .tiktok
            original.preparationTime = "25"
            original.servings = "3"
            original.imageData = Data([1, 2, 3])
            let recipe = try RecipeStore.save(original, editing: nil, in: container.mainContext)
            recipe.notes = "Less salt next time"
            recipe.isFavorite = true
            try RecipeStore.commit(in: container.mainContext)
            id = recipe.id
            var review = RecipeDraft(recipe: recipe)
            XCTAssertTrue(review.recoverTikTokSectionsIfNeeded())
            XCTAssertEqual(RecipeText.lines(in: review.ingredients).count, 9)
            XCTAssertEqual(RecipeText.lines(in: review.instructions).count, 7)
            XCTAssertEqual(review.title, original.title)
            XCTAssertEqual(review.preparationTime, "25")
            XCTAssertEqual(review.servings, "3")
            XCTAssertEqual(review.imageData, original.imageData)
            XCTAssertTrue(review.description.contains("Creator: alexis"))
            XCTAssertFalse(review.instructions.contains("#easydinnerideas"))
            // Opening/canceling the review cannot mutate the persisted recipe.
            XCTAssertEqual(recipe.recipeDescription, originalText)
            XCTAssertTrue(recipe.ingredients.isEmpty)
            XCTAssertTrue(recipe.instructions.isEmpty)
            try RecipeStore.save(review, editing: recipe, in: container.mainContext)
        }
        let reopened = try RecipeStore.container(at: url)
        let recipes = try reopened.mainContext.fetch(FetchDescriptor<Recipe>())
        XCTAssertEqual(recipes.count, 1)
        let saved = try XCTUnwrap(recipes.first)
        XCTAssertEqual(saved.id, id)
        XCTAssertEqual(saved.ingredientLines.count, 9)
        XCTAssertEqual(saved.instructionLines.count, 7)
        XCTAssertEqual(saved.notes, "Less salt next time")
        XCTAssertTrue(saved.isFavorite)
    }

    func testSectionRecoveryPreservesManualPartialAndAlreadyStructuredDrafts() throws {
        var source = RecipeDraft()
        source.sourceURL = link.absoluteString
        source.sourcePlatform = .tiktok
        source.description = tacoMacCaption
        var manual = source
        manual.sourcePlatform = .manual
        XCTAssertFalse(manual.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(manual.description, tacoMacCaption)
        var partial = source
        partial.description = "Ingredients: • Eggs"
        let untouched = partial
        XCTAssertFalse(partial.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(partial, untouched)
        var edited = source
        edited.ingredients = "My edited ingredients"
        let edits = edited
        XCTAssertFalse(edited.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(edited, edits)
        XCTAssertTrue(source.recoverTikTokSectionsIfNeeded())
        let recovered = source
        XCTAssertFalse(source.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(source, recovered)
    }

    func testSourceDetailsFillEmptyFieldsAndPreserveExistingEdits() throws {
        let imported = try TikTokCaptionParser.parse(tacoMacCaption)
        var edited = RecipeDraft()
        edited.title = "Family taco mac"
        edited.description = "My own version"
        edited.ingredients = "Keep my quantities"
        edited.preparationTime = "35"
        edited.servings = "2"
        edited.category = .dinner
        edited.imageData = Data([1, 2, 3])
        edited.sourceURL = link.absoluteString
        edited.sourcePlatform = .tiktok
        edited.fillEmptyDetails(from: imported, useDefaultServings: true)
        XCTAssertEqual(edited.title, "Family taco mac")
        XCTAssertEqual(edited.description, "My own version")
        XCTAssertEqual(edited.ingredients, "Keep my quantities")
        XCTAssertEqual(RecipeText.lines(in: edited.instructions).count, 7)
        XCTAssertEqual(edited.preparationTime, "35")
        XCTAssertEqual(edited.servings, "2")
        XCTAssertEqual(edited.category, .dinner)
        XCTAssertEqual(edited.imageData, Data([1, 2, 3]))
        XCTAssertEqual(edited.sourceURL, link.absoluteString)
        XCTAssertEqual(edited.sourcePlatform, .tiktok)
    }

    func testSourceDetailsPopulateNewDraftAndKeepExistingDefaultPortions() throws {
        let imported = try TikTokCaptionParser.parse("SERVES: 4 Ingredients: • Eggs Instructions: 1. Cook.")
        var fresh = RecipeDraft()
        fresh.sourceURL = link.absoluteString
        fresh.fillEmptyDetails(from: imported, useDefaultServings: true)
        XCTAssertEqual(fresh.title, "Recipe from TikTok")
        XCTAssertEqual(fresh.ingredients, "Eggs")
        XCTAssertEqual(fresh.instructions, "Cook.")
        XCTAssertEqual(fresh.servings, "4")
        XCTAssertEqual(fresh.sourceURL, link.absoluteString)
        var existing = RecipeDraft()
        existing.fillEmptyDetails(from: imported)
        XCTAssertEqual(existing.servings, "1")
        XCTAssertEqual(existing.ingredients, "Eggs")
    }

    func testGroupedChipotleCaptionImportsThroughSourceDraftAndRecovery() throws {
        let source = URL(string: "https://vt.tiktok.com/ZSpFB66ns/")!
        let caption = """
        creamy chipotle chicken pasta ✨ Ingredients   Chicken - 1.5lb chicken boneless skinless chicken breast  - 1/2 tbsp olive oil - 1 tsp chipotle powder  - 1 tsp garlic powder  - 1 tsp onion powder  - 1  tsp chili powder  - 1 tsp oregano  - 1 tsp coriander  - 1 tsp salt - 1/2 tsp black pepper  - 1 tbsp butter (for cooking) - 1 tbsp olive oil (for cooking) Pasta - 16 oz fettuccine  - 3 tbsp unsalted butter - 1/2 yellow onion, diced - 7 garlic cloves, minced - 2 cups heavy cream  - 1/4 cup chicken stock - 3 tbsp chipotle sauce  - 2 tbsp tomato paste  - Juice of 1/2 lemon - 1 cup Parmesan cheese, freshly grated - 1/3 cup Mexican 3 cheese, (chihuahua, oxaca, cotija) - 1 tsp garlic powder - 1 tsp chipotle powder  - 1 tsp onion powder  - 1 tsp chili powder  - 1 tsp smoked paprika  - 1 tsp oregano  - 1/2 tsp cumin - 1/2 tsp coriander (optional) - Salt and pepper to taste Garnish  - Parmesan cheese - Parsley  - Crushed pepper flakes (optional) Instructions Chicken - In a large bowl, combine chicken breasts, olive oil, chili powder, chipotle powder, onion powder, garlic powder, coriander, oregano, salt, and pepper. Toss until evenly coated and marinate for at least 30 minutes. - Heat oil and butter in a large skillet over medium-high heat. Sear chicken for 4–5 minutes per side until lightly charred. - Transfer to a 320°F (160°C) oven and bake until the internal temperature reaches 165°F (74°C) while preparing the sauce. Sauce & Pasta - In the same skillet, sauté diced onion until softened. Add minced garlic and cook until fragrant. - Add butter, followed by the spices, and stir until combined. - Mix in tomato paste and cook until slightly darkened. Add chipotle sauce and cook for 2–3 minutes. - Pour in chicken stock, scraping up the browned bits from the bottom of the skillet. Stir until smooth. - Reduce heat to medium-low and stir in heavy cream. Stir in freshly squeezed lemon juice until smooth and combined. -Add Parmesan and Mexican three-cheese blend, stirring until melted and smooth. Simmer for 2–3 minutes, then season with salt and pepper to taste. - Add the cooked fettuccine and parsley, tossing until evenly coated in the sauce. - Slice the chicken and serve over the pasta. Enjoy! • • • #recipes #chickenrecipe #DinnerIdeas #pasta
        """
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: source)
        let ingredients = RecipeText.lines(in: result.draft.ingredients)
        let steps = RecipeText.lines(in: result.draft.instructions)
        XCTAssertTrue(ingredients.contains("Chicken:"))
        XCTAssertTrue(ingredients.contains("Pasta:"))
        XCTAssertTrue(ingredients.contains("Garnish:"))
        XCTAssertTrue(ingredients.contains("1.5lb chicken boneless skinless chicken breast"))
        XCTAssertTrue(ingredients.contains("1/2 tsp coriander (optional)"))
        XCTAssertFalse(result.draft.ingredients.contains("Instructions"))
        XCTAssertEqual(steps.count, 11)
        XCTAssertTrue(steps[0].hasPrefix("Chicken: In a large bowl"))
        XCTAssertTrue(steps[3].hasPrefix("Sauce & Pasta: In the same skillet"))
        XCTAssertTrue(steps[8].hasPrefix("Add Parmesan and Mexican"))
        XCTAssertTrue(steps.last?.hasSuffix("Enjoy!") == true)
        XCTAssertFalse(result.draft.instructions.contains("#recipes"))
        XCTAssertTrue(result.draft.description.contains("#recipes"))
        XCTAssertEqual(result.draft.sourceURL, source.absoluteString)
        var draft = RecipeDraft()
        draft.sourceURL = source.absoluteString
        draft.title = "My chipotle pasta"
        draft.fillEmptyDetails(from: result.draft)
        XCTAssertEqual(draft.title, "My chipotle pasta")
        XCTAssertEqual(draft.ingredients, result.draft.ingredients)
        XCTAssertEqual(draft.instructions, result.draft.instructions)
        var savedCaption = RecipeDraft()
        savedCaption.sourceURL = source.absoluteString
        savedCaption.sourcePlatform = .tiktok
        savedCaption.description = caption + "\n\nCreator: thesapor"
        XCTAssertTrue(savedCaption.recoverTikTokSectionsIfNeeded())
        XCTAssertEqual(savedCaption.ingredients, result.draft.ingredients)
        XCTAssertEqual(savedCaption.instructions, result.draft.instructions)
        XCTAssertTrue(savedCaption.description.contains("Creator: thesapor"))
    }

    func testUnpairedGroupHeadingStaysUnclassified() throws {
        let result = try TikTokCaptionParser.parse("Ingredients Chicken - a family favorite with no written method.")
        XCTAssertTrue(result.ingredients.isEmpty)
        XCTAssertTrue(result.instructions.isEmpty)
    }

    func testFlattenedCajunCaptionKeepsFourteenIngredientsAndEightSteps() throws {
        let caption = """
        Creamy Cajun chicken pasta - cosy season | ep 9 Ingredients 2 chicken breasts  140g pasta  1 onion 2 garlic cloves 2 tbsp Cajun seasoning  2 tbsp garlic granules  1 tsp paprika  150ml chicken stock  200g reduced-fat crème fraiche  100ml milk  50g Parmesan, grated  Fresh parsley  Olive oil  Salt and pepper Method 1. Season the chicken breasts with half of the Cajun seasoning, half of the garlic granules and half of the paprika. Heat a drizzle of olive oil in a pan over a medium-high heat and fry the chicken until slightly golden on the outside. Transfer to the air fryer and cook at 180°C for a further 15 minutes, or until cooked through. 2. Bring a pan of salted water to the boil and cook the pasta according to the packet instructions. Reserve a little pasta water before draining. 3. Heat a drizzle of olive oil in a large pan over a medium heat. Add the onion and cook until softened, then add the garlic and cook for another minute. 4. Add the remaining Cajun seasoning, garlic granules and paprika. Stir well and cook for 1–2 minutes. 5. Pour in the chicken stock and bring to a gentle simmer. Cook for around 5 minutes, allowing the sauce to reduce and thicken slightly. 6. Reduce the heat and stir in the crème fraîche and milk until combined. Gradually increase the heat until the sauce reaches a gentle simmer. Cook until thickened, stirring regularly, then add the grated Parmesan and chopped parsley. 7. Add the drained pasta to the sauce and toss until coated. Add a splash of reserved pasta water if needed, then season with salt and pepper to taste. 8. Slice the cooked chicken and serve on top of the pasta. Finish with extra Parmesan and fresh parsley.
        """
        let source = URL(string: "https://vt.tiktok.com/ZSpFyLctE/")!
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertEqual(RecipeText.lines(in: result.draft.ingredients), [
            "2 chicken breasts", "140g pasta", "1 onion", "2 garlic cloves", "2 tbsp Cajun seasoning",
            "2 tbsp garlic granules", "1 tsp paprika", "150ml chicken stock", "200g reduced-fat crème fraiche",
            "100ml milk", "50g Parmesan, grated", "Fresh parsley", "Olive oil", "Salt and pepper"
        ])
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions).count, 8)
        XCTAssertTrue(result.draft.instructions.contains("180°C"))
        XCTAssertTrue(result.draft.instructions.contains("1–2 minutes"))
        XCTAssertFalse(result.draft.description.contains("140g pasta"))
        XCTAssertEqual(result.draft.sourceURL, source.absoluteString)
        var draft = RecipeDraft()
        draft.sourceURL = source.absoluteString
        draft.title = "My Cajun pasta"
        draft.fillEmptyDetails(from: result.draft)
        XCTAssertEqual(draft.title, "My Cajun pasta")
        XCTAssertEqual(draft.ingredients, result.draft.ingredients)
        XCTAssertEqual(draft.instructions, result.draft.instructions)
        let narrative = try TikTokCaptionParser.parse("Ingredients 2 good reasons to watch. Method is in the video.")
        XCTAssertTrue(narrative.ingredients.isEmpty)
        XCTAssertTrue(narrative.instructions.isEmpty)
    }

    @MainActor func testCrunchwrapGroupsWithoutIngredientHeadingKeepMeasuresAndWrittenMethod() throws {
        let caption = """
        Cheesy Crunchwraps with Beef BEEF FILLING 1½ tbsp (25 ml) olive oil 1 lb (500 g) ground beef 1⅔ tsp (5 g) paprika 1 tsp (3 g) garlic powder 1 tsp (3 g) cayenne pepper ⅓ tsp (1 g) black pepper ½ beef bouillon cube (5 g) ⅓ cup (50 g) diced green bell pepper 1 small yellow onion (100 g), finely diced 3 tbsp (50 g) tomato sauce WRAPS 8 large flour tortillas (10-inch) Sauce of your choice (salsa, sour cream or chipotle mayo) Cheese slices (cheddar or Monterey Jack) CHEESE CRUST 1½ cups (150 g) shredded Mexican-blend cheese Instructions Set out all of your ingredients. Heat the olive oil in a skillet over medium-high heat. Add the ground beef, paprika, garlic powder, cayenne and black pepper. Crumble the beef bouillon cube over the pan. Cook for 3-4 minutes. Stir in the green bell pepper and onion and cook for 4-5 minutes. Add the tomato sauce and cook until everything comes together. Let the filling cool. Lay a tortilla on a clean work surface and place a slice of cheese in the center. Add sauce to taste, then spread about ⅓ cup (80 g) of the beef filling on top. Leave enough space around the edges. Fold in the sides of the tortilla, then fold the top and bottom over to make a tight package. Place it seam side down. Repeat with the remaining tortillas. Heat a skillet over medium-low to medium-high heat and lightly grease it with oil. Cook the burritos for 2-3 minutes per side, until golden brown and crispy. Lower the heat to medium-low. Sprinkle a small handful of shredded cheese in the center of the pan and let it melt slowly. Place a filled wrap on the melted cheese and cook until the cheese is golden and crispy. Remove from the pan and repeat with the other wraps. #cheese #beef #food #tiktokfood #easyrecipe
        """
        let source = URL(string: "https://www.tiktok.com/@kookmutsjes/video/7701715089908370721?_r=1&_t=ZS-9B8lyH984He")!
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertEqual(RecipeText.ingredientLines(in: result.draft.ingredients), [
            "1½ tbsp (25 ml) olive oil", "1 lb (500 g) ground beef", "1⅔ tsp (5 g) paprika",
            "1 tsp (3 g) garlic powder", "1 tsp (3 g) cayenne pepper", "⅓ tsp (1 g) black pepper",
            "½ beef bouillon cube (5 g)", "⅓ cup (50 g) diced green bell pepper",
            "1 small yellow onion (100 g), finely diced", "3 tbsp (50 g) tomato sauce",
            "8 large flour tortillas (10-inch)", "Sauce of your choice (salsa, sour cream or chipotle mayo)",
            "Cheese slices (cheddar or Monterey Jack)", "1½ cups (150 g) shredded Mexican-blend cheese"
        ])
        let steps = RecipeText.lines(in: result.draft.instructions)
        XCTAssertEqual(steps.count, 20)
        XCTAssertEqual(steps.first, "Set out all of your ingredients.")
        XCTAssertTrue(steps.contains("Cook for 3-4 minutes."))
        XCTAssertTrue(steps.contains("Lower the heat to medium-low."))
        XCTAssertTrue(steps.last?.hasPrefix("Remove from the pan") == true)
        XCTAssertFalse(result.draft.instructions.contains("#cheese"))
        XCTAssertTrue(result.draft.description.contains("#cheese"))
        XCTAssertEqual(result.draft.sourceURL, source.absoluteString)
        let recipe = Recipe(title: "Family crunchwraps")
        var draft = RecipeDraft(recipe: recipe)
        draft.sourceURL = source.absoluteString
        draft.sourcePlatform = .tiktok
        draft.fillEmptyDetails(from: result.draft)
        draft.apply(to: recipe)
        XCTAssertEqual(recipe.title, "Family crunchwraps")
        XCTAssertEqual(recipe.ingredientLines.count, 14)
        XCTAssertEqual(recipe.instructionLines.count, 20)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Crunchwrap-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("Recipes.store")
        do {
            let container = try RecipeStore.container(at: storeURL)
            container.mainContext.autosaveEnabled = false
            try RecipeStore.save(draft, editing: nil, in: container.mainContext)
        }
        let reopened = try RecipeStore.container(at: storeURL)
        let saved = try XCTUnwrap(reopened.mainContext.fetch(FetchDescriptor<Recipe>()).first)
        XCTAssertEqual(saved.title, "Family crunchwraps")
        XCTAssertEqual(saved.ingredientLines.count, 14)
        XCTAssertEqual(saved.instructionLines.count, 20)
        XCTAssertEqual(saved.sourceURL, source.absoluteString)
    }

    func testUppercaseProseWithoutPairedQuantityGroupsIsNotGuessedAsARecipe() throws {
        for text in ["BEEF FILLING 1 lb beef Instructions See the video.",
                     "BEEF FILLING and WRAPS are delicious. Instructions are in the video.",
                     "A TASTY MEAL with 2 options and 3 ideas. Instructions Watch for more."] {
            let draft = try TikTokCaptionParser.parse(text)
            XCTAssertTrue(draft.ingredients.isEmpty)
        }
    }

    func testUnnumberedMethodSentenceBoundariesKeepRangesAndDecimals() {
        XCTAssertEqual(RecipeText.lines(in: RecipeGroupedCaption.methodLines(
            "Cook for 1 - 2 minutes. Rest for 1.5 minutes.")),
            ["1. Cook for 1 - 2 minutes.", "2. Rest for 1.5 minutes."])
        let numbered = "1. Mix and cook. Rest briefly.\n2. Serve."
        XCTAssertEqual(RecipeGroupedCaption.methodLines(numbered), numbered)
    }

    @MainActor func testLemonPastaWithoutSectionHeadingsKeepsTwentyFiveIngredientsAndSevenSteps() throws {
        let caption = """
        creamy lemon chili crisp pasta served with juicyyyy mini chicken meatballs 🍋🌶️ Mini Chicken Meatballs (makes 2-3 servings) * 1 lb ground chicken 454 g * 1 tsp garlic powder 3 g * 1 tsp onion powder 2.5 g * ½ tsp kosher salt 3 g * ½ tsp black pepper 1 g * ⅛ tsp paprika 0.3 g * ¼ cup grated Parmesan 20–25 g * ¼ cup breadcrumbs 25–30 g * 1 large egg about 50 g * 1 tbsp whole milk 15 g * 1 tbsp olive oil, 15 g Lemon Chili Crisp Sauce * 8–10 oz pasta of choice — 225–285 g * 5 tbsp unsalted butter — 71 g * 2 garlic cloves, finely grated — about 6 g * 1 tbsp chili crisp, plus more to finish — about 15 g, or to taste * 1 tsp smoked paprika — 2–2.5 g * ½ tsp garlic powder — 1.5 g * ½ tsp black pepper — 1 g * ½ tsp red pepper flakes — about 1 g, or to taste * 1¼ cups heavy cream — 300 ml / about 300 g * ½–1 cup reserved pasta water — 120–240 ml * Juice of ½ lemon — about 1½ tbsp / 20–25 g * 1 cup finely grated Parmesan — about 90 g * Salt, to taste * Fresh lemon wedges, Parmesan and extra chili crisp, for serving 1. Mix all meatball ingredients until combined. Roll into small tablespoon-sized balls and chill for 20 minutes. 2. Heat oil in a skillet over medium heat and cook meatballs until golden and cooked through to 165°F / 74°C. Set aside. 3. Cook pasta until al dente, reserving 1 cup / 240 ml pasta water before draining. 4. Melt butter over medium-low heat. Add garlic and cook until fragrant, then stir in chili crisp, smoked paprika, garlic powder, black pepper and red pepper flakes. 5. Add heavy cream, lemon juice and ½ cup / 120 ml pasta water. Bring to a gentle simmer. 6. Stir in Parmesan and simmer on low until smooth and glossy, adding more pasta water as needed. 7. Toss in the pasta and meatballs. Finish with extra chili crisp, Parmesan and fresh lemon juice. The full detailed recipe will be up later on my website - link in bio 🪩 #creamypasta #pasta #explore #recipe
        """
        let source = URL(string: "https://www.tiktok.com/@marisakapeal/video/7689155950074170637?_r=1&_t=ZS-9B8mpk9Glc8")!
        let result = try TikTokRecipeDocument.recipe(in: document(caption), sourceURL: source)
        XCTAssertEqual(RecipeText.ingredientLines(in: result.draft.ingredients), [
            "1 lb ground chicken 454 g", "1 tsp garlic powder 3 g", "1 tsp onion powder 2.5 g",
            "½ tsp kosher salt 3 g", "½ tsp black pepper 1 g", "⅛ tsp paprika 0.3 g",
            "¼ cup grated Parmesan 20–25 g", "¼ cup breadcrumbs 25–30 g", "1 large egg about 50 g",
            "1 tbsp whole milk 15 g", "1 tbsp olive oil, 15 g",
            "8–10 oz pasta of choice — 225–285 g", "5 tbsp unsalted butter — 71 g",
            "2 garlic cloves, finely grated — about 6 g", "1 tbsp chili crisp, plus more to finish — about 15 g, or to taste",
            "1 tsp smoked paprika — 2–2.5 g", "½ tsp garlic powder — 1.5 g", "½ tsp black pepper — 1 g",
            "½ tsp red pepper flakes — about 1 g, or to taste", "1¼ cups heavy cream — 300 ml / about 300 g",
            "½–1 cup reserved pasta water — 120–240 ml", "Juice of ½ lemon — about 1½ tbsp / 20–25 g",
            "1 cup finely grated Parmesan — about 90 g", "Salt, to taste",
            "Fresh lemon wedges, Parmesan and extra chili crisp, for serving"
        ])
        XCTAssertEqual(RecipeText.lines(in: result.draft.instructions).count, 7)
        XCTAssertTrue(result.draft.instructions.contains("165°F / 74°C"))
        XCTAssertFalse(result.draft.instructions.contains("link in bio"))
        XCTAssertTrue(result.draft.description.contains("link in bio"))
        XCTAssertTrue(result.draft.description.contains("makes 2-3 servings"))
        XCTAssertEqual(result.draft.servings, "1") // An explicit range is not an exact serving count.
        XCTAssertEqual(result.draft.sourceURL, source.absoluteString)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LemonPasta-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = directory.appendingPathComponent("Recipes.store")
        do {
            let container = try RecipeStore.container(at: store)
            container.mainContext.autosaveEnabled = false
            try RecipeStore.save(result.draft, editing: nil, in: container.mainContext)
        }
        let reopened = try RecipeStore.container(at: store)
        let saved = try XCTUnwrap(reopened.mainContext.fetch(FetchDescriptor<Recipe>()).first)
        XCTAssertEqual(saved.ingredientLines.count, 25)
        XCTAssertEqual(saved.instructionLines.count, 7)
        XCTAssertEqual(saved.sourceURL, source.absoluteString)
    }

    func testMetricConversionsStayInsideExplicitBulletIngredients() throws {
        for marker in ["*", "•", "✅", "-"] {
            let draft = try TikTokCaptionParser.parse("Ingredients: \(marker) 8–10 oz pasta — 225–285 g \(marker) 1 tsp salt — about 5 g Method: 1. Cook.")
            XCTAssertEqual(RecipeText.ingredientLines(in: draft.ingredients), ["8–10 oz pasta — 225–285 g", "1 tsp salt — about 5 g"])
        }
    }

    func testHeaderlessBulletsWithoutRecipeQuantityAndStepEvidenceRemainUnstructured() throws {
        for text in ["My weekend * Friends * Shopping 1. Plan. 2. Enjoy.",
                     "Dinner ideas * Chicken * Pasta See the video for instructions."] {
            let draft = try TikTokCaptionParser.parse(text)
            XCTAssertTrue(draft.ingredients.isEmpty)
        }
    }

    private var tacoMacCaption: String {
        """
        one pan taco mac & cheese 🤗 recipe is below! Taco Mac & Cheese Ingredients * 1 lb ground beef * 1 packet taco seasoning * 4 oz tomato sauce * ½ cup salsa * 16 oz shell pasta * 1 cup beef broth * 1 cup milk * 1½ cups Mexican blend cheese, divided * Optional: parsley for topping Instructions 1. In a large skillet over medium high heat, cook the ground beef with the taco seasoning until browned and fully cooked. 2. Add the tomato sauce and salsa, and stir until combined. 3. Add the uncooked shell pasta, beef broth, and milk. Mix well. 4. Bring to a simmer, reduce the heat to low, cover, and cook for about 10 minutes, stirring occasionally, until the pasta is tender. If the pasta needs more time, continue cooking and add a splash of broth or milk as needed. 5. Once pasta is cooked, stir in 1¼ cups of mexican cheese until melted. 6. Sprinkle the remaining ¼ cup cheese over the top, cover, and let it melt. 7. Top with parsley if desired and serve warm! #easydinnerideas #dinnerideas #mealideas #dinner #onepanmeal
        """
    }

    private func document(_ caption: String) throws -> String {
        let item: [String: Any] = ["desc": caption, "author": ["nickname": "Louis Howard"],
                                  "video": ["cover": "https://p19-common-sign.tiktokcdn.com/dish.image"]]
        let root: [String: Any] = ["__DEFAULT_SCOPE__": ["webapp.video-detail": ["itemInfo": ["itemStruct": item]]]]
        let json = String(decoding: try JSONSerialization.data(withJSONObject: root), as: UTF8.self)
        return "<script id='__UNIVERSAL_DATA_FOR_REHYDRATION__' type='application/json'>\(json)</script>"
    }
}
