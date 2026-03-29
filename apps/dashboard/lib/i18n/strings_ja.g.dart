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
	@override late final _TranslationsCommonJa common = _TranslationsCommonJa._(_root);
	@override late final _TranslationsTimeAgoJa timeAgo = _TranslationsTimeAgoJa._(_root);
	@override late final _TranslationsNavJa nav = _TranslationsNavJa._(_root);
	@override late final _TranslationsAuthJa auth = _TranslationsAuthJa._(_root);
	@override late final _TranslationsWorkflowJa workflow = _TranslationsWorkflowJa._(_root);
	@override late final _TranslationsBuildLogsJa buildLogs = _TranslationsBuildLogsJa._(_root);
	@override late final _TranslationsVariablesJa variables = _TranslationsVariablesJa._(_root);
	@override late final _TranslationsSecretsJa secrets = _TranslationsSecretsJa._(_root);
	@override late final _TranslationsEnvVarsJa envVars = _TranslationsEnvVarsJa._(_root);
	@override late final _TranslationsSettingsJa settings = _TranslationsSettingsJa._(_root);
	@override late final _TranslationsNotificationsJa notifications = _TranslationsNotificationsJa._(_root);
	@override late final _TranslationsTeamJa team = _TranslationsTeamJa._(_root);
	@override late final _TranslationsGithubJa github = _TranslationsGithubJa._(_root);
	@override late final _TranslationsSubscriptionJa subscription = _TranslationsSubscriptionJa._(_root);
}

// Path: common
class _TranslationsCommonJa implements TranslationsCommonEn {
	_TranslationsCommonJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get save => '保存';
	@override String get cancel => 'キャンセル';
	@override String get delete => '削除';
	@override String get add => '追加';
	@override String get edit => '編集';
	@override String error({required Object error}) => 'エラー: ${error}';
	@override String get loading => '読み込み中...';
	@override String get invite => '招待';
}

// Path: timeAgo
class _TranslationsTimeAgoJa implements TranslationsTimeAgoEn {
	_TranslationsTimeAgoJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String secsAgo({required Object count}) => '${count}秒前';
	@override String secsAgoPlural({required Object count}) => '${count}秒前';
	@override String minsAgo({required Object count}) => '${count}分前';
	@override String minsAgoPlural({required Object count}) => '${count}分前';
	@override String hoursAgo({required Object count}) => '${count}時間前';
	@override String daysAgo({required Object count}) => '${count}日前';
	@override String monthsAgo({required Object count}) => '${count}ヶ月前';
}

// Path: nav
class _TranslationsNavJa implements TranslationsNavEn {
	_TranslationsNavJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get workflows => 'ワークフロー';
	@override String get variables => '変数';
	@override String get logs => 'ログ';
	@override String get settings => '設定';
}

// Path: auth
class _TranslationsAuthJa implements TranslationsAuthEn {
	_TranslationsAuthJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get email => 'メールアドレス';
	@override String get password => 'パスワード';
	@override String get login => 'ログイン';
	@override String get createAccount => 'アカウント作成';
	@override String get useYourFirebase => '自分のFirebaseを使用';
	@override String get resetFirebase => 'Firebaseをリセット';
	@override String get resetSuccess => 'Firebaseがリセットされました。アプリを再起動してください。';
	@override String get agreePrefix => '利用規約に同意する ';
	@override String get termsOfService => '利用規約';
	@override String get enterEmail => 'メールアドレスを入力してください';
	@override String get enterPassword => 'パスワードを入力してください';
	@override late final _TranslationsAuthFirebaseFormJa firebaseForm = _TranslationsAuthFirebaseFormJa._(_root);
}

// Path: workflow
class _TranslationsWorkflowJa implements TranslationsWorkflowEn {
	_TranslationsWorkflowJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ワークフロー';
	@override String get addWorkflow => 'ワークフロー追加';
	@override String get noWorkflowFiles => 'ワークフローファイルが見つかりません';
	@override String get addYamlHint => 'リポジトリの .openci/ にYAMLファイルを追加してください。';
	@override String get selectRepo => 'リポジトリを選択';
	@override String get selectRepoHint => 'ワークフローを管理するGitHubリポジトリを選択してください。';
	@override String get selectRepoButton => 'リポジトリを選択';
	@override String get triggers => 'トリガー';
	@override String triggerBranch({required Object type}) => '${type} ブランチ';
	@override String triggerBranchLoading({required Object type}) => '${type} ブランチ (読み込み中...)';
	@override late final _TranslationsWorkflowEditorJa editor = _TranslationsWorkflowEditorJa._(_root);
}

