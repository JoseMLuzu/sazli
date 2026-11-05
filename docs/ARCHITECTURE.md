# Architecture

Sazli is a single native iPhone app with feature folders and small shared components. SwiftUI supplies navigation and state; SwiftData supplies durable local storage. There are no networking or package dependencies.

## Data flow

`SazliApp` creates one disk-backed `ModelContainer`, explicitly disables CloudKit, and supplies the container to the view hierarchy. If opening storage fails, the app displays a recoverable startup message without deleting or replacing existing data. Autosave is disabled on the app context so that writes happen at explicit user actions.

`LibraryView` observes persisted recipes with `@Query`, sorted newest first. `RecipeText.matchesSearch` trims surrounding whitespace and matches the entered phrase against either the recipe title or stored ingredient text, ignoring case and diacritics. It does not translate ingredients or infer missing content. Category and favorites filters apply to those results. No sample records are inserted at launch.

The library is the sidebar of a native `NavigationSplitView`. A UUID selection resolves the current recipe from all stored recipes, independently of the sidebar's current search/filter results. In expanded layouts, selecting a row updates the adjacent detail pane and highlights that row. Compact navigation uses the preferred compact column to show the selected recipe and offers the native back action. Opening or closing Duo retains that selection. Successful deletion clears it and returns compact navigation to the library; invalid selections are also cleared when the observed record identifiers change.

`RecipeEditorView` owns a `RecipeDraft`, populated from a recipe only when editing. Validation happens before any persistence mutation. `RecipeStore.save` creates or updates the model and explicitly saves the context. Save errors roll back the context while retaining the form draft for retry. Cancel and sheet dismissal protect unsaved form changes. Rating edits use separate draft state until Save as well.

Favorites, ratings, and deletion explicitly commit through `RecipeStore`. The context is shared and all storage actions run on the main actor. The app presents one editor at a time, so rollback does not discard another open editor's draft.

## Schema

`Recipe` stores `id`, `title`, `recipeDescription`, `ingredients`, `instructions`, `preparationTime`, `servings`, `category`, `imageData`, `sourceURL`, `sourcePlatform`, `rating`, `notes`, `wouldCookAgain`, `isFavorite`, `createdAt`, and `updatedAt`.

- `recipeDescription` is the description field; SwiftData's model macro rejects a stored property named `description`.
- A preparation time of zero means unspecified. A rating of zero means unrated; users select ratings from one through five and can clear them.
- Servings default to one. Validation accepts 1–999 servings and 0–10,080 minutes, with an empty time accepted.
- Raw strings keep category/platform persistence independent of enum representation changes. Unknown raw values have presentation fallbacks.
- Ingredient and instruction text is preserved as written. Presentation trims line edges and omits blank lines. Every remaining instruction line is one cooking step.
- The photo is optional and uses external storage. The photo processor honors orientation, limits decoding to 1,800 pixels on the longest side, re-encodes JPEG, and does not copy original metadata.
- Every persistent field has a default or is optional. There are no unique attributes or relationships. This reduces obstacles to future CloudKit support, but does not claim that sync or a migration is already implemented.

Add an explicit versioned schema and migration plan before shipping changes to an already distributed data model.

## Links and paste

`SourceLink` accepts only HTTP(S) links with a host and rejects credentials and whitespace. Bare website hosts receive an HTTPS prefix. Platform detection uses full domain boundaries, including subdomains, rather than searching the whole URL for platform names. Users can override the suggested platform.

The field-level text paste tool appends user-supplied text to a selected field. The separate `RecipeImportParser` conservatively recognizes explicit English/Spanish section headings and supported time/serving metadata, preserving unknown content in the description. `ImportRecipeView` opens a value-type draft in the existing editor for review. Text imports do not fetch URL content. Public ChatGPT share links are routed to a dedicated reader. The original URL is retained independently of ingredients and steps.

