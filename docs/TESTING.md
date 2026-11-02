# Testing Sazli

## Automated coverage

- `SazliTests`: URL/platform boundaries, unsafe and malformed links, minimal-recipe validation, newline presentation, disk-backed recipe lifecycle checks, bilingual import parsing, the App Intent handoff, and pending-inbox persistence/retry/failure behavior.
- `Scripts/check_persistence.sh`: compiles the real model/services and uses separate executable launches to verify durable create/edit/rate/favorite/photo/delete behavior. It also exercises link detection and draft validation.
- Xcode's `build-for-testing` action checks that the app and XCTest target compile together. Executing XCTest requires a bootable simulator or an appropriately signed physical device.

## Manual acceptance checklist

1. Launch a fresh install. Confirm a warm cream library, an empty state, no sample recipes, and an **Add a recipe** button.
2. Try saving an empty form. Confirm a clear validation message. Enter a title and a YouTube link, save, and confirm a real library card appears without invented ingredients or steps.
3. Force-quit and reopen Sazli. Confirm the recipe is still present. Open it and confirm the source link, title, and empty content prompts.
4. Edit the recipe. Add a description, ingredients on separate lines, preparation steps on separate lines, time, servings, category, and a photo. Save and reopen the app. Confirm all changes persist.
5. Enter invalid time, servings, and URL values in turn. Confirm saving reports the problem and retains the draft. Cancel a changed form and check the discard confirmation. Check interactive sheet dismissal does not silently lose changes.
6. Search using a title fragment and test every filter. Mark the recipe as a favorite, return to the library, and confirm it appears under **Favorites**. Remove the favorite and verify that filter updates.
7. Paste YouTube, TikTok, Facebook, ChatGPT, and generic web links. Confirm automatic platform suggestions. Confirm a host such as `youtube.com.example.org` is treated as Web. Choose a manual platform override and save it.
8. Use **Paste recipe text**. Paste multiline ingredients and append them to existing ingredients. Repeat with instructions and the description. Confirm no existing content disappears and each nonempty instruction line becomes a step.
9. Add a rating, note, and “would make again” preference. Relaunch and confirm persistence. Modify the rating, clear it, and verify notes can exist without a rating.
10. Start cooking. Move forward and backward, check the progress, open ingredients, and finish. Check a long step scrolls and starts at the top. Check a recipe with no steps explains why cooking is unavailable.
11. Set a short device Auto-Lock interval. Confirm the display stays awake in active cooking mode, and that normal locking returns after closing or backgrounding Sazli. Restore your original Auto-Lock setting afterward.
12. Test system, light, and dark appearances from Settings and verify the preference after relaunch. Check narrow and landscape iPhones, large accessibility text, VoiceOver, and Reduce Motion. Confirm no required action is clipped or unreachable.
13. Open the original link, then test saved recipes in airplane mode. Reading, editing, ratings, and cooking must work offline. An iCloud-only photo or external source link may require a connection.
14. Cancel deletion and confirm the recipe remains. Confirm deletion on a disposable test recipe, relaunch, and confirm it stays deleted.

For the refreshed cooking checklist, mark two ingredients prepared and confirm the count, progress bar, checkmarks, and strikethrough update. Fold Duo, open the ingredient sheet, and confirm the same selections. Uncheck one item there, unfold, and confirm the inline panel reflects the change while the current cooking step stays selected. Closing and reopening cooking should start a fresh checklist without changing the saved ingredient text.

## Import acceptance

Follow [the import guide](IMPORTING.md) to configure the share-sheet shortcut on the actual device. Exercise pasted ChatGPT recipe text, link-only imports from all supported platforms, review cancellation, failed saves, pending-inbox recovery after a cold launch, and a successful save with no duplicate after relaunch. Repeat sharing while another editor is open: the existing draft must stay intact and the shared import must remain pending. Check that Sazli receives only the data supplied by the source app and keeps unknown text rather than inventing missing details.

For the public ChatGPT reader, share a conversation with multiple recipes and later follow-up advice. Check that recipe choices stay separate, time and servings come only from explicit metadata, each numbered heading and paragraph becomes one cooking step, image/component markup never appears in the recipe, and later advice does not replace the chosen method. Cancel the browser/editor, try an offline/deleted/private link, and confirm the link-only fallback and pending inbox remain usable. Repeat with the source app's native share sheet on the physical iPhone; this is distinct from Safari simulator sharing.

## Release follow-up

Final device visual QA, branded icon/logo assets, localization, export/backup design, and App Store signing/distribution are separate from the local recipe-manager implementation. CloudKit, video transcription, general webpage extraction, and a dedicated Share Extension remain outside this implementation; native sharing currently uses the documented Shortcuts action. Supported public ChatGPT share pages use the local reader.
