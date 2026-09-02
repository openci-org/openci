///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$cli$ja cli = _Translations$cli$ja._(_root);
	@override late final _Translations$login$ja login = _Translations$login$ja._(_root);
	@override late final _Translations$use$ja use = _Translations$use$ja._(_root);
	@override late final _Translations$dev$ja dev = _Translations$dev$ja._(_root);
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
}

// Path: cli
class _Translations$cli$ja extends Translations$cli$en {
	_Translations$cli$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'GenuineCI - CI/CD およびシークレット管理コマンドラインツール';
	@override String version({required Object version}) => 'genuineci バージョン: ${version}';
	@override late final _Translations$cli$flags$ja flags = _Translations$cli$flags$ja._(_root);
}

// Path: login
class _Translations$login$ja extends Translations$login$en {
	_Translations$login$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'GenuineCI サーバー（ローカルまたはクラウド）にログインします。';
	@override late final _Translations$login$flags$ja flags = _Translations$login$flags$ja._(_root);
	@override String get loggingIn => 'GenuineCI にログイン中...';
	@override String savedSuccess({required Object profile}) => 'プロファイル「${profile}」の認証情報を保存しました。';
}

// Path: use
class _Translations$use$ja extends Translations$use$en {
	_Translations$use$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '表示言語を設定します（japanese, english）。';
	@override String success({required Object language}) => '言語を${language}に設定しました。';
	@override String invalidLanguage({required Object input}) => '無効な言語です: 「${input}」。対応言語: japanese, english';
}

// Path: dev
class _Translations$dev$ja extends Translations$dev$en {
	_Translations$dev$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'ローカル開発環境（Docker, Tart, DB, サーバー）を管理します。';
	@override late final _Translations$dev$start$ja start = _Translations$dev$start$ja._(_root);
}

// Path: common
class _Translations$common$ja extends Translations$common$en {
	_Translations$common$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String error({required Object error}) => 'エラー: ${error}';
}

// Path: cli.flags
class _Translations$cli$flags$ja extends Translations$cli$flags$en {
	_Translations$cli$flags$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get version => 'ツールのバージョンを表示します。';
	@override String get verbose => '詳細なログ出力を有効にします。';
}

// Path: login.flags
class _Translations$login$flags$ja extends Translations$login$flags$en {
	_Translations$login$flags$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get local => 'ローカルDocker環境（http://localhost:8080）に接続します。';
	@override String get server => '接続先サーバーURL。';
	@override String get teamId => '対象のチームID。';
	@override String get profile => '認証情報を保存するプロファイル名。';
}

// Path: dev.start
class _Translations$dev$start$ja extends Translations$dev$start$en {
	_Translations$dev$start$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'ローカル開発環境（Docker コンテナ、Tart VM、Orchard）を起動します。';
	@override String get starting => 'OpenCI ローカル開発環境を起動しています...';
	@override String get stepTart => 'Step 1: Tart VM ベースイメージを確認中...';
	@override String get stepTartNotFound => 'エラー: Tart VM イメージ「base-macos」が見つかりません。\n以下のコマンドを実行してイメージを準備してください:\n  tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5\n  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos';
	@override String get stepTartExists => 'Tart VM (base-macos) を確認しました。';
	@override String get projectRootNotFound => 'エラー: OpenCI プロジェクトのルートディレクトリが見つかりません。';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'cli.description' => 'GenuineCI - CI/CD およびシークレット管理コマンドラインツール',
			'cli.version' => ({required Object version}) => 'genuineci バージョン: ${version}',
			'cli.flags.version' => 'ツールのバージョンを表示します。',
			'cli.flags.verbose' => '詳細なログ出力を有効にします。',
			'login.description' => 'GenuineCI サーバー（ローカルまたはクラウド）にログインします。',
			'login.flags.local' => 'ローカルDocker環境（http://localhost:8080）に接続します。',
			'login.flags.server' => '接続先サーバーURL。',
			'login.flags.teamId' => '対象のチームID。',
			'login.flags.profile' => '認証情報を保存するプロファイル名。',
			'login.loggingIn' => 'GenuineCI にログイン中...',
			'login.savedSuccess' => ({required Object profile}) => 'プロファイル「${profile}」の認証情報を保存しました。',
			'use.description' => '表示言語を設定します（japanese, english）。',
			'use.success' => ({required Object language}) => '言語を${language}に設定しました。',
			'use.invalidLanguage' => ({required Object input}) => '無効な言語です: 「${input}」。対応言語: japanese, english',
			'dev.description' => 'ローカル開発環境（Docker, Tart, DB, サーバー）を管理します。',
			'dev.start.description' => 'ローカル開発環境（Docker コンテナ、Tart VM、Orchard）を起動します。',
			'dev.start.starting' => 'OpenCI ローカル開発環境を起動しています...',
			'dev.start.stepTart' => 'Step 1: Tart VM ベースイメージを確認中...',
			'dev.start.stepTartNotFound' => 'エラー: Tart VM イメージ「base-macos」が見つかりません。\n以下のコマンドを実行してイメージを準備してください:\n  tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5\n  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos',
			'dev.start.stepTartExists' => 'Tart VM (base-macos) を確認しました。',
			'dev.start.projectRootNotFound' => 'エラー: OpenCI プロジェクトのルートディレクトリが見つかりません。',
			'common.error' => ({required Object error}) => 'エラー: ${error}',
			_ => null,
		};
	}
}