// Path: buildLogs
class _TranslationsBuildLogsJa implements TranslationsBuildLogsEn {
	_TranslationsBuildLogsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String title({required Object date}) => 'ビルドログ - ${date}';
	@override String get noJobs => 'ビルドジョブが見つかりません';
	@override late final _TranslationsBuildLogsStatusJa status = _TranslationsBuildLogsStatusJa._(_root);
	@override late final _TranslationsBuildLogsDetailJa detail = _TranslationsBuildLogsDetailJa._(_root);
	@override late final _TranslationsBuildLogsDurationJa duration = _TranslationsBuildLogsDurationJa._(_root);
}

// Path: variables
class _TranslationsVariablesJa implements TranslationsVariablesEn {
	_TranslationsVariablesJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '変数';
	@override String get envVarsTab => '環境変数';
	@override String get secretsTab => 'シークレット';
}

// Path: secrets
class _TranslationsSecretsJa implements TranslationsSecretsEn {
	_TranslationsSecretsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'シークレットマネージャー';
	@override String get noSecrets => 'シークレットが見つかりません';
	@override String get addSecret => 'シークレット追加';
	@override String get editSecret => 'シークレット編集';
	@override String get secretName => 'シークレット名';
	@override String get secretValue => 'シークレット値';
	@override String get newSecretValue => '新しいシークレット値（空欄で現在の値を維持）';
	@override String get enterSecretName => 'シークレット名を入力してください';
	@override String get enterSecretValue => 'シークレット値を入力してください';
	@override String get addedSuccess => 'シークレットが追加されました';
	@override String get updatedSuccess => 'シークレットが更新されました';
	@override String get deleteConfirm => 'このシークレットを削除しますか？この操作は元に戻せません。';
	@override String get deletedSuccess => 'シークレットが削除されました';
	@override String get unusedSecrets => '未使用のシークレット';
	@override String get notUsedInWorkflows => 'ワークフローで使用されていません';
}

// Path: envVars
class _TranslationsEnvVarsJa implements TranslationsEnvVarsEn {
	_TranslationsEnvVarsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '環境変数';
	@override String get noEnvVars => '環境変数が見つかりません';
	@override String get noCustomEnvVars => 'カスタム環境変数がありません';
	@override String get addEnvVar => '環境変数追加';
	@override String get editEnvVar => '環境変数編集';
	@override String get editRunNumber => '実行番号を編集';
	@override String get keyName => 'キー名';
	@override String get value => '値';
	@override String get keyHint => '例: MY_VARIABLE';
	@override String get valueHint => '例: hello';
	@override String get enterKeyName => 'キー名を入力してください';
	@override String get enterValue => '値を入力してください';
	@override String get invalidKey => '英字、数字、アンダースコアのみ使用できます';
	@override String get valueMustBeNumber => '値は数値である必要があります';
	@override String get addedSuccess => '環境変数が追加されました';
	@override String get updatedSuccess => '環境変数が更新されました';
	@override String get deletedSuccess => '削除しました';
	@override String get runNumberUpdated => '実行番号が更新されました';
}

// Path: settings
class _TranslationsSettingsJa implements TranslationsSettingsEn {
	_TranslationsSettingsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '設定';
	@override String get buildNotifications => 'ビルド通知';
	@override String get configureNotifications => '通知を受け取るタイミングを設定';
	@override String get subscription => 'サブスクリプション';
	@override String get manageSubscription => 'サブスクリプションプランを管理';
	@override String firebaseAppName({required Object name}) => 'Firebaseアプリ名: ${name}';
	@override String get inviteTeamMember => 'チームメンバーを招待';
	@override String get logout => 'ログアウト';
	@override String get logoutSuccess => 'ログアウトしました';
	@override String logoutFailed({required Object error}) => 'ログアウトに失敗: ${error}';
	@override String get deleteAccount => 'アカウント削除';
	@override String get deleteConfirmTitle => 'アカウント削除';
	@override String get deleteConfirmMessage => '本当にアカウントを削除しますか？この操作は元に戻せません。すべてのデータが完全に削除されます。';
	@override String get deleteSuccess => 'アカウントが削除されました';
	@override String get noUserSignedIn => '現在サインインしているユーザーがいません';
	@override String get requiresRecentLogin => 'アカウンを削除する前に、一度ログアウトしてから再度ログインしてください';
	@override String deleteFailed({required Object error}) => 'アカウントの削除に失敗: ${error}';
	@override late final _TranslationsSettingsLanguageJa language = _TranslationsSettingsLanguageJa._(_root);
}

