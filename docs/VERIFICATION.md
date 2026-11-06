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

## Timer Live Activity and Dynamic Island — November 2, 2026

Added an embedded WidgetKit extension and a shared ActivityKit payload for the existing timer. Supported devices show compact/minimal/expanded Dynamic Island content and a Lock Screen card with Sazli colors, recipe, step, and countdown. Native authorization and foreground checks gate creation; no model-name checks are used. Start requests one activity without a push token; pause/resume update it, cancellation ends it, and foreground expiry/reconciliation cleans up completed or orphaned activities. Reopening updates an existing activity without recreating one the user dismissed. System timer text and a stale date provide zero/finished presentation when the app cannot execute. The ordinary timer/notification remain independent. See [timer behavior and system limits](COOKING_TIMER.md).

Verification performed:

- Generic iOS Debug and final Release builds passed. Validated project/extension property lists. The Release app contains `PlugIns/SazliTimerExtension.appex`; its WidgetKit extension identifier, bundle-ID prefix, marketing/build versions, and the app's Boolean `NSSupportsLiveActivities` setting were checked.
- Native XCTest on **iPhone 18 Pro, iOS 27.0**, passed **30 tests with 0 failures, 0 skips, and 0 test-action warnings**. Three added tests check activity transitions independent of notification permission, restore/expiry without requesting another activity, and stable running versus paused payloads. Activity adapters are faked in tests.
- In the simulator, a real five-minute timer created the Live Activity. After leaving Sazli, Dynamic Island displayed the terracotta/coral timer icon and running countdown. Touch-and-hold expanded it to show Sazli, the recipe, step, and remaining time.
- Opening Notification Center showed the real Lock Screen card and the system's **Allow Live Activities from Sazli?** prompt. Allowed it in the simulator; the countdown card remained visible. Tapping it returned to the existing timer controls.
- Pausing in Sazli updated the expanded island to **Paused / 03:29**, unchanged after more than a minute. Resuming restored the running countdown with the same timer; canceling removed the activity from the island.
- A final 30-second timer confirmed the adjusted expanded layout, including fully visible leading/trailing labels. The final native app was built/launched after the foreground-expiry task refinement.
- Updated the project generator to include the extension, dependency, embedding, and shared source. Ran it only against a temporary validation project, checked its three targets and embedding/dependency references, and left the existing signed project/scheme intact.

Created `CookingTimerAttributes.swift`, `CookingTimerLiveActivity.swift`, `SazliLiveActivity/SazliTimerLiveActivity.swift`, and `SazliLiveActivity/Info.plist`. Updated timer coordination/UI calls, library lifecycle reconciliation, timer tests, Xcode targets, generator, and English guides. The recipe schema/store, main bundle identifier, existing signing team, and iOS 17 minimum were preserved. No App Group, push service, backend, or continuous background mode was added. Physical-device appearance, disabled-Live-Activity/non-Island hardware, maximum accessibility sizes, multiple competing activities, and long-duration system limits remain manual acceptance checks.

The final 30-second native test also completed while Sazli was in the foreground: the controls changed to **Time's up / 00:00**, and returning to the Home Screen confirmed the Live Activity had ended before dismissing the saved timer. The test timer was then dismissed and cooking mode closed, restoring its normal idle-timer behavior. Expiry while the app is suspended/terminated and the corresponding stale presentation remain separate manual checks; the guide documents that the app cannot guarantee an exact background end without executing.

Xcode also signed, installed, and launched the final app with its embedded extension on the connected **iPhone 15, iOS 26.6**, under the existing development team. The fresh physical-device process attached, and Xcode reported **Running Sazli on iPhone de Jose manuel Luzuriaga**. Physical Dynamic Island/Lock Screen appearance was not captured through computer control, and no timer or Live Activity permission was started/changed on that phone during deployment. The native appearance and permission results above are from the simulator.

## Sorting, duplicating, and sharing — November 2, 2026

Added Sort recipes to the library options menu, with Recently added, Name A–Z, Highest rated, and Quickest first. The selection persists through AppStorage and applies after search/category/favorites filters. Unknown preparation times sort last and equal keys use deterministic tie-breakers.

Recipe options now include Duplicate recipe and Share recipe. Duplication explicitly saves a fresh UUID and collision-free Copy title, retaining the description, ingredients, method, time, servings, category, image, and original source. Personal ratings, notes, favorites, and cook-again history start fresh. The library selects the newly saved copy. Native ShareLink presents existing content as text, with numbered instructions and the original link; private notes/ratings, photos, and missing ingredient/method sections are not shared or invented.

The generic iOS Debug build passed. The native XCTest run on iPhone 18 Pro, iOS 27.0 completed at 22:30 with **33 tests passed, 0 failed, 0 skipped, and 0 test-action warnings**. Three new tests verify all four sort modes and ties, duplicate uniqueness/content/independent edits with disk-store reopening, and sharing full/link-only content without personal history. Xcode's UI became unavailable during visual checking; tests were run successfully through xcodebuild with simulator access instead. Actual menu interaction, preference relaunch, duplicate navigation, and system share-sheet inspection remain manual checks in TESTING.md.

The signed Debug app and embedded Live Activity extension built with the existing signing team. devicectl confirmed installation and successful launch of com.sazli.app on the connected physical iPhone 15. No recipes were duplicated or messages sent on that phone during deployment. The schema and store location remain unchanged. Added RecipeActions.swift and updated library/detail/store, the existing XCTest file, app target membership, and English documentation; the project generator already includes the new service through its source glob.

## Display performance — November 2, 2026

