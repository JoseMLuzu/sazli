# Recipe robustness simulations

Date: November 4, 2026. This round adds **6,674 deterministic synthetic scenarios** based on the failure families exposed by the Crunchwrap and lemon-pasta captions. Scenario counts are not downloaded-post counts or XCTest method counts.

## New coverage

| Family | Scenarios | Construction |
| --- | ---: | --- |
| Lists with missing ingredient headings | 6,144 | 8 bullet styles × 4 separators × 6 quantity forms × 8 ordered method styles × 2 bullet-spacing forms × with/without Instructions |
| Ingredient groups | 288 | 4 group-label forms × 4 separators × 6 quantity forms × 3 method-heading/prose forms |
| Equivalent measures | 144 | 8 bullet styles × 3 dash types × 6 metric/approximate/parenthetical equivalents |
| Food names and qualifiers | 60 | 15 food/qualifier strings × 4 bullet styles |
| Ambiguous/non-recipe controls | 8 | Missing/gapped methods, unquantified lists, promises of future instructions and prose stay available for review |
| Real text-import routing | 4 | First-line bullet ingredients cannot be discarded as titles |
| Public assistant extraction | 2 | Strong single-recipe implicit structures without Ingredients headings |
| Source-document adapters | 24 | 8 method forms through TikTok, YouTube and Instagram synthetic documents |
| **Total new** | **6,674** | Exact ingredient/action arrays or retention assertions |

Quantity forms include integers, Unicode and mixed fractions, decimal dots and decimal commas. Separators include spaces, newlines, tabs and nonbreaking spaces. Ordered methods include `1.`, `1)`, `(1)`, lowercase/uppercase letters, keycaps, Step labels and Paso labels. The matrix tests both compact ingredient bullets and ordinary spacing. It does not claim every possible language, marker, nested list or malformed recipe is recognized.

## Bugs found and fixed

- Headerless recipes using hyphens/en/em dashes, compact bullets, letters, parenthesized numbers, keycaps or Step/Paso labels could remain unstructured. The reader now validates consecutive ordered markers and strong quantity-led ingredient lists, then canonicalizes only their written markers.
- A recipe could have Instructions but omit Ingredients. The structural reader now preserves the explicit method while recognizing the ingredient list; existing ingredient headings retain priority.
- Metric conversions and short preparation qualifiers could become extra ingredients when the same dash served as a bullet. Named ingredient boundaries now distinguish bare equivalent measures or explicit modifiers from another food name.
- A parenthetical `g)` was mistaken for a lettered list marker. Ordered-list evidence is now validated as a sequence or a leading marker, rather than any matching character inside a measurement.
- Food names such as Sour Cream Sauce, including parenthetical modifiers, could lose Sauce when the legacy group normalizer misread it as a subgroup. Group normalization now requires an explicit structural boundary and retains uncertain food wording.
- The paste router could discard the first bullet ingredient as the title. List-led first lines are preserved as recipe content.
- The public ChatGPT extractor previously required an explicit ingredient heading even for a complete strongly structured assistant recipe. It now accepts supported single implicit structures, preserving assistant-message isolation and leaving ambiguous cover association manual. Multiple-method ambiguity is rejected rather than merging recipes.
- Method-marker normalization now avoids extra blank markers and preserves authored action paragraphs. Existing numbered source methods and the real seven-step lemon pasta remain regression controls.

The standalone persistence shell check also needed the parser files referenced by RecipeDraft. Its explicit compile list was updated so it continues to exercise the real models/services.

## Verification

The initial smaller simulation batch reproduced unsupported formats with failing assertions. After general format fixes, an intermediate run exposed food-name truncation and parenthetical-marker errors. Those failures were fixed; only the final run is counted as passing.

Final native XCTest: **104 tests passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_22-57-43--0500.xcresult`. The matrix is implemented in RecipeRobustnessTests with named activities and representative adapter checks in CrossPlatformImportTests. The existing caption scenarios, exact public-caption regressions, isolated SwiftData save/reopen, share-inbox and timer tests remain in the full suite. Runtime was approximately 65 seconds for the test methods.

The separate `Scripts/check_persistence.sh` passed all six phases: create, verify-create, edit, verify-edit, delete, verify-delete. It uses a temporary local store and removes it afterward. No personal recipe store was accessed.

Logs: `/private/tmp/sazli-robustness-round3-before.log`, `/private/tmp/sazli-robustness-round3-after.log`, `/private/tmp/sazli-robustness-round3-final.log`, `/private/tmp/sazli-robustness-persistence-check.log`. Synthetic tests do not certify public-page availability, source-app share UI or every on-phone interaction. No video/audio interpretation, generated ingredients, backend, schema migration, commits or push were introduced. Unknown or ambiguous content remains editable for review.

The final signed generic iOS Release build passed with both extensions (`/private/tmp/sazli-robustness-round3-release-final.log`), and the Xcode project plist validated. A separate native Foundation replay of retained public documents preserved five TikTok outcomes (Crunchwrap 14/20, lemon pasta 25/7, Cajun 14/8, taco 9/7 and gnocchi 12/3) and two recipes each from retained public mobile/legacy ChatGPT transcripts. These were snapshot replays through current production parser sources with a value-only draft projection, not new network/browser requests or personal-library reads. Log: `/private/tmp/sazli-robustness-replay.log`.

Devicectl confirmed successful installation of the final signed robustness update on the physical iPhone 15, preserving existing app data. No simulated recipe was inserted into the personal library. Interactive review/save remains a manual acceptance step.
