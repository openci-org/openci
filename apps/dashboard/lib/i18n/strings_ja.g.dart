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
	@override late final _TranslationsCommonJa common = _TranslationsCommonJa._(_root);
	@override late final _TranslationsAuthJa auth = _TranslationsAuthJa._(_root);
	@override late final _TranslationsNavigationJa navigation = _TranslationsNavigationJa._(_root);
	@override late final _TranslationsSettingsJa settings = _TranslationsSettingsJa._(_root);
	@override late final _TranslationsVariablesJa variables = _TranslationsVariablesJa._(_root);
	@override late final _TranslationsLogsJa logs = _TranslationsLogsJa._(_root);
	@override late final _TranslationsWorkflowsJa workflows = _TranslationsWorkflowsJa._(_root);
	@override late final _TranslationsLocaleJa locale = _TranslationsLocaleJa._(_root);
}

// Path: common
class _TranslationsCommonJa extends TranslationsCommonEn {
	_TranslationsCommonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'キャンセル';
	@override String get delete => '削除';
	@override String get save => '保存';
	@override String get add => '追加';
	@override String error({required Object error}) => 'エラー: ${error}';
	@override String get openSource => 'オープンソース CI/CD';
}

// Path: auth
class _TranslationsAuthJa extends TranslationsAuthEn {
	_TranslationsAuthJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get email => 'メールアドレス';
	@override String get password => 'パスワード';
	@override String get pleaseEnterEmail => 'メールアドレスを入力してください';
	@override String get pleaseEnterValidEmail => '有効なメールアドレスを入力してください';
	@override String get pleaseEnterPassword => 'パスワードを入力してください';
	@override String get passwordTooShort => 'パスワードは6文字以上にしてください';
	@override String get signIn => 'サインイン';
	@override String get signUp => 'サインアップ';
	@override String get switchToSignUp => 'アカウントをお持ちでない方はこちら';
	@override String get switchToSignIn => 'アカウントをお持ちの方はこちら';
	@override String get agreePrefix => '';
	@override String get termsOfService => '利用規約に同意する';
	@override String get authFailed => '認証に失敗しました';
	@override String get emailAlreadyInUse => 'このメールアドレスは既に登録されています';
	@override String get invalidCredential => 'メールアドレスまたはパスワードが正しくありません';
	@override String get userNotFound => 'このメールアドレスのアカウントは見つかりません';
	@override String get weakPassword => 'パスワードが弱すぎます。6文字以上にしてください。';
	@override String get tooManyRequests => '試行回数が多すぎます。しばらくしてから再度お試しください。';
}

// Path: navigation
class _TranslationsNavigationJa extends TranslationsNavigationEn {
	_TranslationsNavigationJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get workflows => 'ワークフロー';
	@override String get variables => '変数';
	@override String get logs => 'ログ';
	@override String get settings => '設定';
}

// Path: settings
class _TranslationsSettingsJa extends TranslationsSettingsEn {
	_TranslationsSettingsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get general => '一般';
	@override String get buildNotifications => 'ビルド通知';
	@override String get buildNotificationsDesc => '通知を受け取るタイミングを設定';
	@override String get subscription => 'サブスクリプション';
	@override String get subscriptionDesc => 'プランと請求を管理';
	@override String get support => 'サポート';
	@override String get githubRepo => 'GitHubリポジトリ';
	@override String get githubRepoDesc => 'OpenCIにスターとコントリビュートを';
	@override String get openingGithub => 'GitHubを開いています...';
	@override String get reportBug => 'バグを報告';
	@override String get reportBugDesc => 'OpenCIの改善にご協力ください';
	@override String get openingIssueTracker => 'Issue Trackerを開いています...';
	@override String get account => 'アカウント';
	@override String get logout => 'ログアウト';
	@override String get logoutDesc => 'このデバイスからサインアウト';
	@override String get loggedOut => 'ログアウトしました';
	@override String logoutFailed({required Object error}) => 'ログアウトに失敗しました: ${error}';
	@override String get deleteAccount => 'アカウント削除';
	@override String get deleteAccountDesc => 'すべてのデータを完全に削除';
	@override String get deleteConfirmation => 'アカウントを削除してもよろしいですか？この操作は取り消せません。すべてのデータが完全に削除されます。';
	@override String get accountDeleted => 'アカウントを削除しました';
	@override String deleteAccountFailed({required Object error}) => 'アカウントの削除に失敗しました: ${error}';
	@override String get language => '言語';
	@override String get languageDesc => '表示言語を変更';
}

