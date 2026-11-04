# TikTok caption format audit

Reviewed November 3, 2026. This audit separates **six fetched public captions** from **22 constructed format controls**. The controls test parsing rules; they are not a claim that 12 of 22 published TikTok recipes fail or an estimate of platform-wide reliability.

## Public caption observations

| Public source | Observed structure | Current result |
| --- | --- | --- |
| [Louis Howard: gnocchi](https://www.tiktok.com/@louishowardpt/video/7696569418880535830) | Single-line caption, colon headings, bullet ingredients, numbered method, nutrition | 12 ingredients, 3 steps, 4 servings |
| [Alexis: taco mac](https://www.tiktok.com/@thesimplecravings/video/7694085059602550030) | Headings without colons, asterisks, numbered steps, trailing hashtags | 9 ingredients, 7 steps |
| [Fitwaffle: Biscoff](https://www.tiktok.com/@fitwaffle/video/6991489949828648198) | Short dish announcement and tags; no written ingredient list or method | Retained in description; ingredients/steps remain empty |
| [Fitwaffle: Nutella](https://www.tiktok.com/@fitwaffle/video/6989634938173754629) | Short dish announcement and tags; no written ingredient list or method | Retained in description; ingredients/steps remain empty |
| [Fitwaffle: Oreo](https://www.tiktok.com/@fitwaffle/video/6989263737299422469) | Short dish announcement and tags; no written ingredient list or method | Retained in description; ingredients/steps remain empty |
| [Jordi Cruz: vinaigrette](https://www.tiktok.com/@jordicruzof/video/7586754144715820310) | Narrative advice, ingredient bullets, optional additions, and prose; no supported explicit section headings | Retained for manual review in description; no guessed section boundaries |

Fetched the actual public video pages and decoded their embedded captions. A native Foundation audit ran those six downloaded documents through the production document/caption parser. The two structured recipes retained their expected field counts. The four descriptions requiring manual completion/review were not mistaken for complete structured recipes. Video availability and captions can change; this is a dated sample, not a guarantee for every region/device.

## Controlled format checks

All samples below are constructed regression controls in `SazliTests/TikTokCaptionFormatTests.swift`, including negative cases where empty ingredient/method fields are the correct result.

| Format | Before this audit | After corrections |
| --- | --- | --- |
| colon / inline bullets | Pass | Pass |
| no colon / asterisks | Pass | Pass |
| line breaks / unbulleted | Pass | Pass |
| emoji section headings | Failed separation | Pass |
| bold Markdown headings | Failed separation | Pass |
| inline Markdown heading markers | Failed separation | Pass |
| emoji numbered steps | Failed separation | Pass |
| asterisk method bullets | Failed separation | Pass |
| numbered ingredients | Failed separation | Pass |
| checkmark bullets | Failed separation | Pass |
| Spanish procedimiento | Failed separation | Pass |
| Spanish elaboracion heading | Pass | Pass |
| Spanish paso a paso | Failed separation | Pass |
| nutrition footer | Failed separation | Pass |
| tip footer | Failed separation | Pass |
| hashtags followed by emoji | Failed separation | Pass |
| partial recipe without method | Pass | Pass |
| ordinary prose / no recipe | Pass | Pass |
| comma is part of an ingredient | Pass | Pass |
| multiline ingredient group labels | Pass | Pass |
| decimal and fractional quantities | Pass | Pass |
| narrative without headings | Pass | Pass |

The baseline passed 10 controls and failed 12. The corrected parser passes all 22. Assertions compare actual ingredient/step text and note placement, including fractional/decimal quantities, rather than relying only on row counts.

## Corrections

- Treat Markdown and emoji decorations as part of a recognized heading, preventing them from leaking into an ingredient or step.
- Recognize standalone section headings and supported Spanish aliases such as Procedimiento, Elaboración, and Paso a paso.
- Separate explicit bullet/numbered ingredient and method lists, including checkmarks and keycap step numbers.
- Keep explicit macro/nutrition/tip footers and trailing hashtag/emoji blocks in the description.
- Preserve missing content, ordinary prose, fractional/decimal quantities, ingredient commas, and multiline group labels.

Caption normalization now lives in `TikTokCaptionParser.swift`, separate from public-page fetching in `TikTokRecipeDocument.swift`. The source URL, author credit, optional cover handling, and local save workflow are unchanged.

## Limits and manual review

Descriptions containing only a dish name cannot supply ingredients or steps. Narrative recipes without recognizable headings, ambiguous comma-separated ingredient text, food emojis used without clear list markers, and several recipes interleaved in one caption may require editing. Ingredient group labels are retained as text rows. This audit does not introduce audio/video processing, inference, a backend, or automatic rewriting of saved recipes.

The controls are executable as one XCTest matrix with 22 named activities, alongside the existing full regression suite. See [verification](VERIFICATION.md) for actual native build/test/device results.
