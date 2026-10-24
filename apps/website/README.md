# GenuineCI website

Astro + TypeScriptで実装したGenuineCIのLP・Pricing・ブログ・Docsです。
Docsには [Starlight](https://starlight.astro.build/ja/) を使用しています。
ReactなどのUIフレームワークは使わず、静的HTML・CSSと必要なJavaScriptを生成します。
ブランドカラーは **#FFFB00** と黒。公開URLは `https://genuineci.com` です。

## 開発

Node.js **22.23.4以上**とnpmを使用します。rootの `.node-version` に対応する
Vite+やNodeバージョンマネージャーでバージョンを選択してください。
このアプリはrootのnpm workspaceに含まれ、`package-lock.json` を共有します。

```sh
npm ci --workspace genuineci-website --include-workspace-root
npm run dev --workspace genuineci-website
```

`http://localhost:4321/en/` または `/ja/` を開きます。
`/` は `/en/` に転送します。ブラウザーの言語やIPによる自動切り替えは行いません。

## URLと言語

- `/<en|ja>/`: LP・Pricing
- `/<en|ja>/blog/`: ブログ一覧（カテゴリ絞り込み）
- `/<en|ja>/blog/<slug>/`: リリース記事
- `/<en|ja>/docs/`: Docsホーム
- `/<en|ja>/docs/<slug>/`: 各ガイド

言語URLはAstro標準の `getRelativeLocaleUrl()`、表示中の言語は `Astro.currentLocale` を使います。
対応言語・デフォルト言語は `src/lib/i18n.ts` で定義し、`astro.config.mjs` と共有します。
記事・Docsの言語はContent IDの先頭を `getLocaleByPath()` で解決します。
LP・ブログの言語切り替えは同じページの対訳へ移動し、クエリと共通セクションID（`#pricing` など）を維持します。
翻訳で変わるMarkdownの見出しIDは引き継がず、記事の先頭へ移動します。
翻訳がないブログ記事では対訳へのリンクを無効にします。
DocsはStarlight標準の言語選択ドロップダウンを使い、同じページの言語URLへ移動します。
クエリとハッシュの扱いも標準動作に従い、そのまま引き継ぎます。
hreflangは実際に存在する翻訳だけを掲載します。
canonical・hreflang・OGP・X Cardを各ページに生成します。
従来の `noindex, nofollow` 方針を維持しています。

## 記事・Docsの編集

ブログは `content/<en|ja>/blog/`、Docsは `src/content/docs/<en|ja>/docs/` のMarkdown・MDXを編集します。
Astro Content Collectionsが読み込み、`src/content.config.ts` がfrontmatterを検証します。
新しい記事は同じslugで両言語に追加します。一覧は言語ごとに日付の新しい順で表示します。

ブログには `layout: blog-article`、`title`、`description`、`category`、
`date`（`"YYYY-MM-DD"`）が必要です。`author`、`readTime`、`coverLabel`、
`coverTitle` も指定できます。

記事のOGP画像は `astro-og-canvas` がビルド時に自動生成します。
`title`、`description`、`category`、`date` を使い、黄色（#FFFB00）の背景に黒い文字で描画します。
画像の追加やfrontmatterの `image` 指定は不要です。
英語・日本語はそれぞれのMarkdownから別の1200×630 PNGを生成します。
たとえば `/en/blog/v2-3-0/` は `/ogp/en/blog/v2-3-0.png`、
`/ja/blog/v2-3-0/` は `/ogp/ja/blog/v2-3-0.png` をOGP・X Cardで参照します。

生成ルートとデザインは `src/pages/ogp/[...route].ts` にあります。
日本語・英語を含むNoto Sans JPを `src/assets/fonts/` にライセンスとともに同梱し、
画像生成時のフォント取得にはネットワークを使いません。フォントは配信アセットには含まれません。
記事以外のページと既存の共有リンク用に、従来の `public/ogp/` のJPEGは保持しています。

Docsには `title`、`description` を指定します。`layout` の指定は不要です。
Starlightの `docsLoader()` と `docsSchema()` がコンテンツを読み込み、検証します。
`astro.config.mjs` の `starlight.sidebar` にガイドを追加すると、サイドバーと前後リンクに反映されます。
Docsホームは各言語の `index.mdx` にあり、StarlightのHero・CardGrid・LinkCardを使用します。
`docs/` を言語ディレクトリ内に置くことで、既存の `/<en|ja>/docs/…` URLを維持しています。
翻訳のないDocsはStarlightの標準動作で英語本文と未翻訳の案内を表示します。

見出しIDはAstro標準で自動生成し、目次は `render()` が返す `headings` を使います。
旧サイト独自の見出しIDは引き継ぎません。例：`#01-sdk` は `#01-sdkを追加する` になります。
Docsの目次・見出しリンク・コードの色付けとコピーはStarlightとExpressive Codeが生成します。
ライト／ダークの切り替えはページ全体とコードに適用されます。
ブランドカラーは `src/styles/starlight.css`、メタデータとDocsホームへのリンクは `src/lib/docs-route.ts` で調整します。
ブログのMarkdownとLPの `<Code />` は既存のShikiと `css-variables` テーマを使用します。
`src/lib/markdown.ts` がブログのレンダラーを分け、StarlightのMarkdown拡張がブログ表示に影響しないようにしています。
canonical・OGPのURLは `Astro.url.pathname` と `Astro.site` から生成します。
Docs検索はStarlight標準のPagefindで現在の言語の本文を検索します。Cmd/Ctrl+Kでも開けます。
検索インデックスはビルド時に `dist/pagefind/` へ生成されます。検索の確認は `npm run build` 後の `npm run preview` で行います。
`npm run dev` では検索インデックスを生成しません。
LP・ブログの言語切り替えのクエリ・共通アンカー維持は `src/scripts/site.js` で処理します。
コードコピー、テーマ切り替え、モバイルメニューはブラウザーのJavaScriptで動作します。

## 検証

rootから実行します。

```sh
npm run fmt:check --workspace genuineci-website
npm run check --workspace genuineci-website
npm run build --workspace genuineci-website
npm test --workspace genuineci-website
npm run preview --workspace genuineci-website
```

`dist/` にHTML・公開アセットを生成します。テストはビルド後に実行し、
日英ルート・リンク・見出しID・メタデータ・コード例・検索データ・料金表示を検証します。
記事ごとのOGP画像の生成、PNG形式・寸法、言語ごとの画像とX Cardの参照も確認します。
フォーマットの適用は `npm run fmt --workspace genuineci-website` です。

`openci/website_ci.dart` はPRとdevelopへのpushで、依存取得・フォーマット・
Astroの静的解析・ビルド・テストを `bash scripts/ci.sh` で実行します。
このスクリプトは `.node-version` のNode.js公式バイナリを一時ディレクトリへ取得し、
SHA-256を検証した後、npm 11.14.1で依存取得と `npm run verify` を実行します。
ワーカーやFirebase CLIが引き継ぐNode.jsのバージョンに依存せず、実行後に一時ディレクトリを削除します。
macOS / Linuxのarm64・x64、bash・curl・tar・SHA-256コマンドと外部ネットワーク接続が必要です。
ローカルでは同じ処理を `npm run ci --workspace genuineci-website` で実行できます。

## Firebase Hosting

Firebaseプロジェクト `openci-b1b91`、Hostingサイト `genuineci-website`、ターゲット `website` を使用します。
`firebase.json` は `dist/` を公開し、デプロイ前に依存取得と検証を実行します。
旧 `/blog/…` と `/docs/…` は同じslugの `/ja/blog/…` と `/ja/docs/…` へ301転送します。
Astroの開発・プレビューサーバーではHosting固有の旧URL転送は適用されません。

以下は `apps/website` から実行します。

```sh
# Hostingの転送を含めたローカル確認
firebase emulators:start --only hosting --project openci-b1b91

# 7日間のプレビュー
firebase hosting:channel:deploy astro-preview --only website --expires 7d --project openci-b1b91

# 本番公開
firebase deploy --only hosting:website --project openci-b1b91
```

## 構成

- `src/pages/`: URLとページ生成
- `src/layouts/`: HTMLメタ情報・ブログ・Docsの共通レイアウト
- `src/components/`: LP、料金、言語切替、ナビゲーション、コードの表示部品
- `src/assets/fonts/`: OGP画像生成用のフォントとライセンス
- `src/lib/`: 言語、記事情報、ナビゲーション、Markdown処理
- `src/styles/`: 既存デザインのCSS。`content.css` のJaspr Content由来のタイポグラフィはMITライセンス表示を保持
- `src/scripts/`: 検索、メニュー、フィルター、コードコピーなど
- `content/`: Markdown本文とfrontmatter
- `public/`: favicon・OGP画像・第三者ライセンス表示

LPのビルド画面の数値はデザイン用サンプルです。