// Path: variables
class _TranslationsVariablesJa extends TranslationsVariablesEn {
	_TranslationsVariablesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '変数';
	@override String get secrets => 'シークレット';
	@override String get environment => '環境変数';
	@override String get noSecretsYet => 'シークレットがありません';
	@override String get noSecretsDesc => 'APIキーやトークン、\n証明書などの暗号化されたシークレットを追加します。';
	@override String get noEnvVars => '環境変数がありません';
	@override String get noEnvVarsDesc => 'CI/CDビルド中に利用可能な\n変数を追加します。';
	@override String get addSecret => 'シークレットを追加';
	@override String get editSecret => 'シークレットを編集';
	@override String get secretName => 'シークレット名';
	@override String get secretNameHint => '例: API_KEY';
	@override String get secretValue => 'シークレットの値';
	@override String get pleaseEnterSecretName => 'シークレット名を入力してください';
	@override String get pleaseEnterSecretValue => 'シークレットの値を入力してください';
	@override String get secretsEncryptedNote => 'シークレットは暗号化され、ログには表示されません。';
	@override String get secretAdded => 'シークレットを追加しました';
	@override String get secretUpdated => 'シークレットを更新しました';
	@override String get saveChanges => '変更を保存';
	@override String get newValueHint => '新しい値（空欄の場合は現在の値を維持）';
	@override String get addEnvVar => '変数を追加';
	@override String get editEnvVar => '変数を編集';
	@override String get envKey => 'キー';
	@override String get envKeyHint => '例: NODE_ENV';
	@override String get envValue => '値';
	@override String get envValueHint => '例: production';
	@override String get pleaseEnterKey => 'キーを入力してください';
	@override String get pleaseEnterValue => '値を入力してください';
	@override String get variableAdded => '変数を追加しました';
	@override String get variableUpdated => '変数を更新しました';
	@override String get deleteVariable => '変数を削除';
	@override String deleteVariableConfirm({required Object key}) => '「${key}」を削除しますか？';
	@override String get deletedSuccessfully => '削除しました';
}

// Path: logs
class _TranslationsLogsJa extends TranslationsLogsEn {
	_TranslationsLogsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ビルドログ';
	@override String get noBuildsYet => 'ビルドはまだありません';
	@override String get noBuildsDesc => 'ワークフローがトリガーされると、\nビルドログがここに表示されます。';
	@override String get active => '実行中';
	@override String get recent => '最近';
	@override String get retry => 'リトライ';
	@override String get retrying => 'ビルドを再実行中...';
	@override String get buildQueued => 'ビルドをキューに追加しました';
	@override String retryFailed({required Object error}) => 'リトライに失敗しました: ${error}';
	@override String get cancelBuild => 'ビルドをキャンセル';
	@override String get cancelBuildConfirm => 'このビルドをキャンセルしてもよろしいですか？';
	@override String get no => 'いいえ';
	@override String get cancelling => 'ビルドをキャンセル中...';
	@override String get buildCancelled => 'ビルドをキャンセルしました';
	@override String cancelFailed({required Object error}) => 'キャンセルに失敗しました: ${error}';
	@override String get fixWithAI => 'AIで修正';
	@override String get passed => '成功';
	@override String get failed => '失敗';
	@override String get running => '実行中';
	@override String get queued => 'キュー中';
	@override String get cancelled => 'キャンセル済み';
	@override String get unknown => '不明';
}

// Path: workflows
class _TranslationsWorkflowsJa extends TranslationsWorkflowsEn {
	_TranslationsWorkflowsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ワークフロー';
	@override String get noWorkflows => 'ワークフローがありません';
	@override String get noWorkflowsDesc => '最初のCI/CDワークフローを作成して、\nビルドとデプロイを自動化しましょう。';
	@override String get createWorkflow => 'ワークフローを作成';
	@override String steps({required Object count}) => '${count}ステップ';
	@override String get duplicate => '複製';
	@override String get duplicated => 'ワークフローを複製しました';
	@override String duplicateFailed({required Object error}) => '複製に失敗しました: ${error}';
	@override String get deleteWorkflow => 'ワークフローを削除';
	@override String deleteWorkflowConfirm({required Object name}) => '「${name}」を削除してもよろしいですか？';
	@override String get workflowDeleted => 'ワークフローを削除しました';
	@override String deleteFailed({required Object error}) => '削除に失敗しました: ${error}';
	@override String get switchTeam => 'チームを切り替え';
	@override String get editTeam => 'チームを編集';
	@override String get createTeam => 'チームを作成';
	@override String get switchBranchCommit => 'ブランチ・コミットを切り替え';
	@override String get branch => 'ブランチ';
	@override String get commits => 'コミット';
}

