# Testing Sazli

## Automated coverage

- `SazliTests`: name/ingredient search (case, accents, whitespace, empty fields), URL/platform boundaries, unsafe and malformed links, minimal-recipe validation, newline presentation, disk-backed recipe lifecycle checks, bilingual import parsing, the App Intent handoff, and pending-inbox persistence/retry/failure behavior.
- `CookingTimerTests`: deadline accuracy without ticks, pause/resume, running/paused/expired restoration, alert scheduling/cancellation through a fake, denied permission/recovery, failure reporting, duration bounds, formatting, and prevention of a second active timer.
- `Scripts/check_persistence.sh`: compiles the real model/services and uses separate executable launches to verify durable create/edit/rate/favorite/photo/delete behavior. It also exercises link detection and draft validation.
- Xcode's `build-for-testing` action checks that the app and XCTest target compile together. Executing XCTest requires a bootable simulator or an appropriately signed physical device.

## Manual acceptance checklist

For library/recipe actions: choose each Sort recipes option in the library ellipsis menu, combine it with a search/filter, and confirm the choice survives relaunch. Unknown preparation times should sort last. From recipe options, duplicate a photo recipe twice and confirm unique Copy titles, retained content/photo/source, fresh rating/notes/favorites, and independent edits after relaunch. Share a full and a link-only recipe; inspect the system sheet and copied text without sending it to anyone. Confirm numbered steps, original link, and omission of private notes, empty sections, and unspecified time. Repeat on compact/expanded layouts and with accessibility text sizes.

1. Launch a fresh install. Confirm a warm cream library, an empty state, no sample recipes, and an **Add a recipe** button.
2. Try saving an empty form. Confirm a clear validation message. Enter a title and a YouTube link, save, and confirm a real library card appears without invented ingredients or steps.
3. Force-quit and reopen Sazli. Confirm the recipe is still present. Open it and confirm the source link, title, and empty content prompts.
4. Edit the recipe. Add a description, ingredients on separate lines, preparation steps on separate lines, time, servings, category, and a photo. Save and reopen the app. Confirm all changes persist.
5. Enter invalid time, servings, and URL values in turn. Confirm saving reports the problem and retains the draft. Cancel a changed form and check the discard confirmation. Check interactive sheet dismissal does not silently lose changes.
6. Search using a title fragment and an ingredient absent from the title, including uppercase/accent-free input. Clear the search and test every filter with the query still active. Confirm a nonmatching query shows the empty state. Mark the recipe as a favorite, return to the library, and confirm it appears under **Favorites**. Remove the favorite and verify that filter updates.
7. Check the photo grid in light and dark appearance. At standard iPhone text sizes, confirm two columns, readable overlaid titles, serving/time badges, and visible rating/favorite indicators. Search by title, clear the search, open a card, and return. Confirm the plus opens the editor and the ellipsis menu exposes importing and Settings. At accessibility text sizes or in a narrow split-view pane, confirm a single readable column.
8. Paste YouTube, TikTok, Facebook, ChatGPT, and generic web links. Confirm automatic platform suggestions. Confirm a host such as `youtube.com.example.org` is treated as Web. Choose a manual platform override and save it.
9. Use **Paste recipe text**. Paste multiline ingredients and append them to existing ingredients. Repeat with instructions and the description. Confirm no existing content disappears and each nonempty instruction line becomes a step.
10. Add a rating, note, and “would make again” preference. Relaunch and confirm persistence. Modify the rating, clear it, and verify notes can exist without a rating.
11. Check the detail photo and a recipe without a photo, long titles, grouped preparation/servings, ingredient rows, compact numbered method, notes, and source. Use the options menu to edit, rate, and open/cancel deletion. Start cooking, move forward/backward, check progress and ingredients, and finish. Check a long step scrolls and starts at the top. For a recipe with no steps, confirm **Add preparation steps** opens the editor and canceling preserves its content.
12. Set a short device Auto-Lock interval. Confirm the display stays awake in active cooking mode, and that normal locking returns after closing or backgrounding Sazli. Restore your original Auto-Lock setting afterward.
13. Test system, light, and dark appearances from Settings and verify the preference after relaunch. Check narrow and landscape iPhones, large accessibility text, VoiceOver, and Reduce Motion. Confirm no required action is clipped or unreachable.
14. Open the original link, then test saved recipes in airplane mode. Reading, editing, ratings, and cooking must work offline. An iCloud-only photo or external source link may require a connection.
15. Cancel deletion and confirm the recipe remains. Confirm deletion on a disposable test recipe, relaunch, and confirm it stays deleted.