Added RecipeThumbnailCache.swift and RecipeThumbnail.swift, registered both in the existing app target, and replaced synchronous full-photo decoding in RecipeCard and RecipeDetailView. ImageIO decodes display-sized images on a utility task. NSCache reuses decoded images, validates source bytes after photo changes, and uses advisory count/cost eviction limits. Canceled view requests cannot apply stale results. Updated LibraryView to normalize its search once and reuse one filtered/sorted list per content evaluation; updated RecipeText and detail sections to avoid repeated normalization/line parsing. README, architecture, and testing guidance remain in English. No recipe schema, store location, signing, backend, or external dependencies changed.

Validation:

- iOS Simulator Debug build passed.
- All **34 XCTest tests passed with 0 failures** on iPhone 18 Pro, iOS 27.0. The new thumbnail regression checks downsampling, object reuse, changed-photo invalidation, corrupt data, and size bounds. Existing search, sorting, duplication, import, timer, and disk-reopen tests also passed. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.02_22-46-37--0500.xcresult`.
- The fixture decoded a 1600 × 1200 JPEG to 384 × 288 pixels, with its decoded pixel buffer below one tenth of a 1600 × 1200 four-byte-per-pixel buffer. This is an isolated thumbnail check, not a measurement of whole-app memory or frame rate. Corrupt-image testing emitted expected ImageIO diagnostics; simulator image decoding also emitted CVPixelBuffer diagnostics without failing the test.
- Signed generic iOS **Release build passed**, including the existing Live Activity extension. Xcode emitted its existing signed-extension stripping warning. devicectl confirmed installation on the physical iPhone 15. Launch was denied because the phone was locked; physical launch/visual acceptance is pending.
- Simulator visual checking reached the existing pending import sheet and closed its nested ChatGPT reader without discarding content. Device Hub then returned `noWindowsAvailable` while attempting to dismiss the parent sheet. Photo-grid/detail visual acceptance, accessibility sizes, and Instruments Allocations/Time Profiler profiling remain pending.

Build/test logs are under `/private/tmp/sazli-optimization-{build,tests,release}.log`. No commits or push were performed for this stage.

## ChatGPT ingredient/title format fix — November 3, 2026

The reported public share (`6ae9a2ef-d8ec-83e9-8417-ab10621b8705?ogimg=plain`) was readable, but RecipeExtractor rejected both recipes: the first used a styled component title rather than a Markdown title; the second used an inline bold title and `Ingredientes (2 personas)`. The previous extractor required an exact ingredient heading and a separate level-one/two Markdown title.

Updated ChatGPTRecipeExtractor.swift to recognize portion-qualified ingredient headings, styled and inline emphasized titles, and complete recipes without an explicit title (using the editable generic title `Recipe from ChatGPT`). Inline tips are kept outside cooking steps, and recipe boundaries keep separately titled recipes in one message apart. Explicit integer portions are retained; time/portion ranges remain unguessed. Updated ChatGPTShareImportView.swift to distinguish a readable conversation with no complete recipe from a page-read failure and offer a return to text import. The WebKit reader, URL validation, persistence, schema, and original source URLs are unchanged. Updated English importing/testing guidance.

Validation:

- All **37 XCTest tests passed, 0 failures**, on iPhone 18 Pro / iOS 27.0. Three new tests cover the reported heading/title format, styled/missing titles and unguessed ranges, and multiple recipes in one message. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.03_13-57-52--0500.xcresult`.
- Downloaded the supplied public page successfully (HTTP 200). A separate Foundation parser probe used the actual document/extractor/parser/text/link/category source files and a value-only draft projection (without model editing/persistence), processing the complete downloaded HTML. The previous extractor returned **0 recipes** from its two public final assistant messages; the corrected extractor returned **2**: cheese-chicken pappardelle with **8 ingredients, 5 steps, 2 servings**, and garlic-chicken pappardelle with **9 ingredients and 4 steps**. The earlier recipe's `2–3` portion range stayed unguessed.
- Signed iOS **Release build passed**, including the existing extension, with the existing signed-extension stripping warning. After the user unlocked the phone, devicectl confirmed installation on the iPhone 15. Existing app data was preserved.
- Device Hub screen interaction failed with `noWindowsAvailable`; live browser import/editor visual acceptance remains a manual check. The complete-HTML parser reproduction and native tests do not claim successful on-phone browser interaction.

Logs: `/private/tmp/sazli-chatgpt-fix-{tests,release}.log`. No recipes were saved during verification; no commits or push were performed.

devicectl also confirmed successful launch of `com.sazli.app` on the unlocked physical iPhone 15 after installation.

## Optional ChatGPT cover photos — November 3, 2026

Inspected the supplied pappardelle share's image-component metadata and found accessible photo URLs for both final assistant responses. Updated ChatGPTShareDocument to return structured visible messages with explicit `async_image` component URLs/positions while preserving the text-only helper. Updated ChatGPTRecipeExtractor to associate a cover before each ingredient section and carry URLs on the nonpersistent candidate. WebKit/import views now pass these candidates to the editor. Added ChatGPTRecipePhoto.swift and app-target membership for bounded, cookie/credential-free HTTPS downloads with validated image responses/redirects and existing background JPEG preparation. Updated RecipeEditorView to import only the selected cover, allow skipping, show unavailable-photo messages, and retain normal replace/remove/save/discard flows. Updated English README/importing/architecture/testing guides. Schema and store remain unchanged.

Validation:

- Simulator Debug build and all **39 XCTest tests passed, 0 failures** on iPhone 18 Pro / iOS 27.0. New coverage verifies visible-message photo association, user/hidden-message exclusion, step-photo exclusion, supported URL/HTTP/MIME/size checks, and absent/unsupported-photo fallback. Existing persistence, recipe parsing, photo, timer, and action tests also passed. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.03_14-06-34--0500.xcresult`.
- A separate native Foundation probe processed the complete downloaded share HTML using the actual document, extractor, downloader, photo preparation, parser, text, link, and category sources plus the value-only draft projection. Both recipes exposed two candidate cover URLs. Downloads succeeded and produced prepared JPEGs of **359,171 bytes** (cheese-chicken pappardelle) and **68,474 bytes** (garlic-chicken pappardelle). Visually inspected both generated local files: each contains a pasta/chicken dish, without a social-preview card or page banner. This verifies actual network decoding/preparation on the Mac, not the full iPhone browser/editor flow.
- Signed iOS **Release build passed**, including the existing extension, and the project plist validated. devicectl confirmed installation on the user's iPhone 15 without replacing its recipe store.
- Native editor interaction, skip/cancel while downloading, and offline relaunch of a newly saved imported image remain manual acceptance checks. No personal recipes were inserted or changed during verification. Images shown by the share may originate from search; this feature does not claim to retrieve every generated/private ChatGPT image.

Logs: `/private/tmp/sazli-chatgpt-photo-{build,tests,release}.log`. No commits or push were performed.

The subsequent physical launch request was denied because the iPhone had locked again. Installation succeeded; the user must open the updated app to complete on-phone acceptance.

## TikTok public description import — November 3, 2026

The supplied short link `https://vt.tiktok.com/ZSpRSQuyw/` resolved with HTTP 200 to the public Louis Howard video `7696569418880535830`. Its description contains a complete recipe, including inline `WHAT YOU’LL NEED`, bullet ingredients, `METHOD`, `SERVES`, and nutrition/original-recipe credits. Added TikTokRecipeDocument.swift to read that explicit public caption and supported cover URLs through a bounded, ephemeral native request restricted to supported public TikTok redirects. Added TikTokRecipeImportView.swift and routing for pasted/pending video links, keeping review, save, cancel, link-only, and paste-description recovery. Added supported link validation in SourceLink. Moved the existing image download transport to RecipeRemotePhoto.swift with platform-specific hosts while retaining ChatGPTRecipePhoto as its adapter. Editor receives the appropriate photo source; in-app help and English README/importing/architecture/testing guides were updated. Added TikTokRecipeTests.swift and source/target membership. No schema/signing/store changes, video processing, backend, or dependencies.

Validation:

- Simulator Debug build and **43 XCTest tests passed, 0 failures**, on iPhone 18 Pro / iOS 27.0. Four new tests cover public links, exact one-line caption structure, partial/bilingual descriptions, unguessed portion ranges, malformed/oversized pages, and platform-specific image-host restrictions. Existing ChatGPT/photo/persistence/action/timer tests passed. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.03_14-15-49--0500.xcresult`.
- A separate native Foundation probe used the actual TikTok reader, shared downloader, photo preparation, parser/text/link/category sources and the value-only draft projection. It resolved the real short link, read the public caption, and produced **12 ingredients, 3 steps, 4 servings**, preserving the original URL. It obtained two cover candidates and downloaded/prepared a **76,974-byte JPEG**. Visual inspection confirmed a video cover showing the creator with the dish; it is not a promised finished-dish photograph. No total preparation time or personal rating was inferred from cooking instructions or the creator's rating.
- Final signed iOS **Release build passed**, including existing extension, and the project plist validated. The final build includes updated in-app help. No personal recipes were saved during verification.
- Native iPhone/simulator import-sheet interaction, cancellation during loading, real blocked/private videos, shortcut handoff, and offline reopening of a newly saved TikTok recipe remain manual acceptance checks. The live network probe ran on the Mac and does not establish that TikTok will serve every region/device without a challenge. The UI provides fallback actions.

Logs: `/private/tmp/sazli-tiktok-{build,tests,release,release-final}.log`. No commits or push were performed.

devicectl confirmed successful installation and launch of `com.sazli.app` on the physical iPhone 15 with the final TikTok update. Existing app data was retained; no recipe was inserted on the phone during deployment.

## TikTok headings without colons — November 3, 2026

Reproduced the reported field-separation error using the public `@thesimplecravings` video `7694085059602550030`. Its single-line caption uses `Ingredients * … Instructions 1. …`, without colon delimiters, and appends hashtags to the final step. The previous parser imported the whole caption into the description. A new exact-caption regression test failed against the previous parser with 0 ingredients and 0 steps.

Updated only TikTokRecipeDocument.swift's caption normalization to accept missing heading colons when followed by an explicit bullet/numbered list, split inline asterisk/dash ingredient bullets within the ingredient section, and keep trailing hashtag blocks in the description. Quantities, decimal/fractional values, prose, and creator/source metadata are retained. Added three tests in TikTokRecipeTests.swift and updated English importing/testing guidance. Existing saved recipes are not rewritten; reimporting uses the corrected parser. No schema, UI, image transport, signing, or dependency changes.

Validation:

- Full native XCTest suite on iPhone 18 Pro / iOS 27.0: **46 passed, 0 failures**. New tests verify the exact taco mac caption, Spanish headings/fractional and decimal quantities, and ordinary prose mentioning ingredient/instruction words without recipe sections. Existing earlier TikTok caption, ChatGPT, images, persistence, timer, and action tests passed. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.03_14-24-01--0500.xcresult`.
- A native Foundation probe fetched the actual supplied public URL through the production TikTok reader/parser sources with a value-only draft projection: **9 ingredients and 7 steps**. Last ingredient: `Optional: parsley for topping`; last step: `Top with parsley if desired and serve warm!`. It confirmed hashtags were excluded from instructions and the creator credit remained in the description.
- Signed iOS **Release build passed**, including the existing Live Activity extension. No recipes were saved or modified during verification. On-device review/reimport remains a manual acceptance check.