`ImportRecipeIntent` runs in the foreground in the main app and queues original text in `RecipeImportInbox`, a main-actor observable private inbox backed by atomic JSON files. The library observes pending arrivals and resumes them after launch. An inbox item is acknowledged only after a successful save or explicit discard. Imported recipes use the inbox UUID; `RecipeStore.save` recognizes retries and preserves an already saved recipe, covering interruptions between save and acknowledgement. The default SwiftData location and development signing settings are unchanged. There is no App Group, extension, backend, or credential storage. See [importing recipes](IMPORTING.md) for the one-time Shortcuts share-sheet setup and receiving limitations.

`ChatGPTShareWebView` uses a nonpersistent WebKit session to load only a validated public ChatGPT share URL. It blocks unrelated main-frame navigation and cancels work when dismissed. `ChatGPTShareDocument` decodes the embedded reference table as inert JSON, with size/index bounds and strict role/channel/recipient filtering; it does not execute extracted code or parse account history. `ChatGPTRecipeExtractor` selects explicit complete recipe sections, removes presentation markup, normalizes numbered steps, and reads explicit metadata. `ChatGPTShareImportView` lets users choose a recipe and opens the existing editor. Unsupported formats or loading failures retain the link-only fallback. This adapter relies on an observed public website format and needs maintenance if that format changes.

## Cooking and accessibility

Cooking mode scrolls large text per step, supports both directions, and exposes progress and ingredients. `CookingScreenSession` saves the previous system idle-timer value before keeping the display awake. It restores that value on disappearance and whenever the scene leaves the active state, then reacquires it on return.

`CookingTimerStore` owns one app-wide, device-local timer, separate from SwiftData and cooking-view lifetimes. A Codable snapshot in UserDefaults keeps an absolute deadline while running and a frozen remaining duration while paused. Expiry is calculated from the current date, including after suspension or relaunch; `TimelineView` only refreshes presentation. Explicit start/resume operations request notification authorization and schedule a single identifiable UserNotifications request. Pause/cancel remove pending and delivered alerts. Permission or scheduling failures retain the countdown and show a useful notice. A retained notification delegate presents Sazli's timer banner/sound in the foreground. Both the library and cooking observe the shared timer; changing a recipe or step does not replace it. No background mode, remote service, or recipe-schema change is required. See [cooking timer](COOKING_TIMER.md).

The production timer injects `CookingTimerLiveActivity`; test stores have no real activity adapter. Timer mutations serialize their asynchronous notification/activity work. A shared ActivityAttributes type carries only the timer identifier, bounded recipe title, step, phase, duration, deadline, and paused remainder into the embedded WidgetKit extension. The app checks native authorization and foreground availability before requesting an activity without a push token. Pause/resume update the existing activity; cancel/foreground expiry end it. A weak foreground expiry task and scene-activation reconciliation clean up completed/orphaned activities. Reconciliation alone does not recreate an activity dismissed by the user. System-rendered timer text and a stale date provide countdown/expiry presentation when the app cannot execute. There is no App Group, extension database access, remote push service, or background mode. The extension is a dependency of the app and is embedded by its copy phase; both keep iOS 17 as their deployment target.

Native fonts scale with Dynamic Type. Recipe metadata uses a vertical fallback when horizontal space is limited. Horizontal category chips remain scrollable. Buttons have accessible labels and rating controls expose selected stars. Step transitions respect Reduce Motion and move accessibility focus to the current step.

Native navigation traits control the library/detail split. The width of the detail pane controls whether its ingredient and method sections can also sit in parallel. Full-screen cooking uses two balanced, independently scrollable ingredient/step panels when space allows. Section accessibility containers preserve logical ingredient/method groups. Shared measurements live in `SazliLayout`; details and acceptance checks are documented in [adaptive layout](ADAPTIVE_LAYOUT.md).

## Visual system

The library options menu contains a persisted `RecipeSort` picker. Sorting applies after search and category/favorites filters, uses creation time for recency, puts unspecified preparation times last, and has deterministic title/date/UUID tie-breakers. `RecipeStore.duplicate` saves a new value-type draft with a fresh identity and a collision-free Copy suffix, retaining recipe content/photo/source and resetting personal history. The library selects the saved copy for review. `RecipeSharing` formats only existing recipe content and source into text; the detail menu presents it through native `ShareLink`, without sending personal notes, ratings, or photo data.