For the refreshed cooking checklist, mark two ingredients prepared and confirm the count, progress bar, checkmarks, and strikethrough update. Fold Duo, open the ingredient sheet, and confirm the same selections. Uncheck one item there, unfold, and confirm the inline panel reflects the change while the current cooking step stays selected. Closing and reopening cooking should start a fresh checklist without changing the saved ingredient text.

## Timer acceptance

Start a short timer in cooking mode. Check editable minutes/seconds, presets, invalid zero/out-of-range values, and the first-use notification prompt. Verify the count changes while open, pauses without consuming time, and resumes from the same remainder. Change steps and leave cooking; check the same recipe/step timer remains available in the library. Relaunch while running, paused, and after expiry. Check foreground and background delivery, sound/lock-screen behavior on the physical iPhone, permission denial, and recovery after changing notification settings. Pausing/canceling must remove the scheduled alert, and starting another timer must not leave a second notification. Confirm controls remain usable with Dynamic Type, VoiceOver, a small screen, and Duo folding. See [timer behavior](COOKING_TIMER.md).

With Live Activities allowed, start a timer and leave Sazli. Check Dynamic Island compact, expanded, and minimal presentation on supported hardware, plus the Lock Screen card and its first-use permission. Pause/resume in the app and check the activity freezes/continues with the same time. Cancel and confirm removal. Let a short timer expire while the app is running, then while suspended/terminated; verify zero/stale presentation and cleanup after foregrounding. Dismissing the activity alone must keep the timer and notification working, and reopening Sazli must not recreate the dismissed activity. Test with Live Activities disabled and on hardware without Dynamic Island; ordinary timer controls must still work. Long timers remain subject to iOS Live Activity lifetime limits.

## Import acceptance

Follow [the import guide](IMPORTING.md) to configure the share-sheet shortcut on the actual device. Exercise pasted ChatGPT recipe text, link-only imports from all supported platforms, review cancellation, failed saves, pending-inbox recovery after a cold launch, and a successful save with no duplicate after relaunch. Repeat sharing while another editor is open: the existing draft must stay intact and the shared import must remain pending. Check that Sazli receives only the data supplied by the source app and keeps unknown text rather than inventing missing details.

For the public ChatGPT reader, share a conversation with multiple recipes and later follow-up advice. Check that recipe choices stay separate, time and servings come only from explicit metadata, each numbered heading and paragraph becomes one cooking step, image/component markup never appears in the recipe, and later advice does not replace the chosen method. Cancel the browser/editor, try an offline/deleted/private link, and confirm the link-only fallback and pending inbox remain usable. Repeat with the source app's native share sheet on the physical iPhone; this is distinct from Safari simulator sharing.

## Release follow-up

Final device visual QA, branded icon/logo assets, localization, export/backup design, and App Store signing/distribution are separate from the local recipe-manager implementation. CloudKit, video transcription, general webpage extraction, and a dedicated Share Extension remain outside this implementation; native sharing currently uses the documented Shortcuts action. Supported public ChatGPT share pages use the local reader.

## Photo performance regression

`testThumbnailsDownsampleReuseAndInvalidateChangedPhotos` checks a generated 1600 × 1200 image decodes to 384 × 288, repeated requests reuse the UIImage, changed photo bytes under the same ID invalidate the entry, corrupt data returns nil, and requested sizes are bucketed/clamped. Run the full suite to preserve search, sorting, duplication, import, timer, and disk persistence behavior.

On a device, scroll a photo-filled library, search ingredients, open/close details repeatedly, and replace a photo. Check for stale images or cropping/layout changes, including landscape and accessibility text sizes. Use Instruments Allocations and Time Profiler for process-level memory and scrolling measurements; thumbnail pixel-buffer sizes alone do not establish whole-app memory or frame-rate improvements.


## ChatGPT recipe-format regression

The public-share tests cover inline bold titles, styled component titles, `Ingredientes (2 personas)` / `Ingredients (2 servings)` headings, recipes without explicit titles, and two recipes in one message. Verify that the cheese-chicken pappardelle share offers its two recipes separately: the most recent version has eight ingredients, five steps, and two servings; the earlier version has nine ingredients and four steps. Tips belong in the description. Time/serving ranges remain unguessed. Review or cancel without saving to avoid adding test recipes to a personal library.


## Optional ChatGPT cover photos

Review the public pappardelle share and choose either recipe: each should load its own cover photo in the editor. Remove or replace it before saving, or choose **Continue without imported photo** while loading. Test an unavailable photo/offline connection: text must remain editable and saveable. Cancel review without inserting a recipe. Save with a photo, relaunch offline, and check the same image in library/detail.

