# Importing recipes

Sazli accepts recipe text and original links locally. Supported public ChatGPT share pages and TikTok/YouTube video descriptions can also be read directly on the iPhone. It does not connect to private accounts, transcribe videos, or extract arbitrary webpages. No API key or backend is required.

## Paste from ChatGPT and other apps

1. Copy the recipe response or the original link in the source app.
2. In Sazli's library, tap the import icon (a downward arrow into a square).
3. Paste the text or link. For text without a link, choose the source platform yourself.
4. Tap **Review recipe**. Check the name, ingredients, method, time, servings, source, and optional photo in the normal editor.
5. Tap **Save**. The recipe is stored in the existing SwiftData library and opens in the detail pane.

Copying the full ChatGPT recipe text imports its ingredients and steps when it has recognizable headings. A supported public ChatGPT share link starts the on-device reader described below. Private or unreadable links can still be kept as references. Supported TikTok and YouTube video links start a description reader. Facebook and other links are retained as references with empty ingredients and steps until you provide them. Photos can be added in the review editor.

## Read a public ChatGPT conversation

Paste an HTTPS `chatgpt.com/share/<UUID>` link and tap **Review**, or send it through the configured **Send to Sazli** shortcut. Pending share links automatically start the reader. An isolated, nonpersistent WebKit session loads the public page directly on the phone; no ChatGPT account, OpenAI API key, or Sazli server is used.

The reader decodes the page's embedded conversation data and keeps only finalized assistant text addressed to the user. It excludes user prompts, tool output, analysis, and explicitly hidden messages. The extractor offers complete recipes with explicit ingredient and method sections, newest first. If a conversation contains multiple recipes, choose one. Later follow-up advice is not automatically merged into the selected recipe. Review the populated fields in the normal editor and save to the existing SwiftData library.

The extractor removes presentation-only image/component markup, joins numbered step titles with their paragraph text, recognizes explicit time/serving metadata, and retains other recipe text in the description. It accepts ingredient headings with explicit portions, such as `Ingredientes (2 personas)`, and recipe titles written as Markdown, styled text, or bold text inside an introduction. If no explicit title is present, the review uses `Recipe from ChatGPT`. Inline tips stay in the description rather than joining the last cooking step. Ranges such as `25–30 min` or `2–3 porciones` remain unguessed. It keeps the shared conversation as the original source. An accessible cover photo can be imported from the chosen assistant message’s explicit image-component metadata. The editor downloads it when reviewing the recipe, converts it to a local JPEG with the existing photo preparation service, and lets you replace, remove, or skip it. Step images, user attachments, hidden messages, page banners, and social-preview images are not used. Personal ratings and later conversation changes are not automatically imported. Missing details remain available to complete in the editor.

This is a best-effort adapter to a public website, not a supported ChatGPT history API. The website's embedded format can change. Pages requiring login, removed links, browser challenges, network failures, or conversations without complete explicit recipes produce an explanation and a **Keep the link only** fallback. Reading requires internet; saved recipes remain available offline. The browser does not use the user's Safari cookies or attempt to sign in. Facebook and arbitrary webpages remain reference-only imports.

## Recipe photos from public shares

Photo import is optional and best effort. The adapter currently recognizes public `async_image` components and their explicit OpenAI-hosted image URLs. It associates a cover before the ingredient section with that recipe, without borrowing pictures from another message. Ambiguous images in a message containing multiple recipes are left for manual selection through Photos. Image-only generated outputs or private file pointers without an exposed supported image URL are not automatically resolved.

The downloader uses an ephemeral session without account cookies or credentials, permits only supported HTTPS image hosts (including redirects), accepts successful image responses up to 12 MB, and tries at most two URLs. Images are prepared off the main thread and stored through the existing recipe `imageData`. Downloads have timeouts; **Continue without imported photo** cancels the editor request. A failed/unavailable photo shows an explanation and keeps text import available. Nothing is saved until **Save**. Images shown by ChatGPT may come from search; Sazli does not claim that an imported photo was AI generated or create a replacement image.