Color assets define the requested terracotta, coral, orange, olive, and cream palette, plus adaptive surfaces. Dark variants preserve warm contrast. SF Symbols represent UI actions and missing recipe images. The generated S-and-salt-shaker artwork is bundled as `BrandLogo` for the library and `AppIcon` for the Home Screen. The library uses a compact inline navigation bar with only the 36-point logo on the leading side, labeled Sazli for accessibility. A trailing plus opens the recipe editor; the ellipsis menu contains Import recipe and Settings. The stable Your recipes heading and result count precede a grouped search/filter area. Pending imports appear after these controls and before the photo grid. Cards overlay white titles on shaded photos, show servings/time in an adaptive cream badge, and retain favorite/rating indicators. Missing photos use a warm gradient and the category symbol.

`Components/RecipePresentation.swift` defines shared section headings, metadata tiles, numbered step cards, and subtle panel borders. Recipe detail follows a single reading order: photo, overview, ingredients/method, rating/notes, then source. Native typography and section headings replace repeated decorative labels, preparation/servings share one panel, and reading steps place the number beside the text. The same step-card component retains its enlarged presentation in cooking mode. The detail bar has a native back action, favorite, and an options menu for editing, ratings, and confirmed deletion. The bottom action starts cooking or opens the editor to add missing steps. No recipe text or quantities are inferred or rewritten for presentation.

`IngredientRow` is a reading row in recipe detail and an accessible check-off button in cooking mode. Cooking owns a session-only set of prepared ingredient indices. Its count/progress, inline panel, and ingredient sheet use that same state, including across folding and rotation. Leaving cooking starts a fresh checklist next time; it does not modify recipe contents or add persistent fields. Duplicate ingredient text still has independent rows because selection uses line indices.

## Display performance