Automated coverage verifies image metadata is read only from visible final assistant messages, each recipe receives its own cover, step images are excluded, unrelated/authenticated/insecure URLs are rejected, invalid HTTP/type/size responses are rejected, and missing/unsupported candidates return no photo. Existing tests cover photo preparation, thumbnail reuse, and local image-data persistence.


## TikTok description import

Paste `https://vt.tiktok.com/ZSpRSQuyw/` in the importer or send it using the configured shortcut. The public description should populate **12 ingredients, 3 steps, and 4 servings**. The title starts as **Recipe from TikTok**, ready to edit; preparation time remains empty. Check that the 200°C / 40-minute cooking instruction is retained, nutrition and original credits remain in the description, the video cover is optional, and the original short link is retained. Save, reopen offline, and verify local text/photo persistence. Try a private/unavailable link, cancel while loading, and choose **Keep the link only**. No test recipe should be saved to a personal device unless explicitly intended.

TikTokRecipeTests covers supported/unsafe routes, the supplied single-line bilingual caption forms, absent sections, portion ranges, unavailable/malformed/oversized pages, and separate image-host policies. Existing regression tests continue covering ChatGPT, optional photos, persistence, and timers.


### TikTok headings without colons

The public `@thesimplecravings` video `7694085059602550030` writes `Ingredients * … Instructions 1. …` in one caption line. Reimporting should produce **9 ingredient rows and 7 preparation steps**. Fractional amounts (½, 1½, 1¼, ¼), cooking instructions, and optional parsley must remain intact. Hashtags and creator credits belong in the description. Existing saved recipes are not automatically rewritten. Three regression tests cover this exact caption, Spanish headings and decimal quantities, and ordinary prose that must not be classified as a recipe section.


### Caption format matrix

See [TikTok caption format audit](TIKTOK_FORMAT_AUDIT.md) for six observed public captions and the before/after table for 22 constructed controls. `TikTokCaptionFormatTests.testCaptionFormatMatrix` executes the controls as named XCTest activities, checking exact ingredient/step arrays and description-only notes. Controls include Markdown/emoji headings, keycap numbers, ingredient/method bullets, Spanish aliases, macros/tips, hashtags, and deliberate partial/narrative descriptions. They complement the exact-caption regressions in TikTokRecipeTests and are not a statistical sample of TikTok.


### Recover a TikTok description-only draft

Create a test recipe containing the full taco mac caption and a trailing `Creator: alexis` in its description, with TikTok platform/source and empty ingredients/method. Open **Edit**: expect 9 ingredients, 7 steps, and a review notice, with hashtags/creator credit in the description. Cancel and reopen: the stored record must still contain the original text. Save the review and reopen: the same recipe UUID should now contain separate fields. Existing title, time, servings, photo, notes, and favorite must remain intact. Repeat with partially/manual-edited fields: recovery must not overwrite them.

Two regression tests cover explicit-save/disk-reopen behavior and no-op preservation for manual, partial, already structured, and repeated recovery attempts. Live network diagnostics are run separately rather than adding a network-dependent test to the permanent suite.


### Import directly from the source field

In New recipe, paste the supplied Simple Cravings URL in **Original source**. Tap **Import recipe details** beneath the URL. Expect 9 ingredients and 7 steps in their respective fields, with a count/status message and an optional video cover. Save and reopen to verify persistence in the same recipe. Repeat in an existing recipe with a custom title/description/ingredient quantities/time/servings/photo: filled fields must retain those values, and only empty fields should receive source details. Cancel while reading, change the source URL during a request, and skip the cover; stale responses must not replace the current review. Two additional unit tests cover empty-field merging and default-versus-existing portions.

## Cross-platform imports — November 4, 2026

Run the full Sazli scheme on iPhone 17 Pro / iOS 26.5. The suite contains 66 tests, including YouTubeRecipeTests, RecipeImportRoutingTests, and ChatGPTPublicTranscriptTests. These cover URL variants and rejection, title/JSON escaping, Spanish servings/equipment, longer method headings, the word ingredients inside a cooking step, partial/mixed descriptions, source selection, recipe-text priority, public assistant visibility/completion, and cover association. Network-dependent diagnostics are separate and are not retained as permanent tests.

For manual acceptance, use the public links in [IMPORT_AUDIT.md](IMPORT_AUDIT.md) through both library import and Original source → Import recipe details. Confirm notices survive into the editor; existing text and photos survive source imports; changing/canceling requests cannot apply stale results. Save only intentionally created test recipes, reopen offline, and check the same UUID/text/photo. Repeat through the configured share shortcut. Live fetches and parser tests do not replace interactive device acceptance.

