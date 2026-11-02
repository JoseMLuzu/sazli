# Sazli logo concept

`sazli-logo-v1.png` is the original generated logo artwork, based on the user's S-and-salt-shaker reference and Sazli's warm brand palette. The app displays it beside the library welcome text and uses it as its Home Screen icon.

Generated with the built-in ImageGen tool on October 31, 2026. The image has a cream background and no pre-applied iOS corner mask. Image generation approximates the specified colors.

## App integration

- `Assets.xcassets/BrandLogo.imageset` contains the original 1,254-pixel artwork used in the library. At accessibility text sizes, the logo moves above the welcome text.
- `Assets.xcassets/AppIcon.appiconset` contains an opaque 1,024 × 1,024 export of the same artwork. Xcode generates the required icon sizes and iOS applies its corner mask.
- The app target selects `AppIcon` in both Debug and Release. The project generator preserves this setting.

## Generation prompt

```text
Use case: logo-brand.
Asset type: finished square iOS app icon artwork for Sazli, a premium personal recipe book.
Input image: the attached reference is the composition and shape reference. Create a closely related polished logo using Sazli's exact brand palette instead of the reference's bright red.
Primary request: a large, beautifully drawn uppercase S with soft rounded terminals, slightly slanted and friendly, with a compact salt shaker tilted diagonally in the upper right, its perforated oval face pointing down-left toward the S, sprinkling a small graceful trail of tiny salt dots onto the upper part of the letter. Preserve the recognizability, silhouette and minimal charm of the reference.
Color palette: letter S in terracotta #C95A43; shaker body primarily warm orange #F4B15E with a restrained coral #FF8A73 shaded accent, shaker face terracotta #C95A43 and cream perforations; falling grains mostly terracotta and warm orange with at most one subtle olive #8A9B6F accent. Full canvas background solid warm cream #FDF6ED.
Style: extremely clean premium Apple app branding, crisp smooth vector-like edges, generous negative space, simple sculptural forms, very subtle soft shading on the shaker only; keep the S solid terracotta. Balanced at small icon sizes. One logo only.
Composition: square 1024x1024 or higher, straight-on view. S centered in the lower-middle, tilted shaker in the upper right, fully within the canvas with comfortable safe margins; nothing clipped. Artwork fills approximately the central 76% of the square. The cream background extends to all four edges. No separate floating tile, no rounded-square border or inset frame, no outer drop shadow; iOS will mask the final app icon corners.
Text: only the single letter S. No Sazli wordmark, slogan, labels, mockup, watermark, extra objects, utensils, emoji, photorealistic materials or busy effects.
```