Logs: `/private/tmp/sazli-tiktok-caption-{before,tests,release}.log`. The `before` run intentionally demonstrates the regression before the parser fix. No commits or push were performed.

devicectl confirmed successful installation and launch of the corrected build on the physical iPhone 15, preserving existing app data.

## TikTok caption format audit — November 3, 2026

Reviewed six fetched public descriptions: the two previously supplied full-caption recipes, three Fitwaffle dish-only announcements, and Jordi Cruz's narrative vinaigrette advice. A native production-parser audit confirmed 12/3 and 9/7 ingredient/step counts for the structured recipes; the four descriptions lacking supported complete section boundaries remained available for manual review. Full primary-source links and dated observations are in [TikTok caption format audit](TIKTOK_FORMAT_AUDIT.md).

Added 22 explicitly constructed format controls to TikTokCaptionFormatTests.swift. A standalone Foundation baseline run found 12 failing controls (10 passed). Separated pure normalization into TikTokCaptionParser.swift and corrected decorated Markdown/emoji headings, keycap numbered steps, numbered/bulleted ingredient/method lists, supported Spanish heading aliases, and explicit nutrition/macro/tip/hashtag footers. The corrected production parser passes all 22 exact-text controls, including negative/partial/narrative cases and quantity preservation. These control failures are not a measured failure rate across published TikTok videos. Updated TikTokRecipeDocument to delegate to the pure parser, app/test target membership, and English audit/importing/testing documentation. No backend, inference, video processing, schema changes, or automatic rewriting of stored recipes.

Validation:

- Native XCTest with **Xcode 27.2** on iPhone 18 Pro / iOS 27.0: **47 tests passed, 0 failures**. The new matrix is one XCTest containing 22 named activities; existing TikTok exact-caption, ChatGPT/image, disk-persistence, timer, sorting/duplicate/share tests also passed. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.03_20-52-08--0500.xcresult`.
- The initial native run was blocked by a CoreSimulator mismatch after Xcode updated from 27.1 to 27.2. The installed simulator components finished updating during `simctl list devices`; the subsequent full native run passed. No test failures were hidden by counting the earlier blocked run as a pass.
- Six actual downloaded HTML documents were separately processed by the production document/caption/parser sources in a native Foundation audit with a value-only draft projection; all six had the expected structured-versus-manual-review outcome. All 22 constructed controls passed in the separate before/after audit after correction.
- Signed generic iOS **Release build passed**, including the existing extension; the project plist validated. The existing signed-extension stripping warning remains. Native tests emitted the existing simulator image/launch diagnostics and the deliberate corrupt-image diagnostic, without test failures.
- UI presentation and specific on-phone imports for every new format remain manual checks. No personal recipes were inserted, modified, or deleted during the audit. The actual pages may change or be regionally unavailable.

Logs: `/private/tmp/sazli-tiktok-formats-{tests,tests-final,release}.log`. Separate audit results: `/private/tmp/sazli-caption-audit-{before,after}.json`. No commits or push were performed.

devicectl confirmed successful installation of the final caption-format audit build on the physical iPhone 15, preserving existing app data.

The updated app also launched successfully on the iPhone 15 through devicectl. Interactive imports for each new format were not performed on the personal device.

## TikTok imports from Original source — November 4, 2026

The repeated report was traced to an entry path omitted from earlier work: the user pasted the TikTok URL into **Original source inside a recipe**, rather than the library's Import recipe screen. That editor field only retained the link and detected its platform; it did not call the TikTok reader. A focused production-reader diagnostic on the physical iPhone 15 / iOS 26.6 successfully returned **9 ingredients and 7 steps** for the exact public URL, and the exact-caption fixture also passed there. The issue required connecting the editor field to the reader, not another caption-format change.

Added **Import recipe details** directly below a supported TikTok source URL in RecipeEditorView. The action calls the existing public reader and merges into empty fields in the current value draft via RecipeDraft.fillEmptyDetails, retaining existing text, source, photo, and numeric edits. New default portions can be filled from explicit imported values. The editor shows ingredient/step counts, supports optional cover loading/skipping, and cancels stale source/photo requests when the URL changes or the view closes. Saving remains explicit. Source and photo request IDs prevent canceled responses from applying to a newer review.

Also added RecipeDraft.recoverTikTokSectionsIfNeeded for a draft/existing TikTok recipe that already has a complete caption in its description and both text sections empty. It proposes ingredients/method in the editor with a review notice, retaining creator credit in the description and preserving personal title, time, servings, category, photo, notes, ratings, and favorites. Canceling leaves the stored recipe unchanged; only Save applies the recovered fields. Existing/manual/partial structured fields are preserved. Added four regressions and shared the taco mac fixture in TikTokRecipeTests. Updated English README/importing/architecture/testing guides. No schema, signing, backend, or dependencies changed.

Validation:

- Final full XCTest suite on iPhone 17 Pro / iOS 26.5: **51 passed, 0 failures**. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_15-21-59--0500.xcresult`. Tests cover empty-field merges, default versus existing portions, description recovery, cancel/no mutation before Save, disk reopening with the same UUID, and preservation of notes/favorites/edits. Existing caption/ChatGPT/photo/timer/action regressions passed.
- Focused native public-link and exact-caption diagnostic on physical iPhone 15: **2 passed**. The temporary network-dependent diagnostic was removed from permanent test sources after execution. Result: `build/DeviceImportDiagnostics/Logs/Test/Test-Sazli-2026.11.04_15-07-59--0500.xcresult`.
- A subsequent physical-device recovery run completed with **9 passed, 0 failures** using only fixtures and test-created temporary stores. Result: `build/DeviceImportDiagnostics/Logs/Test/Test-Sazli-2026.11.04_15-14-03--0500.xcresult`. The final 11-test source/merge run was compiled but could not launch because the phone locked. It was canceled while waiting for unlock; it is not counted as a passing run. Both new merge regressions passed in the full 51-test simulator suite.
- Signed iOS **Release build passed**, including the existing extension. The earlier full-suite attempt on the iOS 27 simulator failed to launch because SpringBoard crashed; it was not counted as a passing test run. The available iOS 26.5 simulator then completed the full suites successfully.
- Automatic approval review rejected an optional proposal to copy the phone's entire recipe store because it could include unrelated personal recipes. The operation was not retried or bypassed. Investigation continued with the public link and isolated test fixtures; saved personal recipes were not extracted or automatically rewritten.
- Computer-use inspection returned `noWindowsAvailable`; interactive tapping of the new source-field button and photo cancellation remains manual acceptance. Native public-reader results, unit merge/persistence results, and a successful build do not constitute visual acceptance of that button.