## TikTok video descriptions

Paste a supported public `vt.tiktok.com` / `vm.tiktok.com` short link or `tiktok.com/@creator/video/<id>` link and tap **Review**. Sazli resolves public TikTok redirects in a temporary native session and reads the caption from the page’s embedded video record. Shortcuts imports of these links enter the same reader. There is no account access or backend.

Explicit caption sections, including `WHAT YOU’LL NEED`, `INGREDIENTS` / `INGREDIENTES`, `METHOD` / `PREPARACIÓN`, inline bullets (including asterisks), numbered steps, and `SERVES` / `PORCIONES`, are normalized for review. Ingredient/method headings may omit the colon when immediately followed by an explicit list or written on a standalone line. Markdown/emoji heading decorations, checkmark bullets, keycap step numbers, and Spanish Procedimiento/Elaboración/Paso a paso labels are supported; ordinary prose mentioning ingredients or instructions remains in the description. Explicit nutrition/macro/tip footers and trailing hashtag/emoji blocks stay in the description rather than the final cooking step. See the [caption format audit](TIKTOK_FORMAT_AUDIT.md) for tested formats and limits. Nutrition and creator/original-recipe credits stay in the description. Cooking durations inside steps are preserved as written and are not assumed to be total preparation time. Missing ingredients/steps remain empty; a caption without a clear recipe title uses the editable name **Recipe from TikTok**.

The editor attempts to import the public video cover through the shared bounded image downloader. A video cover can show its creator rather than the finished dish; you can remove, replace, or skip it. The original pasted URL is retained even after short-link resolution. No video/audio, subtitles, on-screen text, or comments are downloaded or interpreted. Private/deleted/blocked pages offer retry, description paste, and link-only alternatives. This website adapter depends on TikTok’s public page format and availability; it cannot guarantee every video will import.

### Import from Original source while editing

You can also paste a supported TikTok, YouTube, or public ChatGPT link into **Original source** in **New recipe** or **Edit recipe**, then tap **Import recipe details** directly below the link. This uses the corresponding public reader (with recipe selection for ChatGPT) and fills empty title, description, ingredient, method, and time fields in the current draft. Default portions can be filled for a new recipe; existing/edited portions are preserved. Existing text and photos remain in place. An available cover is attempted only when no photo has been chosen. The editor shows ingredient/step counts after reading; review the fields and choose **Save** to persist them. Changing the source link or dismissing the editor cancels pending results, and cover loading can be skipped. Pasting a link alone remains suitable for saving a reference without fetching details.

### Recover a recipe saved entirely in the description

For a TikTok recipe with a supported original video link, opening **Edit** also checks for explicit recipe sections when both ingredients and method are empty. If both sections can be recovered, the editor proposes them separately and shows a review notice. Creator credits remain in the description. The saved recipe changes only when you choose **Save**; canceling keeps the existing stored text. Personal title, time, servings, category, photo, notes, ratings, and favorites are preserved. Already structured or manually edited ingredient/method fields, incomplete captions, and non-TikTok drafts are left as entered. This recovery also applies to imported drafts presented to the editor.

## Receive content from the iOS share sheet

The app exposes a native **Import recipe** App Intent. To use it from another app:

1. Open Apple's **Shortcuts** app and create **Send to Sazli**.
2. Open the shortcut's Details and enable **Show in Share Sheet**.
3. Configure the shortcut to accept **Text** and **URLs**.
4. Add **Sazli → Import recipe**.
5. Set its **Recipe text or link** parameter to **Shortcut Input**.
6. Save. In another app's system share sheet, choose **Send to Sazli**.

Sazli opens with the received text ready to review. The shortcut is configured once on each device; it is not automatically installed by Sazli. Some apps first show their own sharing menu; use their system share option or copy the link instead. The action receives the data that the source app supplies, not access to the user's account.

