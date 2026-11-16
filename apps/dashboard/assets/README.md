# Dashboard app icons

The app icons use the [OpenCI Logo — Helvetica Bold design in Figma](https://www.figma.com/design/fmTkPD7MY0nHZ1fYNq3ic0/OpenCI-Logos?node-id=2072-9).

- `company_logo.svg` is the unmodified vector wordmark exported from layer
  `2072:2`. Keep it as the vector source when regenerating icons.
- `company_logo.png` is the 2000 × 2000 opaque master for iOS, Android, and web.
  It reproduces the white 500 × 500 Figma frame, with the 373 × 103.064453125
  wordmark positioned at `(63.5, 198.4677734375)`.
- `company_logo_macos.png` is the 2048 × 2048 macOS master. It applies the same
  composition within the existing 1648 × 1648 rounded tile at `(200, 200)`,
  preserving the original transparent exterior and shadow.

The platform PNGs are checked in under `ios/Runner/Assets.xcassets/AppIcon.appiconset`,
`macos/Runner/Assets.xcassets/AppIcon.appiconset`,
`android/app/src/main/res/mipmap-*`, and `web` (favicon and regular/maskable PWA
icons). Preserve the sizes declared by the asset catalogs and web manifest when
regenerating them. iOS, Android, and web PNGs use an opaque white background;
macOS PNGs retain transparency outside the rounded tile.