Logs: `/private/tmp/sazli-{tiktok-iphone-diagnostic,tiktok-recovery-tests,tiktok-recovery-tests-ios26,tiktok-recovery-iphone-tests,source-import-tests,source-import-iphone-tests,source-import-release}.log`. No commits or push were performed for this follow-up.

devicectl confirmed successful installation of the final signed release containing the new Original source import action on the physical iPhone 15. The saved recipe store was preserved. No personal recipes were saved, edited, or extracted during deployment.

The subsequent launch request was denied because the iPhone was locked. Installation succeeded; the user can open the updated app after unlocking to complete interactive acceptance.

## Cross-platform import audit — November 4, 2026

See [IMPORT_AUDIT.md](IMPORT_AUDIT.md) for ten actual public URLs, per-source results, native browser-versus-HTTP distinctions, and remaining manual acceptance. Fixed shared routing, public YouTube description reading, source-field imports across all three readers, partial/mixed review notices, caption section boundaries, and the newer public ChatGPT mobile transcript. No model migration, backend, signing change, or personal recipe extraction was required.

Final full suite: **66 tests passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_17-13-02--0500.xcresult`. Signed Release build passed. Public fetch/browser diagnostics are documented separately from deterministic regression tests and interactive visual acceptance. No commits or push were performed.

The final signed Release build, including the updated import help and Shortcuts action description, passed (`/private/tmp/sazli-cross-import-release-final.log`). devicectl confirmed installation on the physical iPhone 15 with existing app data preserved. Interactive acceptance remains separate from installation.

The installed update launched successfully on the physical iPhone 15 through devicectl. No public sample was automatically saved to the personal library.

## Grouped TikTok caption — November 4, 2026

The supplied `https://vt.tiktok.com/ZSpFB66ns/` exposed another heading shape: Ingredients/Instructions followed by a group name and then a bullet. The paired grouped headings are now supported, keeping explicit subgroup labels and 11 cooking actions separate. The exact downloaded caption produces 35 ingredient items plus 3 group labels. Two new regressions cover parsing, source-draft merging, recovery, and unpaired-heading rejection. Full native suite: **68 passed, 0 failures** on iPhone 17 Pro / iOS 26.5. Signed Release build passed. See [the follow-up audit](IMPORT_AUDIT.md). The first installation attempt lost the device connection (CoreDevice 4000); installation is not claimed for that attempt. No personal recipes were changed and no commits/push were made.

A separate live native Foundation probe using the production TikTok reader also fetched the exact short link successfully and returned 38 ingredient rows / 11 steps. It uses a value-only draft projection and does not access the personal library. Log: `/private/tmp/sazli-grouped-caption-live.log`.

After the device connection recovered, devicectl confirmed successful installation of the final signed update on iPhone 15. Existing app data was preserved; interactive import/save acceptance remains manual.

The subsequent launch was denied because the phone was locked. Installation succeeded; the updated app can be opened manually after unlocking.

## Caption combination simulations — November 4, 2026

Added 1,363 constructed format scenarios across heading/list cross products, punctuation/spacing, Unicode/quantity preservation, unstructured controls and actual paste routing. Fixed shared normalization and a router case that discarded alternate section headings as titles. Native full suite: **72 passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_20-44-17--0500.xcresult`. See [CAPTION_COMBINATION_AUDIT.md](CAPTION_COMBINATION_AUDIT.md) for the scenario breakdown and limits. No commits/push were performed.

The final signed generic iOS Release build passed, including the Live Activity extension (`/private/tmp/sazli-caption-combinations-release-final.log`). The Xcode project plist validated.

Devicectl confirmed successful installation of the final signed update on the physical iPhone 15, preserving existing app data. No simulated recipe was saved into the personal library. Interactive import/save verification remains manual.

## Ingredient presentation — November 4, 2026

RecipeText.ingredientLines now supplies the Recipe presentation accessor used by detail and cooking mode. Explicit group labels such as Pasta:, Chicken:, Salsa:, Guarnición: and For the sauce: are omitted from ingredient rows and cooking checklist counts. Real ingredient rows lose only supported trailing punctuation/whitespace. Commas inside descriptions, decimal quantities, negative temperatures, optional parentheses, and interior colons remain intact. Bare Pasta without a heading colon remains an ingredient. The editor and persisted ingredients string retain the original source; instruction punctuation is unchanged. No schema migration or stored-data rewrite occurs.

A regression checks the same model accessor used by both screens and verifies source preservation. Full native suite: **73 tests passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_20-51-14--0500.xcresult`. Log: `/private/tmp/sazli-ingredient-display-tests.log`. Visual acceptance remains manual. No commits or push were performed.

