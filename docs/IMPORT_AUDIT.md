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
