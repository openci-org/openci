# Dashboard app icons

The artwork comes from [OpenCI Logo — Helvetica Bold, Figma node 2072:9](https://www.figma.com/design/fmTkPD7MY0nHZ1fYNq3ic0/OpenCI-Logos?node-id=2072-9).
`app_icon.svg` is the complete vector export, including the white 500 × 500
artboard. Keep its wordmark paths and colors unchanged.

| Platform      | Asset selection                                                                                                                                                                                |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| iOS / iPadOS  | One opaque 1024 × 1024 PNG in the universal iOS AppIcon slot. Xcode generates the required device sizes.                                                                                       |
| macOS         | PNGs at 16, 32, 64, 128, 256, 512, and 1024px, each rendered directly from `app_icon_macos.svg`. The asset catalog maps 1×/2× representations and Xcode compiles the ICNS.                     |
| Android 8+    | A 108dp adaptive icon with vector foreground and separate white background. The 60dp-wide wordmark fits inside the 66dp safe circle. Android 13+ also has a monochrome layer for themed icons. |
| Older Android | PNG fallback resources at 48, 72, 96, 144, and 192px for the five density buckets.                                                                                                             |
| Web favicon   | The original rainbow **O**, cropped from the wordmark, in `web/favicon.svg`; a 48px PNG is the fallback.                                                                                       |
| Web app       | The full-wordmark SVG for the loading screen, a dedicated 180px Apple touch icon, and 192/512px regular and maskable PWA PNGs.                                                                 |

`company_logo.png` retains the native 1024px Figma render as an opaque source
preview. `company_logo_macos.png` is the 1024px macOS preview. The macOS SVG adds
an inset rounded white tile and shadow around the unchanged artwork.

When regenerating PNGs, rasterize the appropriate SVG at the **destination pixel
size**. Do not enlarge a small PNG or repeatedly resize an intermediate raster.
Keep iOS, Android fallback, and web PNGs opaque. Keep transparency outside the
macOS tile. Check small icons at their actual display size and at 2×/3× density;
use the 1024px originals for enlarged PR previews.

Platform references: [Apple asset catalogs](https://developer.apple.com/documentation/xcode/configuring-your-app-icon),
[Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive),
and [web icon selection](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/rel#icon).
