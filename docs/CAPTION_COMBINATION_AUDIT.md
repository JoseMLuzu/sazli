# Caption combination simulations

Date: November 4, 2026. These are constructed controls, not additional public-link downloads or a statistical sample of social posts.

## Coverage

The permanent XCTest suite now exercises **1,363 format scenarios** across the shared caption parser and real text-import router:

| Set | Scenarios | Checks |
| --- | ---: | --- |
| Heading/list cross product | 1,280 | 8 English/Spanish ingredient headings × 8 method headings × 10 list styles × with/without a colon |
| Punctuation and spacing | 36 | 9 heading delimiters × 4 whitespace types; exact ingredient/step arrays and unchanged quantities |
| Targeted punctuation/Unicode controls | 13 | Qualified ingredients, numeric comma lists, decimal commas/dots, semicolons inside parentheses, portions/ranges, CR and Unicode line separators, decomposed accents, negative temperatures, footers |
| Deliberately unstructured controls | 4 | Prose, missing paired group headings, video-only narrative remain available in the description |
| Existing caption format matrix | 22 | Emoji/Markdown headings, bullets, nutrition/tips, hashtags, group labels, fractions, narrative and incomplete recipes |
| Actual paste routing | 8 | 4 alternative ingredient headings × with/without a title; an embedded source URL must not replace the provided recipe |

The cross product includes ordinary, uppercase and lowercase headings, Ingredient list, Lista de ingredientes, Lo que necesitas, Preparation steps, Modo de preparación, and Cómo preparar. Lists include bullets, no-space asterisks/hyphens, en/em dashes, square bullets, keycap steps, letters, parenthesized numbers, no-space numbered markers, uppercase letter markers, and sequential number-dash markers. Heading delimiters include colon/fullwidth colon, hyphens, en/em dashes, equals, vertical bar, semicolon and ellipsis.

These scenarios are executed inside named XCTest activities and loops; they are not 1,363 separate XCTest methods. Additional assertions verify supported explicit portions, preservation of unsupported portion ranges, and rejection above the 200 KB input limit. The full suite has **72 test methods**.

## Fixes

RecipeCaptionParser normalizes supported whitespace, line separators, clipboard zero-width markers and canonically equivalent accents while preserving fraction characters and original quantities. It recognizes the additional heading/list forms and applies the same rules to TikTok descriptions, YouTube descriptions, and recipe text routed through RecipeImportRouter. The public ChatGPT share extractor retains its separate complete-message/recipe selection logic.

Lettered and parenthesized enumerations require a consecutive sequence before their markers are removed. No-space hyphens before numbers remain literal, preserving negative values such as -5°C. Semicolons separate rows outside parentheses/brackets. Commas separate ingredient rows only before a whitespace-delimited numeric quantity: `2 eggs, 200 g flour` separates, while `1 onion, finely chopped`, `1,5 cups`, and `eggs, salt, pepper` retain their text. Method commas remain intact. Unsupported portion ranges remain in the description rather than being guessed.

The router also checks whether a candidate title line contains an explicit supported section heading. This prevents first lines such as `Ingredient list: • Eggs • Salt` from being discarded as a recipe title. Existing source links and user titles are preserved.

The prior grouped TikTok fix remains covered: paired grouped headings, 35 chipotle-pasta ingredient items plus 3 labels, 11 method steps, source-draft merging and description-only recovery. Existing data changes only on Save.

## Results and limits

The initial 520-scenario simulation run exposed failures in the unsupported forms. After corrections and expansion, the final native run passed **72 tests, 0 failures**, on iPhone 17 Pro / iOS 26.5 with Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_20-44-17--0500.xcresult`. Logs: `/private/tmp/sazli-caption-combinations-before.log` and `/private/tmp/sazli-caption-combinations-complete.log`.

This improves explicit text detection; it does not interpret an arbitrary narrative, transcribe video/audio, translate, infer missing quantities, or guarantee every caption will separate automatically. Unknown text remains editable. A plain comma is ambiguous, so comma-only word lists remain a single ingredient row rather than being guessed. The shared parser is unchanged by network availability; private/unavailable pages still require pasted text or link-only review.

No personal recipe database was extracted, modified, or seeded. No backend, dependencies, schema migration, commits or push were introduced for these simulations. Interactive visual acceptance and share-sheet delivery are separate from automated parser/router tests.

The final signed generic iOS Release build passed, including the Live Activity extension (`/private/tmp/sazli-caption-combinations-release-final.log`). The Xcode project plist validated.

Devicectl confirmed successful installation of the final signed update on the physical iPhone 15, preserving existing app data. No simulated recipe was saved into the personal library. Interactive import/save verification remains manual.
