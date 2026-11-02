# Importing recipes

Sazli accepts recipe text and original links locally. Supported public ChatGPT share pages can also be read directly on the iPhone. It does not connect to private accounts, transcribe videos, or extract arbitrary webpages. No API key or backend is required.

## Paste from ChatGPT and other apps

1. Copy the recipe response or the original link in the source app.
2. In Sazli's library, tap the import icon (a downward arrow into a square).
3. Paste the text or link. For text without a link, choose the source platform yourself.
4. Tap **Review recipe**. Check the name, ingredients, method, time, servings, source, and optional photo in the normal editor.
5. Tap **Save**. The recipe is stored in the existing SwiftData library and opens in the detail pane.

Copying the full ChatGPT recipe text imports its ingredients and steps when it has recognizable headings. A supported public ChatGPT share link starts the on-device reader described below. Private or unreadable links can still be kept as references. YouTube, TikTok, Facebook, and other links are retained as references with empty ingredients and steps until you provide them. Photos can be added in the review editor.

## Read a public ChatGPT conversation

Paste an HTTPS `chatgpt.com/share/<UUID>` link and tap **Review**, or send it through the configured **Send to Sazli** shortcut. Pending share links automatically start the reader. An isolated, nonpersistent WebKit session loads the public page directly on the phone; no ChatGPT account, OpenAI API key, or Sazli server is used.

The reader decodes the page's embedded conversation data and keeps only finalized assistant text addressed to the user. It excludes user prompts, tool output, analysis, and explicitly hidden messages. The extractor offers complete recipes with explicit ingredient and method sections, newest first. If a conversation contains multiple recipes, choose one. Later follow-up advice is not automatically merged into the selected recipe. Review the populated fields in the normal editor and save to the existing SwiftData library.

The extractor removes presentation-only image/component markup, joins numbered step titles with their paragraph text, recognizes explicit time/serving metadata, and retains other recipe text in the description. It keeps the shared conversation as the original source. Photos, personal ratings, and later conversation changes are not automatically imported. Missing details remain available to complete in the editor.

This is a best-effort adapter to a public website, not a supported ChatGPT history API. The website's embedded format can change. Pages requiring login, removed links, browser challenges, network failures, or conversations without complete explicit recipes produce an explanation and a **Keep the link only** fallback. Reading requires internet; saved recipes remain available offline. The browser does not use the user's Safari cookies or attempt to sign in. Other platforms remain reference-only imports.

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
- Reads supported public ChatGPT share pages only. Does not transcribe, infer quantities, generate recipes, or extract arbitrary websites.
- Limits each input to 200 KB and the pending inbox to 20 recipes.
- Keeps shared text in atomic JSON files in the app's private Application Support directory until a recipe is successfully saved or the user explicitly discards the import. Closing a pending import keeps its original text, rather than saving changes made during review.
- Uses the import UUID as the new recipe UUID, preventing a duplicate if the app stops between saving a recipe and acknowledging its inbox entry. Existing recipe edits are preserved on retry.
- Reports unreadable pending files without deleting them. The existing SwiftData store is neither moved nor replaced.

## Verification checklist

- Paste an English or Spanish recipe with Ingredients/Ingredientes and Instructions/Preparación headings; review, edit, save, and reopen it.
- Send a public ChatGPT share link; check the recipe choices, extracted fields, source URL, and review/cancel/save behavior. Paste URLs from the other supported platforms and check that they remain references with empty ingredient/method fields.
- Cancel review: no recipe should be inserted. Close a pending shared import and reopen the app: its original text should remain available.
- Create the shortcut on the destination iPhone. Share a public link through the system share sheet and confirm Sazli receives it; repeat with selected recipe text. Receiving behavior depends on the source app's supplied share content.
- Test with Sazli closed and with Sazli already open. Review and save once, then restart and confirm there is no second copy.

Automated coverage exercises bilingual parsing, link-only behavior, unsafe URL rejection, unknown text preservation, input limits, inbox reopening, failed validation, save-before-acknowledgement interruption, and malformed-file retention. See [verification](VERIFICATION.md) for what has actually run in this environment.
