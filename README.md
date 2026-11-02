# Sazli

Your personal recipe book. A native, local-first iPhone app for saving recipes, keeping original links, cooking step by step, and remembering what worked.

## Open and run

1. Open `Sazli.xcodeproj` in Xcode with Swift 6 support and an installed iOS SDK.
2. Select the **Sazli** scheme and an iPhone simulator running iOS 17 or later.
3. Press **Run** (`⌘R`). The recipe library starts empty.
4. For a physical iPhone, select your development team in **Signing & Capabilities**, use a unique bundle identifier if necessary, and select your device.

The project targets **iOS 17.0**, uses **Swift 6**, and has no package dependencies. Interface text, code comments, and project documentation are in English.

## What is included

- A SwiftData library with title search, category filters, favorites, and empty states.
- Create and edit recipes, including recipes containing only a title and an original link.
- Ingredients and instructions stored as newline-separated text and presented as ingredient rows and numbered steps.
- Optional photo selection through Apple's system Photos picker. Images are downsampled and stored locally.
- Recipe detail, confirmed deletion, editable personal ratings, notes, and a “would make again” preference.
- Cooking mode with large text, progress, previous/next controls, and an ingredient sheet. The previous idle-timer setting is restored when cooking closes or the app becomes inactive.
- Refined recipe presentation with olive ingredient cards, numbered terracotta step cards, preparation/serving tiles, and a dedicated notes card. Cooking ingredients can be checked off with a separate preparation-progress indicator.
- Whole-recipe text/link import with English and Spanish section parsing and editable review before saving. The existing field-level paste tool also remains available.
- A local reader for supported public ChatGPT share pages, offering complete recipes for editable review without an API key or backend.
- A native **Import recipe** Shortcuts action for sharing text and URLs into Sazli, with a durable pending inbox. One-time share-sheet shortcut setup is described in [importing recipes](docs/IMPORTING.md).
- Host-based detection for ChatGPT, YouTube, TikTok, and Facebook, with Web and Manual options. Original links remain editable and open in the system handler.
- Adaptive warm colors, native typography and controls, Dynamic Type, accessibility labels, and persisted System/Light/Dark appearance settings.
- A two-pane recipe book on the open iPhone Duo: browse the library on the left and read or edit the selected recipe on the right. Cooking uses balanced ingredient and step panels. Closing Duo keeps the selected recipe in a single-screen navigation flow.

Supported public ChatGPT share pages can be read directly on the iPhone; the resulting recipes are reviewed before saving. Other links remain references. Video transcription and general webpage extraction are not included, and missing recipe content is never generated. There is no backend, account system, analytics, CloudKit sync, StoreKit, subscription, or Share Extension.

## Structure

```text
Sazli/
  App/                     App entry point and shared visual theme
  Models/                  SwiftData Recipe and stable string-backed enums
  Features/
    Library/               Search, filters, and saved recipe navigation
    RecipeEditor/          Create/edit form, photo picker, and import/review
    RecipeDetail/          Recipe display, favorites, ratings, and deletion
    CookingMode/           Step-by-step cooking
    Settings/              Appearance and local-storage information
  Components/              Cards, stars, ingredient rows, empty state, buttons
  Services/                Validation, storage, link handling, image processing
  Resources/               Adaptive color assets and privacy manifest
SazliTests/                XCTest coverage
Scripts/                   Project generation and process-restart persistence check
docs/                      Architecture and manual QA
```

`RecipeStore` owns explicit save/delete operations. Forms edit a value-type `RecipeDraft`, so cancellation does not mutate a stored recipe. Failed writes roll back the context and show an error. The app never silently substitutes a temporary in-memory store when opening storage fails.

The model uses a UUID, default values, optional external image data, and no uniqueness constraints. Category and platform values are stored as stable strings with fallback presentation. `recipeDescription` stores the requested description field because SwiftData reserves the property name `description`. CloudKit is explicitly disabled; future synchronization still needs entitlements, migration planning, and conflict testing.

## Verification

Build without signing:

```sh
xcodebuild -project Sazli.xcodeproj -scheme Sazli \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

Run the XCTest suite in Xcode with `⌘U`, or use an installed simulator destination:

```sh
xcodebuild -project Sazli.xcodeproj -scheme Sazli \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

Replace the device name with one installed on your machine. The XCTest suite covers link validation and domain boundaries, draft validation, text presentation, create/edit/rate/delete store reopening, and sample imports with real photo decoding, duplicate protection, edit preservation, and missing-photo failure checks.

Verify persistence without a simulator on macOS 14 or later:

```sh
sh Scripts/check_persistence.sh
```

This compiles the actual app model and storage service, then starts six separate processes against a temporary on-disk store. It checks creation, reopening, editing, ratings, notes, favorites, photo data, deletion, and another reopening. It removes only its own temporary test directory. It does not launch or validate the iOS interface.

In environments that prevent the compiler from creating its nested macro sandbox, the checks can use `SAZLI_DISABLE_PLUGIN_SANDBOX=1 sh Scripts/check_persistence.sh`. The equivalent build-only override is `OTHER_SWIFT_FLAGS='$(inherited) -Xfrontend -disable-sandbox'`. These are invocation-level workarounds and are not baked into the Xcode project.

See [manual QA](docs/TESTING.md) for device testing and [architecture](docs/ARCHITECTURE.md) for implementation decisions.

The initial verification passed the device build, all five XCTest cases on an iPhone simulator, and all six separate-process persistence phases. Creation, editing, relaunch persistence, favorites, ratings, and cooking navigation were also exercised in the simulator. See the [verification record](docs/VERIFICATION.md) for the exact environment and remaining device checks.

For iPhone Duo, select the installed **iPhone Duo (iOS 27.1)** destination in Xcode. Device Hub's **Closed**, **Partially Open**, **Open**, and rotation controls exercise the responsive layouts. See [adaptive layout](docs/ADAPTIVE_LAYOUT.md) for behavior and acceptance checks. The deployment target remains iOS 17.

To populate a Debug build for design testing, use **Settings → Add sample recipes**. This explicitly saves four complete recipes with generated illustrative photos, keeps existing recipes and edits, and prevents duplicate imports. The action is absent from Release builds, and normal launches do not import samples. An explicit development launch argument also supports importing on a connected iPhone. See [sample recipes and image prompts](docs/SAMPLE_RECIPES.md).

## Assets and release preparation

The S-and-salt-shaker logo appears in the library and as the Home Screen app icon, using Sazli's warm palette. The original artwork and integration details are available in [Resources/Branding](Sazli/Resources/Branding/README.md). Recipe placeholders use SF Symbols. Localization, backup/export, and App Store distribution configuration remain release work.

The app stores data on the device and works offline. Opening source links and downloading an iCloud-only photo through the system picker may need a connection. Deleting the app removes its local recipe book; cross-device synchronization and an in-app export feature are not available yet.

## Updating the project file

The checked-in project opens directly; generation is not required for normal development. If adding or removing source/resource files outside Xcode, update target membership in Xcode or regenerate the project:

```sh
python3 Scripts/generate_project.py
```

The generator uses only the Python standard library and writes deterministic project and shared-scheme files. It resets generated target settings, so preserve any custom signing or build settings before regenerating.
