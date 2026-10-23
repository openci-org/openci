# GenuineCI website

Astro + TypeScriptで実装したGenuineCIのLP・Pricing・ブログ・Docsです。
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

言語切り替えは同じページの対訳へ移動し、クエリと共通セクションID（`#pricing` など）を維持します。
翻訳で変わるMarkdownの見出しIDは引き継がず、記事の先頭へ移動します。
翻訳がないページでは対訳へのリンクを無効にし、存在しないURLをhreflangへ追加しません。
canonical・hreflang・OGP・X Cardを各ページに生成します。
従来の `noindex, nofollow` 方針を維持しています。

## 記事・Docsの編集

`content/<en|ja>/blog/` と `content/<en|ja>/docs/` のMarkdownを編集します。
Astro Content Collectionsが読み込み、`src/content.config.ts` がfrontmatterを検証します。
新しい記事は同じslugで両言語に追加します。一覧は言語ごとに日付の新しい順で表示します。

ブログには `layout: blog-article`、`title`、`description`、`category`、
`date`（`"YYYY-MM-DD"`）が必要です。`author`、`readTime`、`coverLabel`、
`coverTitle`、`image`、`imageAlt` も指定できます。

Docsには `layout: genuine-docs`、`title`、`description` を指定します。
`group`、`eyebrow`、`reading` は任意です。
`src/lib/navigation.ts` にガイドを追加すると、サイドバーと前後リンクに反映されます。
Docsホームの内容は `src/components/DocsHome.astro` で編集します。

目次はMarkdownの見出しから生成します。既存の見出しIDを維持する処理と
コード表示の拡張は `src/lib/markdown.ts` にあります。
Docs検索は現在の言語のタイトル・説明・本文を検索します。Cmd/Ctrl+Kでも開けます。
コードコピー、Light / Dark切り替え、モバイルメニューはブラウザーのJavaScriptで動作します。

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
`test/fixtures/legacy-heading-ids.json` は移行前に公開した見出しリンクの互換性を検証するための記録です。
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
- `src/lib/`: 言語、記事情報、ナビゲーション、Markdown処理
- `src/styles/`: 既存デザインのCSS。`content.css` のJaspr Content由来のタイポグラフィはMITライセンス表示を保持
- `src/scripts/`: 検索、メニュー、フィルター、コードコピーなど
- `content/`: Markdown本文とfrontmatter
- `public/`: favicon・OGP画像・第三者ライセンス表示

LPのビルド画面の数値はデザイン用サンプルです。
