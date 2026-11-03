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


## Compact library navigation bar — November 2, 2026

Updated `LibraryView.swift` to use an inline native navigation bar. The 28-point brand logo and Sazli wordmark are centered together; the existing import and Settings actions stay on the trailing side. Removed the separate welcome block and large scrolling title, and moved the filters closer to the navigation bar. The bar uses the existing adaptive cream background. Recipe navigation, forms, pending imports, and persistence logic were not changed.

The generic iOS Debug build passed. The compact dark-mode library was visually inspected on **iPhone 18 Pro, iOS 27.0** in Device Hub: a single brand row, both trailing actions, the existing pending-import banner, filters, and saved recipe cards were present. The temporary import view was closed without discarding its pending item. The persisted imported pasta recipe was still present among four saved recipes after launch.

Updated the visual-system description in `ARCHITECTURE.md`. This is a presentation-only change; no additional unit tests were introduced. Full VoiceOver, maximum Dynamic Type, and all expanded/folded layout combinations remain in the broader manual checklist.

Xcode also built, installed, and launched this update on the connected **iPhone 15, iOS 26.6** after the device was unlocked. The debug session attached successfully and Xcode reported **Running Sazli on iPhone de Jose manuel Luzuriaga**. Physical-device appearance was not captured through computer control.

## Photo-grid library — November 2, 2026

Updated `LibraryView.swift` and `RecipeCard.swift` to present a photo grid inspired by the supplied reference while keeping Sazli's adaptive palette. The library now includes a collection heading/count, an in-content search field with a clear action, category filters, a navigation-bar plus, and an ellipsis menu for importing and Settings. Cards show shaded full-bleed photos, overlaid titles, serving/time badges, and rating/favorite indicators. Two columns are used at pane widths of at least 340 points; narrower panes and accessibility text sizes use one. Native split navigation and persistence are unchanged.

The final generic iOS Debug build passed. An earlier iteration was built and launched natively on **iPhone 18 Pro, iOS 27.0**: the two-column library, heading, search, navigation actions, saved records, and Settings route were visually checked. The explicit Debug sample importer reported four photo recipes added while keeping the four existing records. The simulator was temporarily switched from Dark to Light for photo review.

Before final photo inspection, native control began returning `cgWindowNotFound` for both Device Hub and Xcode. The last rating-badge refinement has passed compilation but has not yet received native visual review. Search interaction, final light/dark photo inspection, restoring the simulator's previous Dark appearance, and deploying this grid update to the connected iPhone remain pending native access. No additional unit tests were introduced for this presentation-only change.

## Library hierarchy and leading logo — November 2, 2026

Updated `LibraryView.swift` to put only the brand logo on the leading side of the native navigation bar. The visible centered wordmark was removed; Sazli remains the logo's accessibility label. The stable Your recipes heading has a result count beneath it. Search and filters are grouped together, followed by a smaller pending-import row when needed, then the photo grid. The plus and ellipsis actions remain on the trailing side.

Native access recovered during this follow-up. The final generic iOS Debug build passed, and Xcode built and launched the update on **iPhone 18 Pro, iOS 27.0**. Visually checked the final photo cards, leading logo, heading, grouped controls, and pending row in both Light and Dark. The simulator's original Dark appearance was restored. Searching for avocado returned one recipe; clearing restored all eight records. A photo card opened its detail and the native back action returned to the grid. The plus opened an empty new-recipe editor, which was canceled. The ellipsis menu exposed Import recipe and Settings, and Settings opened successfully. Favorites reduced the grid to the existing rated recipe with its star and heart visible; All restored the full grid. The pending import was closed without discarding it. These checks also complete the preceding photo-grid visual/search checks.

Documentation changes are in `ARCHITECTURE.md` and this verification record. No model, store, or project/signing settings changed. Full VoiceOver, maximum Dynamic Type, and expanded Duo regression checks remain in the manual checklist.

Xcode also built, installed, and launched the final update on the connected **iPhone 15, iOS 26.6**, using the existing development team. The fresh device debug process attached, and Xcode reported **Running Sazli on iPhone de Jose manuel Luzuriaga**. Physical-device appearance was not captured through computer control.

## Ingredient search and recipe-detail cleanup — November 2, 2026

Added name/ingredient search through `RecipeText.matchesSearch`, retaining category/favorites filtering. The query is a substring/phrase matched against either the title or stored ingredient text; surrounding whitespace, case, and accents are ignored. There is no translation, inferred ingredient data, or search of method/source/notes. Updated the search placeholder, accessibility label, and empty-state guidance.

Reorganized recipe detail into photo, category/title/description, a single preparation/servings panel, ingredients/method, rating/notes, and original source. Sections have simpler headings, reading steps place a small number beside the text, and cooking retains its large step presentation. The native detail bar keeps Back and Favorite, with editing, rating, and confirmed deletion in an ellipsis menu. The fixed bottom action starts cooking or opens the existing editor when preparation steps are missing. Photo framing now follows its available width and exposes a descriptive accessibility label. Ingredient/method columns and accessibility stacking remain in place.

Verification performed:

- Eight direct checks of the actual Swift search helper passed, covering title and ingredient matches, uppercase, accents, whitespace, misses, and empty ingredients.
- The native XCTest run on **iPhone 18 Pro, iOS 27.0**, completed at **15:42:11** with **20 tests passed, 0 failed, 0 skipped, and 0 test-action warnings**. It includes the new search test and the existing persistence/import regression suite.
- The final generic iOS Debug build passed after the final presentation/accessibility refinements. Xcode also built and launched the final version on the simulator.
- Searching for **olive oil** through the UI returned four saved recipes whose titles do not contain that phrase. Applying Breakfast reduced the results to one; returning to All restored four, and clearing the query restored all eight recipes.
- Visually inspected the photo/detail overview in Light and Dark, compact method cards and notes in Dark, the no-photo/no-steps recipe, the source row's accessible label, and the detail options menu. The final photo accessibility label was present in the native tree. Restored the simulator's original Dark appearance afterward.
- Opened/canceled the rating sheet. Opened/canceled the existing editor using Add preparation steps on a link-only recipe. Opened the deletion confirmation and dismissed it without deleting. Start cooking opened the large step view; Next step advanced from step 1/5 (20%) to 2/5 (40%), and Close returned to detail.

Updated `LibraryView.swift`, `RecipeText.swift`, `RecipeEmptyState.swift`, `RecipeDetailView.swift`, `RecipePresentation.swift`, and `SazliTests.swift`, plus the English README, architecture, testing guide, and this record. The SwiftData schema/store, existing recipe content, signing settings, and external-service configuration are unchanged. Full VoiceOver, maximum Dynamic Type, expanded Duo regression, and oldest-supported-iOS acceptance remain manual checks.

The final version was also built, installed, and launched on the connected **iPhone 15, iOS 26.6**, with the existing signing configuration. After native access was restored, Xcode showed the fresh physical-device process attached and **Running Sazli on iPhone de Jose manuel Luzuriaga**. Physical-device appearance was not captured through computer control.

## Local cooking timer — November 2, 2026

Added a single app-wide cooking timer with editable minutes/seconds, duration presets, pause/resume/cancel, recipe/step context, a countdown summary in cooking and the library, and an explicit finished state. Running deadlines and paused remaining durations persist in UserDefaults independently of SwiftData. The UserNotifications service requests permission only on Start timer, schedules a local alert, removes it on pause/cancel, and retains a working countdown when permission or scheduling fails. Foreground alerts support banner, notification-list, and default sound presentation. No backend, remote-notification capability, background mode, or recipe-schema change was added.

Verification performed:

- Generic iOS Debug and Release builds passed. The project property list passed validation, with the existing team and deployment target retained.
- Native XCTest on **iPhone 18 Pro, iOS 27.0** completed at **16:01:20** with **27 tests passed, 0 failed, 0 skipped, and 0 test-action warnings**. Seven new tests cover deadline calculations, pause/resume, restoration/expiry, denied authorization/recovery, scheduling failure, validation, formatting, and prevention of a second active timer. Notification requests in these tests use an injected fake.
- Through the native UI, opened Timer from cooking, entered 0 minutes/20 seconds, started it, and observed the first-use notification prompt. After allowing notifications on the simulator, the countdown and scheduled-alert message appeared. Pausing froze it at 15 displayed seconds.
- Terminated/relaunched Sazli using Xcode while paused. The library summary and reopened controls both recovered the same 15 seconds after more than a minute. Resuming counted down to **Time's up / 00:00**, and Dismiss timer removed the summary. Original recipes and the pending import were retained.
- The final foreground notification-list refinement was compiled and launched natively after the test run; it does not change timer-state transitions. Full lock-screen sound, Focus behavior, VoiceOver, maximum Dynamic Type, and all Duo layouts remain manual acceptance checks.

Created `CookingTimerStore.swift`, `CookingTimerNotifications.swift`, `CookingTimerView.swift`, `CookingTimerTests.swift`, and [the timer guide](COOKING_TIMER.md). Updated cooking/library integration, target source references, README, architecture, and testing documentation. The Xcode project was edited directly without regenerating signing settings.

The final Release build also passed after the foreground notification-list refinement. For a second native test, started a 40-second timer, sent Sazli to the background with more than 30 seconds remaining, and stopped the app's debug process in Xcode. After expiry, iOS Notification Center contained **Timer finished — Avocado & Egg Toast · Step 1 is ready to check.** The notification was visually confirmed, and tapping it relaunched Sazli. This verifies actual local notification delivery independently of a running app process on the simulator; physical sound/Focus behavior remains separate acceptance work.

After that notification launch, the library recovered **Timer finished** and the controls showed **Time's up / 00:00**. Dismissing cleared the test timer and restored the normal library. A final presentation guard prevents pending imports from opening while the library's timer controls or a timer update are active. The final Release build and project validation passed after this guard.

Xcode built, installed, and launched the final version on the connected **iPhone 15, iOS 26.6**, retaining the existing signing configuration. The fresh device debug process attached and Xcode reported **Running Sazli on iPhone de Jose manuel Luzuriaga**. Notification permission was exercised only in the simulator; the physical iPhone will ask when the user first starts a timer. No timer was started or notification permission changed on the physical phone during deployment.