RecipeThumbnail loads ImageIO thumbnails in a utility task, sized to the view and display scale (128-pixel buckets, up to the stored photo's 1800-pixel preparation limit). RecipeThumbnailCache keeps disposable decoded images in NSCache with a 40-entry limit and a 24 MiB cost target, including retained compressed data. These are advisory eviction limits, not a hard process-memory ceiling. Photo bytes validate each hit, so changing a photo under the same recipe ID cannot reuse an outdated cache entry. Metadata-only updates can reuse the image. Canceled view requests cannot replace the current image. Original photos and the SwiftData schema remain unchanged.

The library normalizes the search once, applies category filtering before text matching, and calculates one filtered/sorted result for its heading, empty state, and grid per content evaluation. Detail sections split ingredient/method text once per section evaluation, avoiding repeated line parsing in ingredient-row dividers. No persisted derived-data cache or search index is required.

## Optional public-share cover photos

ChatGPTShareDocument retains explicit public image-component metadata alongside each visible final assistant message. ChatGPTRecipeExtractor attaches supported cover URLs to SharedRecipeCandidate, outside the persisted model. Only the selected candidate is downloaded by RecipeEditorView. ChatGPTRecipePhoto bounds download size, validates supported HTTPS hosts/redirects and image responses, and prepares JPEG data through RecipePhoto off the main thread. The editor supports cancellation/skipping, missing-photo explanations, replacement/removal, and existing explicit save/discard behavior. Original URLs/cookies are not persisted as image dependencies; the prepared image is saved in Recipe.imageData. Text import remains usable when an image fails. No image search, generation service, account access, or backend was added.


## TikTok descriptions and shared remote photos

SourceLink accepts supported public video and short-link routes. TikTokRecipeDocument resolves only supported TikTok redirects, bounds HTML download size, and decodes the public `__UNIVERSAL_DATA_FOR_REHYDRATION__` video record. It normalizes explicit caption headings/bullets/steps for RecipeImportParser, retaining caption text, credits, source, and optional cover candidates. VideoRecipeImportView uses the existing review/save workflow and pending import identity. Incomplete captions remain editable, and unavailable pages can be kept as links. RecipeRemotePhoto shares the existing bounded image-download logic across ChatGPT, TikTok, and YouTube, with separate host policies; ChatGPTRecipePhoto retains its existing adapter interface. There is no schema change, transcription, account access, or backend.


## Source-field imports and review recovery

RecipeEditorView exposes a TikTok details-import action beside the original source field and calls the existing TikTokRecipeDocument reader. RecipeDraft.fillEmptyDetails merges into empty review fields; explicit existing values and source URL remain unchanged. Source/photo requests have separate identities and cancellation checks, preventing a response for an old URL from applying to a newer draft. The same optional photo task handles library and source-field imports. RecipeDraft.recoverTikTokSectionsIfNeeded can propose separate fields for a description-only TikTok draft with explicit complete sections; the editor shows a review notice. Both paths mutate value drafts, and persistence still requires the existing explicit Save operation.

## Shared source import routing

RecipeImportRouter selects a value draft, public ChatGPT reader, or VideoRecipeReader for both paste and pending inbox entry paths. Explicit recipe text wins over embedded links. RecipeCaptionParser normalizes supported caption sections for TikTok and YouTube. YouTubeRecipeDocument bounds native requests to 4 MB, validates video IDs/playability/redirects, and decodes only the public description and thumbnails. VideoRecipeImportView passes partial/mixed review notices to the editor. Source-field actions use the same readers; ChatGPT selection returns a candidate to the existing draft without inserting another recipe. Empty-field merging and explicit Save remain the only persistence path.

ChatGPTPublicTranscript adapts the newer public mobile transcript JSON alongside the existing reference-table adapter. It excludes incomplete, user, hidden, and analysis content, validates message identity/public-share metadata, and reads fallback Markdown without executing component code. Cover candidates require explicit supported safe URLs and unambiguous image metadata. Source and photo tasks retain cancellation identities. No persisted schema or signing changes are required.

## Native Share Extension

SazliShareExtension is embedded alongside the unchanged Live Activity extension. ShareViewController hosts a small SwiftUI receiver using the existing visual assets. ShareContentReader loads typed NSURL/NSString representations (with supported URL/plain-text/text fallbacks) from bounded NSItemProvider inputs, validates HTTP(S) URL representations, ignores file/image attachments, and deduplicates duplicate text representations. It receives only source-supplied data; no network parsing or persistence model runs inside the extension.

SazliShared/SharedRecipeInbox defines the shared immutable request record and bounded, file-coordinated atomic App Group inbox. It permits 20 requests of at most 200 KB each, validates file identity/size/content, and retains unreadable data. On launch/activation, RecipeImportInbox copies requests into the original private inbox with the same UUID, verifies an existing copy on interrupted delivery, and acknowledges the shared file only after a durable verified copy. Full private inboxes leave incoming requests in the shared inbox; removing a private request reloads delivery. Shared corruption reports an error while preserving valid private requests. The personal SwiftData store is not shared or migrated.

Only the main app and Share Extension have App Group entitlements. Sharing does not open the app through undocumented selectors; the user opens Sazli to review/save. The optional foreground App Intent remains compatible. The project generator now models all four targets; it was validated in a temporary directory, preserving actual project signing and target configuration.

## Instagram and tabular ingredient text

InstagramRecipeDocument joins VideoRecipeReader, sharing the existing review UI, source-field merge/cancellation and optional-photo workflow. SourceLink validates supported public post routes; the native reader validates same-post redirects/canonical identity and bounded metadata before passing captions to RecipeCaptionParser. Original URLs survive canonical route aliases. SourcePlatform adds a raw-string Instagram case; RecipeRemotePhoto adds a bounded Instagram CDN policy. No recipe-store migration or account access occurs.

RecipeImportParser converts only recognized ingredient/quantity Markdown tables within explicit ingredient sections. Caption footer normalization protects table regions so Notes columns do not interrupt ingredients. Shared quantity recognition supports Unicode/mixed fractions. ChatGPTRecipeExtractor recognizes decorated headings and explicit portion variants without guessing ranges; numbered caption methods preserve in-sentence dashes.