// Path: notifications
class _TranslationsNotificationsJa implements TranslationsNotificationsEn {
	_TranslationsNotificationsJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ビルド通知';
	@override String get all => 'すべて';
	@override String get allDesc => '成功時と失敗時の両方で通知';
	@override String get successOnly => '成功時のみ';
	@override String get successOnlyDesc => 'ビルド成功時のみ通知';
	@override String get failureOnly => '失敗時のみ';
	@override String get failureOnlyDesc => 'ビルド失敗時のみ通知';
	@override String get none => 'なし';
	@override String get noneDesc => '通知を送信しない';
	@override String get updated => '通知設定が更新されました';
	@override String updateFailed({required Object error}) => '更新に失敗: ${error}';
	@override String errorLoading({required Object error}) => '設定の読み込みエラー: ${error}';
}

// Path: team
class _TranslationsTeamJa implements TranslationsTeamEn {
	_TranslationsTeamJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get switchTeam => 'チーム切替';
	@override String get editTeam => 'チーム編集';
	@override String get createTeam => 'チーム作成';
	@override String get createNewTeam => '新しいチームを作成';
	@override String get teamName => 'チーム名';
	@override String get newTeamName => '新しいチーム名';
	@override String get selectTeam => 'チームを選択';
	@override String get selectTeamLabel => 'チーム';
	@override String get enterTeamName => 'チーム名を入力してください';
	@override String get selectTeamValidation => 'チームを選択してください';
	@override String get createdSuccess => 'チームが作成されました';
	@override String get updatedSuccess => 'チーム名が更新されました';
	@override String get selectedSuccess => 'チームが選択されました';
	@override String get inviteTitle => 'チームメンバーを招待';
	@override String get inviteEmail => 'メールアドレス';
	@override String get enterEmail => 'メールアドレスを入力してください';
	@override String get invitedSuccess => 'チームメンバーが招待されました';
}

// Path: github
class _TranslationsGithubJa implements TranslationsGithubEn {
	_TranslationsGithubJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get connectTitle => 'GitHubと連携';
	@override String get connectDescription => 'GitHubアカウントを連携して\nリポジトリを自動的に選択できるようにします。';
	@override String get connectButton => 'GitHubと連携する';
}

// Path: subscription
class _TranslationsSubscriptionJa implements TranslationsSubscriptionEn {
	_TranslationsSubscriptionJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'サブスクリプション';
	@override String get noOfferings => '利用可能なプランがありません';
	@override String get noPackages => '利用可能なパッケージがありません';
	@override String get plans => 'プラン';
	@override String get restorePurchases => '購入を復元';
	@override String get purchaseSuccess => '購入が完了しました！';
	@override String purchaseFailed({required Object error}) => '購入に失敗: ${error}';
	@override String get restoreSuccess => '購入が正常に復元されました';
	@override String restoreFailed({required Object error}) => '復元に失敗: ${error}';
	@override String get activeSubscription => 'アクティブなサブスクリプション';
	@override String get active => '有効';
	@override String get termsOfUse => '利用規約';
	@override String get privacyPolicy => 'プライバシーポリシー';
	@override String get subscriptionTerms => 'サブスクリプションは、現在の期間の終了の少なくとも24時間前までにキャンセルしない限り、自動的に更新されます。Apple IDアカウントには、現在の期間の終了前24時間以内に更新料金が請求されます。購入後は、App Storeのアカウント設定からサブスクリプションの管理・キャンセルが可能です。';
	@override String get subscriptionTermsWeb => 'サブスクリプションは、現在の請求期間の終了前にキャンセルしない限り、自動的に更新されます。アカウント設定からサブスクリプションの管理・キャンセルが可能です。お支払いはStripeにより安全に処理されます。';
	@override String get perWeek => '週額';
	@override String get perMonth => '月額';
	@override String get per3Months => '3ヶ月ごと';
	@override String get per6Months => '6ヶ月ごと';
	@override String get perYear => '年額';
}

