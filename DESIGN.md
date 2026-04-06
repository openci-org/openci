# OpenCI Design System (DESIGN.md)

このファイルは、OpenCIのUI/UXの一貫性を保つためのデザインシステム定義ファイルです。Google Stitchが提唱する「AIコーディングエージェントのためのUIデザインの信頼できる情報源（Source of Truth）」として機能します。

## 1. Design Philosophy (デザイン哲学)

OpenCIはOSSのCI/CDサービスであり、「誰でも直感的に使えること」を最優先事項としています。
そのため、独自のデザイン言語を構築するのではなく、**Material Design 3 (M3) の原則に厳密に従います。**
ユーザーにとって予測可能で、アクセシビリティが高く、プラットフォームに馴染む標準的なUIコンポーネントを組み合わせることで、最高のUXを提供します。

## 2. Color Palette & Tokens (カラーパレットとトークン)

ハードコードされた色は原則として禁止し、常に `Theme.of(context).colorScheme` を使用します。

### 2.1. Base Colors (ベースカラー)
- **背景色**: `surface` を基本とし、階層を表現する場合は `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh` などを活用する。
- **テキスト・アイコン**: `onSurface`, `onSurfaceVariant` を適切に使い分け、コントラスト比を確保する。
- **アクセント・アクション**: `primary`, `secondary`, `tertiary` を使用する。

### 2.2. Status Colors (ステータスカラー)
CI/CDのステータス表現には、意味論的なカラー（Semantic Colors）を割り当てます。
- **Success**: `Colors.green` 系のカスタムカラースキーム、または M3 の `tertiary` 等を拡張して使用。
- **Failed/Error**: `colorScheme.error` および `colorScheme.onError`。
- **In Progress/Queued**: `colorScheme.primary` または `colorScheme.secondary`。

## 3. Typography (タイポグラフィ)

フォントサイズやウェイトを直接指定（ハードコード）することは避け、`Theme.of(context).textTheme` のセマンティックなスタイルを使用します。

- **Page Title**: `headlineSmall` または `titleLarge`
- **Card Title**: `titleMedium`
- **Body Text**: `bodyMedium` または `bodyLarge`
- **Secondary Text (タイムスタンプ等)**: `bodySmall` または `labelMedium` (`colorScheme.onSurfaceVariant` と組み合わせる)
- **Chip/Badge Label**: `labelSmall` または `labelMedium`
- **コード・ログ**: `bodyMedium` 等をベースに `fontFamily: 'monospace'` を適用する。

## 4. Spacing & Layout (余白とレイアウト)

Material Designの **8dp グリッドシステム** に従います。マージンやパディングは、原則として `8`, `16`, `24`, `32` などの8の倍数（または小規模な調整用の `4`）を使用します。

- **画面全体のパディング**: `16dp` または `24dp`
- **コンポーネント間のスペース**: `16dp` または `8dp`
- **カード内のパディング**: `16dp`
- **Border Radius (角丸)**: M3の標準トークンに従う（例: カードは `12dp` または `16dp`）

## 5. Components (コンポーネントパターン)

### 5.1. Cards (カード)
M3の標準的なカードスタイル（Elevated, Filled, Outlined）を文脈に応じて使い分けます。
- CI/CDのリスト表示など、情報量が多い画面では視覚的ノイズを減らすため **Filled Card** (`surfaceContainerHighest` 等を使用) または **Outlined Card** を推奨します。
- ナビゲーションを伴うカードは、タップ可能であることを示すため `InkWell` でラップし、末尾に `Icons.chevron_right` を配置します。

### 5.2. Status Badges & Chips (ステータスバッジとチップ)
- **ルール**: ステータス表示にはアイコン単体を使用せず、必ず `[アイコン] + [テキスト]` の構成にします。
- **コンポーネント**: Materialの `Chip` コンポーネント、またはそれをベースにしたピル型（完全な角丸）のカスタムウィジェットを使用します。
- **In Progress**: アイコンの代わりに `SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))` などを配置します。

### 5.3. Buttons (ボタン)
M3の標準ボタンを重要度に応じて使い分けます。
- **高重要度 (保存、実行)**: `FilledButton`
- **中重要度 (キャンセル、編集)**: `OutlinedButton` または `FilledButton.tonal`
- **低重要度 (テキストリンク的)**: `TextButton`

### 5.4. Interaction (インタラクション)
- タップ可能な要素には必ずリップルエフェクト（`InkWell` や `ButtonStyle`）を適用し、ユーザーにフィードバックを与えます。
- 処理の成功・失敗などの一時的なフィードバックは `SnackBar` で提供します。

## 6. Iconography (アイコン)

- **基本アイコン**: Material Designの公式アイコンである `material_symbols_icons` を第一選択とします。
- **Git/ブランド関連**: GitHubやブランチなどの特定ドメインのアイコンが必要な場合のみ、Font Awesome (`font_awesome_flutter`) を使用します。

## 7. Web Considerations (Web特有の考慮事項)

- **スクロール**: Web環境でスクロール可能であることを明示するため、長大なリストやログビューアは `Scrollbar` でラップします。
- **ナビゲーション**: 長文コンテンツや詳細情報のインライン展開（`ExpansionTile` の多用）はDOMの肥大化とスクロールパフォーマンス低下を招くため避け、`Navigator.push` を用いた別画面への遷移を基本とします。
- **テキスト選択**: ログ、コミットSHA、エラーメッセージなど、ユーザーがコピーする可能性のあるテキストには `SelectableText` を使用します。