Signed Release build passed (`/private/tmp/sazli-ingredient-display-release.log`) and devicectl confirmed installation on the physical iPhone 15, preserving app data. No personal recipes were modified during installation.

## Recipe integrity and missing Cajun ingredients — November 4, 2026

Reproduced six failures with new tests before fixing them: a quantified flattened ingredient heading in the supplied TikTok, spaced numeric ranges treated as bullets, numeric weight qualifiers split inside explicit bullets, numbered Markdown ChatGPT steps moved to notes, decorated/alternate-line-ending titles lost by paste routing, and actual prefixed ingredients hidden by the display filter. See [the follow-up audit](IMPORT_AUDIT.md). The exact supplied caption now yields 14 ingredients and 8 steps; source merging preserves the user's existing title.

Full native suite: **79 passed, 0 failures** on iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_21-01-49--0500.xcresult`. The baseline failure log is retained separately from the passing run: `/private/tmp/sazli-recipe-integrity-before.log` / `/private/tmp/sazli-recipe-integrity-after.log`. No model migration, account connection, dependencies, personal recipe database extraction, commits or push. Visual acceptance remains manual.

A separate live native Foundation probe using the production TikTok reader successfully fetched the exact Cajun short link and verified 14 ingredients, 8 steps, the original source URL and `50g Parmesan, grated`. It uses a value-only draft projection and does not access the personal library. Log: `/private/tmp/sazli-cajun-live-audit.log`. The final signed iOS Release build passed, including the Live Activity extension (`/private/tmp/sazli-recipe-integrity-release.log`).

Devicectl confirmed successful installation of the final signed update on the physical iPhone 15 with existing app data preserved. No public sample was saved or modified in the personal library. Source-field visual/save acceptance remains manual.

## Native Share Extension — November 4, 2026

Implemented SazliShareExtension with a native SwiftUI receiver, shared visual assets and explicit Add to imports / Done / Cancel behavior. It accepts source-supplied HTTP(S) links or recipe text, without fetching account/history data or inserting recipes inside the extension. SazliShared contains the typed NSItemProvider reader and durable App Group request store. RecipeImportInbox receives verified durable copies using the original UUID before acknowledging shared files. Existing SwiftData recipes remain in their original private store. App Group entitlements apply to the main app and share target only; the existing timer target/signing configuration is unchanged.

Validation:

- Full native XCTest on iPhone 17 Pro / iOS 26.5: **86 tests passed, 0 failures**. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_21-16-49--0500.xcresult`. ShareImportTests adds seven tests covering real typed NSURL/NSString providers, duplicate text, file/empty/oversized rejection, durable handoff/reopening, interrupted-copy verification, malformed shared files preserving private imports, capacity and identifier checks. Existing recipe parsing/save/reopen/timer tests passed.
- The initial build found incorrect source-phase membership for the new shared files; it was corrected without regenerating the real project. A subsequent native provider test exposed NSURL's archived data representation, so the receiver now prefers typed URL/string object loading rather than assuming raw UTF-8. Temporary type-only diagnostics were removed. Earlier failed runs are not counted as passes.
- Signed generic iOS Release build passed with both extensions. Automatic provisioning updates succeeded using the existing development team. The main app and embedded Share Extension signatures both contain `group.com.sazli.app.imports`; share-service metadata and codesign deep/strict verification passed. No credentials or signing keys were read/exported.
- The project generator was updated for the shared files, App Group entitlement paths and four targets, then run in a separate temporary directory. Its generated plist and expected target/source membership validated; the actual project/team configuration was preserved.
- Computer-use inspection of Device Hub returned `noWindowsAvailable`. The actual ChatGPT share menu, extension presentation and on-phone end-to-end save remain manual acceptance; passing provider tests and installed metadata do not certify that interaction.

The supported flow is ChatGPT/system Share → Sazli → Add to imports → Done, then open Sazli to review/save. Apple documents containing-app URL opening for Today extensions, not arbitrary Share Extensions; no private selector/responder workaround is used. Sources: [extension overview](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionOverview.html), [App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups). No backend, API key, stored-recipe migration, commits or push.

Logs: `/private/tmp/sazli-share-extension-tests-final.log` and `/private/tmp/sazli-share-extension-release-final.log`. The optional Shortcuts action remains available alongside direct sharing.

Devicectl confirmed successful installation of the final signed app with the Share Extension on the physical iPhone 15. Existing app data was preserved and no shared test recipe was inserted into the personal library.

The subsequent launch was denied because the iPhone was locked. Installation succeeded; open the updated app manually after unlocking.

## Instagram and additional format simulations — November 4, 2026

Added the bounded public Instagram caption/cover reader and connected it to existing paste, share-inbox and source-field review. Added explicit ingredient-table handling, protected Notes columns, mixed/Unicode fractions, prefix portion metadata, ChatGPT emoji/alias headings, named Tip footers, and numbered-method sentence-dash preservation. See [the import audit](IMPORT_AUDIT.md) for five refreshed public links, snapshot-versus-live distinctions and limits.