// Path: auth.firebaseForm
class _TranslationsAuthFirebaseFormJa implements TranslationsAuthFirebaseFormEn {
	_TranslationsAuthFirebaseFormJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '自分のFirebaseを使用';
	@override String get name => '名前';
	@override String get apiKey => 'APIキー';
	@override String get appId => 'アプリID';
	@override String get messagingSenderId => 'メッセージ送信者ID';
	@override String get projectId => 'プロジェクトID';
	@override String get storageBucket => 'ストレージバケット';
	@override String get pickConfig => 'Firebase設定を選択';
}

// Path: workflow.editor
class _TranslationsWorkflowEditorJa implements TranslationsWorkflowEditorEn {
	_TranslationsWorkflowEditorJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get createTitle => 'ワークフロー作成';
	@override String get editTitle => 'ワークフロー編集';
	@override String get editorTab => 'エディター';
	@override String get yamlTab => 'YAML';
	@override String get basicInfo => '基本情報';
	@override String get workflowName => 'ワークフロー名';
	@override String get stepName => 'ステップ名';
	@override String get stepNameHint => '例: iOSアプリビルド';
	@override String get type => 'タイプ';
	@override String get command => 'コマンド';
	@override String get action => 'アクション';
	@override String get actionHint => 'タップしてアクションを検索';
	@override String get version => 'バージョン';
	@override String get kWith => 'with';
	@override String get loadingInputs => '入力を読み込み中...';
	@override String get couldNotLoadInputs => '入力を読み込めませんでした';
	@override String get noInputs => 'このアクションには入力が定義されていません';
	@override String get enterAction => 'アクションを入力して利用可能な入力を確認';
	@override String get loadingVersions => 'バージョンを読み込み中...';
	@override String get required => '必須';
	@override String get editStep => 'ステップ編集';
	@override String get deleteStep => 'ステップ削除';
	@override String get deleteStepConfirm => 'このステップを削除しますか？';
	@override String get saveToRepo => 'リポジトリに保存';
	@override String get fileName => 'ファイル名';
	@override String get fileNameHint => '例: build.yaml';
	@override String get howToSave => '保存方法';
	@override String get commitDirectly => '直接コミット';
	@override String commitToBranch({required Object branch}) => '${branch} ブランチにコミット';
	@override String get createPR => 'プルリクエストを作成';
	@override String get createPRSubtitle => '新しいブランチが作成され、PRが開かれます';
	@override String commitToBranchButton({required Object branch}) => '${branch} にコミット';
	@override String get createPRButton => 'プルリクエストを作成';
	@override String get enterFileName => 'ファイル名を入力してください';
	@override String get fileNameMustEndYaml => 'ファイル名は .yaml または .yml で終わる必要があります';
	@override String get prCreated => 'プルリクエスト作成完了';
	@override String prNumber({required Object number}) => 'PR #${number} が作成されました。';
	@override String get close => '閉じる';
	@override String get openInGitHub => 'GitHubで開く';
	@override String committedToBranch({required Object branch}) => 'ワークフローファイルが ${branch} にコミットされました';
	@override String get prCreatedSuccess => 'プルリクエストが作成されました';
}

// Path: buildLogs.status
class _TranslationsBuildLogsStatusJa implements TranslationsBuildLogsStatusEn {
	_TranslationsBuildLogsStatusJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get success => '成功';
	@override String get failed => '失敗';
	@override String get inProgress => '実行中';
	@override String get queued => '待機中';
	@override String get cancelled => 'キャンセル';
}

