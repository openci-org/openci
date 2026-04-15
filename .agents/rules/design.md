---
globs:
alwaysApply: true
---

## OpenCI Dashboard Design Guidelines

OpenCI prioritizes UX above all else. The UI must balance **premium feel** and **clarity**, taking inspiration from polished developer tools like Linear, Vercel, and GitHub Actions.

---

### 1. Status Representation

- **Always use pill-shaped badges** for status display. Never use standalone icons for status.
- Badges consist of `status icon + label text` (e.g., ✅ Success).
- Badge background: `statusColor.withValues(alpha: 0.15)`, border: `statusColor.withValues(alpha: 0.3)`.
- For `in_progress`, use a small `CircularProgressIndicator` instead of an icon.
- Status labels in English: `Success`, `Failed`, `In Progress`, `Queued`.

### 2. Card Design

- Card background must be **neutral** (`surfaceContainerLow`). Do not tint cards with status colors.
- Border: `outlineVariant.withValues(alpha: 0.3)`, subtle and understated.
- Always use `elevation: 0`. No drop shadows.
- Default border radius: `12`.
- When a card navigates to a detail page, place a chevron `Icons.chevron_right` on the trailing edge.

### 3. Information Hierarchy & Navigation

- **Show only summaries on list screens.** Detail info should live on a dedicated detail page, not inline.
  - Avoid `ExpansionTile` for inline expansion on web — it causes scroll performance issues.
- Navigate via `Navigator.push` + `MaterialPageRoute`.
- Detail pages should use full-screen layout with `Expanded` + `ListView` for smooth scrolling.

### 4. Expandable Content

- Make expandability **visually obvious**. A small chevron alone is not enough.
- Wrap multi-line content in a **card-style container** (background color + border).
- Place an expand badge (`unfold_more` icon + `N lines` label) on the trailing edge.
- Expanded content uses a slightly darker background (`Color(0xFF1A1A1A)`) with a top border separator.

### 5. Color Palette

- Leverage Material 3 `colorScheme`. Minimize hardcoded colors.
- Dark UI (e.g., log viewer): background `#121212`, secondary `#1A1A1A`, code area `#1E1E1E`.
- Text colors: use `onPrimary`, `onSurface`, `onSurfaceVariant` appropriately.
- Chip/badge colors by purpose:
  - Branch: `Colors.purple`
  - Pull Request: `Colors.green`
  - Tag: `Colors.amber`
  - Commit: `Colors.blueGrey`

### 6. Typography

- Use `fontFamily: 'monospace'` for code and logs.
- Font size reference:
  - Page title: `16px`, `FontWeight.w600`
  - Card title: `15px`, `FontWeight.bold`
  - Chip/badge label: `11–12px`, `FontWeight.w500–w600`
  - Secondary text (timestamps, etc.): `12px`
  - Log lines: `13px`, monospace

### 7. Spacing

- Between cards: `margin: EdgeInsets.only(bottom: 12)`
- Card inner padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 14)`
- Between chips: `spacing: 6, runSpacing: 6`
- Border radius: cards `12`, chips `6`, badges `12–20`

### 8. Interaction

- Use `InkWell` for tappable elements to enable hover/splash effects.
- Provide feedback via SnackBar (`context.showSnackBarMessage`).
- Utility actions (e.g., copy logs) use `IconButton` + `tooltip`.

### 9. Icons

- Use Font Awesome (`font_awesome_flutter`) for Git-related icons.
- Use Material Icons for UI action icons.
- Use `material_symbols_icons` for navigation icons.
- Never rely on icons alone to convey status — always pair with a text label.

### 10. Web Considerations

- Wrap `ListView` with `Scrollbar` to indicate scrollability.
- Separate long-form content into dedicated pages instead of inline expansion.
- Use `SelectableText` for copyable text (logs, commit SHAs, etc.).
