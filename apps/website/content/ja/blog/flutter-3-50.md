---
layout: blog-article
title: |-
  Flutter 3.50の新機能
  非公式日本語訳
description: Flutter 3.50の公式発表を全文日本語訳。ネイティブAPIとの直接連携の安定化、WebAssemblyの高速化、Material／Cupertinoのパッケージ分離、iOSの入力遅延改善などを、短い要約とともに紹介します。
category: Flutter
date: "2026-11-12"
readTime: 20 min read
author: Emma Twersky（原著）／GenuineCI（日本語訳）
coverLabel: UNOFFICIAL JAPANESE TRANSLATION
coverTitle: Flutter 3.50
---

Emma Twersky 著「[What's new in Flutter 3.50](https://flutter.dev/blog/whats-new-in-flutter-3-50)」（The Flutter Blog、2026年11月11日公開）の**非公式日本語訳**です。原文の本文・図版は [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ja)、コード例は [BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause) に基づき掲載しています。

## まずは要点だけ

_この節はGenuineCIによる要約です。次の「日本語訳」以降が原文本文の翻訳です。_

- **ネイティブAPIとの直接連携が安定版に。** FFIgenとJNIgenを使い、DartからObjective-C・Java・KotlinのAPIを直接呼び出せます。Pigeonの新しい連携モードはプレビューです。
- **Webの実行速度と更新時のキャッシュを改善。** Safari／FirefoxでのWebAssembly実行が高速化し、`--web-content-hash` でファイル名にコンテンツハッシュを付けられます。
- **Material／Cupertinoの分離が次の段階へ。** 従来のSDK同梱ライブラリが非推奨となり、新規プロジェクトでは独立した `material_ui` を標準で使います。
- **iOSのタッチ入力遅延を1フレーム短縮。** iOS 27での実機デバッグも改善され、Swift Package Managerへの移行とIntel Macのサポート終了に向けた準備が進みます。
- **Androidのセキュリティとビルド環境を更新。** リリースビルドの `Intent` 検証を強化し、AGP 9の新DSLにオプトインで対応します。プラグインはBuilt-in Kotlinへの移行が必要です。
- **AI開発向けの公式ツールを拡充。** AIコーディング支援用の公式プラグイン、パッケージに同梱できるスキル、Genkit Dart 1.0、MediaPipeによるオンデバイスAIが紹介されています。

## 日本語訳

_Flutterの次の10年に向けた投資_

Flutter 3.50が、[Dart 3.14](https://dart.dev/blog/announcing-dart-3-14) とともにリリースされました。今回のリリースには、Flutterがこれから向かう方向を示す数々の更新が含まれています。ネイティブAPIとの直接連携が安定版となり、DartとネイティブプラットフォームのAPIを相互に呼び出せるようになりました。SafariとFirefoxで高速化されたWebAssemblyに加え、ブラウザー標準のテキストレイアウトにより、FlutterのWebアプリの速度が大きく向上します。

独自ハードウェアに対応するためのプラットフォーム埋め込みAPIも拡充しました。また、新規プロジェクトでは、独立した `material_ui` と `cupertino_ui` パッケージが標準となります。

いつもと同じく、これらはFlutterコミュニティと、フレームワークやエコシステム全体への皆さんの貢献なしには実現できませんでした。今回のリリースサイクルだけでも、初参加の69人を含む188人のコントリビューターが、1,200件以上のコミットを取り込みました。ターミナルで `flutter upgrade` を実行して最新版を入手するか、このまま読み進めて新機能をご覧ください。

## ネイティブAPIとの直接連携

昨年、私たちは、従来のプラットフォームチャネルに伴うシリアライズのオーバーヘッド、文字列ベースの接続処理、必ず非同期になることによる遅延をなくすため、[ネイティブAPIとの直接連携に向けた構想](https://flutter.dev/blog/flutters-path-towards-seamless-interop) を発表しました。Flutter 3.50では、その数年にわたる取り組みが本番で使える段階に到達しました。以前から安定版だったFFIgenのCサポートに加え、Objective-C向けの [FFIgen](https://pub.dev/packages/ffigen) と、Java／Kotlin向けの [JNIgen](https://pub.dev/packages/jnigen) が安定版となります。

また、両ジェネレーターを内部で使って型安全なバインディングを生成する、[Pigeon](https://pub.dev/packages/pigeon) の新しいネイティブ連携モードもプレビューできます。

ネイティブ機能との連携では、プラットフォームチャネルでのメッセージのやり取りを省き、Dartとプラットフォームコードを直接呼び出せるようになりました。同期呼び出しやバックグラウンドのisolateからの呼び出しも可能です。FFIgenではCやObjective-CのAPIに、JNIgenではAndroidのシステムAPIや独自のJava／Kotlinライブラリにバインディングを作成し、FlutterやDartのアプリで利用できます。複数のプラットフォームに対応するプラグインを作る場合は、Pigeonのネイティブ連携モードが、iOS・macOS・Androidでのデータ変換とネイティブオブジェクトのライフタイムを自動的に管理します。

![従来のMethodChannelによるシリアライズと、生成されたJNI／FFIバインディングによるホストAPIの直接呼び出しの比較。](/blog/flutter-3-50/native-interop.webp)

_ネイティブAPIとの直接連携では、プラットフォームチャネルのシリアライズを省き、FFIとJNIを通じてネイティブAPIを直接呼び出します。_

パッケージ作者、コントリビューター、Early Access Program参加者の皆さん、とりわけJon Holtan、Rody Davis、Dominik Roszkowski、Alexander Thiele、Morgan McKenzieに感謝します。コミュニティの皆さんは、初期ビルドのテスト、ドキュメントのレビュー、APIの設計に協力してくれました。ネイティブAPIとの直接連携については、今後、専用の記事で詳しくお伝えします。

詳しくは、[ネイティブ連携のドキュメント](https://docs.flutter.dev/interop) をご覧ください。

## Webプラットフォーム

Webでは、Flutter 3.50は、ブラウザーをまたいだWebAssembly実行の高速化に加え、組み込みのアセットキャッシュ更新機能、最新のJS連携を使っているかどうかのチェック、より小さなブラウザー標準のテキスト描画を組み合わせています。

### SafariとFirefoxでのWebAssembly

`flutter build web --wasm` を実行すると、アプリをWebAssemblyとJavaScriptの両方にコンパイルし、古いブラウザーでは自動的にJavaScriptにフォールバックします。Chromium系ブラウザー（ChromeとEdge 137以降）では、すでにWebAssemblyが標準で使われています。Flutter 3.50では、Safari 26.2以降（macOSとiOS）とFirefox 147以降で、負荷の高いウィジェットのベンチマークにおいて、JavaScriptの2倍を超えるフレームレートを実現しました。将来の安定版で標準になるのに先立ち、今すぐ `web/flutter_bootstrap.js` で次のようにオプトインできます。

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

### Webコンテンツのハッシュを組み込みでサポート

FlutterのWebアプリを更新してデプロイしても、再訪したユーザーのブラウザーに古いJavaScriptや整合しないアセットがキャッシュされていることがあります。`flutter build web` に `--web-content-hash` を渡すと、コンパイルされたJavaScript、WebAssembly、`build/web/assets/**` のファイル名にコンテンツハッシュを埋め込み、`flutter_bootstrap.js` を自動更新して、この問題を解決します。

これにより、ハッシュ付きのアプリバンドルとアセットを最長1年間キャッシュしつつ（`Cache-Control: public, max-age=31536000, immutable`）、`index.html` と `flutter_bootstrap.js` は `no-cache` にして、毎回のデプロイで正しい組み合わせを読み込めます。このフラグは、独自のService WorkerやWorkboxのパイプライン向けに `build/web/precache_manifest.json` も生成し、非推奨となった `flutter_service_worker.js` のトークンを置き換えます。

詳しくは、[WebコンテンツのハッシュとHTTPキャッシュ](https://docs.flutter.dev/deployment/web#web-content-hashing) をご覧ください。

### Webでの従来のJS連携をチェック

FlutterのWebアプリやプラグインは、JS連携ライブラリを使ってローカルストレージなどのブラウザー機能にアクセスしたり、サードパーティーのJavaScript SDKをラップしたりします。Dartの従来のJavaScript専用ライブラリ（`dart:html`、`dart:js`、`dart:js_util`、`package:js`）は、`dart:js_interop` と `package:web` への移行を促すため非推奨となりました。新しいライブラリはJavaScriptとWebAssemblyのどちらのビルドでも動作し、従来のライブラリは将来のDartリリースで削除される予定です。

`flutter build web`、`flutter run`、`flutter test --platform chrome` に `--no-deprecated-js-interop` を渡すと、古いJS関連のインポートを検出できます。アプリや依存パッケージが従来のブラウザーライブラリに依存している場合に、ビルドを早い段階で失敗させ、WebAssemblyへの準備を進められます。

詳しくは、[互換性のあるJS連携ライブラリの使用](https://docs.flutter.dev/platform-integration/web/wasm#js-interop-wasm) と [Dart 3.14の発表](https://dart.dev/blog/announcing-dart-3-14) をご覧ください。

### ブラウザー標準のテキストレイアウトのプレビュー

Chromeチームと協力し、Chromeの実験的なEnhanced `TextMetrics` APIを使って構築した `WebParagraph` では、C++のフォントパーサーを同梱する代わりに、ブラウザーがOSのフォントを直接キャンバス上でシェーピングできます。テキストレイアウトをブラウザーに任せることで、CanvasKitのダウンロードサイズを5.46 MBから約3.75 MBに縮小し、フォールバックフォントのネットワークリクエストをなくします。さまざまな言語の文字が豆腐と呼ばれる欠字の四角になることを防ぎ、ネイティブのカラー絵文字も描画します。

詳しくは、[WebParagraphの実験的プレビュー（#172561）](https://github.com/flutter/flutter/issues/172561) をご覧ください。

## プラットフォームの差し替え対応

[Google I/Oで発表したPluggable Platforms](https://youtu.be/I1uIbGh1dGE?t=2294) に続き、Flutterを新しいOSやハードウェアへ移植しやすくする取り組みを進めています。Flutter 3.50では、基盤となるImpellerとVulkanの埋め込みAPIで、重要な2つの不足を補いました。コミュニティのコントリビューター [xiaowei-guan](https://github.com/xiaowei-guan) がVulkanの外部テクスチャをサポートし、独自の埋め込み実装から [テクスチャをエンジンに直接渡し](https://github.com/flutter/flutter/pull/188855)、ImpellerとSkiaの両バックエンドでサンプリングできるようにしました。

独自の埋め込み実装は、メモリが不足したときに `FlutterEngineNotifyLowMemoryWarning` を呼び出して、[Impellerのオフスクリーン描画ターゲットのキャッシュを即座に解放](https://github.com/flutter/flutter/pull/193497) できるようにもなりました。

## デザインパッケージの分離

Flutter 3.47で独立した `material_ui` と `cupertino_ui` の1.0を公開したのに続き、Flutter 3.50では、SDKに組み込まれた `package:flutter/material.dart` と `package:flutter/cupertino.dart` のライブラリ、および `package:flutter_localizations` 内のそれらのローカライズデリゲートを正式に非推奨としました。`flutter create` で作成する新規プロジェクトは、標準で `package:material_ui` をインポートします。

![SDK同梱のmaterial.dart／cupertino.dartから、pub.dev上の独立したmaterial_ui／cupertino_uiパッケージへ、dart fixで移行する流れ。](/blog/flutter-3-50/design-packages.webp)

_`dart fix` を使い、SDK同梱のデザインライブラリから、独立した `material_ui` と `cupertino_ui` へ移行します。_

`dart fix --apply --code=migrate_design_widgets` を実行すると、既存のインポートとローカライズデリゲートを自動的に更新できます。

詳しくは、[MaterialとCupertinoの移行ガイド](https://docs.flutter.dev/release/breaking-changes/material-ui-and-cupertino-ui) と [MaterialとCupertinoの分離](https://flutter.dev/blog/decoupling-material-cupertino) をご覧ください。

## フレームワーク

フレームワークでは、コミュニティとチームの貢献により、sliverをクリップするウィジェット、より安定したテキスト選択、論理サイズに基づく画像キャッシュ、アクセシビリティの改善、デスクトップのマルチウィンドウ機能の更新が加わりました。

### スクロールとsliver

コミュニティのコントリビューターは、Flutter 3.50の独自スクロールビュー向けに、優れた改善を届けてくれました。[Emmanuel Lefebvre Dibon](https://github.com/manu-sncf) は、`clipOverlap` オプションを備えた `SliverClipRect` と `SliverClipRRect` を追加しました。固定されたヘッダーを切り落とさずに、スクロールする領域を角丸にしたりクリップしたりできます。[Mairramer](https://github.com/Mairramer) は、`ListView.separated` に `itemExtentBuilder` を追加しました。区切り線のあるリストで、画面外のウィジェットを構築せずに、可変の高さを持つ行のサイズを必要に応じて決定できます。

Mairramerは `ScrollPhysics.shouldUpdate` も導入しました。設定が変わったときに、アプリのスクロール動作を動的に更新できます。[Soroush Yousefpour](https://github.com/gabrimatic) は `RawScrollbar.mouseCursor` を更新し、スクロールバーのつまみとトラックの上にあるときだけマウスポインターを変更し、周囲のコンテンツでは通常のカーソルを保つようにしました。また、フレームワークの修正により、`Scrollable.ensureVisible` は固定ヘッダーを通り過ぎず、表示に必要な正確な位置でスクロールを止めるようになりました。

`SliverFillRemaining` は、スクロールビューの末尾でオーバースクロールによる伸縮のオフセットを正確に計算するようになりました。最後に、`TreeSliver` は展開・折りたたみ中の枝を適切にクリップし、アニメーション中の子の行が隣の項目に重ならないようにします。

<figure>
  <img src="/blog/flutter-3-50/sliver-clip-rrect.webp" alt="SliverClipRRectがスクロールするsliverコンテンツを角丸の領域にクリップするアニメーション。" width="320" loading="lazy" />
  <figcaption>SliverClipRRectは、固定ヘッダーを切り落とさずにスクロール領域を角丸にクリップします。</figcaption>
</figure>

### テキスト入力と選択

モバイル・Web・デスクトップ全体で、テキスト編集と選択がより安定しました。[Alex Li](https://github.com/AlexV525) は、`TextInputType.numberWithOptions` に `password` オプションを追加しました。Androidアプリで、PIN入力用の安全な数字キーボードを開けます。また、Androidアプリでは `AutofillHints.emailOTPCode` を使い、メールのワンタイム認証コードを自動入力できます。新しい `Hyphens` 列挙型では、行の折り返し時にソフトハイフンを表示するかどうかを制御できます。

[Nicodemus Lin](https://github.com/nicolinx) は、複数行テキストの上側の選択ハンドルをドラッグしたときに、画面が跳ねる問題を修正しました。[Nickolas de Luca Alberton](https://github.com/nickolasdeluca) は、中央寄せや右寄せの単一行テキストフィールドで、上下の矢印キーによるカーソル移動を修正しました。`PageView` 内でドラッグしてテキストを選択しても、誤って隣のページへ切り替わらなくなりました。左から右に書く文字と右から左に書く文字が混在する場合も、選択ハンドルが選択したテキストの方向を向いたままになります。

### 画像と描画のAPI

コミュニティのコントリビューターは、Flutterの画像読み込みとキャッシュのAPIも充実させました。[Kishan Rathore](https://github.com/rkishan516) は、`DecorationImage` に `ImageProvider` 型の `placeholder` を追加しました。背景画像を読み込んでいる間、コンテナーに代わりの画像を表示できます。[Anas Saifi](https://github.com/anazr9) は `FadeInImageTransition.fadeInOver` を追加しました。不透明なプレースホルダーの上に画像を滑らかにフェードインさせ、途中で空白がちらつくのを防ぎます。

[Koji Wakamiya](https://github.com/koji-1009) は、`ResizeImage` に `useLogicalSize`、`Image` に `useLogicalCacheSize` を追加しました。`BuildContext` なしで、画面密度に合わせてキャッシュ画像のサイズを調整できます。[Ishaq Hassan](https://github.com/ishaquehassan) は `RawImage` に `blendMode` を公開し、独自ウィジェットで画像を描画するときに、直接色のブレンド効果を適用できるようにしました。独自形状の `BoxBorder` も、アニメーション中に状態間を滑らかに遷移するようになりました。

`HSVColor.lerp` と `HSLColor.lerp` による色のアニメーションでは、色相環の最短経路を通るようになり、意図しない色の変化を防ぎます。

<figure>
  <img src="/blog/flutter-3-50/image-placeholder.webp" alt="DecorationImageがぼかしたプレースホルダーのカードを表示した後、鮮明な画像を読み込むアニメーション。" width="320" loading="lazy" />
  <figcaption>DecorationImage.placeholderは、背景画像の読み込み中に代わりの画像を表示します。</figcaption>
</figure>

### アクセシビリティとナビゲーション

Flutter 3.50は、各プラットフォームのキーボード操作、スクリーンリーダー対応、ダイアログのカスタマイズを改善します。独自のスライダーウィジェットでは、`SemanticsRole.slider` を使い、スクリーンリーダーが値と操作を正確に読み上げられるようになりました。アプリは `MediaQueryData.reduceMotion` でユーザーの「視差効果を減らす」設定を検出し、スライドアニメーションを穏やかなフェードに置き換えられます。Escapeキーを押すと、キーボードフォーカスを動かさずに、開いている `Tooltip` と `RawTooltip` のオーバーレイを閉じるようになりました。これにより、Webのアクセシビリティ基準を満たします。

Webでは、VoiceOverと `WidgetsApp.router` の修正により、オーバーレイ内のスクリーンリーダーとキーボードのフォーカスが、予期せずリセットされずに保たれます。[Ishaq Hassan](https://github.com/ishaquehassan) が追加した `FocusableActionDetector` の `skipTraversal` オプションにより、独自の操作可能なウィジェットをTabキーでの移動対象から除外できます。ダイアログでは、[Mairramer](https://github.com/Mairramer) が `showDialog` に追加した `barrierBuilder` コールバックを使い、背景のぼかしなど、モーダルの背面をカスタマイズできます。

最後に、`Navigator.popUntilWithResult` は、移動先のルートにローカル履歴のエントリーがある場合でも、最後にpopされたルートへ結果を返すようになりました。

### デスクトップのウィンドウ

Canonicalとの連携、そしてメンテナーの [Robert Ancell](https://github.com/robert-ancell)、[Matthew Kosarek](https://github.com/mattkae)、[Matej Knopp](https://github.com/knopp) の尽力により、Flutterの実験的なデスクトップ向けマルチウィンドウAPIは、Linux・macOS・Windowsで成熟を続けています。Linuxでは、`WindowControllerLinux` を使い、独自のタイトルバー、透過ウィンドウ、ネイティブのドラッグによる移動やサイズ変更の操作を実装できます。

macOSでは、表示前にウィンドウとダイアログの大きさをコンテンツに合わせられるようになり、起動時にサイズ変更が一瞬見えるのを防ぎます。3つのデスクトッププラットフォーム全体では、マルチウィンドウのコードを簡潔にするため、`RegularWindow` を `Window` に改名しました。Flutterで馴染みのあるレイアウトの命名に合わせ、`sizedToContent` プロパティも `shrinkWrap` に置き換えられます。最後に、`WindowManager` は `WidgetsApp` より上に配置されるようになり、追加のウィンドウが独立したUIとナビゲーション状態を持てます。

![macOSで動作するFlutter Multi-Window Reference Application。メインウィンドウと別ウィンドウのダイアログを表示している。](/blog/flutter-3-50/desktop-multi-window.webp)

_macOSで動作するデスクトップのマルチウィンドウのリファレンスアプリ。_

## エンジン

内部では、Flutter 3.50は、Impellerのハードウェアアクセラレーションによるプリミティブ描画を拡張し、モバイルGPUの安定性を改善するとともに、WindowsとLinuxのグラフィックスの再現性を高めます。

### Impellerの描画

macOS・Linux・Windows向けのImpellerのSigned Distance Field（SDF、符号付き距離場）レンダラーは、複雑な形状をCPUで計算する代わりに、GPUで直接、鮮明な枠線・図形・グラデーションを描画します。これにより、フレームの描画時間が短くなり、カード・枠線・影が多数ある画面でも、スクロールとアニメーションを滑らかに保てます。Flutter 3.50では、この高速な描画経路を、線・細い枠線・角丸・グラデーションへと拡張し、macOSのグラデーションや繰り返し描画されるテキストの影も高速化しました。

独自の3Dシーンや2Dゲーム向けに、Flutter GPUは2Dテクスチャ配列をサポートします。ゲームやグラフィックスの開発者は、スプライトシート、タイルマップ、地形のレイヤーを、タイル間に継ぎ目を生じさせず、より少ない描画呼び出しにまとめられます。また、シェーダーパイプラインの設定に問題があるとき、Flutter GPUがよりわかりやすいDartのエラーメッセージを返すようになり、グラフィックスのバグを早く発見・修正できます。

![ImpellerのSDFとMSAAの拡大比較。SDFでは斜めの輪郭が滑らかになり、MSAAでは階段状に見える。](/blog/flutter-3-50/impeller-sdf.webp)

_ImpellerのSDFレンダラーは、GPUで直接、鮮明でアンチエイリアスの効いた輪郭を描画します。_

コミュニティのコントリビューターは、OpenGLの起動とGPUの安定性についても、効果の大きい修正を取り込みました。[xiaowei-guan](https://github.com/xiaowei-guan) は、OpenGLのシェーダー初期化をバックグラウンドスレッドへ移し、最初のフレームをより早く表示できるようにしました。[seunggi](https://github.com/dfdgsdfg) は、テクスチャ読み込み時のMali GPUのクラッシュを解消し、該当するAndroid端末でアプリが突然終了するのを防ぎました。[krll-kov](https://github.com/krll-kov) は、古い端末でのOpenGL ES 2のテクスチャ描画を修正し、アニメーション画像のフレームをまたいで透明度を保つようにしました。

描画の不具合を防ぐため、BシリーズのPowerVR GPUでは、VulkanからOpenGLへ自動的にフォールバックするようにもなりました。

### デスクトップのグラフィックス

WindowsとLinuxでは、描画の再現性と性能を大きく改善しました。Windowsのエンジンは、古いPCへの対応を維持しつつ新しいグラフィックス機能を利用できるよう、OpenGL ES 2への自動フォールバックを保ちながら、[標準でOpenGL ES 3を要求](https://github.com/flutter/flutter/pull/191516) するようになりました。Windowsアプリでは、各国語のユーザー名やフォルダー名など、ASCII以外の文字を含むパスからアセットやファイルを読み込めるようにもなりました。

Windowsでは、コントラストを改善してテキストをより鮮明に描画し、各フレームでの余分な全画面コピーを省いて、GPUの負荷を下げます。WindowsとLinuxの両方で、アンチエイリアスの改善により、重なったUI要素や独自の図形のギザギザが滑らかになります。

## iOSとmacOS

Xcode 27とiOS 27の公開後、最初の安定版リリースとなるFlutter 3.50では、iOSのタッチ入力遅延を減らし、実機デバッグを円滑にするとともに、CocoaPodsとIntel Macからの移行を進めます。

### iOSのタッチ応答を高速化

コミュニティの [Matej Knopp](https://github.com/knopp) は、iOSのタッチイベントの後に、エンジンがフレーム生成をどのようにスケジュールするかを大幅に見直しました。タッチイベントを直ちにフレームワークへ渡すため、次のvsyncを待たずに、同じディスプレー更新の周期内でフレームを構築します。

その結果、入力遅延が丸1フレーム減りました。60 HzのiOS端末では16 ms、120 HzのProMotionディスプレーでは8 msの短縮です。2015年のiPhone 6sにまでさかのぼる実機で、幅広いベンチマークにより確認しています。今後のリリースでiOSの入力遅延をさらに下げるため、追加の作業も進めています。ご期待ください。

![Flutter 3.50でiOSのタッチ応答が高速化した様子の比較。](/blog/flutter-3-50/ios-touch-response.webp)

_Flutter 3.50では、iOSのタッチ処理のスケジュールを高速化し、入力遅延を1フレーム短縮します。_

詳しくは、[iOSのタッチ入力遅延のベンチマーク（#191199）](https://github.com/flutter/flutter/issues/191199) をご覧ください。

### iOS 27でのデバッグ

新しくペアリングしたiPhoneや、アップグレード直後のiPhoneでアプリを実行するとき、Xcodeを一度開くまで白い画面のまま止まることがなくなりました。Flutter CLIが端末を自動的に準備し、準備に失敗した場合は、必要な対応を案内します。Flutter 3.50では、iOS 27の端末で `flutter run` を使ったときに、起動時にときどき発生していたクラッシュも解消しています。Xcode 27でビルドすると、iOS 17以降初めて、実機のiPhoneとiPadで `flutter screenshot` が再び使えるようになります。

デバッグ中に実行しているアプリのスクリーンショットを、ターミナルから直接撮影できるようになりました。

### Swift Package Managerへの移行

CocoaPods trunkが2026年12月に読み取り専用となるため、Flutterの一時的なCocoaPodsへのフォールバックも終了に向かっています。Flutter 3.50からは、Swift Package Managerを無効にすると、Flutter CLIのすべてのコマンドで警告が表示されます。将来のリリースでは、無効化するためのフラグを削除し、最終的にはCocoaPodsへのフォールバック自体も削除する予定です。以前、ビルドの問題を回避するためにSwift Package Managerを無効にした場合は、今のうちに再び有効にし、設定を確認してください。

詳しくは、[プラグイン作者向けのSwift Package Managerのガイド](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-plugin-authors) をご覧ください。

### Apple SiliconでのmacOSビルド

FlutterはIntel Macの実機でのテストを行わなくなり、Intel Macでビルドすると、CLIが一度だけ警告を表示するようになりました。将来のリリースでIntel Macをホストとして使うサポートが終了すると、iOS・macOS・Android向けのビルドにはApple Silicon搭載のMacが必要になります。Xcode 27ではmacOSアプリにIntel向けのバイナリーを同梱する必要がなくなったため、今すぐ `flutter config --enable-macos-arm64-only` を実行して、Apple Silicon専用のmacOSアプリをビルドできます。これは、今後のリリースで標準になる予定です。

詳しくは、[macOSのIntelサポートを非推奨にする方針](https://flutter.dev/go/macos-intel-deprecation) をご覧ください。

## Android

Androidでは、Flutter 3.50はリリースモードの `Intent` のセキュリティを強化し、プラットフォームビュー向けのHybrid Composition++を拡充するとともに、Android Gradle Plugin 9の新しいDSLへのオプトインによる対応を可能にします。

### Intentのセキュリティ強化

以前のFlutter製Androidアプリは、ユーザーの端末にインストールされた、どのアプリからでも、実行時の設定を含む `Intent` のextrasを受け入れていました。Flutter 3.50は、標準のディープリンクを維持しながら、リリースビルドにおけるこの脆弱性を解消します。リリースビルドでは、外部の `Intent` のextrasに含まれる `route`、`dart_entrypoint`、`cached_engine_id` の値を無視します。また、`Intent` のextrasから渡されたり、ビルド済みのリリースAPK（`--use-application-binary`）と組み合わせて渡されたりする `--dart-flags` などの実行時のエンジンフラグを拒否します。

デバッグビルドでは、無視したextrasについて警告をログに出力します。ビルド済みのバイナリーに独自のエンジンフラグを指定してテストする場合は、profileモードか、新しくビルドしたバイナリーが必要になりました。

詳しくは、[Androidのエントリーポイントに対するIntent検証の厳格化](https://docs.flutter.dev/release/breaking-changes/stricter-android-entrypoint-intent-verification) と [リリースモードでのAndroidエンジンフラグの制限](https://docs.flutter.dev/release/breaking-changes/restrict-android-engine-flags-release-mode) をご覧ください。

### Hybrid Composition++

Hybrid Composition++（HCPP）は、地図やWebビューなどのAndroidのネイティブビューを埋め込むための、Flutterの最新のプラットフォームビューの仕組みです。従来の合成方式で発生していた、スクロール時の表示のずれやテキスト入力の不具合を防ぎます。合成処理をAndroid OSに直接任せることで、HCPPは滑らかなスクロールを実現します。Flutter 3.50では、`AndroidViewSurface` におけるモーションイベントをバッファリングせずに配信し、`RenderAndroidView` のレイアウト順序を修正して、さらに改善しました。

コミュニティの [Amaan Ansari](https://github.com/amaan-0331) は、`FlutterEngine` が `Activity` より長く存続するときに発生するクラッシュも修正しました。

HCPPはFlutter 3.44の安定版から利用でき、ベータチャネルでは3.49.0-0.1.pre以降、標準で有効になっています。安定版でも将来、標準になる予定です。HCPPにはAndroid 14（API 34）以上と、Vulkan上で動作するImpellerの両方が必要です。両方を満たさない端末では、既存のプラットフォームビュー方式へ自動的にフォールバックします。

対応するAPI 34以上のVulkan端末では、`flutter config --enable-hcpp` を実行し、デバッグモードでプラットフォームビューを配置した際に、`logcat` へ `Using HCPP platform view rendering strategy` と表示されることを確認してください。

詳しくは、[Platform ViewsによるAndroidのネイティブビューのホスティング](https://docs.flutter.dev/platform-integration/android/platform-views#hcpp) をご覧ください。

### プラグイン向けのBuilt-in Kotlin

[Flutter 3.44の新機能](https://flutter.dev/blog/whats-new-in-flutter-3-44) で紹介したとおり、Androidコードを持つFlutterプラグインは、Android Gradle PluginのBuilt-in Kotlinへ直接移行する必要があります。AGPのバージョン判定で分岐している場合も含め、Kotlin Gradle Plugin（KGP）を手動で適用しているプラグインは、将来 `pub.dev` のスコアが低くなり、AGP 10ではビルドできなくなります。プラグインのGradle設定を更新し、`pubspec.yaml` のSDK制約を `flutter: ">=3.44.0"` に設定し、変更内容を `CHANGELOG.md` に記載してください。

詳しくは、[プラグイン作者向けのBuilt-in Kotlin移行ガイド](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors) をご覧ください。

### AGP 9の新しいDSLへの対応

Flutter 3.47から3.50までの間に、Flutter Gradle Pluginを、従来の `BaseExtension` の内部実装ではなく、Android Gradle Plugin 9の新しい公開APIを使うように書き直しました。また、`flutter/packages` 内のすべての公式プラグインを、対応するAGPの各バージョンでBuilt-in Kotlinを使えるように移行しました。Flutter 3.50の安定版では、プロジェクト内のすべてのプラグインがBuilt-in Kotlinに対応したら、AGP 9の新しいDSLにオプトインできます。

詳しくは、[アプリ開発者向けのBuilt-in Kotlin移行ガイド](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers) をご覧ください。

### Androidのツールチェーンの既定値を更新

Flutter 3.50で作成する新規Androidプロジェクトは、Android Gradle Plugin（AGP）9.3.1とGradle 9.5.0を使います。Kotlin Gradle Plugin 2.4.20と、最小要件となるJava 17で動作を確認しています。AGPのBuilt-in Kotlinを使う場合は、AGPがKotlinの互換性を直接管理するため、FlutterはKotlinのバージョンに関する警告を表示しなくなります。今回のリリースでGradleのビルドに公開されるSDK変数の既定値は、`flutter.compileSdkVersion` がAPI 36、`flutter.targetSdkVersion` がAPI 36、`flutter.minSdkVersion` がAPI 24です。

## 開発体験

Flutter 3.50では、日々の作業を支える更新として、AIエージェント向けの公式プラグイン、再利用可能なパッケージのスキル、Dart Analysis Serverにおける初回リネーム処理の高速化が加わります。

### AIコーディング用のプラグインとパッケージのスキル

Flutter 3.50は、AIコーディング支援ツールで開発するチーム向けに、公式のツールを拡充します。Flutterの公式エージェントプラグインには、タスクごとのエージェントスキル、DartとFlutterのMCPサーバーの設定、専門エージェント、継続して適用されるエージェントルールがまとめられています。`lib/` 以下を編集すると、MCPサーバー経由で `hot_reload` または `hot_restart` を実行する、ホットリロードの自動実行ルール（`flutter-hot-reload`）も含まれます。

パッケージ作者は、`pub.dev` パッケージのトップレベルの `skills/` ディレクトリーに、エージェントのスキルを直接同梱することもできます。アプリ開発者は `dart run skills@ get` を使い、パッケージの依存関係からスキルを見つけてインストールできます。作者は公開前に、CIで `package:skills_lint` を実行し、`SKILL.md` のfrontmatter、ディレクトリー構成、命名規則がAgent Skillsの仕様に沿っているかを確認できます。

詳しくは、[AIを使った開発の始め方](https://docs.flutter.dev/ai/get-started) と [パッケージのスキル](https://dart.dev/ai/package-skills) をご覧ください。

### Analysis ServerとDevTools

日々のエディターでの作業では、Dart Analysis Serverが検索インデックスを構築するとき、複数の解析ドライバーで重複していた、共有パッケージのディレクトリー探索をまとめるようになりました。これにより、複数パッケージからなるワークスペースでの初回リネーム要求を高速化します。16個のコンテキストを持つDevToolsのワークスペースでは、2.0秒から0.9秒へと57%高速化しました。また、Flutter DevToolsも独立した `material_ui` と `cupertino_ui` パッケージを使うようになりました。

## AIとエコシステム

エコシステム全体では、本番向けのAIパッケージが大きな節目を迎えました。また、Google PlayのFlutterアプリが100万本を突破し、FlutterのRFCプロセスも公開されます。

### Genkit Dart 1.0

Genkit Dartは安定版の1.0に到達しました。DartとFlutterで、フルスタックかつ複数モデルに対応するエージェント型アプリケーションを構築するためのもので、エンドツーエンドの型安全性、ストリーミングフロー、ツール呼び出し、OpenTelemetryによるトレースに対応します。

![Genkit DartとA2UIを使ったCymbal BistroのFlutterアプリ。対話型の予約カードをストリーミングし、予約ツールを呼び出すデモ。](/blog/flutter-3-50/genkit-dart.webp)

_Genkit Dart 1.0が、対話型のA2UI予約フローをストリーミングし、ツールを呼び出す様子。_

詳しくは、[Genkit Dartのドキュメント](https://genkit.dev) をご覧ください。

### MediaPipeによるオンデバイスAI

Google AI Edgeの新しいMediaPipeパッケージが `pub.dev` に登場します。LiteRTとLiteRT-LMを基盤とし、画像・音声・テキストに関する20種類のオンデバイスタスクを、Flutterアプリから直接利用できます。モデルを端末上で直接動かすことで、ネットワークの遅延やクラウド推論の費用をなくせます。

詳しくは、[MediaPipe Tasks for Flutterのギャラリー](https://google.github.io/flutter-mediapipe/) をご覧ください。

### Google Playのアプリが100万本に

Flutterコミュニティは最近、Google Playで公開されたFlutterアプリが100万本を超えるという、大きな節目を迎えました。Flutterでアプリを作り、届け、成長させているすべての開発者とチームに感謝します。

### パッケージのエコシステムの注目点

パッケージのエコシステムでは、スクロール可能なリスト内でインラインのAdMobバナーを再利用することで、iOSでのベンチマークにおいて、性能が23%改善したと測定されました。また、今回のサイクルで公開された、特に注目したい2つのコミュニティパッケージがあります。純粋なDartでクラウドインフラを定義する [Terradart](https://terradart.dev/) と、Flutterで対話型のノード図をプログラムから構築する [`vyuh_diagram_flutter`](https://pub.dev/packages/vyuh_diagram_flutter) です。

詳しくは、[AdMobバナー再利用のガイド](https://developers.google.com/admob/flutter/banner/banner-recycling) をご覧ください。

### 導入事例

世界中のチームが、Flutterを使って意欲的な本番アプリを届け続けています。[Holafly](https://flutter.dev/showcase/holafly) は、モバイルアプリを3か月で単一のFlutterモノレポへ統合し、月間アクティブユーザー200万人以上、eSIM 2,500万件にサービスを提供しています。[Knowunity](https://flutter.dev/showcase/knowunity) は、FlutterをGoとGeminiと組み合わせ、月間800万〜1,000万人のアクティブな学生を支えています。[Buzz](https://flutter.dev/showcase/buzz) は、iOSとAndroidでFlutterを使い、人とAIエージェントが並んで協働する、オープンソースのワークスペースを提供しています。

Google AI Edgeチームは、モバイルとデスクトップのユーザーにオンデバイスAI推論を届けるため、EloquentとForesightのアプリをFlutterで構築しました。

### Flutterのビジネス上の価値

エンジニアリング部門のリーダーが、今後の計画に向けてFlutterを評価できるよう、新しい2026年版のホワイトペーパーでは、エンジニアリングの生産性、開発速度、事業の投資対効果に関する、データに基づいた知見を紹介しています。

詳しくは、[Flutterのビジネス上の価値](https://flutter.dev/why-flutter) をご覧ください。

### Flutter RFCの発表

Flutterは、技術設計と意思決定のため、公開のRequest for Comments（RFC）プロセスを採用します。RFCは、実装前の早い段階でアイデアを共有し、トレードオフを検討し、サブシステムのメンテナーと方針を合わせ、アーキテクチャー上の合意を作るための、協調的で透明性のある場になります。

詳しくは、[Flutterの設計ドキュメント](https://github.com/flutter/flutter/blob/master/docs/contributing/Design-Documents.md#flutter-rfcs--design-documents) と [`flutter/rfc`](https://github.com/flutter/rfc) をご覧ください。

## 非推奨化と破壊的変更

Flutter 3.50では、SDKに組み込まれた `package:flutter/material.dart` と `package:flutter/cupertino.dart` のライブラリ、および対応する `flutter_localizations` のデリゲートを正式に非推奨とします。Androidのリリースビルドでは、`Intent` の検証を厳格にし、デバッグ用のエンジンフラグを拒否します。あわせて、ウィジェットの動作に4つの更新があります。`package:material_ui` の `DropdownButtonFormField` には明示的な `enabled` プロパティが加わり、`onChanged` コールバックに `null` を渡す代わりに、ドロップダウンを直接無効化できます。

ソフトハイフンを含むテキストは、単語が行をまたいで折り返されるとき、自動的にハイフンを表示するようになりました。右から左へ書くテキスト内のインラインの `WidgetSpan` 要素は、意図せず順序が反転することなく、自然な読み順で表示されます。モバイルブラウザーでは、`viewport-fit=cover` が設定されている場合、`SafeArea` が端末のノッチやホームインジケーターを考慮するようになり、画面の切り欠き部分にUIが重なるのを防ぎます。

フレームワークの整理も2つ含まれます。

- 以前から非推奨だった `ignoringSemantics` プロパティを、`IgnorePointer`、`AbsorbPointer`、`SliverIgnorePointer` と、それらのレンダーオブジェクトから削除しました。
- `RenderProxyBox` と、`RenderProxyBoxMixin` を使うその他のレンダーオブジェクトの `computeDryBaseline` は、子がベースラインを持たない場合、アサーションで失敗する代わりに `null` を返すようになりました。

詳しくは、[Flutterの破壊的変更](https://docs.flutter.dev/release/breaking-changes) をご覧ください。

## Flutter 3.50にアップグレード

issueの報告、設計のレビュー、プルリクエストの取り込みを通じ、Flutterの次の10年を形作ってくれたコミュニティのすべてのコントリビューターに感謝します。Flutter 3.50は、[Dart 3.14](https://dart.dev/blog/announcing-dart-3-14) とともに利用できます。SDKをアップグレードして、今回のリリースで追加された機能を試してみてください。

```bash
flutter upgrade
```

今回のリリースに含まれるすべてのプルリクエストについては、[Flutter 3.50のリリースノート](https://docs.flutter.dev/release/release-notes/release-notes-3.50.0) と [破壊的変更](https://docs.flutter.dev/release/breaking-changes) をご覧ください。

---

## 出典とライセンス

本文・図の説明・代替テキストを日本語に翻訳し、見出しや改行を調整しています。製品名、API名、コード例、バージョン番号は原文の表記を保持しています。冒頭の要約はGenuineCIが追加しました。

- **原文：** [What's new in Flutter 3.50](https://flutter.dev/blog/whats-new-in-flutter-3-50) — [Emma Twersky](https://github.com/twerske)、The Flutter Blog、2026年11月11日公開。
- **日本語訳・要約：** GenuineCI。2026年11月12日時点の原文をもとに翻訳しました。原文の一人称はFlutterチームを指します。
- **本文と図版：** 原文の [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ja) に基づき掲載しています。日本語訳と追加した要約も、同じCC BY 4.0で公開します。図中の英語は原文のままです。再利用時は原著者・原文・ライセンス・翻訳や変更の表示を保持してください。
- **コード例：** 原文の指定に従い、[BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause) を適用します。[Flutterの著作権表示とライセンス全文](/licenses/flutter-BSD-3-Clause.txt) も併せて掲載しています。
- **商標：** Flutterなどの名称・商標は各権利者に帰属します。本記事はGoogle／Flutterによる公式翻訳・推奨・承認を示すものではありません。