// Path: buildLogs.detail
class _TranslationsBuildLogsDetailJa implements TranslationsBuildLogsDetailEn {
	_TranslationsBuildLogsDetailJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get viewDetails => '詳細を表示';
	@override String get retry => '再実行';
	@override String get cancelBuild => 'ビルドをキャンセル';
	@override String get cancelConfirm => '本当にこのビルドをキャンセルしますか？';
	@override String get cancelNo => 'いいえ';
	@override String get cancelling => 'ビルドをキャンセル中...';
	@override String get buildCancelled => 'ビルドがキャンセルされました';
	@override String failedToCancel({required Object error}) => 'キャンセルに失敗: ${error}';
	@override String get retrying => 'ビルドジョブを再実行中...';
	@override String get retrySuccess => 'ビルドジョブがキューに追加されました';
	@override String failedToRetry({required Object error}) => '再実行に失敗: ${error}';
	@override String get noRuns => 'まだ実行がありません';
	@override String get waitingForLogs => 'ログを待機中...';
	@override String logEntries({required Object count}) => '${count}件のログ';
	@override String get copyAll => 'すべてのログをコピー';
	@override String get logsCopied => 'ログがクリップボードにコピーされました';
	@override String lines({required Object count}) => '${count}行';
}

// Path: buildLogs.duration
class _TranslationsBuildLogsDurationJa implements TranslationsBuildLogsDurationEn {
	_TranslationsBuildLogsDurationJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get lessThanMinute => '<1分';
	@override String minutes({required Object count}) => '${count}分';
	@override String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours}時間${minutes}分';
	@override String hours({required Object count}) => '${count}時間';
}

