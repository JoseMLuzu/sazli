# Sample recipes and photos

In a Debug build, open **Settings → Add sample recipes** to add four complete, editable examples to the current local SwiftData library:

- Avocado & Egg Toast — breakfast, 12 minutes, 2 servings.
- Lemon & Spinach Pasta — lunch, 25 minutes, 2 servings.
- Roasted Vegetable Couscous — dinner, 35 minutes, 2 servings.
- Berry Yogurt Parfait — dessert, 10 minutes, 2 servings.

Each includes ingredients, preparation steps, and a bundled illustrative food photo. The photos were generated with the built-in ImageGen tool; the notes in each sample identify the generated image. These are authored examples, not recipes extracted from a source link. No original-source URL or personal rating is fabricated.

Import is explicit and available only in Debug settings or with the development launch argument described below. Normal launches do not add sample records. Stable UUIDs prevent duplicate imports and preserve edits to previously imported samples. All missing photos load before any insertion, then the batch saves once. An import error does not leave a partial set of new recipes. Existing recipes are retained.

Photos are converted to JPEG for the asset catalog and copied into each recipe's persisted `imageData` when imported. Reading the samples and their photos is then entirely local. Each sample can be edited or deleted like any other recipe. Importing again explicitly restores missing sample records, while keeping existing ones and their edits.

For a connected development iPhone, the same explicit import can run with the Debug launch argument `-sazli-import-samples`. It saves to that device's local SwiftData container and reports counts in Xcode's console. Remove the argument after the requested import. Normal launches and Release builds do not run it. This provides device-local test content without enabling synchronization.

## Image assets

The selected images are saved in `Sazli/Resources/Assets.xcassets/`:

- `SampleAvocadoToast.imageset/SampleAvocadoToast.jpg`
- `SampleLemonPasta.imageset/SampleLemonPasta.jpg`
- `SampleVegetableBowl.imageset/SampleVegetableBowl.jpg`
- `SampleBerryParfait.imageset/SampleBerryParfait.jpg`

## ImageGen prompts

### SampleAvocadoToast

```text
Use case: photorealistic-natural. Asset type: square food photograph for a sample recipe in Sazli, a premium warm minimalist recipe-book app. Create a single realistic editorial food photo, overhead three-quarter angle, soft natural window light, warm cream linen table with a subtle terracotta accent napkin, handcrafted ivory ceramic plate or bowl. Center the entire dish comfortably with all food inside the frame and enough surrounding negative space for an app image crop. High-end food magazine styling but approachable homemade presentation, realistic ingredient textures, natural colors, no people, hands, writing, letters, text, logos, watermarks, collage, border or UI. 1024x1024 square or higher. Dish: two thick slices of toasted sourdough topped with mashed avocado, fully set soft-scrambled eggs, halved cherry tomatoes, a small pinch of chili flakes, and freshly ground black pepper. A lemon wedge at the edge of the plate. Make it look fresh and inviting, with visible green avocado, golden eggs and red tomatoes.
```

### SampleLemonPasta

```text
Use case: photorealistic-natural. Asset type: square food photograph for a sample recipe in Sazli, a premium warm minimalist recipe-book app. Create a single realistic editorial food photo, overhead three-quarter angle, soft natural window light, warm cream linen table with a subtle terracotta accent napkin, handcrafted ivory ceramic plate or bowl. Center the entire dish comfortably with all food inside the frame and enough surrounding negative space for an app image crop. High-end food magazine styling but approachable homemade presentation, realistic ingredient textures, natural colors, no people, hands, writing, letters, text, logos, watermarks, collage, border or UI. 1024x1024 square or higher. Dish: linguine pasta tossed with baby spinach, olive oil, garlic, lemon zest and grated Parmesan, neatly twirled into a generous mound in a shallow ceramic bowl. A lemon wedge next to the bowl and a few fine Parmesan shavings on top. No tomato, meat, seafood or other toppings. Fresh green spinach and bright yellow lemon accents.
```

### SampleVegetableBowl

```text
Use case: photorealistic-natural. Asset type: square food photograph for a sample recipe in Sazli, a premium warm minimalist recipe-book app. Create a single realistic editorial food photo, overhead three-quarter angle, soft natural window light, warm cream linen table with a subtle terracotta accent napkin, handcrafted ivory ceramic plate or bowl. Center the entire dish comfortably with all food inside the frame and enough surrounding negative space for an app image crop. High-end food magazine styling but approachable homemade presentation, realistic ingredient textures, natural colors, no people, hands, writing, letters, text, logos, watermarks, collage, border or UI. 1024x1024 square or higher. Dish: a colorful couscous bowl with roasted chickpeas, golden roasted sweet potato cubes, zucchini half moons and red bell pepper, a creamy pale tahini-lemon drizzle, and chopped fresh parsley. Ingredients arranged in inviting loose sections around the couscous, showing all colors and textures clearly. No meat, eggs or avocado.
```

### SampleBerryParfait

```text
Use case: photorealistic-natural. Asset type: square food photograph for a sample recipe in Sazli, a premium warm minimalist recipe-book app. Create a single realistic editorial food photo, overhead three-quarter angle, soft natural window light, warm cream linen table with a subtle terracotta accent napkin, handcrafted ivory ceramic plate or bowl. Center the entire dish comfortably with all food inside the frame and enough surrounding negative space for an app image crop. High-end food magazine styling but approachable homemade presentation, realistic ingredient textures, natural colors, no people, hands, writing, letters, text, logos, watermarks, collage, border or UI. 1024x1024 square or higher. Dish: two small clear glass yogurt parfaits with distinct layers of thick Greek yogurt, crunchy golden oat granola, sliced strawberries and blueberries. A light drizzle of honey over the top, with a tiny fresh mint garnish. Place the two glass cups close together on a small ivory saucer. The layers and fresh berries should be clearly visible from the slightly elevated three-quarter angle, no overhead-only view.
```

