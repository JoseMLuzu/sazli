# Verification record

Verified on October 31, 2026, using Xcode 27.1, Swift 6.4 in Swift 6 language mode, and the iOS 27.1 SDK. The deployment target remains iOS 17.0.

## Results

| Check | Result |
| --- | --- |
| Generic iPhone Debug build without signing | Passed |
| App and XCTest target build-for-testing | Passed |
| XCTest on iPhone 18 Pro, iOS 27.0 | 5 passed, 0 failed, 0 skipped |
| Separate-process disk persistence check on macOS | All 6 phases passed |
| Xcode project property-list validation | Passed |
| Privacy manifest property-list validation | Passed |

The simulator's XCTest result bundle reported a successful test action and build, with zero errors and zero warnings. The passing tests were:

- `testDiskStoreReopensAfterCreateEditRateAndDelete`
- `testDraftValidatesMinimalAndInvalidRecipes`
- `testLinePresentationPreservesTextAndRemovesEmptyLines`
- `testPlatformDetectionUsesDomainBoundaries`
- `testSourceValidation`

The separate-process check verified the actual SwiftData model and services against an on-disk store, including a 500 KB external image value, source metadata, ingredients, steps, time, servings, category, ratings, notes, favorites, and deletion.

## Simulator interaction

Sazli was built and launched from Xcode in Device Hub on the iPhone 18 Pro simulator. The following were checked through the interface:

- The initial library contained no recipes and displayed its empty state.
- Creating a recipe produced a persisted library card and readable detail.
- A pasted YouTube URL selected YouTube automatically.
- A saved edit remained present after terminating and relaunching the app.
- Multiline ingredient and method entry saved three separate ingredients and two numbered steps.
- Adding a favorite updated the card and the Favorites filter.
- A four-star rating, note, and cook-again preference appeared in the detail after saving.
- Cooking mode advanced from step 1 to step 2, changed progress from 50% to 100%, navigated backward, and displayed the ingredient sheet.
- Leaving cooking mode returned to the recipe and library.
- Light library/detail and dark rating/cooking screens were visually inspected.

A single recipe created through the form remains in this simulator for inspection. The application does not seed sample data.

During input testing, the ingredient/method controls were changed from vertically expanding text fields to `TextEditor` so Return reliably inserts line breaks. The final editors were checked through keyboard entry and saving, and the final app/test build passed.

## Environment notes and remaining QA

The restricted command-line environment could not connect to CoreSimulator directly and prevented Swift's nested macro sandbox from starting. Command-line builds used the invocation-only compiler workaround documented in the README. Xcode's graphical interface could build, launch, and run the simulator tests normally. The persistence harness emitted restricted CoreData store-notification warnings, but every independent store reopening and assertion passed.

These results do not replace the full acceptance checklist on a physical device or the oldest supported iOS release. Photo-picker ingestion, actual Auto-Lock timing/restoration, full VoiceOver navigation, maximum Dynamic Type sizes, narrow/landscape layouts, and all manual paste/validation/destructive-confirmation paths still need the full [acceptance checklist](TESTING.md). The native unit suite and persistence harness cover storage and validation logic, rather than every UI path.

## Logo integration follow-up

The generated artwork was added to the library header and exported as an opaque 1,024-pixel app icon. Both Debug and Release target settings select `AppIcon`; the original artwork remains unchanged. The generic iPhone build passed, and its generated Info.plist includes `CFBundleIcons` with `CFBundleIconName` set to `AppIcon`. Xcode also built, installed, and launched this update on the connected iPhone running iOS 26.6. The updated library header and Home Screen icon were then visually confirmed in the iPhone 18 Pro simulator; the existing saved recipe remained available after the update.

## iPhone Duo adaptation

Verified on the installed **iPhone Duo, iOS 27.1** simulator on October 31, 2026:

- The generic iPhone app/test build passed with the iOS 17 deployment target unchanged.
- All **5 XCTest cases passed**, with **0 failures, 0 skipped tests, and 0 test-action warnings**. The result bundle identifies iPhone Duo as the destination.
- An unsaved recipe title and preparation time survived a Closed → Open transition in the editor.
- Two recipes created through the form appeared side by side in Open and stacked vertically in Closed.
- A recipe remained open while unfolding, with ingredients and method changing to parallel columns.
- Cooking displayed the ingredient panel on the expanded display. At step 2 of 3, the selected step and 67% progress survived Open → Partially Open → Closed → Open and rotation.
- The closed display retained accessible cooking controls and an ingredient-sheet action. The rotated expanded display retained its ingredient panel and readable current step.

The two manually entered recipes are simulator QA records, not launch-time sample data. The adaptation changes presentation only; the SwiftData schema is unchanged. The simulator checks do not establish behavior on physical Duo hardware. Full accessibility text-size/VoiceOver testing and the broader acceptance checklist remain separate QA work. See [adaptive layout](ADAPTIVE_LAYOUT.md) for implementation details and repeatable checks.

## Two-pane recipe workspace follow-up

