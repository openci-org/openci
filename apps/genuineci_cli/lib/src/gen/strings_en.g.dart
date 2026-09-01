///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$cli$en cli = Translations$cli$en.internal(_root);
	late final Translations$login$en login = Translations$login$en.internal(_root);
	late final Translations$use$en use = Translations$use$en.internal(_root);
	late final Translations$dev$en dev = Translations$dev$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
}

// Path: cli
class Translations$cli$en {
	Translations$cli$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'GenuineCI command-line tool for managing CI/CD and secrets.'
	String get description => 'GenuineCI command-line tool for managing CI/CD and secrets.';

	/// en: 'genuineci version: ${version}'
	String version({required Object version}) => 'genuineci version: ${version}';

	late final Translations$cli$flags$en flags = Translations$cli$flags$en.internal(_root);
}

// Path: login
class Translations$login$en {
	Translations$login$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Log in to GenuineCI server (Local or Cloud).'
	String get description => 'Log in to GenuineCI server (Local or Cloud).';

	late final Translations$login$flags$en flags = Translations$login$flags$en.internal(_root);

	/// en: 'Logging in to GenuineCI...'
	String get loggingIn => 'Logging in to GenuineCI...';

	/// en: 'Successfully saved credentials for profile "${profile}".'
	String savedSuccess({required Object profile}) => 'Successfully saved credentials for profile "${profile}".';
}

// Path: use
class Translations$use$en {
	Translations$use$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Set the default display language (japanese, english).'
	String get description => 'Set the default display language (japanese, english).';

	/// en: 'Language set to ${language}.'
	String success({required Object language}) => 'Language set to ${language}.';

	/// en: 'Invalid language "${input}". Supported languages: japanese, english.'
	String invalidLanguage({required Object input}) => 'Invalid language "${input}". Supported languages: japanese, english.';
}

// Path: dev
class Translations$dev$en {
	Translations$dev$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Manage local development environment (Docker, Tart, DB, Server).'
	String get description => 'Manage local development environment (Docker, Tart, DB, Server).';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Error: ${error}'
	String error({required Object error}) => 'Error: ${error}';
}

// Path: cli.flags
class Translations$cli$flags$en {
	Translations$cli$flags$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Print the current tool version.'
	String get version => 'Print the current tool version.';

	/// en: 'Enable verbose logging output.'
	String get verbose => 'Enable verbose logging output.';
}

// Path: login.flags
class Translations$login$flags$en {
	Translations$login$flags$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Log in to local Docker environment (http://localhost:8080).'
	String get local => 'Log in to local Docker environment (http://localhost:8080).';

	/// en: 'Server base URL.'
	String get server => 'Server base URL.';

	/// en: 'Target team ID.'
	String get teamId => 'Target team ID.';

	/// en: 'Profile name to store credentials under.'
	String get profile => 'Profile name to store credentials under.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'cli.description' => 'GenuineCI command-line tool for managing CI/CD and secrets.',
			'cli.version' => ({required Object version}) => 'genuineci version: ${version}',
			'cli.flags.version' => 'Print the current tool version.',
			'cli.flags.verbose' => 'Enable verbose logging output.',
			'login.description' => 'Log in to GenuineCI server (Local or Cloud).',
			'login.flags.local' => 'Log in to local Docker environment (http://localhost:8080).',
			'login.flags.server' => 'Server base URL.',
			'login.flags.teamId' => 'Target team ID.',
			'login.flags.profile' => 'Profile name to store credentials under.',
			'login.loggingIn' => 'Logging in to GenuineCI...',
			'login.savedSuccess' => ({required Object profile}) => 'Successfully saved credentials for profile "${profile}".',
			'use.description' => 'Set the default display language (japanese, english).',
			'use.success' => ({required Object language}) => 'Language set to ${language}.',
			'use.invalidLanguage' => ({required Object input}) => 'Invalid language "${input}". Supported languages: japanese, english.',
			'dev.description' => 'Manage local development environment (Docker, Tart, DB, Server).',
			'common.error' => ({required Object error}) => 'Error: ${error}',
			_ => null,
		};
	}
}
