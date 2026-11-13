# OpenCI product website

Astro + TypeScriptで実装したOpenCIの製品LP・料金ページ・ブログ・Docsです。
Docsには [Starlight](https://starlight.astro.build/ja/) を使用しています。
ReactなどのUIフレームワークは使わず、静的HTML・CSSと必要なJavaScriptを生成します。
製品LP、料金ページ、ブログはレインボーのロゴと青を使います。公開URLは `https://openci.org` です。
写真の撮影者と配布元はフッター、同梱フォント（Geist・Geist Mono、Lora、Noto Serif JP）のライセンスは `public/licenses/*-OFL.txt` に記載しています。

## 開発

Node.js **22.23.4以上**とnpmを使用します。rootの `.node-version` に対応する
Vite+やNodeバージョンマネージャーでバージョンを選択してください。
このアプリはrootのnpm workspaceに含まれ、`package-lock.json` を共有します。

```sh
npm ci --workspace openci-website --workspace landing-page --include-workspace-root
npm run dev --workspace openci-website
```

`http://localhost:4321/en/` または `/ja/` を開きます。
`/` は `/en/` に転送します。ブラウザーの言語やIPによる自動切り替えは行いません。

## URLと言語

- `/<en|ja>/`: 製品LP
- `/<en|ja>/pricing/`: Cloudの料金試算、比較条件、セルフホスト、FAQ
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
対訳を公開するときは同じslugで追加します。一覧は言語ごとに日付の新しい順で表示します。

ブログには `layout: blog-article`、`title`、`description`、`category`、
`date`（`"YYYY-MM-DD"`）が必要です。`author`、`readTime`、`coverLabel`、
`coverTitle`、`coverImage`（`/images/` 配下のカバー写真）も指定できます。

記事のOGP画像はビルド時に自動生成します。ブログに表示しているカバー写真を左側に、
OpenCIロゴ、記事タイトル、説明、カテゴリ、公開日を右側に配置します。
`coverImage` を指定すると記事とOGPの写真が一緒に変わります。省略時はどちらもBlanca Lakeの写真を使います。
英語・日本語はそれぞれのMarkdownから別の1200×630 PNGを生成します。
たとえば `/en/blog/v2-3-0/` は `/ogp/en/blog/v2-3-0.png`、
`/ja/blog/v2-3-0/` は `/ogp/ja/blog/v2-3-0.png` をOGP・X Cardで参照します。

生成ルートは `src/pages/ogp/[...route].ts`、写真と文字の配置は `src/lib/blog-card.ts` にあります。
CanvasKitは同梱の写真とフォント（Lora、Geist、Noto Sans JP）で画像を描画します。
旧リリースの共有URL `/ogp/v2-1-0.jpg`、`/ogp/v2-2-0.jpg`、`/ogp/v2-3-0.jpg` にも
英語記事のカードをJPEGで生成します。ブログ一覧を含む記事以外のページでは `/ogp/openci.jpg` を使用します。

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
npm run fmt:check --workspace openci-website
npm run check --workspace openci-website
npm run build --workspace openci-website
npm test --workspace openci-website
npm run preview --workspace openci-website
```

`dist/` にHTML・公開アセットを生成します。テストはビルド後に実行し、
日英ルート・リンク・見出しID・メタデータ・コード例・検索データ・料金表示を検証します。
記事ごとのOGP画像の生成、PNG形式・寸法、言語ごとの画像とX Cardの参照も確認します。
フォーマットの適用は `npm run fmt --workspace openci-website` です。

`openci/website_ci.dart` はPRとdevelopへのpushで、依存取得・フォーマット・
Astroの静的解析・ビルド・テストを `bash scripts/ci.sh` で実行します。
このスクリプトは `.node-version` と一致するNode.jsを使います。手元にない場合は
公式バイナリを一時ディレクトリへ取得してSHA-256を検証します。npm 11.14.1で依存取得と `npm run build:hosting` を実行します。
macOS / Linuxのarm64・x64、bash・curl・tar・SHA-256コマンドと外部ネットワーク接続が必要です。
ローカルでは同じ処理を `npm run ci --workspace openci-website` で実行できます。

## Firebase Hosting

`openci.org` はFirebaseプロジェクト・Hostingサイト `openci-b1b91` のターゲット `website` で公開します。
デプロイ前に `npm run build:hosting` で製品サイトを検証し、`apps/landing_page` のStudioと過去のリリースを加えた `build/hosting/` を生成します。
`/studio/`、`/studio/about/`、`/ja/releases/…` は元のURLで公開します。
旧ドメイン `genuineci.com` はFirebase Hostingのカスタムドメイン設定で `openci.org` へ301転送します。
旧 `/blog/…` と `/docs/…` は同じslugの `/ja/blog/…` と `/ja/docs/…` へ301転送します。
Astroの開発・プレビューサーバーではHosting固有の旧URL転送は適用されません。

OpenCI は PR ごとに1時間のプレビューを作り、URL を PR に投稿します。`develop` への push で本番を更新します。
以下の手動コマンドは `apps/website` から実行します。

```sh
# Hostingの転送を含めたローカル確認
npm run build:hosting
firebase emulators:start --only hosting --project openci-b1b91

# 1時間のプレビュー
firebase hosting:channel:deploy astro-preview --only website --expires 1h --project openci-b1b91

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