[Apple's App Intents documentation](https://developer.apple.com/documentation/appintents/appintent) describes exposing native actions to Shortcuts. [Apple's Shortcuts guide](https://support.apple.com/guide/shortcuts/launch-a-shortcut-from-another-app-apd163eb9f95/ios) describes running shortcuts from other apps.

This implementation uses a foreground intent in the main app and a private inbox, with no Share Extension or App Group. It preserves the current development team's signing configuration and existing recipe store. The **Sazli** app does not automatically appear as its own share-extension tile: **Send to Sazli** appears as a shortcut after the setup above.

## Parsing and recovery

- Recognizes explicit English and Spanish ingredient/method headings, including common Markdown heading and bullet forms.
- Reads preparation time only when a supported minutes unit is explicit, and servings only when an explicit supported integer is supplied.
- Keeps unrecognized content in the description. Without section headings, it does not guess which lines are ingredients or cooking steps.
- Detects known platforms by host boundaries and retains the original HTTP(S) URL. Unknown hosts are Web; text without a link defaults to Manual.
- Reads supported public ChatGPT share pages and TikTok/YouTube descriptions. Does not transcribe, infer quantities, generate recipes, or extract arbitrary websites.
- Limits each input to 200 KB and the pending inbox to 20 recipes.
- Keeps shared text in atomic JSON files in the app's private Application Support directory until a recipe is successfully saved or the user explicitly discards the import. Closing a pending import keeps its original text, rather than saving changes made during review.
- Uses the import UUID as the new recipe UUID, preventing a duplicate if the app stops between saving a recipe and acknowledging its inbox entry. Existing recipe edits are preserved on retry.
- Reports unreadable pending files without deleting them. The existing SwiftData store is neither moved nor replaced.

## Verification checklist

- Paste an English or Spanish recipe with Ingredients/Ingredientes and Instructions/Preparación headings; review, edit, save, and reopen it.
- Send a public ChatGPT share link; check the recipe choices, extracted fields, source URL, and review/cancel/save behavior. Paste TikTok/YouTube video URLs and check their description review; Facebook and arbitrary web links should remain references.
- Cancel review: no recipe should be inserted. Close a pending shared import and reopen the app: its original text should remain available.
- Create the shortcut on the destination iPhone. Share a public link through the system share sheet and confirm Sazli receives it; repeat with selected recipe text. Receiving behavior depends on the source app's supplied share content.
- Test with Sazli closed and with Sazli already open. Review and save once, then restart and confirm there is no second copy.

Automated coverage exercises bilingual parsing, link-only behavior, unsafe URL rejection, unknown text preservation, input limits, inbox reopening, failed validation, save-before-acknowledgement interruption, and malformed-file retention. See [verification](VERIFICATION.md) for what has actually run in this environment.

## YouTube descriptions and share routing

Supported HTTPS watch, youtu.be, Shorts, live, and embed URLs identify one video. The reader fetches its public watch page without account cookies, reads the matching playable video record as inert JSON, and keeps the original pasted URL. It does not download audio, subtitles, or the video. An available thumbnail can be skipped or replaced.

Explicit English/Spanish ingredient and method headings populate separate fields. Equipment, tips, and unrecognized text stay in the description. Missing methods remain empty. If an unlabeled ingredient section mixes several cooking directions, the original description remains available for manual organization. Partial/mixed results carry a notice into the review editor. No recipe is stored before Save.

Bare supported links and short recognized share wrappers use the same router in the library and pending inbox. Complete pasted recipe text takes priority over a link inside it. Multiple links and unrecognized prose remain editable text instead of silently choosing a source. Public ChatGPT pages support both the legacy embedded reference table and the newer public mobile transcript; only complete visible assistant responses are candidates. See [audit results](IMPORT_AUDIT.md).