The full-width recipe grid was replaced with native library/detail navigation using `NavigationSplitView`. On the open Duo, selecting either saved recipe kept the library visible and updated the adjacent detail, including the selected-row outline. Closing Duo retained the selected recipe in compact detail navigation; the native Back action returned to the library. Selecting the other recipe in compact mode and reopening Duo retained that new selection in the two-pane workspace.

Full-screen cooking was visually checked from the detail pane and displayed balanced ingredient/step panels across the whole window. The generic iPhone app/test build passed, and the follow-up XCTest run on **iPhone Duo, iOS 27.1** again reported **5 passed, 0 failed, 0 skipped, and 0 test-action warnings**. No schema or deployment-target changes were made.

Deletion now clears the root selection after a successful save, and removal of an observed record also clears an invalid selection. That UI deletion path, detailed filter/selection combinations, and all editor-fold combinations remain part of the manual acceptance checklist; the existing tests cover the underlying persistence/validation behavior.

## Recipe presentation refresh

Added shared presentation components for section icons/subtitles, preparation and serving tiles, numbered step cards, and rounded bordered panels. Ingredient rows, recipe detail, source/notes surfaces, and the two-panel cooking screen use the refined styling. The Xcode project includes the new component file without regenerating signing settings.

The generic iPhone app/test build passed. The final regression run on **iPhone Duo, iOS 27.1** reported **5 passed, 0 failed, 0 skipped, and 0 test-action warnings**. The ingredient card, metadata tiles, numbered method cards, reading empty states, and enlarged cooking card were visually inspected in the simulator.

Cooking checklist behavior was checked directly: preparing two ingredients updated their accessibility values, checkmarks, strikethrough, and progress to 2 of 3 (67%). Advancing separately to step 2 left both progress values independent. After folding Duo, the ingredient sheet retained both prepared rows. Unchecking one there and unfolding updated the inline panel to 1 of 3 (33%) while cooking stayed at step 2 of 3 (67%). Rotation retained those values as well. These marks are session state and do not alter the recipe schema or stored text.

The refreshed source-link surface, every notes/rating combination, and maximum Dynamic Type/VoiceOver behavior remain part of the broader manual checklist. The test suite covers persistence and validation; the listed design/checklist results come from simulator interaction rather than automated UI tests.

## Explicit sample recipes with photos

Added four complete, editable sample recipes and generated food photos, documented in [sample recipes](SAMPLE_RECIPES.md). Import was performed from the Debug Settings action on iPhone Duo. The success message reported four added recipes, and the library increased from two existing QA recipes to six records. The existing recipes remained present. Photo thumbnails and the avocado-toast detail image were visually checked. After terminating and relaunching the app, all six records remained available; the pasta recipe opened with its persisted photo, ingredients, and six preparation steps.

The **7-test** suite passed on **iPhone Duo, iOS 27.1**, with **0 failures, 0 skipped tests, and 0 test-action warnings**. New tests load and decode all four bundled photos, check recipe content/categories, confirm existing user content and edited samples survive repeat import, and verify a missing photo does not insert a partial batch. The generic iPhone Debug app/test build and Release build both passed. The import service and Settings action compile only in Debug; automatic launch-time seeding is not enabled.

## Connected iPhone 15 import

Sazli was built and launched on the user's connected iPhone 15 using the existing signing configuration. A temporary Debug launch argument invoked the same importer against the phone's local container. Xcode's device console confirmed: `Sazli sample import complete: 4 added; 5 recipes; 4 with photos.` The existing recipe was retained. The temporary argument was removed from the shared Run scheme afterward, leaving the app running on the phone. A generic iPhone Debug build passed before deployment. This is a device-local import, not synchronization with the simulator.

## Library heading cleanup — November 1, 2026

Removed the large in-content tagline so the native Sazli navigation title is the only main heading. The logo is now 56 points, beside a single secondary-style welcome line. The generic iPhone Debug build passed, and the resulting dark-mode header was visually checked on the iPhone 18 Pro simulator running iOS 27.0. No persistence or navigation logic changed.


## Text/link import and Shortcuts — November 1, 2026

Added whole-recipe import/review, a conservative English/Spanish parser, a durable private pending inbox, and a foreground App Intent exposed to Apple's Shortcuts app. The SwiftData schema, store location, bundle identifier, and signing team were preserved. No Share Extension, App Group, account integration, network extraction, or backend was added.

Verification performed:

