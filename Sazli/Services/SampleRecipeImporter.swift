#if DEBUG
  import Foundation
  import SwiftData
  import UIKit

  @MainActor
  enum SampleRecipeImporter {
  static let launchArgument = "-sazli-import-samples"
    static let recipeCount = 4

    @discardableResult
    static func importRecipes(in context: ModelContext) throws -> Int {
      try importRecipes(in: context, imageLoader: loadImage)
    }

    // Load every missing photo before inserting anything, then save the batch once.
    @discardableResult
    static func importRecipes(in context: ModelContext, imageLoader: (String) throws -> Data) throws
      -> Int
    {
      let existingIDs = Set(try context.fetch(FetchDescriptor<Recipe>()).map(\.id))
      let prepared = try samples.filter { !existingIDs.contains($0.id) }.map { sample in
        (sample, try imageLoader(sample.photo))
      }
      guard !prepared.isEmpty else { return 0 }
      let now = Date()
      for (index, entry) in prepared.enumerated() {
        let (sample, imageData) = entry
        let recipe = Recipe(title: sample.title)
        recipe.id = sample.id
        recipe.recipeDescription = sample.description
        recipe.ingredients = sample.ingredients
        recipe.instructions = sample.instructions
        recipe.preparationTime = sample.minutes
        recipe.servings = 2
        recipe.category = sample.category.rawValue
        recipe.imageData = imageData
        recipe.notes =
          "Sample recipe for exploring Sazli. The photo is AI-generated and illustrative."
        recipe.createdAt = now.addingTimeInterval(-Double(index) * 60)
        recipe.updatedAt = recipe.createdAt
        context.insert(recipe)
      }
      try RecipeStore.commit(in: context)
      return prepared.count
    }

    private static func loadImage(_ name: String) throws -> Data {
      guard let image = UIImage(named: name), let data = image.jpegData(compressionQuality: 0.86)
      else {
        throw ImportError.missingPhoto(name)
      }
      return data
    }

    enum ImportError: LocalizedError {
      case missingPhoto(String)
      var errorDescription: String? {
        switch self {
        case .missingPhoto(let name):
          "The sample photo \(name) couldn't be loaded. No recipes were added."
        }
      }
    }

    private struct Sample {
      let id: UUID
      let title: String
      let description: String
      let category: RecipeCategory
      let minutes: Int
      let photo: String
      let ingredients: String
      let instructions: String
    }

    private static let samples: [Sample] = [
      Sample(
        id: UUID(uuidString: "5A211000-0000-4000-8000-000000000001")!,
        title: "Avocado & Egg Toast",
        description:
          "Crisp sourdough, creamy avocado, and soft scrambled eggs with a bright squeeze of lemon.",
        category: .breakfast, minutes: 12, photo: "SampleAvocadoToast",
        ingredients: """
          2 thick slices sourdough bread
          1 ripe avocado
          2 eggs
          100 g cherry tomatoes, halved
          2 tsp olive oil
          1 tsp lemon juice, plus wedges to serve
          A pinch of chili flakes (optional)
          Salt and black pepper, to taste
          """,
        instructions: """
          Toast the sourdough until golden and crisp.
          Mash the avocado with the lemon juice and a pinch of salt.
          Beat the eggs. Warm the olive oil in a small pan over medium-low heat, add the eggs, and stir gently until fully set.
          Spread the avocado over the toast, then add the scrambled eggs and halved tomatoes.
          Finish with black pepper and optional chili flakes. Serve immediately with lemon wedges.
          """),
      Sample(
        id: UUID(uuidString: "5A211000-0000-4000-8000-000000000002")!,
        title: "Lemon & Spinach Pasta",
        description: "A fresh, silky bowl of linguine with spinach, garlic, lemon, and Parmesan.",
        category: .lunch, minutes: 25, photo: "SampleLemonPasta",
        ingredients: """
          180 g linguine
          100 g baby spinach
          1 lemon, zest and juice
          2 garlic cloves, finely sliced
          2 tbsp olive oil
          30 g Parmesan, finely grated
          150 ml reserved pasta cooking water
          Salt and black pepper, to taste
          """,
        instructions: """
          Bring a pot of salted water to a boil. Cook the linguine according to the package, reserving 150 ml cooking water before draining.
          Warm the olive oil in a large pan over medium heat. Add the garlic and cook gently for about 1 minute without browning.
          Add the spinach and stir until just wilted, about 2 minutes.
          Add the drained pasta, lemon zest, and half the reserved water. Toss well, then remove the pan from the heat.
          Stir in the Parmesan and lemon juice to taste. Add more reserved water a little at a time until the sauce lightly coats the pasta.
          Season with black pepper and serve with any remaining Parmesan and lemon zest.
          """),
      Sample(
        id: UUID(uuidString: "5A211000-0000-4000-8000-000000000003")!,
        title: "Roasted Vegetable Couscous",
        description:
          "Golden roasted vegetables and chickpeas over fluffy couscous, finished with a lemon-tahini drizzle.",
        category: .dinner, minutes: 35, photo: "SampleVegetableBowl",
        ingredients: """
          120 g dry couscous
          180 ml boiling water, plus extra for the dressing
          1 small sweet potato, cut into 1.5 cm cubes
          1 zucchini, sliced into half moons
          1 red bell pepper, chopped
          240 g cooked chickpeas, drained and patted dry
          2 tbsp olive oil
          1 tsp smoked paprika
          2 tbsp tahini
          1 tbsp lemon juice
          2 tbsp chopped fresh parsley
          Salt and black pepper, to taste
          """,
        instructions: """
          Heat the oven to 220°C. Place the sweet potato, zucchini, pepper, and chickpeas on a large baking tray.
          Toss with olive oil, smoked paprika, salt, and pepper. Spread into an even layer and roast for 25 minutes, turning halfway, until the sweet potato is tender.
          Place the couscous in a heatproof bowl. Add the boiling water, or the amount recommended on its package, cover, and leave for 5 minutes. Fluff with a fork.
          Stir the tahini and lemon juice together. Add a little water at a time until pourable, then season with salt.
          Divide the couscous between two bowls and add the roasted vegetables and chickpeas.
          Drizzle over the dressing and scatter with parsley. Serve warm.
          """),
      Sample(
        id: UUID(uuidString: "5A211000-0000-4000-8000-000000000004")!,
        title: "Berry Yogurt Parfait",
        description:
          "Creamy Greek yogurt layered with juicy berries, crunchy granola, and a little honey.",
        category: .dessert, minutes: 10, photo: "SampleBerryParfait",
        ingredients: """
          400 g plain Greek yogurt
          80 g oat granola
          150 g strawberries, hulled and sliced
          100 g blueberries
          2 tsp honey
          4 small mint leaves (optional)
          """,
        instructions: """
          Wash and dry the berries, then slice the strawberries.
          Spoon a layer of yogurt into each of two glasses. Add some granola and berries.
          Repeat the layers with the remaining yogurt, granola, and fruit, finishing with berries on top.
          Drizzle each glass with a teaspoon of honey and add optional mint leaves. Serve immediately so the granola stays crisp.
          """),
    ]
  }
#endif
