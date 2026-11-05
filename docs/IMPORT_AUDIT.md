# Cross-platform import audit

Date: November 4, 2026. This is a focused sample, not a guarantee of availability across every region or account.

## Public samples

Ten distinct public URLs were requested. TikTok/YouTube results below use actual downloaded public HTML processed by production parsers. ChatGPT results distinguish browser loading from raw HTTP metadata: HTTP 200 alone did not mean a conversation was available.

| Sample | Public link | Observed result after fixes |
| --- | --- | --- |
| tiktok-taco | [Open source](https://www.tiktok.com/@thesimplecravings/video/7694085059602550030) | 9 ingredient rows / 7 method rows from the public caption. |
| tiktok-gnocchi | [Open source](https://vt.tiktok.com/ZSpRSQuyw/) | 12 ingredient rows / 3 method rows / 4 servings; original short link retained. |
| tiktok-short-caption | [Open source](https://www.tiktok.com/@fitwaffle/video/6991489949828648198) | Caption lacks explicit recipe sections; retained for manual completion. |
| youtube-user | [Open source](https://www.youtube.com/watch?v=o-jXn6P-4rM) | 14 ingredient rows (including group labels), 2 servings, no written method; equipment retained in description. |
| youtube-pasta | [Open source](https://www.youtube.com/watch?v=r9RlhEIcNYY) | 25 ingredient-section rows / 33 method-section rows from English sections; group labels and repeated seasoning lines retained as written. Arabic/unrecognized text remains in description. Review grouping manually. |
| youtube-chicken | [Open source](https://www.youtube.com/watch?v=POENEyhCmaA) | Unlabeled mixed ingredients/directions: original description retained with a manual-organization notice. |
| chatgpt-tuna | [Open source](https://chatgpt.com/share/6ae7d243-9704-83e9-aa7d-5db0d563bae3) | Live native WebKit: 2 recipe candidates. |
| chatgpt-chicken | [Open source](https://chatgpt.com/share/6ae9a2ef-d8ec-83e9-8417-ab10621b8705?ogimg=plain) | Initial live WebKit: failed on the newer mobile transcript; captured public document now yields 2 candidates (8/5 and 9/4 ingredient/method rows), with 2 cover URL alternatives each. Subsequent live WebKit request also yielded 2 candidates. |
| chatgpt-bread | [Open source](https://chatgpt.com/share/6adb32cd-eea4-83ec-8266-3aaff6703ded) | Live native WebKit: 1 recipe candidate. |
| chatgpt-legacy | [Open source](https://chatgpt.com/share/67d6e91f-b17c-800f-8745-13428b2acee4) | Public response HTTP 404; unavailable fallback, not a successful recipe import. |

Counts describe nonempty parsed rows, not inferred ingredients or semantic steps. Multiline spice lists inside a written method stay as supplied; the importer does not infer grouping or translate Arabic. An optional YouTube thumbnail or TikTok cover may show a creator rather than the final dish.

## Problems fixed

- YouTube previously remained reference-only. Its public description and thumbnail now enter the same review workflow as TikTok, including source-field imports.
- Library paste and pending-inbox routing differed. One router now handles supported bare links, bounded recognized share wrappers, and recipe text containing links. Recipe text takes priority; ambiguous inputs remain editable.
- Long method headings, Spanish portions, equipment footers, and no-space ingredient bullets were missed. Shared normalization now recognizes them. An occurrence of “ingredients:” inside a method no longer resets the section.
- Partial and mixed descriptions could appear fully imported. Notices now remain visible inside the editor; missing sections remain empty, and deliberately mixed unlabeled captions are preserved for manual organization.
- One supplied ChatGPT share used the newer public mobile transcript, which the legacy adapter could not read. A bounded inert-JSON adapter now reads complete visible assistant responses and supported unambiguous image metadata. The legacy adapter also accepts complete messages with absent channel metadata while excluding analysis/incomplete responses.
- Equivalent validated public-share paths no longer fail navigation checks due only to trailing slashes/aliases. Supported clipboard wrappers and edge invisible characters are normalized.
- Original source now offers the matching reader for TikTok, YouTube, and public ChatGPT. Selected ChatGPT candidates merge into the current value draft; existing fields are preserved and no second recipe is inserted before Save.

## Verification evidence

- Xcode 27.2, iPhone 17 Pro / iOS 26.5: **66 permanent XCTest tests passed, 0 failures**. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_17-13-02--0500.xcresult`.
- Signed generic iOS Release build passed, including the existing Live Activity extension.
- Separate production native Foundation fetching exercised the three YouTube videos using watch, youtu.be, and Shorts URL forms, plus the TikTok short link. A YouTube image download produced 71,781 bytes of prepared image data. These probes use a value-only draft projection, not the personal recipe store.
- Separate native simulator WebKit diagnostics loaded the three available ChatGPT shares. The initial chicken failure was investigated using only the test browser's public HTML. Its newer mobile-format snapshot then produced two complete recipes using the corrected production adapter; another live request also returned two. Provider page variants can differ between requests. The temporary network-dependent tests were removed from the permanent suite.
- The final production parser was rerun against the captured mobile transcript and bilingual YouTube pasta page after the method-header fix.
- No personal recipe database was extracted or changed. No backend, API key, account connection, audio/video extraction, or generated recipe content was introduced.

The first WebKit test attempt could not start SpringBoard. Restarting only the isolated test simulator allowed the diagnostics to run; the blocked attempt is not counted as a pass. Computer-use surfaces were unavailable, so interactive tapping, editor presentation, share-sheet delivery, and save/reopen acceptance for each new link remain manual checks. Existing automated isolated-store persistence tests passed; this does not claim every sample was saved to the personal phone.

Local diagnostic logs: `/private/tmp/sazli-cross-import-tests-complete.log`, `/private/tmp/sazli-cross-import-release.log`, `/private/tmp/sazli-live-video-audit.log`, `/private/tmp/sazli-public-share-browser-audit-retry.log`, `/private/tmp/sazli-public-share-chicken-diagnostic.log`, and `/private/tmp/sazli-public-share-chicken-after.log`. Raw public pages and temporary probes remain outside the repository. No commits or push were performed.

The final signed Release build, including the updated import help and Shortcuts action description, passed (`/private/tmp/sazli-cross-import-release-final.log`). devicectl confirmed installation on the physical iPhone 15 with existing app data preserved. Interactive acceptance remains separate from installation.

## Grouped chipotle pasta follow-up — November 4, 2026

The reported [short link](https://vt.tiktok.com/ZSpFB66ns/) resolves to [the sapor's chipotle chicken pasta](https://www.tiktok.com/@thesapor/video/7695883596913003789). The public caption flattens `Ingredients Chicken - …` and `Instructions Chicken - …` onto one line. The existing heading boundary required a colon, newline, or immediate list marker, so both sections stayed in the description. This was a parser limitation, not missing source content.

RecipeCaptionParser now recognizes a bounded short group label before a bullet only when both ordered ingredient and method headings are present. Explicit common subgroup labels are separated; method groups are attached to their first action rather than becoming empty cooking steps. The existing no-space `-Add` marker is retained as an action, and decorative trailing bullet separators are removed from the method. Amounts, temperatures, optional ingredients, source link, hashtags, and creator credit remain as written. The captured public page yields **35 ingredient items plus 3 group labels (38 rows), and 11 method steps**.

Two regression tests cover the exact caption through the production document parser, empty-field source merging, description-only recovery, preservation of a personal title/credits/source, and an unpaired group heading that must remain unclassified. Native XCTest on iPhone 17 Pro / iOS 26.5: **68 tests passed, 0 failures**. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_20-23-28--0500.xcresult`. Signed Release build passed. Logs: `/private/tmp/sazli-grouped-tiktok-tests.log` and `/private/tmp/sazli-grouped-tiktok-release.log`. Source-field UI acceptance remains manual; paste the link and tap **Import recipe details**, review, then Save. Previously saved description-only TikTok recipes propose recovered fields on Edit without changing storage before Save.

The first device-install attempt failed with CoreDevice error 4000 / connection reset by peer; that attempt is not counted as a successful installation. No commits or push were performed for this follow-up.

A separate live native Foundation probe using the production TikTok reader also fetched the exact short link successfully and returned 38 ingredient rows / 11 steps. It uses a value-only draft projection and does not access the personal library. Log: `/private/tmp/sazli-grouped-caption-live.log`.

After the device connection recovered, devicectl confirmed successful installation of the final signed update on iPhone 15. Existing app data was preserved; interactive import/save acceptance remains manual.

## Recipe integrity and Cajun pasta — November 4, 2026

The supplied [TikTok short link](https://vt.tiktok.com/ZSpFyLctE/) resolves to [Hope Crosby's creamy Cajun chicken pasta](https://www.tiktok.com/@hopecrosby_eatss/video/7699566942000123168). Its public description contains the full recipe, but ingredients have neither bullets nor line breaks: `Ingredients 2 chicken breasts 140g pasta … Method 1. …`. The previous heading rule missed Ingredients while still recognizing the numbered method.

The shared reader now accepts this quantified ingredient heading only when a supported explicit method follows it. In that bounded ingredient section, repeated spacing separates rows and explicit numeric quantities can separate a flattened list. Unquantified items with explicit double-space separation remain intact. The exact caption produces **14 ingredients / 8 method steps**, including Fresh parsley, Olive oil, Salt and pepper, and `50g Parmesan, grated`. Temperatures, duration ranges, source URL and creator credit remain available. The exact document regression also checks empty-field source merging and preservation of a personal title. A prose control without an explicit method remains unstructured.

Additional integrity bugs reproduced and fixed:

- Spaced ranges such as `1 - 2 eggs` and `Rest 4 – 5 minutes` were mistaken for list bullets. Numeric range separators are now retained within the same row/action.
- A comma followed by a numeric weight inside an explicit bullet (`1 onion, 150 g total`) could incorrectly create a second ingredient. Explicit list boundaries now take priority over comma-based splitting.
- Public ChatGPT recipe methods written as numbered Markdown headings (`### 1. Mix` / `### 2.Cook`) could be moved to notes, rejecting a complete recipe or losing steps. The extractor recognizes these numbered headings and joins each following cooking paragraph; subsequent unrelated notes remain separate.
- Pasted titles could be lost with Markdown decoration, CR-only or Unicode line separators. The actual import router now preserves the title across those formats.
- The ingredient display filter could hide a real prefixed item such as `For the sauce: 2 tbsp oil:`. Group-prefix suppression now preserves rows containing an internal colon or quantity.

New fixtures first reproduced these failures in the baseline run. The full corrected native suite passed **79 tests, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_21-01-49--0500.xcresult`. Logs: `/private/tmp/sazli-recipe-integrity-before.log` and `/private/tmp/sazli-recipe-integrity-after.log`. Existing format combinations, public-share filtering/photos, save/reopen, timers and recipe actions passed as part of the suite.

These are explicit text boundaries, not semantic recipe inference. Ambiguous unquantified inline prose remains for review. Existing/manual fields are preserved on source import, and saving still requires Save. No personal recipe was modified and no commits/push were made for this follow-up. Interactive source-field acceptance is separate from parser and merge tests.

A separate live native Foundation probe using the production TikTok reader successfully fetched the exact Cajun short link and verified 14 ingredients, 8 steps, the original source URL and `50g Parmesan, grated`. It uses a value-only draft projection and does not access the personal library. Log: `/private/tmp/sazli-cajun-live-audit.log`. The final signed iOS Release build passed, including the Live Activity extension (`/private/tmp/sazli-recipe-integrity-release.log`).

Devicectl confirmed successful installation of the final signed update on the physical iPhone 15 with existing app data preserved. No public sample was saved or modified in the personal library. Source-field visual/save acceptance remains manual.

## Instagram and additional cross-platform formats — November 4, 2026

Added an on-device reader for public Instagram post/Reel captions. Previously Instagram URLs were classified as Web references. Supported HTTPS `/p/`, `/reel/`, `/reels/`, and `/tv/` links now identify Instagram and enter the existing public-description review from library paste, Original source, or direct share delivery. Unsupported/private routes remain references. The persisted platform is still a raw string; no SwiftData migration is needed.

The reader uses a bounded 4 MB ephemeral native request with no account cookies/credentials, validates redirects and canonical post identity, and reads exposed description/cover metadata as inert HTML attributes. Numeric/named HTML entities are decoded once. A recognized engagement wrapper is removed without inventing caption content. Available cover URLs use the existing bounded downloader with Instagram CDN host checks. Login/unavailable/mismatched pages retain retry/text/link-only alternatives; partial captions have a review notice. This is a public-page adapter, not account integration or video extraction.

### Public sample observations

| Source | Evidence in this round | Result |
| --- | --- | --- |
| [Instagram carbonara](https://www.instagram.com/reel/C3DxXB-KVno/) | Fresh public HTML and a live native request with the production reader | 5 ingredient rows / 4 numbered steps; cover candidate and original URL retained |
| [Instagram wrap](https://www.instagram.com/p/DbyCp--A0sF/) | Fresh public HTML through the production document parser | 4 ingredient rows / 4 method paragraphs; canonical Reel alias accepted for the same post |
| [Instagram unavailable sample](https://www.instagram.com/p/DcyRpLQudxf/) | Fresh HTTP 200 page without usable public post metadata | Unavailable fallback; not counted as a successful recipe import |
| [TikTok Cajun pasta](https://vt.tiktok.com/ZSpFyLctE/) | Refreshed public HTML through the corrected production parser | 14 ingredient rows / 8 steps |
| [YouTube bilingual pasta](https://www.youtube.com/watch?v=r9RlhEIcNYY) | Refreshed public HTML through the corrected production parser | 25 ingredient-section rows / 33 method-section rows, including original group/seasoning lines |
| ChatGPT public transcripts retained from the earlier audit | Previously captured public mobile and legacy documents through current production extractors | 2 recipes each: 8/5 and 9/4 rows; 7/4 and 6/5 rows respectively. No new live ChatGPT browser run is claimed for this round. |

### Reproduced format failures and fixes

- Recognized ingredient/quantity Markdown tables now become individual ingredient rows, including supported optional Notes columns. Unknown columns, malformed cells or escaped-pipe ambiguity stay editable instead of dropping content.
- The caption footer normalizer previously interpreted a table's Notes column as the end of ingredients. Table regions are now protected from footer recognition.
- Flat ingredient lists beginning with Unicode fractions or mixed fractions (`½`, `1 1/2`, `1½`) were missed. Bounded explicit quantity recognition now includes these forms while retaining existing numeric/range controls.
- Prefix portion labels such as Ingredients (serves 2) now populate explicit metadata. Unsupported ranges remain in the description and do not produce an estimated serving count.
- ChatGPT recipe headings with leading/trailing emojis, ingredient-list aliases and supported portion variants now remain recognizable. Existing complete/visible assistant-message filtering and photo association remain in place.
- A real Instagram caption revealed that a sentence dash inside a numbered method was creating a fifth step from the author's four steps. Numbered/lettered methods now preserve in-sentence dashes while dash-bulleted lists remain supported.
- Named Top Tip footers now stay in the description without leaving the author's name attached to the last cooking action.

CrossPlatformImportTests exercises seven constructed caption formats through TikTok, YouTube and Instagram documents (21 document controls), four ChatGPT heading/table variants, public-link routing/identity/entity handling, partial/unavailable sources and malformed-table preservation. These controls are synthetic, not 21 additionally downloaded posts. The existing 1,363 format scenarios and recipe/share/store regressions remain part of the full suite.

Final native XCTest: **90 tests passed, 0 failures**, Xcode 27.2, iPhone 17 Pro / iOS 26.5. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_21-53-10--0500.xcresult`. The baseline failed on the unsupported formats, and an intermediate run exposed the Notes-column collision; only the final corrected run is counted as passing. Signed generic iOS Release build passed, including both extensions. The Xcode project plist validated.

Logs: `/private/tmp/sazli-cross-platform-round2-{before,after,verified}.log`, `/private/tmp/sazli-cross-platform-round2-release-final.log`, `/private/tmp/sazli-round2-instagram-native-final.log`, and `/private/tmp/sazli-round2-other-sources.log`. Native command-line probes use a value-only draft projection, not the personal library. Interactive on-phone imports/save, regional availability and source-app share-sheet delivery remain manual acceptance. No personal recipes were extracted or modified; no commits or push were made.

Devicectl confirmed successful installation of the final signed update on the physical iPhone 15. Existing app data was preserved; no public test recipe was inserted into the personal library. Interactive on-phone review/save for the new Instagram entry path remains manual acceptance.

## Crunchwraps without an Ingredients heading — November 4, 2026

The reported [Kookmutsjes TikTok](https://www.tiktok.com/@kookmutsjes/video/7701715089908370721?_r=1&_t=ZS-9B8lyH984He) exposes a complete public caption. It uses BEEF FILLING, WRAPS and CHEESE CRUST instead of an Ingredients heading, and its Instructions paragraph has no numbered/bulleted steps. The previous parser left this unsupported format in the description. This reproduces a parsing failure, not a reproduced failure of SwiftData Save.

RecipeGroupedCaption now recognizes this bounded shape only with at least two explicit all-caps quantity-led ingredient groups and a subsequent written method. Group labels are retained as editable Markdown headings and excluded from ingredient checklist/display counts. Quantity splitting skips values inside parentheses/brackets, so `1½ tbsp (25 ml)` and `1⅔ tsp (5 g)` stay intact. Parenthetical item boundaries preserve the source's separate tortilla, sauce and cheese entries without inventing ingredients. Unsupported unquantified text remains available for review.

For this previously unnumbered method, Foundation sentence boundaries produce separate written actions. Existing author-numbered/bulleted methods are retained. Decimal and duration-range controls prevent numeric punctuation from becoming false actions. The source yields **14 ingredient items and 20 written method sentences**; these are sentence boundaries, not an inferred reconstruction of the video. The original source link and hashtags/creator credit are retained. Source-field status counts now use the actual display/checklist ingredient count rather than counting hidden group headings.

Validation:

- A baseline fixture run reproduced the missing-fields failure. The exact-caption regression now verifies all fourteen ingredient strings, intact parenthetical metric measures, twenty methods, source identity, hashtag separation, and existing-title preservation.
- The regression also saves through RecipeStore into an isolated temporary SwiftData store, closes it and reopens it, verifying the saved title, original URL, 14 ingredients and 20 methods. No personal recipe data is used.
- Full native suite: **93 tests passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_22-14-00--0500.xcresult`.
- A separate live native probe with the production TikTok reader fetched the exact supplied URL and returned 14/20 with the source URL preserved. The command-line probe uses a value-only draft projection; the disk-save regression uses the real app model/services.
- Signed generic iOS Release build passed with both extensions; Xcode project plist validated. Interactive on-phone review/save remains manual acceptance.

Logs: `/private/tmp/sazli-crunchwrap-{before,tests-persistence,release,live}.log`. The new helper is registered in the existing app target; project signing, schema and the recipe-store location are unchanged. No personal recipe was inserted or modified. No commits or push were performed.

Devicectl confirmed installation of the final signed Crunchwrap fix on the physical iPhone 15, preserving existing app data. No test recipe was saved in the personal library.

## Lemon pasta without either section heading — November 4, 2026

The reported [Marisa Kapeal TikTok](https://www.tiktok.com/@marisakapeal/video/7689155950074170637?_r=1&_t=ZS-9B8mpk9Glc8) exposes a complete written recipe but no explicit Ingredients or Instructions label. It has quantity-led asterisk ingredients, title-case subgroups and a consecutive seven-step method. The previous parser left it in the description; a separate bullet-normalization bug could turn em-dash metric equivalents into extra ingredients.

RecipeBulletedCaption now recognizes this bounded written structure when there are at least two quantity-led bullet items before a consecutive numbered method starting at 1. Existing explicit section headings retain priority. The numbered method is retained as authored. Supported trailing culinary group labels are kept as editable headings and excluded from ingredient counts; source portion ranges remain unguessed in the description. Explicit website/link-in-bio notices stay in the description rather than the last cooking action. Inputs without sufficient quantity/step evidence remain editable and unstructured.

Ingredient bullets now take precedence over in-item dash conversions. Asterisks/checkmark/standard bullet lists retain internal dash equivalents; hyphen-bulleted lists retain Unicode em/en-dash equivalents. This preserves items such as `8–10 oz pasta of choice — 225–285 g`, decimal gram measures, optional qualifiers and commas as a single ingredient. The shared parser change also applies to supported YouTube/Instagram descriptions and pasted recipe text.

The exact source now yields **25 ingredient items and 7 author-numbered preparation steps**. The exact-caption fixture first reproduced the failure, then verifies all 25 ingredient strings, metric equivalents, decimals, safe temperature text, website/hashtag separation, original URL and unguessed portion ranges. It also saves through RecipeStore to an isolated SwiftData database and reopens it to verify 25/7/source preservation. Additional controls cover four bullet styles and prose that must remain unclassified. Existing Crunchwrap 14/20 and all prior imports remain in the regression suite.

Final native suite: **96 tests passed, 0 failures**, iPhone 17 Pro / iOS 26.5, Xcode 27.2. Result: `build/ActionTests/Logs/Test/Test-Sazli-2026.11.04_22-24-47--0500.xcresult`. Logs: `/private/tmp/sazli-lemon-pasta-before.log` and `/private/tmp/sazli-lemon-pasta-after.log`. Interactive on-phone review/save remains manual acceptance. No personal recipe data was extracted or changed; no commits/push were made.

A separate live native public-reader probe verified the exact supplied lemon-pasta URL with 25 ingredient items, 7 steps, preserved original source and intact metric/decimal items (`/private/tmp/sazli-lemon-pasta-live.log`). The probe uses a value-only draft projection; the persistence regression uses the actual app model/services in a temporary store. Signed generic iOS Release build passed, including both extensions (`/private/tmp/sazli-lemon-pasta-release.log`); project plist validated.

Devicectl confirmed successful installation of the final signed lemon-pasta fix on the physical iPhone 15, preserving existing app data. No test recipe was inserted into the personal library. Interactive on-phone review/Save remains manual acceptance.
