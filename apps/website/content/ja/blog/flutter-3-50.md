---
layout: blog-article
title: |-
  Flutter 3.50の新機能
  非公式日本語訳
description: Flutter 3.50の公式発表の全文日本語訳です。ネイティブAPIとの直接連携、WebAssemblyの高速化、Material／Cupertinoのパッケージ分離、iOSの入力遅延の改善など、主な変更を冒頭の要約とともに紹介します。
category: Flutter
date: "2026-11-12"
readTime: 20 min read
author: Emma Twersky（原著）／OpenCI（日本語訳）
coverLabel: UNOFFICIAL JAPANESE TRANSLATION
coverImage: /images/landing/guide-signing.webp
coverTitle: Flutter 3.50
---

Emma Twersky 著「[What's new in Flutter 3.50](https://flutter.dev/blog/whats-new-in-flutter-3-50)」（The Flutter Blog、2026年11月11日公開）の**非公式日本語訳**です。原文の本文・図版は [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ja)、コード例は [BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause) に基づき掲載しています。

## まずは要点だけ

_この節はOpenCIが作成した要約です。次の「日本語訳」から原文の翻訳が始まります。_

- **ネイティブAPIとの直接連携が安定版に。** FFIgenとJNIgenを使い、DartからObjective-C・Java・KotlinのAPIを直接呼び出せます。Pigeonの新しい連携モードはプレビューです。
- **Webの実行速度とキャッシュ管理を改善。** Safari／FirefoxでのWebAssembly実行が高速化し、`--web-content-hash` でファイル名にコンテンツハッシュを付けられます。
- **Material／CupertinoのSDK同梱ライブラリを非推奨に。** 新規プロジェクトでは、独立した `material_ui` パッケージを標準で使います。
- **iOSのタッチ入力遅延を1フレーム短縮。** iOS 27での実機デバッグも改善されました。Swift Package Managerへの移行やIntel Macのサポート終了に向けた対応も進んでいます。
- **Androidのセキュリティとビルド環境を更新。** リリースビルドの `Intent` 検証を強化しました。AGP 9の新DSLは、必要な条件を満たしたうえで設定を有効にすると利用できます。プラグインはBuilt-in Kotlinへの移行が必要です。
- **AI開発向けの公式ツールを拡充。** AIコーディング支援用の公式プラグイン、パッケージに同梱できるスキル、Genkit Dart 1.0、MediaPipeによるオンデバイスAIが紹介されています。

## 日本語訳

_Flutterのこれからの10年を見据えて_

Flutter 3.50が、[Dart 3.14](https://dart.dev/blog/announcing-dart-3-14) とともにリリースされました。今回は、Flutterの今後の方向性を示す多くの変更が加わっています。ネイティブAPIとの直接連携が安定版になり、DartとネイティブプラットフォームのAPIを相互に呼び出せるようになりました。Webでは、SafariとFirefoxでのWebAssembly実行の高速化や、ブラウザー標準のテキストレイアウト機能の活用により、アプリの実行速度が大きく向上します。

独自のハードウェアにFlutterを組み込むためのAPIも拡充しました。また、新規プロジェクトでは、独立した `material_ui` と `cupertino_ui` パッケージを標準で使うようになります。

今回も、Flutterコミュニティから多くの貢献が寄せられました。このリリースサイクルでは、初めて参加した69人を含む188人による、1,200件以上のコミットが取り込まれています。フレームワークや関連プロジェクトを支えてくださった皆さんに感謝します。最新版を使うには、ターミナルで `flutter upgrade` を実行してください。新機能の詳細は、このあと紹介します。

## ネイティブAPIとの直接連携

昨年、私たちは [ネイティブAPIとの直接連携に向けた構想](https://flutter.dev/blog/flutters-path-towards-seamless-interop) を発表しました。従来のプラットフォームチャネルでは、シリアライズの負荷、メソッド名などを文字列でやり取りする手間、必ず非同期で呼び出すことによる遅延が生じます。この構想は、そうした課題の解消を目指すものです。数年にわたる開発を経て、Flutter 3.50では本番環境で利用できるようになりました。以前から安定版だったFFIgenのC対応に加え、Objective-C向けの [FFIgen](https://pub.dev/packages/ffigen) と、Java／Kotlin向けの [JNIgen](https://pub.dev/packages/jnigen) が安定版になっています。

また、[Pigeon](https://pub.dev/packages/pigeon) の新しいネイティブ連携モードをプレビュー版として試せます。このモードは、内部で両ジェネレーターを使い、型安全なバインディングを生成します。

これにより、プラットフォームチャネルでメッセージをやり取りせずに、Dartとネイティブコードの間で関数を直接呼び出せます。同期呼び出しや、バックグラウンドのisolateからの呼び出しにも対応します。FFIgenはCやObjective-CのAPI、JNIgenはAndroidのシステムAPIや独自のJava／Kotlinライブラリに対応するバインディングを生成し、FlutterやDartのアプリから利用できるようにします。複数のプラットフォームに対応するプラグインを開発する場合は、Pigeonのネイティブ連携モードにより、iOS・macOS・Androidでのデータ変換とネイティブオブジェクトの生存期間の管理を自動化できます。

![従来のMethodChannelによるシリアライズと、生成されたJNI／FFIバインディングによるホストAPIの直接呼び出しの比較。](/images/blog/flutter-3-50/native-interop.webp)

_ネイティブAPIとの直接連携では、プラットフォームチャネルのシリアライズを省き、FFIとJNIを通じてネイティブAPIを直接呼び出します。_

パッケージ作者、コントリビューター、Early Access Program参加者の皆さん、特にJon Holtan、Rody Davis、Dominik Roszkowski、Alexander Thiele、Morgan McKenzieに感謝します。初期ビルドのテストやドキュメントのレビューを通じ、APIの設計にも協力していただきました。ネイティブAPIとの直接連携については、今後、別の記事で詳しく紹介します。

詳しくは、[ネイティブ連携のドキュメント](https://docs.flutter.dev/interop) をご覧ください。

## Webプラットフォーム

Web向けには、複数のブラウザーでのWebAssembly実行の高速化、アセットのキャッシュを更新する仕組み、古いJS連携ライブラリの検出機能を追加しました。ブラウザー標準の機能を活用し、テキスト描画を軽量化する取り組みも進んでいます。

### SafariとFirefoxでのWebAssembly

`flutter build web --wasm` を実行すると、アプリはWebAssemblyとJavaScriptの両方にコンパイルされます。古いブラウザーでは、自動的にJavaScript版へ切り替わります。Chromium系ブラウザー（ChromeとEdge 137以降）では、すでにWebAssemblyでの実行が標準になっています。Flutter 3.50では、Safari 26.2以降（macOSとiOS）とFirefox 147以降でも実行が高速化しました。ウィジェットの描画負荷が高いベンチマークでは、JavaScript実行時の2倍を超えるフレームレートを記録しています。これらのブラウザーでも今後の安定版では標準で有効になる予定ですが、今すぐ試すには `web/flutter_bootstrap.js` に次の設定を追加してください。

```js
{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {
    wasmAllowList: {
      blink: true,
      webkit: true,
      gecko: true,
    },
  },
});
```

詳しくは、[WebAssembly（Wasm）のサポート](https://docs.flutter.dev/platform-integration/web/wasm) をご覧ください。

<a id="webコンテンツのハッシュを組み込みでサポート"></a>

### Webコンテンツのハッシュ化に対応

FlutterのWebアプリを更新しても、再訪したユーザーのブラウザーに古いJavaScriptが残ったり、新旧のアセットが混在したりすることがあります。`flutter build web` に `--web-content-hash` を指定すると、コンパイルされたJavaScript、WebAssembly、`build/web/assets/**` のファイル名に、内容に応じたハッシュ値が付くようになります。`flutter_bootstrap.js` も自動で更新されるため、古いキャッシュが使われる問題を防げます。

ハッシュ付きのアプリバンドルとアセットには、最長1年間のキャッシュを設定できます（`Cache-Control: public, max-age=31536000, immutable`）。一方、`index.html` と `flutter_bootstrap.js` を `no-cache` にしておけば、デプロイのたびに新しいファイルの組み合わせを読み込めます。このフラグを指定すると、独自のService WorkerやWorkboxで使う `build/web/precache_manifest.json` も生成されます。これは、非推奨になった `flutter_service_worker.js` のトークンに代わるものです。

詳しくは、[WebコンテンツのハッシュとHTTPキャッシュ](https://docs.flutter.dev/deployment/web#web-content-hashing) をご覧ください。

<a id="webでの従来のjs連携をチェック"></a>

### 古いJS連携ライブラリの使用を検出

FlutterのWebアプリやプラグインでは、JS連携ライブラリを通じてローカルストレージなどのブラウザー機能を使ったり、サードパーティーのJavaScript SDKをラップしたりします。Dartの従来のJavaScript専用ライブラリ（`dart:html`、`dart:js`、`dart:js_util`、`package:js`）は非推奨になりました。今後は、JavaScriptとWebAssemblyの両方に対応する `dart:js_interop` と `package:web` を使ってください。従来のライブラリは、将来のDartリリースで削除される予定です。

`flutter build web`、`flutter run`、`flutter test --platform chrome` に `--no-deprecated-js-interop` を指定すると、古いJS連携ライブラリのインポートを検出できます。アプリ本体や依存パッケージに古いライブラリが残っていると、ビルドが早い段階で失敗します。WebAssembly対応に向け、移行が必要な箇所を洗い出すのに役立ちます。

詳しくは、[互換性のあるJS連携ライブラリの使用](https://docs.flutter.dev/platform-integration/web/wasm#js-interop-wasm) と [Dart 3.14の発表](https://dart.dev/blog/announcing-dart-3-14) をご覧ください。

### ブラウザー標準のテキストレイアウトのプレビュー

`WebParagraph` は、Chromeチームと共同で開発した、Chromeの実験的なEnhanced `TextMetrics` APIを使う仕組みです。C++のフォント解析処理をアプリに同梱せず、OSのフォントを使ったシェーピング（文字の形や配置の調整）をブラウザー側で行い、キャンバスに描画できます。テキストレイアウトをブラウザーに任せることで、CanvasKitのダウンロードサイズは5.46 MBから約3.75 MBに縮小します。フォールバックフォントを取得するための通信も不要になります。各言語の文字が欠字の四角、いわゆる「豆腐」になる問題を防ぎ、ネイティブのカラー絵文字も表示できます。

詳しくは、[WebParagraphの実験的プレビュー（#172561）](https://github.com/flutter/flutter/issues/172561) をご覧ください。

<a id="プラットフォームの差し替え対応"></a>

## Pluggable Platformsの改善

[Google I/Oで発表したPluggable Platforms](https://youtu.be/I1uIbGh1dGE?t=2294) の取り組みとして、Flutterを新しいOSやハードウェアへ移植しやすくするための開発を続けています。Flutter 3.50では、ImpellerとVulkanのエンベダーAPIに、2つの機能を追加しました。エンベダーとは、FlutterをOSやハードウェアに組み込むための実装です。コミュニティの [xiaowei-guan](https://github.com/xiaowei-guan) によるVulkanの外部テクスチャ対応により、独自のエンベダーから [テクスチャをエンジンに直接渡し](https://github.com/flutter/flutter/pull/188855)、ImpellerとSkiaの両バックエンドでサンプリングできるようになりました。

また、メモリが不足したときに、エンベダーから `FlutterEngineNotifyLowMemoryWarning` を呼び出すことで、[Impellerのオフスクリーン描画ターゲットのキャッシュを即座に解放](https://github.com/flutter/flutter/pull/193497) できるようになりました。

## デザインパッケージの分離

Flutter 3.47では、SDKから独立した `material_ui` と `cupertino_ui` の1.0を公開しました。これに続き、Flutter 3.50では、SDK同梱の `package:flutter/material.dart` と `package:flutter/cupertino.dart`、および `package:flutter_localizations` に含まれる対応するローカライズデリゲートを正式に非推奨としました。`flutter create` で作成する新規プロジェクトでは、標準で `package:material_ui` をインポートします。

![SDK同梱のmaterial.dart／cupertino.dartから、pub.dev上の独立したmaterial_ui／cupertino_uiパッケージへ、dart fixで移行する流れ。](/images/blog/flutter-3-50/design-packages.webp)

_`dart fix` を使い、SDK同梱のデザインライブラリから、独立した `material_ui` と `cupertino_ui` へ移行します。_

`dart fix --apply --code=migrate_design_widgets` を実行すると、既存のインポートとローカライズデリゲートを自動的に更新できます。

詳しくは、[MaterialとCupertinoの移行ガイド](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui) と [MaterialとCupertinoの分離](https://flutter.dev/blog/decoupling-material-cupertino) をご覧ください。

## フレームワーク

フレームワークでは、コミュニティと開発チームの貢献により、sliverをクリップするウィジェットや、論理サイズに基づく画像キャッシュなどを追加しました。テキスト選択の安定性、アクセシビリティ、デスクトップのマルチウィンドウ機能も改善しています。

### スクロールとsliver

コミュニティの貢献により、カスタムスクロールビューも使いやすくなりました。[Emmanuel Lefebvre Dibon](https://github.com/manu-sncf) は、`clipOverlap` オプションを備えた `SliverClipRect` と `SliverClipRRect` を追加しました。固定ヘッダーが欠けないようにしながら、スクロール領域を角丸にしたり、クリップしたりできます。[Mairramer](https://github.com/Mairramer) は、`ListView.separated` に `itemExtentBuilder` を追加しました。区切り線付きのリストで行ごとに高さが異なる場合も、画面外のウィジェットを構築せず、必要に応じて各行のサイズを決められます。

Mairramerは `ScrollPhysics.shouldUpdate` も追加しました。設定の変更に応じて、スクロール動作を動的に更新できます。[Soroush Yousefpour](https://github.com/gabrimatic) は `RawScrollbar.mouseCursor` を修正しました。スクロールバーのつまみやトラックにポインターが重なったときだけカーソルが変わり、周囲のコンテンツでは通常のカーソルが表示されます。また、`Scrollable.ensureVisible` は、固定ヘッダーを表示する位置で正確に止まり、余分にスクロールしなくなりました。

`SliverFillRemaining` は、スクロールビューの末尾で、オーバースクロールによる伸縮のオフセットを正しく計算するようになりました。`TreeSliver` では、ツリーの枝を展開・折りたたみする際の描画範囲を適切にクリップし、アニメーション中の子の行が隣の項目に重ならないようにしました。

<figure>
  <img src="/images/blog/flutter-3-50/sliver-clip-rrect.webp" alt="SliverClipRRectがスクロールするsliverコンテンツを角丸の領域にクリップするアニメーション。" width="320" loading="lazy" />
  <figcaption>SliverClipRRectでは、固定ヘッダーが欠けないようにしながら、スクロール領域を角丸にクリップできます。</figcaption>
</figure>

### テキスト入力と選択

モバイル・Web・デスクトップで、テキストの編集や選択がより安定しました。[Alex Li](https://github.com/AlexV525) は、`TextInputType.numberWithOptions` に `password` オプションを追加しました。AndroidアプリでPINなどを入力する際に、パスワード入力用の数字キーボードを開けるようになります。また、`AutofillHints.emailOTPCode` を使うと、メールで届くワンタイム認証コードをAndroidアプリで自動入力できます。新しい `Hyphens` 列挙型では、行の折り返し時にソフトハイフンを表示するかどうかを指定できます。

[Nicodemus Lin](https://github.com/nicolinx) は、複数行テキストの上側の選択ハンドルをドラッグすると、画面の表示位置が急に変わる問題を修正しました。[Nickolas de Luca Alberton](https://github.com/nickolasdeluca) は、中央寄せや右寄せの1行のテキストフィールドで、上下の矢印キーを押したときのカーソル移動を修正しました。`PageView` 内でテキストをドラッグして選択する際に、誤って隣のページへ切り替わる問題も解消しました。左から右に書く文字と右から左に書く文字が混在する場合も、選択ハンドルは選択範囲の方向を正しく向くようになりました。

### 画像と描画のAPI

コミュニティの貢献により、画像の読み込みやキャッシュを扱うAPIも充実しました。[Kishan Rathore](https://github.com/rkishan516) は、`DecorationImage` に `ImageProvider` 型の `placeholder` を追加しました。背景画像を読み込んでいる間、プレースホルダーの画像を表示できます。[Anas Saifi](https://github.com/anazr9) が追加した `FadeInImageTransition.fadeInOver` では、不透明なプレースホルダーの上に画像を滑らかにフェードインさせ、切り替え時に一瞬空白が表示されるのを防げます。

[Koji Wakamiya](https://github.com/koji-1009) は、`ResizeImage` に `useLogicalSize`、`Image` に `useLogicalCacheSize` を追加しました。`BuildContext` を使わずに、画面のピクセル密度に応じたサイズで画像をキャッシュできます。[Ishaq Hassan](https://github.com/ishaquehassan) は、`RawImage` で `blendMode` を指定できるようにしました。カスタムウィジェットで画像を描画する際に、色のブレンド効果を直接適用できます。また、独自の形状を持つ `BoxBorder` も、アニメーションによる状態の切り替えが滑らかになりました。

`HSVColor.lerp` と `HSLColor.lerp` による色のアニメーションでは、色相環上の短い方の経路で色を変化させるようになりました。これにより、意図しない色の変化を防ぎます。

<figure>
  <img src="/images/blog/flutter-3-50/image-placeholder.webp" alt="DecorationImageがぼかしたプレースホルダーのカードを表示した後、鮮明な画像を読み込むアニメーション。" width="320" loading="lazy" />
  <figcaption>DecorationImage.placeholderでは、背景画像の読み込み中にプレースホルダーの画像を表示できます。</figcaption>
</figure>

### アクセシビリティとナビゲーション

各プラットフォームで、キーボード操作、スクリーンリーダー対応、ダイアログのカスタマイズを改善しました。カスタムのスライダーウィジェットで `SemanticsRole.slider` を使うと、スクリーンリーダーに値や操作方法を正しく伝えられます。`MediaQueryData.reduceMotion` では、ユーザーが動きを抑える設定（Reduce Motion）を有効にしているかを調べ、スライドアニメーションを控えめなフェードに置き換えられます。また、Escapeキーを押すと、キーボードフォーカスを動かさずに `Tooltip` と `RawTooltip` のオーバーレイを閉じられるようになりました。Webのアクセシビリティ基準に沿った動作です。

Webでは、VoiceOverと `WidgetsApp.router` を修正し、オーバーレイ内でスクリーンリーダーやキーボードのフォーカスが予期せずリセットされる問題を解消しました。[Ishaq Hassan](https://github.com/ishaquehassan) が `FocusableActionDetector` に追加した `skipTraversal` オプションでは、ユーザーが操作するカスタムウィジェットを、Tabキーによるフォーカス移動の対象から除外できます。また、[Mairramer](https://github.com/Mairramer) が `showDialog` に追加した `barrierBuilder` コールバックにより、ダイアログの背後に表示する背景をカスタマイズし、ぼかしなどを適用できます。

`Navigator.popUntilWithResult` は、遷移先のルートにローカル履歴がある場合でも、最後にpopされたルートへ結果を返すようになりました。

### デスクトップのウィンドウ

Canonicalや、メンテナーの [Robert Ancell](https://github.com/robert-ancell)、[Matthew Kosarek](https://github.com/mattkae)、[Matej Knopp](https://github.com/knopp) の協力により、Linux・macOS・Windows向けの実験的なマルチウィンドウAPIも改良が進んでいます。Linuxでは、`WindowControllerLinux` を使って、独自のタイトルバーや透過ウィンドウ、ネイティブのドラッグ操作によるウィンドウの移動・サイズ変更を実装できます。

macOSでは、表示前にウィンドウやダイアログのサイズを内容に合わせられるようになりました。これにより、表示直後にサイズが変わってちらつくのを防げます。3つのデスクトッププラットフォーム共通の変更として、コードを簡潔にするために `RegularWindow` の名前を `Window` に変更しました。`sizedToContent` プロパティも、FlutterのほかのレイアウトAPIと名前をそろえ、`shrinkWrap` に変更しています。また、`WindowManager` がウィジェットツリー上で `WidgetsApp` より上に置かれるようになり、追加のウィンドウごとに、独立したUIとナビゲーションの状態を持てるようになりました。

![macOSで動作するFlutter Multi-Window Reference Application。メインウィンドウと別ウィンドウのダイアログを表示している。](/images/blog/flutter-3-50/desktop-multi-window.webp)

_macOSで動作する、マルチウィンドウの実装例を示すアプリ。_

## エンジン

エンジンでは、Impellerで基本図形をGPU描画する処理を拡充しました。モバイルGPUの安定性や、Windows・Linuxでの表示品質も改善しています。

### Impellerの描画

macOS・Linux・Windows向けのImpellerのSigned Distance Field（SDF、符号付き距離場）レンダラーは、複雑な形状をCPUで計算せず、GPU上で直接、くっきりした枠線や図形、グラデーションを描画します。フレームの描画時間を短縮できるため、カードや枠線、影が多い画面でも、スクロールやアニメーションが滑らかになります。Flutter 3.50では、この高速な描画方式を、線・細い枠線・角丸・グラデーションにも適用しました。また、macOSでのグラデーションや、繰り返し描画するテキストの影も高速化しています。

独自の3Dシーンや2Dゲームの開発に向けて、Flutter GPUが2Dテクスチャ配列に対応しました。スプライトシート、タイルマップ、地形のレイヤーをまとめて描画し、タイル間に継ぎ目を出さずにドローコールを減らせます。また、シェーダーパイプラインの設定に問題がある場合は、より分かりやすいDartのエラーメッセージが表示され、描画の不具合を見つけて修正しやすくなりました。

![ImpellerのSDFとMSAAの拡大比較。SDFでは斜めの輪郭が滑らかになり、MSAAでは階段状に見える。](/images/blog/flutter-3-50/impeller-sdf.webp)

_ImpellerのSDFレンダラーは、GPUで直接、鮮明でアンチエイリアスの効いた輪郭を描画します。_

OpenGLの起動時間やGPUの安定性にも、コミュニティによる修正が入っています。[xiaowei-guan](https://github.com/xiaowei-guan) は、OpenGLのシェーダー初期化をバックグラウンドスレッドへ移し、最初のフレームを表示するまでの時間を短縮しました。[seunggi](https://github.com/dfdgsdfg) は、Mali GPUでテクスチャを読み込む際のクラッシュを解消し、対象のAndroid端末でアプリが突然終了する問題を修正しました。[krll-kov](https://github.com/krll-kov) は、古い端末でのOpenGL ES 2のテクスチャ描画を修正しました。また、アニメーション画像のフレームが切り替わっても、透明度が正しく維持されるようにしています。

描画の不具合を防ぐため、BシリーズのPowerVR GPUでは、VulkanからOpenGLへ自動的にフォールバックするようにもなりました。

### デスクトップのグラフィックス

WindowsとLinuxでは、描画の品質と性能を改善しました。Windowsのエンジンは、[標準でOpenGL ES 3を要求](https://github.com/flutter/flutter/pull/191516) するようになりました。利用できない場合は自動的にOpenGL ES 2へ切り替わるため、古いPCへの対応を保ちつつ、新しいグラフィックス機能を使えます。また、Windowsアプリでは、ユーザー名やフォルダー名などに非ASCII文字を含むパスからも、アセットやファイルを読み込めるようになりました。

Windowsでは、テキストのコントラストが改善され、文字がくっきり表示されるようになりました。フレームごとに行っていた余分な全画面コピーも省き、GPUの負荷を抑えています。WindowsとLinuxの両方で、アンチエイリアスを改善し、重なったUI要素や独自の図形の輪郭に出るギザギザを減らしました。

## iOSとmacOS

Flutter 3.50は、Xcode 27とiOS 27の公開後、初めての安定版リリースです。iOSのタッチ応答や実機でのデバッグを改善しました。あわせて、CocoaPodsの利用終了や、Intel Macのサポート終了に向けた移行も進めています。

### iOSのタッチ応答を高速化

コミュニティの [Matej Knopp](https://github.com/knopp) は、iOSでタッチイベントが発生した後の、フレーム生成のタイミングを大幅に見直しました。タッチイベントを直ちにフレームワークへ渡すことで、次の垂直同期（vsync）を待たず、タッチが発生した画面更新の周期内でフレームを構築します。

この変更により、入力遅延を1フレーム分短縮しました。60 HzのiOS端末では16 ms、120 HzのProMotionディスプレーでは8 msの短縮です。2015年のiPhone 6sを含む幅広い実機でベンチマークを行い、改善を確認しています。今後のリリースに向けて、さらなる入力遅延の削減にも取り組んでいます。

![Flutter 3.50でiOSのタッチ応答が高速化した様子の比較。](/images/blog/flutter-3-50/ios-touch-response.webp)

_Flutter 3.50では、iOSのタッチ処理のタイミングを見直し、入力遅延を1フレーム短縮しました。_

詳しくは、[iOSのタッチ入力遅延のベンチマーク（#191199）](https://github.com/flutter/flutter/issues/191199) をご覧ください。

### iOS 27でのデバッグ

新しくペアリングしたiPhoneや、OSのアップグレード直後のiPhoneでアプリを実行すると、Xcodeを一度開くまで白い画面で止まってしまう問題を解消しました。Flutter CLIがデバッグに必要な端末の準備を自動で行い、失敗した場合は対処方法を案内します。iOS 27の端末で `flutter run` を実行した際に、起動時にときどき発生していたクラッシュも修正しました。また、Xcode 27でビルドすると、iOS 17以降使えなくなっていた `flutter screenshot` が、実機のiPhoneとiPadで再び利用できます。

デバッグ中に実行しているアプリのスクリーンショットを、ターミナルから直接撮影できるようになりました。

### Swift Package Managerへの移行

CocoaPods trunkが2026年12月に読み取り専用となることに伴い、Flutterが暫定的に残しているCocoaPodsへのフォールバックも、段階的に廃止する予定です。Flutter 3.50からは、Swift Package Managerを無効にしていると、Flutter CLIのすべてのコマンドで警告が表示されます。将来のリリースでは無効化するためのフラグを削除し、最終的にはCocoaPodsへのフォールバック自体も削除します。ビルドの問題を回避するためにSwift Package Managerを無効にしていた場合は、再び有効にして、問題なく使えるか確認してください。

詳しくは、[プラグイン作者向けのSwift Package Managerのガイド](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors) をご覧ください。

### Apple SiliconでのmacOSビルド

Intel Macの実機でのテストは終了しました。Intel Macでビルドすると、CLIに一度だけ警告が表示されます。今後のリリースで、開発環境としてのIntel Macのサポートが終了すると、iOS・macOS・Android向けのビルドにはApple Silicon搭載のMacが必要になります。Xcode 27では、macOSアプリにIntel向けのバイナリーを同梱する必要がなくなりました。`flutter config --enable-macos-arm64-only` を実行すると、Apple Silicon専用のmacOSアプリをビルドできます。このビルド方式は、今後のリリースで標準になる予定です。

詳しくは、[macOSのIntelサポートを非推奨にする方針](https://flutter.dev/go/macos-intel-deprecation) をご覧ください。

## Android

Androidでは、リリースモードでの `Intent` の扱いを厳格にし、セキュリティを強化しました。プラットフォームビュー向けのHybrid Composition++も改善しています。また、設定を有効にすることで、Android Gradle Plugin 9の新しいDSLを利用できるようになりました。

### Intentのセキュリティ強化

以前は、端末内のどのアプリから送られた場合でも、実行時設定を含む `Intent` の追加情報（extras）を受け入れていました。Flutter 3.50では、通常のディープリンクの動作を保ちながら、リリースビルドでこの脆弱性に対処しました。外部からの `Intent` のextrasに含まれる `route`、`dart_entrypoint`、`cached_engine_id` の値を無視します。また、`Intent` のextras経由で渡されたり、ビルド済みのリリースAPK（`--use-application-binary`）と組み合わせて指定されたりした `--dart-flags` などの実行時エンジンフラグも受け付けなくなりました。

デバッグビルドでは、無視したextrasについて警告がログに出力されます。ビルド済みのバイナリーに独自のエンジンフラグを指定してテストするには、profileモードを使うか、バイナリーを新しくビルドする必要があります。

詳しくは、[Androidのエントリーポイントに対するIntent検証の厳格化](https://docs.flutter.dev/release/breaking-changes/stricter-android-entrypoint-intent-verification) と [リリースモードでのAndroidエンジンフラグの制限](https://docs.flutter.dev/release/breaking-changes/restrict-android-engine-flags-release-mode) をご覧ください。

### Hybrid Composition++

Hybrid Composition++（HCPP）は、地図やWebビューなど、AndroidのネイティブビューをFlutterに埋め込むための新しい仕組みです。合成処理をAndroid OSに直接任せることで、従来の方式で起きていたスクロール時の表示のずれやテキスト入力の不具合を防ぎ、滑らかにスクロールできます。Flutter 3.50では、`AndroidViewSurface` のモーションイベントをバッファリングせずに渡すようにし、`RenderAndroidView` のレイアウト順序も修正しました。

コミュニティの [Amaan Ansari](https://github.com/amaan-0331) は、`Activity` の終了後も `FlutterEngine` が残っている場合に発生するクラッシュを修正しました。

HCPPはFlutter 3.44の安定版から利用できます。ベータチャネルでは3.49.0-0.1.pre以降、標準で有効になっており、今後は安定版でも標準になる予定です。利用には、Android 14（API 34）以上と、Vulkan上で動作するImpellerの両方が必要です。条件を満たさない端末では、これまでのプラットフォームビュー方式に自動的に切り替わります。

対応するAPI 34以上のVulkan端末で `flutter config --enable-hcpp` を実行してください。デバッグモードでプラットフォームビューを配置したときに、`logcat` に `Using HCPP platform view rendering strategy` と表示されれば、HCPPが使われています。

詳しくは、[Platform ViewsによるAndroidのネイティブビューのホスティング](https://docs.flutter.dev/platform-integration/android/platform-views#hcpp) をご覧ください。

### プラグイン向けのBuilt-in Kotlin

[Flutter 3.44の新機能](https://flutter.dev/blog/whats-new-in-flutter-3-44) で紹介したとおり、Androidコードを含むFlutterプラグインは、Android Gradle PluginのBuilt-in Kotlinへ移行する必要があります。Kotlin Gradle Plugin（KGP）を手動で適用しているプラグインは、今後 `pub.dev` の評価スコアが下がり、AGP 10ではビルドできなくなります。AGPのバージョンに応じて適用を切り替えている場合も同様です。プラグインのGradle設定を更新し、`pubspec.yaml` のSDK制約を `flutter: ">=3.44.0"` に設定したうえで、変更内容を `CHANGELOG.md` に記載してください。

詳しくは、[プラグイン作者向けのBuilt-in Kotlin移行ガイド](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors) をご覧ください。

### AGP 9の新しいDSLへの対応

Flutter 3.47から3.50までの開発期間に、Flutter Gradle Pluginを書き直しました。従来の `BaseExtension` の内部実装に依存する方式から、Android Gradle Plugin 9の新しい公開APIを使う方式へ移行しています。また、`flutter/packages` にあるすべての公式プラグインを更新し、各プラグインがサポートするAGPの全バージョンでBuilt-in Kotlinを使えるようにしました。Flutter 3.50の安定版では、プロジェクト内のすべてのプラグインがBuilt-in Kotlinに対応していれば、設定を有効にしてAGP 9の新しいDSLを利用できます。

詳しくは、[アプリ開発者向けのBuilt-in Kotlin移行ガイド](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) をご覧ください。

### Androidのツールチェーンの既定値を更新

Flutter 3.50で作成する新規Androidプロジェクトでは、Android Gradle Plugin（AGP）9.3.1とGradle 9.5.0を使います。Kotlin Gradle Plugin 2.4.20との組み合わせで動作を確認しており、Java 17以上が必要です。AGPのBuilt-in Kotlinを使う場合は、AGP側でKotlinの互換性を管理するため、FlutterからKotlinのバージョンに関する警告は表示されなくなります。Gradleのビルドで参照するSDK変数の既定値は、`flutter.compileSdkVersion` がAPI 36、`flutter.targetSdkVersion` がAPI 36、`flutter.minSdkVersion` がAPI 24です。

## 開発体験

日々の開発を支える機能として、AIエージェント向けの公式プラグインや、パッケージに同梱して再利用できるスキルが加わりました。Dart Analysis Serverでは、初回のリネーム処理も高速化しています。

### AIコーディング用のプラグインとパッケージのスキル

AIコーディング支援ツールを使うチーム向けに、公式ツールを拡充しました。Flutterの公式エージェントプラグインには、タスク別のスキル、DartとFlutterのMCPサーバー設定、用途別のエージェント、エージェントが継続して使うルールが含まれています。たとえば、`lib/` 以下を編集すると、MCPサーバー経由で `hot_reload` または `hot_restart` を実行するルール（`flutter-hot-reload`）があり、ホットリロードを自動で行います。

パッケージ作者は、`pub.dev` に公開するパッケージのトップレベルに `skills/` ディレクトリーを置き、エージェント用のスキルを同梱できます。アプリ開発者は `dart run skills@ get` を実行すると、依存パッケージに含まれるスキルを探してインストールできます。パッケージの公開前には、CIで `package:skills_lint` を実行し、`SKILL.md` のメタデータ（frontmatter）、ディレクトリー構成、命名規則がAgent Skillsの仕様に沿っているかを確認できます。

詳しくは、[AIを使った開発の始め方](https://docs.flutter.dev/ai/get-started) と [パッケージのスキル](https://dart.dev/ai/package-skills) をご覧ください。

### Analysis ServerとDevTools

Dart Analysis Serverでは、検索インデックスを構築する際に、同じ共有パッケージのディレクトリーを複数の解析ドライバーが重複して探索しないようにしました。これにより、複数のパッケージを含むワークスペースで、初回のリネーム処理が速くなりました。コンテキストが16個あるDevToolsのワークスペースでは、処理時間が2.0秒から0.9秒となり、57%高速化しています。また、Flutter DevToolsも独立した `material_ui` と `cupertino_ui` パッケージを使うようになりました。

## AIとエコシステム

AI分野では、Genkit Dartが安定版1.0になり、MediaPipeのFlutter向けパッケージも登場します。Google PlayのFlutterアプリ数は100万件を突破し、Flutterの設計を公開の場で議論するRFCプロセスも導入されます。

### Genkit Dart 1.0

Genkit Dartの安定版1.0がリリースされました。DartとFlutterで、複数のモデルを利用するフルスタックのAIエージェントアプリを構築できます。エンドツーエンドの型安全性に加え、フローのストリーミング、ツール呼び出し、OpenTelemetryを使ったトレースに対応しています。

![Genkit DartとA2UIを使ったCymbal BistroのFlutterアプリ。対話型の予約カードをストリーミングで表示し、予約ツールを呼び出すデモ。](/images/blog/flutter-3-50/genkit-dart.webp)

_Genkit Dart 1.0で、A2UIによる対話型の予約画面をストリーミングで表示し、ツールを呼び出す様子。_

詳しくは、[Genkit Dartのドキュメント](https://genkit.dev) をご覧ください。

### MediaPipeによるオンデバイスAI

Google AI Edgeの新しいMediaPipeパッケージが `pub.dev` に登場します。LiteRTとLiteRT-LMを利用し、画像・音声・テキストを扱う20種類の処理を、Flutterアプリから端末上で実行できます。推論のためのネットワーク通信が不要なので、通信による遅延やクラウドでの推論費用を避けられます。

詳しくは、[MediaPipe Tasks for Flutterのギャラリー](https://google.github.io/flutter-mediapipe/) をご覧ください。

<a id="google-playのアプリが100万本に"></a>

### Google PlayのFlutterアプリが100万件を突破

Google Playで公開されているFlutterアプリが100万件を超えました。Flutterでアプリを開発・公開し、その後も改良を続けてくださっているすべての開発者とチームに感謝します。

<a id="パッケージのエコシステムの注目点"></a>

### 注目のパッケージ

スクロールするリスト内でインラインのAdMobバナーを再利用する仕組みにより、iOSのベンチマークで23%の性能改善を確認しました。また、このリリース期間に公開されたコミュニティ製パッケージを2つ紹介します。Dartだけでクラウドインフラを定義できる [Terradart](https://terradart.dev/) と、Flutterで対話型のノード図をプログラムから作成できる [`vyuh_diagram_flutter`](https://pub.dev/packages/vyuh_diagram_flutter) です。

詳しくは、[AdMobバナー再利用のガイド](https://developers.google.com/admob/flutter/banner/banner-recycling) をご覧ください。

### 導入事例

世界中のチームが、Flutterで開発したアプリを本番環境で運用しています。[Holafly](https://flutter.dev/showcase/holafly) は、モバイルアプリを3か月で単一のFlutterモノレポに統合しました。月間アクティブユーザー200万人以上、eSIM 2,500万件という規模のサービスを支えています。[Knowunity](https://flutter.dev/showcase/knowunity) は、FlutterにGoとGeminiを組み合わせ、月間800万〜1,000万人の学生が利用するサービスを支えています。[Buzz](https://flutter.dev/showcase/buzz) は、iOSとAndroidのアプリにFlutterを採用しています。人とAIエージェントが一緒に作業できる、オープンソースのワークスペースです。

Google AI Edgeチームは、モバイルとデスクトップでオンデバイスAI推論を利用できるEloquentとForesightのアプリを、Flutterで開発しました。

### Flutterのビジネス上の価値

今後の開発計画でFlutterの採用を検討する技術部門のリーダーに向けて、2026年版のホワイトペーパーを公開しました。開発の生産性やスピード、事業面での投資対効果について、データに基づいて紹介しています。

詳しくは、[Flutterのビジネス上の価値](https://flutter.dev/why-flutter) をご覧ください。

<a id="flutter-rfcの発表"></a>

### Flutter RFCの導入

Flutterでは、技術設計や意思決定について公開の場で議論する、Request for Comments（RFC）プロセスを導入します。実装に着手する前からアイデアを共有し、選択肢ごとの利点や欠点を検討できます。各サブシステムのメンテナーと認識を合わせ、アーキテクチャーの方針をすり合わせるための、開かれた議論の場です。

詳しくは、[Flutterの設計ドキュメント](https://github.com/flutter/flutter/blob/master/docs/contributing/Design-Documents.md#flutter-rfcs--design-documents) と [`flutter/rfc`](https://github.com/flutter/rfc) をご覧ください。

## 非推奨化と破壊的変更

Flutter 3.50では、SDK同梱の `package:flutter/material.dart` と `package:flutter/cupertino.dart`、および対応する `flutter_localizations` のデリゲートを正式に非推奨としました。Androidのリリースビルドでは、`Intent` の検証が厳格になり、デバッグ用のエンジンフラグを受け付けなくなっています。

ウィジェットの動作にも4つの変更があります。`package:material_ui` の `DropdownButtonFormField` には、`enabled` プロパティを追加しました。`onChanged` コールバックに `null` を渡さずに、ドロップダウンを無効化できます。

ソフトハイフンを含む単語が行末で折り返されると、ハイフンが自動的に表示されるようになりました。右から左へ書くテキスト内のインラインの `WidgetSpan` 要素も、逆順になることなく、自然な読み順で表示されます。モバイルブラウザーでは、`viewport-fit=cover` が設定されていると、`SafeArea` が端末のノッチやホームインジケーターを考慮し、UIが画面の切り欠きなどに重ならないようにします。

フレームワークには、次の2つの変更もあります。

- 以前から非推奨だった `ignoringSemantics` プロパティを、`IgnorePointer`、`AbsorbPointer`、`SliverIgnorePointer` と、それらのレンダーオブジェクトから削除しました。
- `RenderProxyBox` や、`RenderProxyBoxMixin` を使うほかのレンダーオブジェクトでは、子がベースラインを持たない場合、`computeDryBaseline` がアサーションエラーを起こさずに `null` を返すようになりました。

詳しくは、[Flutterの破壊的変更](https://docs.flutter.dev/release/breaking-changes) をご覧ください。

## Flutter 3.50にアップグレード

issueの報告や設計レビュー、プルリクエストを通じて、Flutterのこれからの10年を支える開発に協力してくださった皆さんに感謝します。Flutter 3.50は、[Dart 3.14](https://dart.dev/blog/announcing-dart-3-14) とともに利用できます。SDKをアップグレードして、今回追加された機能を試してみてください。

```bash
flutter upgrade
```

今回のリリースに含まれる全プルリクエストの一覧や詳しい変更内容は、[Flutter 3.50のリリースノート](https://docs.flutter.dev/release/release-notes/release-notes-3.50.0) と [破壊的変更](https://docs.flutter.dev/release/breaking-changes) をご覧ください。

---

## 出典とライセンス

本文・図の説明・代替テキストを日本語に翻訳し、読みやすさを考慮して語順や言い回し、見出し、改行を調整しています。製品名、API名、コード例、バージョン番号は原文の表記を保持しています。冒頭の要約はOpenCIが追加しました。

- **原文：** [What's new in Flutter 3.50](https://flutter.dev/blog/whats-new-in-flutter-3-50) — [Emma Twersky](https://github.com/twerske)、The Flutter Blog、2026年11月11日公開。
- **日本語訳・要約：** OpenCI。2026年11月12日時点の原文をもとに翻訳しました。原文の一人称はFlutterチームを指します。
- **本文と図版：** 原文の [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ja) に基づき掲載しています。日本語訳と追加した要約も、同じCC BY 4.0で公開します。図中の英語は原文のままです。再利用時は原著者・原文・ライセンス・翻訳や変更の表示を保持してください。
- **コード例：** 原文の指定に従い、[BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause) を適用します。[Flutterの著作権表示とライセンス全文](/licenses/flutter-BSD-3-Clause.txt) も併せて掲載しています。
- **商標：** Flutterなどの名称・商標は各権利者に帰属します。本記事はGoogle／Flutterによる公式翻訳・推奨・承認を示すものではありません。
