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
