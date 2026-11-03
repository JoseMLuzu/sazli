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

Native fonts scale with Dynamic Type. Recipe metadata uses a vertical fallback when horizontal space is limited. Horizontal category chips remain scrollable. Buttons have accessible labels and rating controls expose selected stars. Step transitions respect Reduce Motion and move accessibility focus to the current step.

Native navigation traits control the library/detail split. The width of the detail pane controls whether its ingredient and method sections can also sit in parallel. Full-screen cooking uses two balanced, independently scrollable ingredient/step panels when space allows. Section accessibility containers preserve logical ingredient/method groups. Shared measurements live in `SazliLayout`; details and acceptance checks are documented in [adaptive layout](ADAPTIVE_LAYOUT.md).

## Visual system

Color assets define the requested terracotta, coral, orange, olive, and cream palette, plus adaptive surfaces. Dark variants preserve warm contrast. SF Symbols represent UI actions and missing recipe images. The generated S-and-salt-shaker artwork is bundled as `BrandLogo` for the library and `AppIcon` for the Home Screen. The library uses a compact inline navigation bar with only the 36-point logo on the leading side, labeled Sazli for accessibility. A trailing plus opens the recipe editor; the ellipsis menu contains Import recipe and Settings. The stable Your recipes heading and result count precede a grouped search/filter area. Pending imports appear after these controls and before the photo grid. Cards overlay white titles on shaded photos, show servings/time in an adaptive cream badge, and retain favorite/rating indicators. Missing photos use a warm gradient and the category symbol.

`Components/RecipePresentation.swift` defines shared section headings, metadata tiles, numbered step cards, and subtle panel borders. Recipe detail follows a single reading order: photo, overview, ingredients/method, rating/notes, then source. Native typography and section headings replace repeated decorative labels, preparation/servings share one panel, and reading steps place the number beside the text. The same step-card component retains its enlarged presentation in cooking mode. The detail bar has a native back action, favorite, and an options menu for editing, ratings, and confirmed deletion. The bottom action starts cooking or opens the editor to add missing steps. No recipe text or quantities are inferred or rewritten for presentation.

`IngredientRow` is a reading row in recipe detail and an accessible check-off button in cooking mode. Cooking owns a session-only set of prepared ingredient indices. Its count/progress, inline panel, and ingredient sheet use that same state, including across folding and rotation. Leaving cooking starts a fresh checklist next time; it does not modify recipe contents or add persistent fields. Duplicate ingredient text still has independent rows because selection uses line indices.