// Path: settings.language
class _TranslationsSettingsLanguageJa implements TranslationsSettingsLanguageEn {
	_TranslationsSettingsLanguageJa._(this._root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '言語';
	@override String get subtitle => '表示言語を変更';
	@override String get system => 'システムのデフォルト';
	@override String get english => 'English';
	@override String get japanese => '日本語';
	@override String get spanish => 'Español';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.save' => '保存',
			'common.cancel' => 'キャンセル',
			'common.delete' => '削除',
			'common.add' => '追加',
			'common.edit' => '編集',
			'common.error' => ({required Object error}) => 'エラー: ${error}',
			'common.loading' => '読み込み中...',
			'common.invite' => '招待',
			'timeAgo.secsAgo' => ({required Object count}) => '${count}秒前',
			'timeAgo.secsAgoPlural' => ({required Object count}) => '${count}秒前',
			'timeAgo.minsAgo' => ({required Object count}) => '${count}分前',
			'timeAgo.minsAgoPlural' => ({required Object count}) => '${count}分前',
			'timeAgo.hoursAgo' => ({required Object count}) => '${count}時間前',
			'timeAgo.daysAgo' => ({required Object count}) => '${count}日前',
			'timeAgo.monthsAgo' => ({required Object count}) => '${count}ヶ月前',
			'nav.workflows' => 'ワークフロー',
			'nav.variables' => '変数',
			'nav.logs' => 'ログ',
			'nav.settings' => '設定',
			'auth.email' => 'メールアドレス',
			'auth.password' => 'パスワード',
			'auth.login' => 'ログイン',
			'auth.createAccount' => 'アカウント作成',
			'auth.useYourFirebase' => '自分のFirebaseを使用',
			'auth.resetFirebase' => 'Firebaseをリセット',
			'auth.resetSuccess' => 'Firebaseがリセットされました。アプリを再起動してください。',
			'auth.agreePrefix' => '利用規約に同意する ',
			'auth.termsOfService' => '利用規約',
			'auth.enterEmail' => 'メールアドレスを入力してください',
			'auth.enterPassword' => 'パスワードを入力してください',
			'auth.firebaseForm.title' => '自分のFirebaseを使用',
			'auth.firebaseForm.name' => '名前',
			'auth.firebaseForm.apiKey' => 'APIキー',
			'auth.firebaseForm.appId' => 'アプリID',
			'auth.firebaseForm.messagingSenderId' => 'メッセージ送信者ID',
			'auth.firebaseForm.projectId' => 'プロジェクトID',
			'auth.firebaseForm.storageBucket' => 'ストレージバケット',
			'auth.firebaseForm.pickConfig' => 'Firebase設定を選択',
			'workflow.title' => 'ワークフロー',
			'workflow.addWorkflow' => 'ワークフロー追加',
			'workflow.noWorkflowFiles' => 'ワークフローファイルが見つかりません',
			'workflow.addYamlHint' => 'リポジトリの .openci/ にYAMLファイルを追加してください。',
			'workflow.selectRepo' => 'リポジトリを選択',
			'workflow.selectRepoHint' => 'ワークフローを管理するGitHubリポジトリを選択してください。',
			'workflow.selectRepoButton' => 'リポジトリを選択',
			'workflow.triggers' => 'トリガー',
			'workflow.triggerBranch' => ({required Object type}) => '${type} ブランチ',
			'workflow.triggerBranchLoading' => ({required Object type}) => '${type} ブランチ (読み込み中...)',
			'workflow.editor.createTitle' => 'ワークフロー作成',
			'workflow.editor.editTitle' => 'ワークフロー編集',
			'workflow.editor.editorTab' => 'エディター',
			'workflow.editor.yamlTab' => 'YAML',
			'workflow.editor.basicInfo' => '基本情報',
			'workflow.editor.workflowName' => 'ワークフロー名',
			'workflow.editor.stepName' => 'ステップ名',
			'workflow.editor.stepNameHint' => '例: iOSアプリビルド',
			'workflow.editor.type' => 'タイプ',
			'workflow.editor.command' => 'コマンド',
			'workflow.editor.action' => 'アクション',
			'workflow.editor.actionHint' => 'タップしてアクションを検索',
			'workflow.editor.version' => 'バージョン',
			'workflow.editor.kWith' => 'with',
			'workflow.editor.loadingInputs' => '入力を読み込み中...',
			'workflow.editor.couldNotLoadInputs' => '入力を読み込めませんでした',
			'workflow.editor.noInputs' => 'このアクションには入力が定義されていません',
			'workflow.editor.enterAction' => 'アクションを入力して利用可能な入力を確認',
			'workflow.editor.loadingVersions' => 'バージョンを読み込み中...',
			'workflow.editor.required' => '必須',
			'workflow.editor.editStep' => 'ステップ編集',
			'workflow.editor.deleteStep' => 'ステップ削除',
			'workflow.editor.deleteStepConfirm' => 'このステップを削除しますか？',
			'workflow.editor.saveToRepo' => 'リポジトリに保存',
			'workflow.editor.fileName' => 'ファイル名',
			'workflow.editor.fileNameHint' => '例: build.yaml',
			'workflow.editor.howToSave' => '保存方法',
			'workflow.editor.commitDirectly' => '直接コミット',
			'workflow.editor.commitToBranch' => ({required Object branch}) => '${branch} ブランチにコミット',
			'workflow.editor.createPR' => 'プルリクエストを作成',
			'workflow.editor.createPRSubtitle' => '新しいブランチが作成され、PRが開かれます',
			'workflow.editor.commitToBranchButton' => ({required Object branch}) => '${branch} にコミット',
			'workflow.editor.createPRButton' => 'プルリクエストを作成',
			'workflow.editor.enterFileName' => 'ファイル名を入力してください',
			'workflow.editor.fileNameMustEndYaml' => 'ファイル名は .yaml または .yml で終わる必要があります',
			'workflow.editor.prCreated' => 'プルリクエスト作成完了',
			'workflow.editor.prNumber' => ({required Object number}) => 'PR #${number} が作成されました。',
			'workflow.editor.close' => '閉じる',
			'workflow.editor.openInGitHub' => 'GitHubで開く',
			'workflow.editor.committedToBranch' => ({required Object branch}) => 'ワークフローファイルが ${branch} にコミットされました',
			'workflow.editor.prCreatedSuccess' => 'プルリクエストが作成されました',
			'buildLogs.title' => ({required Object date}) => 'ビルドログ - ${date}',
			'buildLogs.noJobs' => 'ビルドジョブが見つかりません',
			'buildLogs.status.success' => '成功',
			'buildLogs.status.failed' => '失敗',
			'buildLogs.status.inProgress' => '実行中',
			'buildLogs.status.queued' => '待機中',
			'buildLogs.status.cancelled' => 'キャンセル',
			'buildLogs.detail.viewDetails' => '詳細を表示',
			'buildLogs.detail.retry' => '再実行',
			'buildLogs.detail.cancelBuild' => 'ビルドをキャンセル',
			'buildLogs.detail.cancelConfirm' => '本当にこのビルドをキャンセルしますか？',
			'buildLogs.detail.cancelNo' => 'いいえ',
			'buildLogs.detail.cancelling' => 'ビルドをキャンセル中...',
			'buildLogs.detail.buildCancelled' => 'ビルドがキャンセルされました',
			'buildLogs.detail.failedToCancel' => ({required Object error}) => 'キャンセルに失敗: ${error}',
			'buildLogs.detail.retrying' => 'ビルドジョブを再実行中...',
			'buildLogs.detail.retrySuccess' => 'ビルドジョブがキューに追加されました',
			'buildLogs.detail.failedToRetry' => ({required Object error}) => '再実行に失敗: ${error}',
			'buildLogs.detail.noRuns' => 'まだ実行がありません',
			'buildLogs.detail.waitingForLogs' => 'ログを待機中...',
			'buildLogs.detail.logEntries' => ({required Object count}) => '${count}件のログ',
			'buildLogs.detail.copyAll' => 'すべてのログをコピー',
			'buildLogs.detail.logsCopied' => 'ログがクリップボードにコピーされました',
			'buildLogs.detail.lines' => ({required Object count}) => '${count}行',
			'buildLogs.duration.lessThanMinute' => '<1分',
			'buildLogs.duration.minutes' => ({required Object count}) => '${count}分',
			'buildLogs.duration.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours}時間${minutes}分',
			'buildLogs.duration.hours' => ({required Object count}) => '${count}時間',
			'variables.title' => '変数',
			'variables.envVarsTab' => '環境変数',
			'variables.secretsTab' => 'シークレット',
			'secrets.title' => 'シークレットマネージャー',
			'secrets.noSecrets' => 'シークレットが見つかりません',
			'secrets.addSecret' => 'シークレット追加',
			'secrets.editSecret' => 'シークレット編集',
			'secrets.secretName' => 'シークレット名',
			'secrets.secretValue' => 'シークレット値',
			'secrets.newSecretValue' => '新しいシークレット値（空欄で現在の値を維持）',
			'secrets.enterSecretName' => 'シークレット名を入力してください',
			'secrets.enterSecretValue' => 'シークレット値を入力してください',
			'secrets.addedSuccess' => 'シークレットが追加されました',
			'secrets.updatedSuccess' => 'シークレットが更新されました',
			'secrets.deleteConfirm' => 'このシークレットを削除しますか？この操作は元に戻せません。',
			'secrets.deletedSuccess' => 'シークレットが削除されました',
			'secrets.unusedSecrets' => '未使用のシークレット',
			'secrets.notUsedInWorkflows' => 'ワークフローで使用されていません',
			'envVars.title' => '環境変数',
			'envVars.noEnvVars' => '環境変数が見つかりません',
			'envVars.noCustomEnvVars' => 'カスタム環境変数がありません',
			'envVars.addEnvVar' => '環境変数追加',
			'envVars.editEnvVar' => '環境変数編集',
			'envVars.editRunNumber' => '実行番号を編集',
			'envVars.keyName' => 'キー名',
			'envVars.value' => '値',
			'envVars.keyHint' => '例: MY_VARIABLE',
			'envVars.valueHint' => '例: hello',
			'envVars.enterKeyName' => 'キー名を入力してください',
			'envVars.enterValue' => '値を入力してください',
			'envVars.invalidKey' => '英字、数字、アンダースコアのみ使用できます',
			'envVars.valueMustBeNumber' => '値は数値である必要があります',
			'envVars.addedSuccess' => '環境変数が追加されました',
			'envVars.updatedSuccess' => '環境変数が更新されました',
			'envVars.deletedSuccess' => '削除しました',
			'envVars.runNumberUpdated' => '実行番号が更新されました',
			'settings.title' => '設定',
			'settings.buildNotifications' => 'ビルド通知',
			'settings.configureNotifications' => '通知を受け取るタイミングを設定',
			'settings.subscription' => 'サブスクリプション',
			'settings.manageSubscription' => 'サブスクリプションプランを管理',
			'settings.firebaseAppName' => ({required Object name}) => 'Firebaseアプリ名: ${name}',
			'settings.inviteTeamMember' => 'チームメンバーを招待',
			'settings.logout' => 'ログアウト',
			'settings.logoutSuccess' => 'ログアウトしました',
			'settings.logoutFailed' => ({required Object error}) => 'ログアウトに失敗: ${error}',
			'settings.deleteAccount' => 'アカウント削除',
			'settings.deleteConfirmTitle' => 'アカウント削除',
			'settings.deleteConfirmMessage' => '本当にアカウントを削除しますか？この操作は元に戻せません。すべてのデータが完全に削除されます。',
			'settings.deleteSuccess' => 'アカウントが削除されました',
			'settings.noUserSignedIn' => '現在サインインしているユーザーがいません',
			'settings.requiresRecentLogin' => 'アカウンを削除する前に、一度ログアウトしてから再度ログインしてください',
			'settings.deleteFailed' => ({required Object error}) => 'アカウントの削除に失敗: ${error}',
			'settings.language.title' => '言語',
			'settings.language.subtitle' => '表示言語を変更',
			'settings.language.system' => 'システムのデフォルト',
			'settings.language.english' => 'English',
			'settings.language.japanese' => '日本語',
			'settings.language.spanish' => 'Español',
			'notifications.title' => 'ビルド通知',
			'notifications.all' => 'すべて',
			'notifications.allDesc' => '成功時と失敗時の両方で通知',
			'notifications.successOnly' => '成功時のみ',
			'notifications.successOnlyDesc' => 'ビルド成功時のみ通知',
			'notifications.failureOnly' => '失敗時のみ',
			'notifications.failureOnlyDesc' => 'ビルド失敗時のみ通知',
			'notifications.none' => 'なし',
			'notifications.noneDesc' => '通知を送信しない',
			'notifications.updated' => '通知設定が更新されました',
			'notifications.updateFailed' => ({required Object error}) => '更新に失敗: ${error}',
			'notifications.errorLoading' => ({required Object error}) => '設定の読み込みエラー: ${error}',
			'team.switchTeam' => 'チーム切替',
			'team.editTeam' => 'チーム編集',
			'team.createTeam' => 'チーム作成',
			'team.createNewTeam' => '新しいチームを作成',
			'team.teamName' => 'チーム名',
			'team.newTeamName' => '新しいチーム名',
			'team.selectTeam' => 'チームを選択',
			'team.selectTeamLabel' => 'チーム',
			'team.enterTeamName' => 'チーム名を入力してください',
			'team.selectTeamValidation' => 'チームを選択してください',
			'team.createdSuccess' => 'チームが作成されました',
			'team.updatedSuccess' => 'チーム名が更新されました',
			'team.selectedSuccess' => 'チームが選択されました',
			'team.inviteTitle' => 'チームメンバーを招待',
			'team.inviteEmail' => 'メールアドレス',
			'team.enterEmail' => 'メールアドレスを入力してください',
			'team.invitedSuccess' => 'チームメンバーが招待されました',
			'github.connectTitle' => 'GitHubと連携',
			'github.connectDescription' => 'GitHubアカウントを連携して\nリポジトリを自動的に選択できるようにします。',
			'github.connectButton' => 'GitHubと連携する',
			'subscription.title' => 'サブスクリプション',
			'subscription.noOfferings' => '利用可能なプランがありません',
			'subscription.noPackages' => '利用可能なパッケージがありません',
			'subscription.plans' => 'プラン',
			'subscription.restorePurchases' => '購入を復元',
			'subscription.purchaseSuccess' => '購入が完了しました！',
			'subscription.purchaseFailed' => ({required Object error}) => '購入に失敗: ${error}',
			'subscription.restoreSuccess' => '購入が正常に復元されました',
			'subscription.restoreFailed' => ({required Object error}) => '復元に失敗: ${error}',
			'subscription.activeSubscription' => 'アクティブなサブスクリプション',
			'subscription.active' => '有効',
			'subscription.termsOfUse' => '利用規約',
			'subscription.privacyPolicy' => 'プライバシーポリシー',
			'subscription.subscriptionTerms' => 'サブスクリプションは、現在の期間の終了の少なくとも24時間前までにキャンセルしない限り、自動的に更新されます。Apple IDアカウントには、現在の期間の終了前24時間以内に更新料金が請求されます。購入後は、App Storeのアカウント設定からサブスクリプションの管理・キャンセルが可能です。',
			'subscription.subscriptionTermsWeb' => 'サブスクリプションは、現在の請求期間の終了前にキャンセルしない限り、自動的に更新されます。アカウント設定からサブスクリプションの管理・キャンセルが可能です。お支払いはStripeにより安全に処理されます。',
			'subscription.perWeek' => '週額',
			'subscription.perMonth' => '月額',
			'subscription.per3Months' => '3ヶ月ごと',
			'subscription.per6Months' => '6ヶ月ごと',
			'subscription.perYear' => '年額',
			_ => null,
		};
	}
}
