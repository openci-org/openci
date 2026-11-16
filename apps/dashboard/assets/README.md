# Dashboard app icons

Use the white **OpenCI** wordmark on the six-color rainbow background from
[OpenCI Logo — Helvetica Bold on Rainbow, Figma node 2077:2](https://www.figma.com/design/fmTkPD7MY0nHZ1fYNq3ic0/OpenCI-Logos?node-id=2077-2).
`app_icon.svg` is the complete 500 × 500 vector export. Keep its wordmark paths
and rainbow colors unchanged.

| Platform      | Asset selection                                                                                                                                                                                                      |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| iOS / iPadOS  | One opaque 1024 × 1024 PNG in the universal iOS AppIcon slot, exported directly by Figma. Xcode generates the required device sizes.                                                                                 |
| macOS         | PNGs at 16, 32, 64, 128, 256, 512, and 1024px, each rendered directly from `app_icon_macos.svg`. The asset catalog maps 1×/2× representations.                                                                       |
| Android 8+    | A 108dp adaptive icon with a white vector foreground and separate rainbow vector background. The 60dp-wide wordmark fits inside the 66dp safe circle. Android 13+ reuses the foreground for themed monochrome icons. |
| Older Android | PNG fallback resources at 48, 72, 96, 144, and 192px for the five density buckets.                                                                                                                                   |
| Web favicon   | The original white **O** on the same rainbow background in `web/favicon.svg`, with a 48px PNG fallback.                                                                                                              |
| Web app       | The full-wordmark SVG for the loading screen, a dedicated 180px Apple touch icon, and 192/512px regular and maskable PWA PNGs.                                                                                       |

`company_logo.png` retains the native 1024px Figma render as an opaque source
preview. `company_logo_macos.png` is the 1024px macOS preview. The macOS SVG adds
an inset rounded tile and shadow around the unchanged artwork.

Android's rainbow bands fill the central 72dp viewport. Its green and blue end
bands extend into the outer movement area, keeping all six colors visible under
round and rounded-square launcher masks. The monochrome foreground contains only
the white wordmark, so themed icons use the system's chosen colors.

When regenerating PNGs, rasterize the appropriate SVG at the **destination pixel
size**. Do not enlarge a small PNG or repeatedly resize an intermediate raster.
Keep iOS, Android fallback, and web PNGs opaque. Keep transparency outside the
macOS tile. Check small icons at their actual display size and at 2×/3× density;
use the 1024px originals for enlarged PR previews.

Platform references: [Apple asset catalogs](https://developer.apple.com/documentation/xcode/configuring-your-app-icon),
[Android adaptive icons](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive),
and [web icon selection](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Attributes/rel#icon).
