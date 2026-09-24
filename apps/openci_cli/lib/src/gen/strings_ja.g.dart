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
	@override late final _Translations$list$ja list = _Translations$list$ja._(_root);
	@override late final _Translations$register$ja register = _Translations$register$ja._(_root);
	@override late final _Translations$use$ja use = _Translations$use$ja._(_root);
	@override late final _Translations$dev$ja dev = _Translations$dev$ja._(_root);
	@override late final _Translations$sync$ja sync = _Translations$sync$ja._(_root);
	@override late final _Translations$common$ja common = _Translations$common$ja._(_root);
}

// Path: cli
class _Translations$cli$ja extends Translations$cli$en {
	_Translations$cli$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'OpenCI - CI/CD およびシークレット管理コマンドラインツール';
	@override String version({required Object version}) => 'openci バージョン: ${version}';
	@override late final _Translations$cli$flags$ja flags = _Translations$cli$flags$ja._(_root);
}

// Path: login
class _Translations$login$ja extends Translations$login$en {
	_Translations$login$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'ローカルまたはリモートのOpenCIサーバーにログインします。';
	@override late final _Translations$login$flags$ja flags = _Translations$login$flags$ja._(_root);
	@override String get loggingIn => 'OpenCI にログイン中...';
	@override String savedSuccess({required Object profile}) => 'プロファイル「${profile}」を保存し、有効にしました。';
	@override String get noArguments => 'loginに位置引数は指定できません。';
	@override String get authenticationFailed => 'ローカルサーバーの認証に失敗しました。openci dev start で起動したサーバーを確認してください。';
	@override String requestFailed({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。';
	@override String get localTeamRequired => 'このユーザーはtest-teamを利用できません。チームが初期データとして作成され、このAuth Emulatorユーザーが所属していることを確認してください。';
	@override String get invalidResponse => 'サーバーから返されたチーム一覧が不正です。';
	@override String get connectionFailed => 'ローカルサーバーに接続できませんでした。openci dev start の起動状態を確認してください。';
	@override String get saveFailed => '認証情報を保存できませんでした。ローカルの認証情報ファイルと権限を確認してください。';
	@override String get localOptionsConflict => '--localとリモートログイン用のオプションは同時に指定できません。';
	@override String get serverRequired => '--serverには認証情報、クエリ、フラグメントを含まない有効なHTTPSのURLを指定してください。ローカル開発には--localを使ってください。';
	@override String get emptyOptions => 'Firebase APIキーとチームIDには空の値を指定できません。';
	@override String get emailPrompt => 'メールアドレス: ';
	@override String get passwordPrompt => 'パスワード: ';
	@override String get inputRequired => '対話可能な端末でメールアドレスとパスワードを入力してください。ログインを中止しました。';
	@override String get firebaseAuthenticationFailed => 'Firebaseへのログインに失敗しました。メールアドレス、パスワード、Firebase APIキー、接続状態を確認してください。';
	@override String get emulatorAuthenticationFailed => 'Auth Emulatorへのログインに失敗しました。Emulatorが起動していること、demo-openciにユーザーが存在すること、メールアドレスとパスワードが正しいことを確認してください。';
	@override String get remoteConnectionFailed => 'リモートサーバーに接続できませんでした。サーバーURLと接続状態を確認してください。';
	@override String get noTeams => '所属チームがありません。先にdashboardでチームを作成するか参加してください。';
	@override String get teamRequired => '複数のチームがあります。上記のIDを--team-idで指定して再度ログインしてください。';
	@override String get teamNotFound => '指定されたチームに所属していません。';
}

// Path: list
class _Translations$list$ja extends Translations$list$en {
	_Translations$list$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'OpenCIのリソースを一覧表示します。';
	@override late final _Translations$list$secrets$ja secrets = _Translations$list$secrets$ja._(_root);
}

// Path: register
class _Translations$register$ja extends Translations$register$en {
	_Translations$register$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'OpenCIにリソースを登録します。';
	@override late final _Translations$register$secret$ja secret = _Translations$register$secret$ja._(_root);
	@override late final _Translations$register$secretFile$ja secretFile = _Translations$register$secretFile$ja._(_root);
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

// Path: sync
class _Translations$sync$ja extends Translations$sync$en {
	_Translations$sync$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'ローカルのワークフロー定義をOpenCIと同期します。';
	@override late final _Translations$sync$paths$ja paths = _Translations$sync$paths$ja._(_root);
	@override late final _Translations$sync$secrets$ja secrets = _Translations$sync$secrets$ja._(_root);
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
	@override String get local => 'Auth Emulator（127.0.0.1:9099）のユーザーのメールアドレスとパスワードでローカルAPI（http://localhost:8080）にログインします。';
	@override String get server => 'リモートのOpenCIサーバーURL（HTTPS）。';
	@override String get teamId => '複数チームに所属している場合に選択するチームID。';
	@override String get firebaseApiKey => 'Firebase Web APIキー（独自のFirebaseプロジェクトを使う場合に指定）。';
}

// Path: list.secrets
class _Translations$list$secrets$ja extends Translations$list$secrets$en {
	_Translations$list$secrets$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '現在のチームのシークレット名を名前順に一覧表示します。';
	@override String get noArguments => 'list secretsに位置引数は指定できません。';
	@override String get loginRequired => 'openci login（ローカルならopenci login --local）を実行してからシークレットを一覧表示してください。';
	@override String requestFailed({required Object status}) => 'シークレット名を取得できませんでした（HTTP ${status}）。';
	@override String get fetchFailed => 'シークレット名を取得できませんでした。サーバーの接続状態とレスポンスを確認してください。';
	@override String get empty => '現在のチームにはシークレットが登録されていません。';
}

// Path: register.secret
class _Translations$register$secret$ja extends Translations$register$secret$en {
	_Translations$register$secret$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '現在のチームのシークレットを登録・更新します。名前と値を順に入力します。値は入力中は非表示で、Enterで確定すると******と表示します。';
	@override String get noArguments => 'register secretに位置引数は指定できません。名前と値は対話入力で指定してください。';
	@override String get invalidName => 'シークレット名には英数字とアンダースコアを使い、数字で始めないでください。';
	@override String get loginRequired => 'openci login（ローカルならopenci login --local）を実行してからシークレットを登録してください。';
	@override String get namePrompt => 'シークレット名:';
	@override String get valuePrompt => 'シークレット値:';
	@override String get inputRequired => 'シークレットは登録されませんでした。対話可能な端末で名前と空でない値を入力してください。';
	@override String get inputFailed => 'シークレット名または値を読み取れませんでした。対話可能な端末で再試行してください。';
	@override String requestFailed({required Object status}) => 'シークレットを登録できませんでした（HTTP ${status}）。';
	@override String get saveFailed => 'シークレットを登録できませんでした。サーバーの接続状態を確認してください。';
	@override String saved({required Object teamId, required Object name}) => 'チーム${teamId}にシークレット${name}を保存しました。';
}

// Path: register.secretFile
class _Translations$register$secretFile$ja extends Translations$register$secretFile$en {
	_Translations$register$secretFile$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '対話式でファイルを選択し、内容をBase64化して現在のチームのシークレットに登録します。';
	@override String get noArguments => 'register secretFileに位置引数は指定できません。対話入力でファイルを選択してください。';
	@override String get filePrompt => 'シークレットに登録するファイルを選択';
	@override String get controls => '入力で絞込 / Tab・↑↓: 補完 / Enter: 移動・選択 / Esc: 中止';
	@override String get noMatches => '候補がありません。パスを入力してください。隠しファイルは . で表示できます。';
	@override String get notFound => 'ファイルが見つかりません。存在するファイルを選択してください。';
	@override String get cancelled => 'ファイルは登録されませんでした。対話可能な端末でファイルを選択してください。';
	@override String get inputFailed => 'ファイルを選択できませんでした。対話可能な端末で再試行してください。';
	@override String get readFailed => '選択したファイルを読み取れませんでした。通常のファイルであることと読み取り権限を確認してください。';
	@override String get emptyFile => '選択したファイルは空です。シークレットは登録されませんでした。';
}

// Path: dev.start
class _Translations$dev$start$ja extends Translations$dev$start$en {
	_Translations$dev$start$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'ローカルサービスを起動し、Ctrl+CまでMac側のOrchard Workerを実行します。';
	@override late final _Translations$dev$start$flags$ja flags = _Translations$dev$start$flags$ja._(_root);
	@override String get starting => 'OpenCI ローカル開発環境を起動しています...';
	@override String get stepTart => 'Step 1: Tart VM ベースイメージを確認中...';
	@override String get stepTartNotFound => 'エラー: Tart VM イメージ「base-macos」が見つかりません。\n以下のコマンドを実行してイメージを準備してください:\n  tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5\n  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos';
	@override String get stepTartExists => 'Tart VM (base-macos) を確認しました。';
	@override String get stepAuthEmulator => 'Firebase Auth Emulator を起動し、準備完了を待っています...';
	@override String get stepAuthEmulatorFailed => 'エラー: Firebase Auth Emulator の起動または準備完了の確認に失敗しました。';
	@override String get stepDockerCompose => 'Step 5: Docker コンテナを起動中...';
	@override String get stepDockerComposeFailed => 'エラー: Docker コンテナの起動に失敗しました。';
	@override String get stepDockerComposeStarted => 'Docker コンテナを起動しました。';
	@override String get stepDockerComposeDown => 'ローカルのDockerコンテナを停止・削除しています（データ用ボリュームは保持します）...';
	@override String get stepDockerComposeDownFailed => 'エラー: ローカルのDockerコンテナの終了に失敗しました。チェックアウトのルートで docker compose -f docker-compose.yml -f docker-compose.local.yml -f docker-compose.local-api.yml down --remove-orphans を実行して再試行してください。';
	@override String get stepOrchardWaiting => 'Step 3: Orchard Controller の起動を待機中...';
	@override String get stepOrchardNotReady => 'エラー: Orchard Controller の起動を確認できませんでした。';
	@override String get stepOrchardContext => 'Step 4: Orchard CLI コンテキストを登録中...';
	@override String get stepOrchardContextFailed => 'エラー: Orchard CLI コンテキストの登録に失敗しました。';
	@override String get stepOrchardContextRegistered => 'Orchard CLI コンテキストを認証しました。';
	@override String get stepOrchardWorker => 'Mac側のOrchard Workerを起動します。Ctrl+Cで停止できます。Dockerコンテナは起動したままになります。';
	@override String get stepOrchardWorkerFailed => 'エラー: Orchard Workerを起動できなかったか、異常終了しました。';
	@override String get stepSeed => 'Step 6: ローカルテストデータを投入中...';
	@override String get stepSeedFailed => 'エラー: ローカルテストデータの投入に失敗しました。';
	@override String get stepSeedCompleted => 'ローカルテストデータを投入しました。';
	@override String get projectRootNotFound => 'エラー: OpenCI プロジェクトのルートディレクトリが見つかりません。';
	@override String get stepOrchardController => 'Step 2: Orchard Controllerを起動中...';
	@override String get stepBuildJobWorkerWaiting => 'サービスを再起動する前に、実行中のビルドジョブの終了を待っています...';
}

// Path: sync.paths
class _Translations$sync$paths$ja extends Translations$sync$paths$en {
	_Translations$sync$paths$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'pubspec.yamlのworkspaceからopenci/paths.g.dartを生成します。';
	@override String get noArguments => 'sync pathsに位置引数は指定できません。';
	@override String get projectRootNotFound => 'pubspec.yamlとopenciディレクトリのあるプロジェクトが見つかりません。ワークフローのあるプロジェクト内で実行してください。';
	@override String fileAccessFailed({required Object path}) => '${path}を読み書きできませんでした。ファイルの有無とアクセス権限を確認してください。';
	@override String saved({required Object path}) => 'ワークスペースのパスを生成しました: ${path}';
}

// Path: sync.secrets
class _Translations$sync$secrets$ja extends Translations$sync$secrets$en {
	_Translations$sync$secrets$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '現在のチームのシークレット名からopenci/secrets.g.dartを生成します。';
	@override String get noArguments => 'sync secretsに位置引数は指定できません。';
	@override String get loginRequired => 'openci login（ローカルならopenci login --local）を実行してからシークレットを同期してください。';
	@override String get workflowDirectoryNotFound => 'openciディレクトリが見つかりません。ワークフローのあるプロジェクト内で実行してください。';
	@override String requestFailed({required Object status}) => 'シークレット名を取得できませんでした（HTTP ${status}）。';
	@override String get fetchFailed => 'シークレット名を取得できませんでした。サーバーの接続状態とレスポンスを確認してください。';
	@override String get saveFailed => 'secrets.g.dartを保存できませんでした。保存先とファイルの権限を確認してください。';
	@override String saved({required Object path}) => 'シークレット定義を生成しました: ${path}';
}

// Path: dev.start.flags
class _Translations$dev$start$flags$ja extends Translations$dev$start$flags$en {
	_Translations$dev$start$flags$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get seed => 'サービス起動後にデフォルトの動作確認用ジョブを1件投入します。';
}

/// The flat map containing all translations for locale <ja>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsJa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'cli.description' => 'OpenCI - CI/CD およびシークレット管理コマンドラインツール',
			'cli.version' => ({required Object version}) => 'openci バージョン: ${version}',
			'cli.flags.version' => 'ツールのバージョンを表示します。',
			'cli.flags.verbose' => '詳細なログ出力を有効にします。',
			'login.description' => 'ローカルまたはリモートのOpenCIサーバーにログインします。',
			'login.flags.local' => 'Auth Emulator（127.0.0.1:9099）のユーザーのメールアドレスとパスワードでローカルAPI（http://localhost:8080）にログインします。',
			'login.flags.server' => 'リモートのOpenCIサーバーURL（HTTPS）。',
			'login.flags.teamId' => '複数チームに所属している場合に選択するチームID。',
			'login.flags.firebaseApiKey' => 'Firebase Web APIキー（独自のFirebaseプロジェクトを使う場合に指定）。',
			'login.loggingIn' => 'OpenCI にログイン中...',
			'login.savedSuccess' => ({required Object profile}) => 'プロファイル「${profile}」を保存し、有効にしました。',
			'login.noArguments' => 'loginに位置引数は指定できません。',
			'login.authenticationFailed' => 'ローカルサーバーの認証に失敗しました。openci dev start で起動したサーバーを確認してください。',
			'login.requestFailed' => ({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。',
			'login.localTeamRequired' => 'このユーザーはtest-teamを利用できません。チームが初期データとして作成され、このAuth Emulatorユーザーが所属していることを確認してください。',
			'login.invalidResponse' => 'サーバーから返されたチーム一覧が不正です。',
			'login.connectionFailed' => 'ローカルサーバーに接続できませんでした。openci dev start の起動状態を確認してください。',
			'login.saveFailed' => '認証情報を保存できませんでした。ローカルの認証情報ファイルと権限を確認してください。',
			'login.localOptionsConflict' => '--localとリモートログイン用のオプションは同時に指定できません。',
			'login.serverRequired' => '--serverには認証情報、クエリ、フラグメントを含まない有効なHTTPSのURLを指定してください。ローカル開発には--localを使ってください。',
			'login.emptyOptions' => 'Firebase APIキーとチームIDには空の値を指定できません。',
			'login.emailPrompt' => 'メールアドレス: ',
			'login.passwordPrompt' => 'パスワード: ',
			'login.inputRequired' => '対話可能な端末でメールアドレスとパスワードを入力してください。ログインを中止しました。',
			'login.firebaseAuthenticationFailed' => 'Firebaseへのログインに失敗しました。メールアドレス、パスワード、Firebase APIキー、接続状態を確認してください。',
			'login.emulatorAuthenticationFailed' => 'Auth Emulatorへのログインに失敗しました。Emulatorが起動していること、demo-openciにユーザーが存在すること、メールアドレスとパスワードが正しいことを確認してください。',
			'login.remoteConnectionFailed' => 'リモートサーバーに接続できませんでした。サーバーURLと接続状態を確認してください。',
			'login.noTeams' => '所属チームがありません。先にdashboardでチームを作成するか参加してください。',
			'login.teamRequired' => '複数のチームがあります。上記のIDを--team-idで指定して再度ログインしてください。',
			'login.teamNotFound' => '指定されたチームに所属していません。',
			'list.description' => 'OpenCIのリソースを一覧表示します。',
			'list.secrets.description' => '現在のチームのシークレット名を名前順に一覧表示します。',
			'list.secrets.noArguments' => 'list secretsに位置引数は指定できません。',
			'list.secrets.loginRequired' => 'openci login（ローカルならopenci login --local）を実行してからシークレットを一覧表示してください。',
			'list.secrets.requestFailed' => ({required Object status}) => 'シークレット名を取得できませんでした（HTTP ${status}）。',
			'list.secrets.fetchFailed' => 'シークレット名を取得できませんでした。サーバーの接続状態とレスポンスを確認してください。',
			'list.secrets.empty' => '現在のチームにはシークレットが登録されていません。',
			'register.description' => 'OpenCIにリソースを登録します。',
			'register.secret.description' => '現在のチームのシークレットを登録・更新します。名前と値を順に入力します。値は入力中は非表示で、Enterで確定すると******と表示します。',
			'register.secret.noArguments' => 'register secretに位置引数は指定できません。名前と値は対話入力で指定してください。',
			'register.secret.invalidName' => 'シークレット名には英数字とアンダースコアを使い、数字で始めないでください。',
			'register.secret.loginRequired' => 'openci login（ローカルならopenci login --local）を実行してからシークレットを登録してください。',
			'register.secret.namePrompt' => 'シークレット名:',
			'register.secret.valuePrompt' => 'シークレット値:',
			'register.secret.inputRequired' => 'シークレットは登録されませんでした。対話可能な端末で名前と空でない値を入力してください。',
			'register.secret.inputFailed' => 'シークレット名または値を読み取れませんでした。対話可能な端末で再試行してください。',
			'register.secret.requestFailed' => ({required Object status}) => 'シークレットを登録できませんでした（HTTP ${status}）。',
			'register.secret.saveFailed' => 'シークレットを登録できませんでした。サーバーの接続状態を確認してください。',
			'register.secret.saved' => ({required Object teamId, required Object name}) => 'チーム${teamId}にシークレット${name}を保存しました。',
			'register.secretFile.description' => '対話式でファイルを選択し、内容をBase64化して現在のチームのシークレットに登録します。',
			'register.secretFile.noArguments' => 'register secretFileに位置引数は指定できません。対話入力でファイルを選択してください。',
			'register.secretFile.filePrompt' => 'シークレットに登録するファイルを選択',
			'register.secretFile.controls' => '入力で絞込 / Tab・↑↓: 補完 / Enter: 移動・選択 / Esc: 中止',
			'register.secretFile.noMatches' => '候補がありません。パスを入力してください。隠しファイルは . で表示できます。',
			'register.secretFile.notFound' => 'ファイルが見つかりません。存在するファイルを選択してください。',
			'register.secretFile.cancelled' => 'ファイルは登録されませんでした。対話可能な端末でファイルを選択してください。',
			'register.secretFile.inputFailed' => 'ファイルを選択できませんでした。対話可能な端末で再試行してください。',
			'register.secretFile.readFailed' => '選択したファイルを読み取れませんでした。通常のファイルであることと読み取り権限を確認してください。',
			'register.secretFile.emptyFile' => '選択したファイルは空です。シークレットは登録されませんでした。',
			'use.description' => '表示言語を設定します（japanese, english）。',
			'use.success' => ({required Object language}) => '言語を${language}に設定しました。',
			'use.invalidLanguage' => ({required Object input}) => '無効な言語です: 「${input}」。対応言語: japanese, english',
			'dev.description' => 'ローカル開発環境（Docker, Tart, DB, サーバー）を管理します。',
			'dev.start.description' => 'ローカルサービスを起動し、Ctrl+CまでMac側のOrchard Workerを実行します。',
			'dev.start.flags.seed' => 'サービス起動後にデフォルトの動作確認用ジョブを1件投入します。',
			'dev.start.starting' => 'OpenCI ローカル開発環境を起動しています...',
			'dev.start.stepTart' => 'Step 1: Tart VM ベースイメージを確認中...',
			'dev.start.stepTartNotFound' => 'エラー: Tart VM イメージ「base-macos」が見つかりません。\n以下のコマンドを実行してイメージを準備してください:\n  tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5\n  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos',
			'dev.start.stepTartExists' => 'Tart VM (base-macos) を確認しました。',
			'dev.start.stepAuthEmulator' => 'Firebase Auth Emulator を起動し、準備完了を待っています...',
			'dev.start.stepAuthEmulatorFailed' => 'エラー: Firebase Auth Emulator の起動または準備完了の確認に失敗しました。',
			'dev.start.stepDockerCompose' => 'Step 5: Docker コンテナを起動中...',
			'dev.start.stepDockerComposeFailed' => 'エラー: Docker コンテナの起動に失敗しました。',
			'dev.start.stepDockerComposeStarted' => 'Docker コンテナを起動しました。',
			'dev.start.stepDockerComposeDown' => 'ローカルのDockerコンテナを停止・削除しています（データ用ボリュームは保持します）...',
			'dev.start.stepDockerComposeDownFailed' => 'エラー: ローカルのDockerコンテナの終了に失敗しました。チェックアウトのルートで docker compose -f docker-compose.yml -f docker-compose.local.yml -f docker-compose.local-api.yml down --remove-orphans を実行して再試行してください。',
			'dev.start.stepOrchardWaiting' => 'Step 3: Orchard Controller の起動を待機中...',
			'dev.start.stepOrchardNotReady' => 'エラー: Orchard Controller の起動を確認できませんでした。',
			'dev.start.stepOrchardContext' => 'Step 4: Orchard CLI コンテキストを登録中...',
			'dev.start.stepOrchardContextFailed' => 'エラー: Orchard CLI コンテキストの登録に失敗しました。',
			'dev.start.stepOrchardContextRegistered' => 'Orchard CLI コンテキストを認証しました。',
			'dev.start.stepOrchardWorker' => 'Mac側のOrchard Workerを起動します。Ctrl+Cで停止できます。Dockerコンテナは起動したままになります。',
			'dev.start.stepOrchardWorkerFailed' => 'エラー: Orchard Workerを起動できなかったか、異常終了しました。',
			'dev.start.stepSeed' => 'Step 6: ローカルテストデータを投入中...',
			'dev.start.stepSeedFailed' => 'エラー: ローカルテストデータの投入に失敗しました。',
			'dev.start.stepSeedCompleted' => 'ローカルテストデータを投入しました。',
			'dev.start.projectRootNotFound' => 'エラー: OpenCI プロジェクトのルートディレクトリが見つかりません。',
			'dev.start.stepOrchardController' => 'Step 2: Orchard Controllerを起動中...',
			'dev.start.stepBuildJobWorkerWaiting' => 'サービスを再起動する前に、実行中のビルドジョブの終了を待っています...',
			'sync.description' => 'ローカルのワークフロー定義をOpenCIと同期します。',
			'sync.paths.description' => 'pubspec.yamlのworkspaceからopenci/paths.g.dartを生成します。',
			'sync.paths.noArguments' => 'sync pathsに位置引数は指定できません。',
			'sync.paths.projectRootNotFound' => 'pubspec.yamlとopenciディレクトリのあるプロジェクトが見つかりません。ワークフローのあるプロジェクト内で実行してください。',
			'sync.paths.fileAccessFailed' => ({required Object path}) => '${path}を読み書きできませんでした。ファイルの有無とアクセス権限を確認してください。',
			'sync.paths.saved' => ({required Object path}) => 'ワークスペースのパスを生成しました: ${path}',
			'sync.secrets.description' => '現在のチームのシークレット名からopenci/secrets.g.dartを生成します。',
			'sync.secrets.noArguments' => 'sync secretsに位置引数は指定できません。',
			'sync.secrets.loginRequired' => 'openci login（ローカルならopenci login --local）を実行してからシークレットを同期してください。',
			'sync.secrets.workflowDirectoryNotFound' => 'openciディレクトリが見つかりません。ワークフローのあるプロジェクト内で実行してください。',
			'sync.secrets.requestFailed' => ({required Object status}) => 'シークレット名を取得できませんでした（HTTP ${status}）。',
			'sync.secrets.fetchFailed' => 'シークレット名を取得できませんでした。サーバーの接続状態とレスポンスを確認してください。',
			'sync.secrets.saveFailed' => 'secrets.g.dartを保存できませんでした。保存先とファイルの権限を確認してください。',
			'sync.secrets.saved' => ({required Object path}) => 'シークレット定義を生成しました: ${path}',
			'common.error' => ({required Object error}) => 'エラー: ${error}',
			_ => null,
		};
	}
}