- Generic iOS Debug app/test compilation passed. Generic iOS Release compilation passed, including App Intents metadata extraction.
- Xcode ran **14 XCTest cases** on **iPhone 18 Pro, iOS 27.0**, with **0 failures**. The final run completed at 18:55 on November 1. Coverage includes the foreground intent's original-text handoff, bilingual parsing, platform links, input limits, queue reopening, invalid-file retention, and duplicate prevention across a saved-but-unacknowledged import.
- The six separate-process persistence phases passed again against an isolated on-disk store. Restricted-environment CoreData notification messages did not cause assertion failures.
- In the simulator, pasted a complete recipe with Ingredients/Instructions headings, chose ChatGPT as its source, reviewed the separated fields, saved, and observed the two ingredients and two numbered method steps in recipe detail.
- Shortcuts discovered **Sazli → Import recipe**. Created a simulator-local **Send to Sazli** shortcut accepting Text and URLs, showed it in the share sheet, and assigned Shortcut Input to the action's text parameter.
- Safari's system share sheet displayed **Send to Sazli**. Running it with `https://example.com/recipe` opened Sazli's import screen containing the complete URL. No recipe content was fetched by Sazli.
- Restarted Sazli before saving that shared link; the import screen recovered the pending URL. Reviewed and saved it, then confirmed Web source metadata, empty ingredients/method, and disabled cooking in recipe detail.
- Xcode built, installed, and launched the final update on the connected **iPhone 15, iOS 26.6**, using the existing signing team. Xcode reported **Running Sazli on iPhone de Jose manuel Luzuriaga**.

The share-sheet shortcut was created and exercised on the simulator, **not on the physical iPhone**. The phone still needs the one-time shortcut configuration in [importing recipes](IMPORTING.md). Actual share payloads from installed ChatGPT, YouTube, TikTok, and Facebook apps, physical-device paste permission behavior, full accessibility QA, and the oldest supported iOS release remain manual acceptance checks. Native sharing was verified with Safari; the platform-specific URL cases and intent input path were verified by XCTest.

New files: `RecipeImportParser.swift`, `RecipeImportInbox.swift`, `ImportRecipeIntent.swift`, `ImportRecipeView.swift`, `RecipeImportHelpView.swift`, and this feature's [import guide](IMPORTING.md). Updated library navigation, editor initialization/save callbacks, idempotent store insertion, Settings help, the existing XCTest file, the Xcode source list, README, architecture, and testing documentation.


## Public ChatGPT share reader — November 1, 2026

The supplied public ChatGPT conversation was opened in a private Safari window without a ChatGPT login. Its recipe text was readable. A temporary copy of the public page's HTML was kept outside the repository for adapter verification; the complete conversation and share identifier were not added to app resources or tests.

Implemented a local WebKit reader and an inert JSON decoder for the observed public page format. Complete recipes are selected from finalized assistant text, with component markup removed, numbered step titles joined to their paragraphs, explicit time/serving metadata read, and later conversational advice kept separate. The SwiftData schema, private store location, development signing settings, and existing recipes were preserved. No API key, AI service call, App Group, backend, or new package dependency was introduced.

Verification performed:

- Generic iOS Debug app/test compilation passed; generic iOS Release compilation passed.
- The final native XCTest run on **iPhone 18 Pro, iOS 27.0** completed at **22:31:23** with **19 tests passed and 0 failures**. New tests cover strict public-share URL validation, uppercase HTTPS, final/visible assistant filtering, malformed and oversized payloads, observed component markup, explicit metadata, step grouping, duplicate candidates, and separation from follow-up advice.
- A separate invocation of the actual Swift extraction code against the temporary real-page HTML found four finalized assistant messages and two complete recipe candidates. The tuna recipe had its original title, 15 minutes, one serving, seven ingredients, and four cooking steps.
- Inside Sazli on the simulator, pasted the supplied public URL and tapped Review. The live isolated WebKit session fetched the conversation and displayed both recipe choices, with the tuna version first. Selecting it opened the existing editor with its real title, 15-minute time, one serving, ingredient list, method, and original ChatGPT URL populated.
- Saved that draft through the UI. Recipe detail displayed the imported title, time, servings, seven ingredients, four method steps, ChatGPT source, and an enabled cooking action. The shared-link workflow later launched Sazli from a stopped state. Reopening the saved recipe after that restart remains a separate manual UI check; disk persistence is covered by the existing XCTest suite.
- In Safari on the simulator, opened the same public conversation and chose the existing **Send to Sazli** shortcut from the system share sheet. Sazli opened directly into **Import from ChatGPT** and automatically started reading the public conversation. This verifies the pending share URL is routed into the local reader without requiring a separate paste/review action.

The website adapter is best-effort and relies on an observed public page format. Unsupported formats, login requirements, deleted links, browser challenges, or network failures retain a link-only fallback. The parser does not merge subsequent oil-adjustment advice into the original recipe or import generated/query-based images. Other platforms remain reference-only. The complete physical-iPhone share/import acceptance flow remains separate from these simulator results.

New source files: `Services/ChatGPTShareDocument.swift`, `Services/ChatGPTRecipeExtractor.swift`, `Features/RecipeEditor/ChatGPTShareWebView.swift`, and `Features/RecipeEditor/ChatGPTShareImportView.swift`. Added `SazliTests/ChatGPTShareTests.swift`; updated source-link validation, importer routing, input capitalization, help/editor/intent wording, project source references, and English documentation. See [importing recipes](IMPORTING.md).


Deployment note for this follow-up: selection of the connected iPhone destination was attempted, but native computer control began returning `cgWindowNotFound` for Xcode and Device Hub before the final run/install could be verified. The previous iPhone build remains the last confirmed physical-device deployment. The new public-share reader has been built and exercised on the simulator; installation on the physical iPhone is pending restored native UI access.