// Path: locale
class _TranslationsLocaleJa extends TranslationsLocaleEn {
	_TranslationsLocaleJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get en => 'English';
	@override String get ja => '日本語';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.cancel' => 'キャンセル',
			'common.delete' => '削除',
			'common.save' => '保存',
			'common.add' => '追加',
			'common.error' => ({required Object error}) => 'エラー: ${error}',
			'common.openSource' => 'オープンソース CI/CD',
			'auth.email' => 'メールアドレス',
			'auth.password' => 'パスワード',
			'auth.pleaseEnterEmail' => 'メールアドレスを入力してください',
			'auth.pleaseEnterValidEmail' => '有効なメールアドレスを入力してください',
			'auth.pleaseEnterPassword' => 'パスワードを入力してください',
			'auth.passwordTooShort' => 'パスワードは6文字以上にしてください',
			'auth.signIn' => 'サインイン',
			'auth.signUp' => 'サインアップ',
			'auth.switchToSignUp' => 'アカウントをお持ちでない方はこちら',
			'auth.switchToSignIn' => 'アカウントをお持ちの方はこちら',
			'auth.agreePrefix' => '',
			'auth.termsOfService' => '利用規約に同意する',
			'auth.authFailed' => '認証に失敗しました',
			'auth.emailAlreadyInUse' => 'このメールアドレスは既に登録されています',
			'auth.invalidCredential' => 'メールアドレスまたはパスワードが正しくありません',
			'auth.userNotFound' => 'このメールアドレスのアカウントは見つかりません',
			'auth.weakPassword' => 'パスワードが弱すぎます。6文字以上にしてください。',
			'auth.tooManyRequests' => '試行回数が多すぎます。しばらくしてから再度お試しください。',
			'navigation.workflows' => 'ワークフロー',
			'navigation.variables' => '変数',
			'navigation.logs' => 'ログ',
			'navigation.settings' => '設定',
			'settings.title' => '設定',
			'settings.general' => '一般',
			'settings.buildNotifications' => 'ビルド通知',
			'settings.buildNotificationsDesc' => '通知を受け取るタイミングを設定',
			'settings.subscription' => 'サブスクリプション',
			'settings.subscriptionDesc' => 'プランと請求を管理',
			'settings.support' => 'サポート',
			'settings.githubRepo' => 'GitHubリポジトリ',
			'settings.githubRepoDesc' => 'OpenCIにスターとコントリビュートを',
			'settings.openingGithub' => 'GitHubを開いています...',
			'settings.reportBug' => 'バグを報告',
			'settings.reportBugDesc' => 'OpenCIの改善にご協力ください',
			'settings.openingIssueTracker' => 'Issue Trackerを開いています...',
			'settings.account' => 'アカウント',
			'settings.logout' => 'ログアウト',
			'settings.logoutDesc' => 'このデバイスからサインアウト',
			'settings.loggedOut' => 'ログアウトしました',
			'settings.logoutFailed' => ({required Object error}) => 'ログアウトに失敗しました: ${error}',
			'settings.deleteAccount' => 'アカウント削除',
			'settings.deleteAccountDesc' => 'すべてのデータを完全に削除',
			'settings.deleteConfirmation' => 'アカウントを削除してもよろしいですか？この操作は取り消せません。すべてのデータが完全に削除されます。',
			'settings.accountDeleted' => 'アカウントを削除しました',
			'settings.deleteAccountFailed' => ({required Object error}) => 'アカウントの削除に失敗しました: ${error}',
			'settings.language' => '言語',
			'settings.languageDesc' => '表示言語を変更',
			'variables.title' => '変数',
			'variables.secrets' => 'シークレット',
			'variables.environment' => '環境変数',
			'variables.noSecretsYet' => 'シークレットがありません',
			'variables.noSecretsDesc' => 'APIキーやトークン、\n証明書などの暗号化されたシークレットを追加します。',
			'variables.noEnvVars' => '環境変数がありません',
			'variables.noEnvVarsDesc' => 'CI/CDビルド中に利用可能な\n変数を追加します。',
			'variables.addSecret' => 'シークレットを追加',
			'variables.editSecret' => 'シークレットを編集',
			'variables.secretName' => 'シークレット名',
			'variables.secretNameHint' => '例: API_KEY',
			'variables.secretValue' => 'シークレットの値',
			'variables.pleaseEnterSecretName' => 'シークレット名を入力してください',
			'variables.pleaseEnterSecretValue' => 'シークレットの値を入力してください',
			'variables.secretsEncryptedNote' => 'シークレットは暗号化され、ログには表示されません。',
			'variables.secretAdded' => 'シークレットを追加しました',
			'variables.secretUpdated' => 'シークレットを更新しました',
			'variables.saveChanges' => '変更を保存',
			'variables.newValueHint' => '新しい値（空欄の場合は現在の値を維持）',
			'variables.addEnvVar' => '変数を追加',
			'variables.editEnvVar' => '変数を編集',
			'variables.envKey' => 'キー',
			'variables.envKeyHint' => '例: NODE_ENV',
			'variables.envValue' => '値',
			'variables.envValueHint' => '例: production',
			'variables.pleaseEnterKey' => 'キーを入力してください',
			'variables.pleaseEnterValue' => '値を入力してください',
			'variables.variableAdded' => '変数を追加しました',
			'variables.variableUpdated' => '変数を更新しました',
			'variables.deleteVariable' => '変数を削除',
			'variables.deleteVariableConfirm' => ({required Object key}) => '「${key}」を削除しますか？',
			'variables.deletedSuccessfully' => '削除しました',
			'logs.title' => 'ビルドログ',
			'logs.noBuildsYet' => 'ビルドはまだありません',
			'logs.noBuildsDesc' => 'ワークフローがトリガーされると、\nビルドログがここに表示されます。',
			'logs.active' => '実行中',
			'logs.recent' => '最近',
			'logs.retry' => 'リトライ',
			'logs.retrying' => 'ビルドを再実行中...',
			'logs.buildQueued' => 'ビルドをキューに追加しました',
			'logs.retryFailed' => ({required Object error}) => 'リトライに失敗しました: ${error}',
			'logs.cancelBuild' => 'ビルドをキャンセル',
			'logs.cancelBuildConfirm' => 'このビルドをキャンセルしてもよろしいですか？',
			'logs.no' => 'いいえ',
			'logs.cancelling' => 'ビルドをキャンセル中...',
			'logs.buildCancelled' => 'ビルドをキャンセルしました',
			'logs.cancelFailed' => ({required Object error}) => 'キャンセルに失敗しました: ${error}',
			'logs.fixWithAI' => 'AIで修正',
			'logs.passed' => '成功',
			'logs.failed' => '失敗',
			'logs.running' => '実行中',
			'logs.queued' => 'キュー中',
			'logs.cancelled' => 'キャンセル済み',
			'logs.unknown' => '不明',
			'workflows.title' => 'ワークフロー',
			'workflows.noWorkflows' => 'ワークフローがありません',
			'workflows.noWorkflowsDesc' => '最初のCI/CDワークフローを作成して、\nビルドとデプロイを自動化しましょう。',
			'workflows.createWorkflow' => 'ワークフローを作成',
			'workflows.steps' => ({required Object count}) => '${count}ステップ',
			'workflows.duplicate' => '複製',
			'workflows.duplicated' => 'ワークフローを複製しました',
			'workflows.duplicateFailed' => ({required Object error}) => '複製に失敗しました: ${error}',
			'workflows.deleteWorkflow' => 'ワークフローを削除',
			'workflows.deleteWorkflowConfirm' => ({required Object name}) => '「${name}」を削除してもよろしいですか？',
			'workflows.workflowDeleted' => 'ワークフローを削除しました',
			'workflows.deleteFailed' => ({required Object error}) => '削除に失敗しました: ${error}',
			'workflows.switchTeam' => 'チームを切り替え',
			'workflows.editTeam' => 'チームを編集',
			'workflows.createTeam' => 'チームを作成',
			'workflows.switchBranchCommit' => 'ブランチ・コミットを切り替え',
			'workflows.branch' => 'ブランチ',
			'workflows.commits' => 'コミット',
			'locale.en' => 'English',
			'locale.ja' => '日本語',
			_ => null,
		};
	}
}