Final native suite: **90 passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_21-53-10--0500.xcresult`. Signed generic iOS Release build passed with both extensions; project plist validated. Public Instagram native carbonara request verified 5 ingredient rows / 4 author-numbered steps. The second captured public Instagram sample yielded 4/4; a third HTTP 200 page correctly remained unavailable. Refreshed TikTok/YouTube samples retained 14/8 and 25/33. Previously captured public ChatGPT mobile/legacy documents each still yielded two recipes; no new live browser run was claimed. Probes use value-only drafts and isolated source documents. No personal recipe database access, account connection, schema migration, commits or push. Interactive share/import/save acceptance remains manual.

Devicectl confirmed successful installation of the final signed update on the physical iPhone 15. Existing app data was preserved; no public test recipe was inserted into the personal library. Interactive on-phone review/save for the new Instagram entry path remains manual acceptance.

## Kookmutsjes Crunchwrap TikTok — November 4, 2026

The supplied caption omitted an Ingredients heading and numbered method markers. Added conservative all-caps quantity-led group recognition, parenthetical-measure protection, sentence separation for this unnumbered method, and explicit group-heading display filtering. The exact source now produces 14 ingredients / 20 written method sentences. The new regression saves and reopens the recipe in an isolated SwiftData store, preserving fields/title/source; prose controls prevent single/unsupported group guesses. Source-field status uses the cleaned ingredient count.

Final full native suite: **93 passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_22-14-00--0500.xcresult`. Live native public reader probe verified 14/20 and the exact original URL. Signed generic iOS Release build passed and project plist validated. Logs: `/private/tmp/sazli-crunchwrap-tests-persistence.log`, `/private/tmp/sazli-crunchwrap-live.log`, `/private/tmp/sazli-crunchwrap-release.log`. See [the audit](IMPORT_AUDIT.md). No personal data/database extraction or recipe insertion, migration, commits or push. Interactive source-field review/save is separate from the passing isolated persistence test.

Devicectl confirmed installation of the final signed Crunchwrap fix on the physical iPhone 15, preserving existing app data. No test recipe was saved in the personal library.

## Headerless lemon pasta TikTok — November 4, 2026

The supplied Marisa Kapeal video has quantity-led asterisk ingredients and consecutive numbered steps, but omits Ingredients/Instructions labels. RecipeBulletedCaption now recognizes that explicit structure conservatively, keeps supported group labels as editable headings, and retains website notices as description text. Ingredient bullet handling also preserves metric equivalents separated by em/en dashes rather than creating extra food rows.

Exact-caption verification: 25 ingredients / 7 authored steps, including complete metric equivalents, decimal grams, source URL and unguessed portion range. The regression saves and reopens the recipe in an isolated temporary SwiftData database. Full native suite: **96 passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_22-24-47--0500.xcresult`. Logs: `/private/tmp/sazli-lemon-pasta-{before,after}.log`. Existing Crunchwrap, Instagram, ChatGPT, share, timer and persistence regressions passed. See [the audit](IMPORT_AUDIT.md). No personal recipe insertion/extraction, schema migration, commits or push; interactive acceptance remains separate from the isolated save test.

A separate live native public-reader probe verified the exact supplied lemon-pasta URL with 25 ingredient items, 7 steps, preserved original source and intact metric/decimal items (`/private/tmp/sazli-lemon-pasta-live.log`). The probe uses a value-only draft projection; the persistence regression uses the actual app model/services in a temporary store. Signed generic iOS Release build passed, including both extensions (`/private/tmp/sazli-lemon-pasta-release.log`); project plist validated.

Devicectl confirmed successful installation of the final signed lemon-pasta fix on the physical iPhone 15, preserving existing app data. No test recipe was inserted into the personal library. Interactive on-phone review/Save remains manual acceptance.

## Large recipe-structure simulation audit — November 4, 2026

Added 6,674 new deterministic scenarios around the two recent TikTok failure families, including absent section labels, bullet/ordinal variants, equivalent measures, food names/qualifiers, explicit method-only headings, routing and public-assistant extraction. Fixed the failures exposed by the baseline and intermediate runs. See [ROBUSTNESS_AUDIT.md](ROBUSTNESS_AUDIT.md) for counts, concrete fixes and limits.

Final full native suite: **104 passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_22-57-43--0500.xcresult`. Updated standalone persistence check passed create/reopen/edit/reopen/delete/reopen using a temporary store. Existing exact TikTok, ChatGPT, Instagram, YouTube, share-inbox and timer regressions passed. No personal data was accessed or rewritten; no model migration, backend, commits or push. Interactive acceptance remains separate from programmatic tests.

The final signed generic iOS Release build passed with both extensions (`/private/tmp/sazli-robustness-round3-release-final.log`), and the Xcode project plist validated. A separate native Foundation replay of retained public documents preserved five TikTok outcomes (Crunchwrap 14/20, lemon pasta 25/7, Cajun 14/8, taco 9/7 and gnocchi 12/3) and two recipes each from retained public mobile/legacy ChatGPT transcripts. These were snapshot replays through current production parser sources with a value-only draft projection, not new network/browser requests or personal-library reads. Log: `/private/tmp/sazli-robustness-replay.log`.

Devicectl confirmed successful installation of the final signed robustness update on the physical iPhone 15, preserving existing app data. No simulated recipe was inserted into the personal library. Interactive review/save remains a manual acceptance step.

