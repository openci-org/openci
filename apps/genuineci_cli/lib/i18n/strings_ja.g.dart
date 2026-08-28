///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJa with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$cli$ja cli = _Translations$cli$ja._(_root);
	@override late final _Translations$login$ja login = _Translations$login$ja._(_root);
	@override late final _Translations$use$ja use = _Translations$use$ja._(_root);
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
}

// Path: cli
class _Translations$cli$ja implements Translations$cli$en {
	_Translations$cli$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'GenuineCI - CI/CD およびシークレット管理コマンドラインツール';
	@override String version({required Object version}) => 'genuineci バージョン: ${version}';
	@override late final _Translations$cli$flags$ja flags = _Translations$cli$flags$ja._(_root);
}

// Path: login
class _Translations$login$ja implements Translations$login$en {
	_Translations$login$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'GenuineCI サーバー（ローカルまたはクラウド）にログインします。';
	@override late final _Translations$login$flags$ja flags = _Translations$login$flags$ja._(_root);
	@override String get loggingIn => 'GenuineCI にログイン中...';
	@override String savedSuccess({required Object profile}) => 'プロファイル「${profile}」の認証情報を保存しました。';
}

// Path: use
class _Translations$use$ja implements Translations$use$en {
	_Translations$use$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '表示言語を設定します（japanese, english）。';
	@override String success({required Object language}) => '言語を${language}に設定しました。';
	@override String invalidLanguage({required Object input}) => '無効な言語です: 「${input}」。対応言語: japanese, english';
}

// Path: common
class _Translations$common$ja implements Translations$common$en {
	_Translations$common$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String error({required Object error}) => 'エラー: ${error}';
}

// Path: cli.flags
class _Translations$cli$flags$ja implements Translations$cli$flags$en {
	_Translations$cli$flags$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get version => 'ツールのバージョンを表示します。';
	@override String get verbose => '詳細なログ出力を有効にします。';
}

// Path: login.flags
class _Translations$login$flags$ja implements Translations$login$flags$en {
	_Translations$login$flags$ja._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get local => 'ローカルDocker環境（http://localhost:8080）に接続します。';
	@override String get server => '接続先サーバーURL。';
	@override String get teamId => '対象のチームID。';
	@override String get profile => '認証情報を保存するプロファイル名。';
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
			'common.error' => ({required Object error}) => 'エラー: ${error}',
			_ => null,
		};
	}
}