## Caption punctuation and heading simulations

See [CAPTION_COMBINATION_AUDIT.md](CAPTION_COMBINATION_AUDIT.md) for 1,363 constructed scenarios and their breakdown. TikTokCaptionFormatTests compares exact ingredient and method arrays across headings, marker forms, punctuation and Unicode spacing, with deliberate unstructured controls. RecipeImportRoutingTests checks that alternate first-line section headings survive actual paste routing, with source links and optional titles preserved. The full native suite now has 72 passing tests; scenario counts are not XCTest method counts. Manual source-field acceptance still requires Import recipe details, review and explicit Save.

## Recipe integrity regressions

The 79-test suite additionally covers the exact Cajun TikTok caption (14 ingredients / 8 steps), spaced ranges with three dash forms, explicit-bullet numeric weight qualifiers, ChatGPT numbered Markdown step headings with continuation paragraphs, title preservation over five newline forms and three title decorations, and real ingredient rows with group-like prefixes. Test the Cajun short link from the library and Original source → Import recipe details. Check Parmesan's comma qualifier, the unquantified herbs/oil/seasoning rows, and the eight numbered actions. Source imports preserve existing fields; clear an intentionally incorrect manually filled field before reimporting, or review the original caption in the editor. No changes persist before Save.

## Direct share-sheet acceptance

On the destination iPhone, use ChatGPT's system Share sheet and choose Sazli (enable it in More if needed). Send a public conversation link, tap Add to imports/Done, then open Sazli and review/save. Repeat with selected recipe text and with a TikTok/YouTube URL. Test Sazli initially closed and already running; cancel before sending (no inbox entry), cancel recipe review after sending (pending retained), retry after reopening, and save once (no duplicate). Existing personal recipes and an already-open editor must remain intact. Images/files alone must not be offered as supported imports.

ShareImportTests covers native NSURL/NSString providers, duplicate text, unsafe file URLs, empty/oversized data, durable handoff, interrupted-copy recovery with the same UUID, malformed shared files retaining private imports, capacity/backpressure, and filename identity validation. The permanent full suite has 86 tests. These provider/store tests do not certify ChatGPT's actual current share menu or replace interactive physical-device acceptance.

## Instagram and cross-platform format controls

The full suite now has 90 tests. CrossPlatformImportTests adds 21 synthetic document controls across TikTok/YouTube/Instagram, four ChatGPT heading/table variants, source/entity/identity checks and malformed/unsupported table controls. Check real Instagram sample outcomes in IMPORT_AUDIT.md. On the phone, try a public Instagram Reel through both direct sharing and Original source → Import recipe details; verify the source, optional cover, ingredient quantities and method counts before Save. Login/private/unavailable pages should offer fallback. Interactive device acceptance remains distinct from native provider/parser tests and Mac snapshot probes.

## Recipes with all-caps ingredient groups

The Kookmutsjes Crunchwrap URL in IMPORT_AUDIT.md should produce 14 checklist ingredient items and 20 written-sentence actions. Verify measures such as `1½ tbsp (25 ml)` and the separate tortilla/sauce/cheese rows. Group names stay in editable source text but are omitted from ingredient checklists/counts. Import through Original source → Import recipe details, review, Save, and reopen. If an older TikTok recipe has only the full caption in its description with both sections empty, Edit can propose the recovered sections; canceling must leave the stored recipe unchanged. The full suite now has 93 tests including exact-caption save/reopen in an isolated store and sentence-range/decimal controls.

## Numbered recipes without section headings

The Marisa Kapeal TikTok in IMPORT_AUDIT.md should populate 25 ingredient checklist rows and 7 original numbered actions. Verify pasta's `8–10 oz — 225–285 g` equivalent remains one item, decimal gram values are intact, title-case subgroup names are hidden from ingredient counts, and the website/bio notice belongs to the description. Reimport through the original source button or direct sharing, review, Save and reopen. The 96-test suite includes exact-caption isolated disk persistence, four bullet-marker controls and deliberately non-recipe prose.

## Large structural robustness matrices

See [ROBUSTNESS_AUDIT.md](ROBUSTNESS_AUDIT.md) for 6,674 additional deterministic scenarios and exact counts. RecipeRobustnessTests exercises headerless/grouped formats, quantities, delimiters, equivalents, food-name preservation, false-positive controls, first-line routing and implicit public-assistant structures. CrossPlatformImportTests repeats ordered formats through all three public description adapters. The full suite now has 104 tests; scenario counts are not method counts. The standalone persistence script includes current parser dependencies and passed its six isolated store phases.