## Cooking voice assistance — November 5, 2026

Added optional narration and local Spanish/English voice commands to cooking mode, with pause/resume/repeat, explicit permission handling, interrupted-session cleanup, and reading/capture exclusion. Both options begin off. No recipe migration or backend.

Full native suite: **123 passed, 0 failures**, including 19 voice tests on iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.05_01-35-52--0500.xcresult`; log: `/private/tmp/sazli-cooking-voice-full-tests.log`. Signed generic iOS Release build passed with both extensions; log: `/private/tmp/sazli-cooking-voice-release.log`. Project generator validated separately without altering signing.

The signed update installed on the paired iPhone 15 after a connection-reset retry. Device Hub inspection reached the simulator library/editor, then failed with `noWindowsAvailable` before cooking controls could be reviewed. No real microphone/narration acceptance is claimed; follow [COOKING_VOICE.md](COOKING_VOICE.md). No commits or push.

## Voice permission crash correction — November 5, 2026

The iPhone crash report `Sazli-2026-11-05-014624.ips` identified an EXC_BREAKPOINT in `_dispatch_assert_queue_fail` from `NativeCookingCommandListener.authorize(language:)`, called by Speech/TCC on a background queue. The authorization closure had inherited MainActor isolation under Swift 6. Usage-description keys were present; this was a callback isolation failure.

The production authorization callback is now explicitly nonisolated/Sendable. Audio-tap and recognition-result callbacks are also explicitly Sendable; UI/controller updates continue through MainActor tasks. A new regression invokes the production permission callback on a global queue for all four authorization states, without requesting microphone permission. All **20 voice tests passed, 0 failures**. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.05_01-47-49--0500.xcresult`; log: `/private/tmp/sazli-voice-crash-fix-tests.log`. Real microphone acceptance remains separate from these tests.

The corrected signed Release build passed (`/private/tmp/sazli-voice-crash-fix-release.log`) and installed successfully on the paired iPhone 15. No recipe store was accessed or changed by diagnosis.

## Spanish command availability correction — November 5, 2026

Replaced hard-coded Spanish (Spain) recognition with same-language regional resolution. The paired iPhone 15 reported `es-US`, `es-MX`, `es-419`, and `es-CO` as locally supported/available; `es-ES` and `es-CL` reported no local support. This reproduced the original guard rejection without recording audio. A temporary native capability-only diagnostic passed on the physical phone and was removed after diagnosis. Its result is `build/DeviceVoiceDiagnostics/Logs/Test/Test-Sazli-2026.11.05_01-56-05--0500.xcresult`; log `/private/tmp/sazli-spanish-device-capabilities.log`. The initial diagnostic build needed the existing development team passed as a command-line override; project signing settings were preserved.

All **23 permanent voice tests passed, 0 failures** on iPhone 17 Pro / iOS 26.5. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.05_01-54-52--0500.xcresult`; log `/private/tmp/sazli-voice-spanish-tests.log`. Signed iOS Release build passed, log `/private/tmp/sazli-voice-spanish-release.log`. No new permission, server fallback, recipe mutation, migration, commits, or push. Device availability probing does not certify spoken recognition accuracy.

The Spanish correction installed successfully on the paired iPhone 15. User should retry Español → Voice commands and speak Siguiente/Anterior/Repetir/Detener between readings.

## Cooking presentation refresh — November 5, 2026

Updated CookingModeView, CookingVoiceControls and the prominent RecipeStepCard. Removed the repeated step badge and tinted heading panel, gave the instruction more space, moved voice settings to a sheet, and grouped Ingredients/Timer/Voice above persistent step navigation. The active voice status and Pause/Resume remain directly accessible. No model or voice/timer service behavior changed.

**33 targeted tests passed, 0 failures** (23 voice, 10 timer), iPhone 17 Pro / iOS 26.5. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.05_02-05-05--0500.xcresult`; log `/private/tmp/sazli-cooking-layout-tests.log`. Interactive Device Hub review verified the new step screen with a long sample instruction, Next advancing to step 2 with 33% progress, the separate Voice panel, enabling Read aloud, and returning to the step with reading still enabled. Sample recipes were loaded only in the test simulator through the existing debug argument. Real microphone recognition, accessibility-size and Duo visual acceptance were not repeated in this pass.

Signed iOS Release build passed (`/private/tmp/sazli-cooking-layout-release.log`) and installed successfully on the paired iPhone 15. No commits or push.

## Native narration quality — November 5, 2026

CookingSpeechOutput now ranks available same-language voices by quality, regional preference, system voice and stable identifier. Novelty/Personal voices are excluded. Utterances preserve recipe text and use normal pitch/default cadence. CookingVoiceTests adds three tests for quality/language exclusions, regional/system tie breaking, compact fallback and native Spanish utterance preservation. No UI controls, recipe schema, microphone permissions or external services were added.

**26 voice tests passed, 0 failures** on iPhone 17 Pro / iOS 26.5; log `/private/tmp/sazli-natural-narration-tests.log`. Signed Release build passed; log `/private/tmp/sazli-natural-narration-release.log`. The physical-phone utterance test initially waited for the locked device, then completed successfully when it became available. It reported the selected voice as Mónica / es-ES / quality 1 (basic), so no higher-quality eligible Spanish voice was available to the app in that snapshot. Its log is `/private/tmp/sazli-natural-narration-device.log`. No audio was played by this test and no microphone access was requested. Subjective audio quality remains manual; downloading a higher-quality voice is a user action.

The signed narration update installed successfully on the paired iPhone 15. No commits or push.
