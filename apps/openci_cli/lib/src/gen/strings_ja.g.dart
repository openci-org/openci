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
	@override late final _Translations$update$ja update = _Translations$update$ja._(_root);
	@override late final _Translations$login$ja login = _Translations$login$ja._(_root);
	@override late final _Translations$status$ja status = _Translations$status$ja._(_root);
	@override late final _Translations$list$ja list = _Translations$list$ja._(_root);
	@override late final _Translations$register$ja register = _Translations$register$ja._(_root);
	@override late final _Translations$setup$ja setup = _Translations$setup$ja._(_root);
	@override late final _Translations$switchCommand$ja switchCommand = _Translations$switchCommand$ja._(_root);
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
	@override String get description => 'GenuineCI - CI/CD およびシークレット管理コマンドラインツール';
	@override String version({required Object version}) => 'genuineci バージョン: ${version}';
	@override late final _Translations$cli$flags$ja flags = _Translations$cli$flags$ja._(_root);
}

// Path: update
class _Translations$update$ja extends Translations$update$en {
	_Translations$update$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'GenuineCI CLIをpub.devの最新安定版に更新します。';
	@override String get noArguments => 'updateに位置引数は指定できません。';
	@override String available({required Object current, required Object latest}) => 'アップデートがあります！ ${current} → ${latest}';
	@override String get confirm => '今すぐ更新しますか？';
	@override String updating({required Object version}) => 'GenuineCI CLIを${version}に更新中...';
	@override String updated({required Object version}) => 'GenuineCI CLIを${version}に更新しました。';
	@override String upToDate({required Object version}) => 'GenuineCI CLI ${version}は最新です。';
	@override String get checkFailed => '更新を確認できませんでした。pub.devへの接続を確認して再実行してください。';
	@override String get installFailed => 'GenuineCI CLIを更新できませんでした。上記のDartの出力を確認して再実行してください。';
	@override String get dartUnavailable => 'Dartを起動できませんでした。Dart SDKがインストールされ、dartがPATHに含まれていることを確認してください。';
	@override String get rerunCommand => '更新したCLIを使うには、元のコマンドを再実行してください。';
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
	@override String get authenticationFailed => 'ローカルサーバーの認証に失敗しました。genuineci dev start で起動したサーバーを確認してください。';
	@override String requestFailed({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。';
	@override String get localTeamRequired => 'このユーザーはtest-teamを利用できません。チームが初期データとして作成され、このAuth Emulatorユーザーが所属していることを確認してください。';
	@override String get invalidResponse => 'サーバーから返されたチーム一覧が不正です。';
	@override String get connectionFailed => 'ローカルサーバーに接続できませんでした。genuineci dev start の起動状態を確認してください。';
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

// Path: status
class _Translations$status$ja extends Translations$status$en {
	_Translations$status$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '現在のプロファイル、サーバー、チーム名とIDを表示します。';
	@override String get noArguments => 'statusに位置引数は指定できません。';
	@override String profile({required Object value}) => 'プロファイル: ${value}';
	@override String server({required Object value}) => 'サーバー: ${value}';
	@override String team({required Object value}) => '選択中のチームID: ${value}';
	@override String get notSet => '未設定';
	@override String get noActiveProfile => 'プロファイルが未設定です。genuineci login（ローカルなら genuineci login --local）を実行してください。';
	@override String profileMissing({required Object profile}) => '現在のプロファイル「${profile}」が見つかりません。genuineci login（ローカルなら genuineci login --local）を実行してください。';
	@override String get invalidServer => '不正なサーバーURL';
	@override String get readFailed => '保存済みのプロファイルを読み取れませんでした。認証情報ファイルの形式と権限を確認してください。';
	@override String get profileChanged => '確認中に現在のプロファイルまたは選択中のチームが変更されました。genuineci statusを再実行してください。';
	@override String get loginRequired => '現在のチームを確認するには、genuineci login（またはgenuineci login --local）を実行してください。';
	@override String get noTeamSelected => 'チームが選択されていません。genuineci switch teamでチームを選択してください。';
	@override String get noTeams => '所属するチームがありません。ダッシュボードでチームを作成するか、チームに参加してください。';
	@override String get teamNotFound => '選択中のチームは利用できなくなりました。genuineci switch teamで利用可能なチームを選択してください。';
	@override String requestFailed({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。';
	@override String get fetchFailed => 'チーム一覧を取得できませんでした。現在のプロファイルのサーバーURLとネットワーク接続を確認してください。';
	@override String get invalidResponse => 'サーバーから不正なチーム一覧が返されました。現在のプロファイルが対応するOpenCIサーバーを指しているか確認してください。';
	@override String teamName({required Object value}) => 'チーム名: ${value}';
}

// Path: list
class _Translations$list$ja extends Translations$list$en {
	_Translations$list$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'OpenCIのリソースを一覧表示します。';
	@override late final _Translations$list$teams$ja teams = _Translations$list$teams$ja._(_root);
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

// Path: setup
class _Translations$setup$ja extends Translations$setup$en {
	_Translations$setup$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'OpenCI の外部サービス連携をセットアップします。';
	@override late final _Translations$setup$ascKeys$ja ascKeys = _Translations$setup$ascKeys$ja._(_root);
}

// Path: switchCommand
class _Translations$switchCommand$ja extends Translations$switchCommand$en {
	_Translations$switchCommand$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'OpenCIで使用するチームを切り替えます。';
	@override late final _Translations$switchCommand$team$ja team = _Translations$switchCommand$team$ja._(_root);
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
	@override String get description => 'シークレット定義とワークスペースパスをopenci/generatedに生成します。';
	@override late final _Translations$sync$paths$ja paths = _Translations$sync$paths$ja._(_root);
	@override late final _Translations$sync$secrets$ja secrets = _Translations$sync$secrets$ja._(_root);
	@override String get noArguments => 'syncに位置引数は指定できません。生成対象を選ぶには--secretsまたは--pathsを指定してください。';
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
	@override String get checkUpdates => '対話可能な端末で更新を確認し、インストールするか選択します。';
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

// Path: list.teams
class _Translations$list$teams$ja extends Translations$list$teams$en {
	_Translations$list$teams$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '所属チームの名前とIDを一覧表示します。*は現在のチームです。';
	@override String get noArguments => 'list teamsに位置引数は指定できません。';
	@override String get loginRequired => 'genuineci login（ローカルならgenuineci login --local）を実行してからチームを一覧表示してください。';
	@override String requestFailed({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。';
	@override String get fetchFailed => 'チーム一覧を取得できませんでした。現在のプロファイルのサーバーURLとネットワーク接続を確認してください。';
	@override String get invalidResponse => 'サーバーから返されたチーム一覧が不正です。';
	@override String get empty => '所属チームがありません。ダッシュボードでチームを作成するか参加してください。';
}

// Path: list.secrets
class _Translations$list$secrets$ja extends Translations$list$secrets$en {
	_Translations$list$secrets$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '現在のチームのシークレット名を名前順に一覧表示します。';
	@override String get noArguments => 'list secretsに位置引数は指定できません。';
	@override String get loginRequired => 'genuineci login（ローカルならgenuineci login --local）を実行してからシークレットを一覧表示してください。';
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
	@override String get loginRequired => 'genuineci login（ローカルならgenuineci login --local）を実行してからシークレットを登録してください。';
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

// Path: setup.ascKeys
class _Translations$setup$ascKeys$ja extends Translations$setup$ascKeys$en {
	_Translations$setup$ascKeys$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => 'App Store Connect API キーを発行して OpenCI に保存します。';
	@override String get noArguments => 'setup asc-keys は位置引数を受け付けません。';
	@override String get keyDirectoryHelp => 'key.json と .p8 があるディレクトリから発行済みのキーを保存します。新しいキーは発行しません。';
	@override String get keyDirectoryRequired => '--key-directory には空でないディレクトリのパスを指定してください。';
	@override String saveDestination({required Object server, required Object team, required Object name}) => 'OpenCI の保存先: ${server}\n  Team ID: ${team}\n  Secret: ${name}';
	@override String secretWillReplace({required Object name}) => '続行すると、既存の ${name} シークレットを置き換えます。';
	@override String get savePreflightFailed => 'OpenCI チームのシークレットへのアクセスを確認できませんでした。キーを発行する前にサーバーと接続を確認してください。';
	@override String get saveProfileChanged => 'セットアップ中に OpenCI のプロファイルまたは認証情報が変更されました。キーは保存していません。保存先のプロファイルとチームを確認して再試行してください。';
	@override String get savedKeyInvalid => '有効な保存済みキーを読み取れませんでした。保存先の key.json と対応する .p8 ファイルを確認してください。';
	@override String cacheFound({required Object version, required Object path}) => 'asc ${version} 用のキャッシュファイルが見つかりました: ${path}';
	@override String installing({required Object version}) => 'Apple Silicon Mac 用の asc ${version} をダウンロードしてインストールしています...';
	@override String installed({required Object version, required Object path}) => 'asc ${version} をインストールしました: ${path}';
	@override String versionVerified({required Object version}) => 'asc ${version} の動作を確認しました。';
	@override String get appleIdPrompt => 'Apple ID（メールアドレス）: ';
	@override String get appleIdReceived => 'Apple ID を受け付けました。';
	@override String get appleIdRequired => 'Apple ID が入力されなかったため、セットアップを中止しました。';
	@override String get terminalRequired => 'Apple ID の入力には対話可能な端末が必要です。端末で genuineci setup asc-keys を実行してください。';
	@override String get appleIdInputFailed => 'Apple ID を読み取れませんでした。対話可能な端末で再試行してください。';
	@override String get loginStartFailed => 'asc のログイン処理を起動できませんでした。キャッシュ内の asc ファイルに実行権限があることを確認して再試行してください。';
	@override String get authenticationVerified => 'Apple の認証状態を確認しました。';
	@override String get selectedProvider => '選択中の App Store Connect Provider:';
	@override String providerId({required Object id}) => '  Provider ID: ${id}';
	@override String publicProviderId({required Object id}) => '  Public Provider ID: ${id}';
	@override String get providerUnavailable => '選択中の App Store Connect Provider を取得できませんでした。';
	@override String get confirmKeyCreation => 'この Provider の全アプリにアクセスできる APP_MANAGER 権限の GenuineCI キーを新規発行し、上記の OpenCI 保存先に保存しますか？ [y/N] ';
	@override String get confirmKeySave => 'このキーを上記の OpenCI 保存先に保存しますか？ [y/N] ';
	@override String get keySaveCancelled => 'キーの保存を中止しました。OpenCI のシークレットは変更していません。';
	@override String get keyCreationCancelled => 'キーの発行を中止しました。新しいキーの発行はリクエストしていません。';
	@override String get keyConfirmationFailed => '確認の入力を読み取れませんでした。対話可能な端末で genuineci setup asc-keys を実行してください。';
	@override String get keyDirectoryFailed => 'キーの保存先を準備できませんでした。権限とディスクの空き容量を確認してください。新しいキーの発行はリクエストしていません。';
	@override String keyOutputDirectory({required Object path}) => 'キーの保存先: ${path}';
	@override String get keyCreated => 'APP_MANAGER 権限の GenuineCI API キーを発行しました。';
	@override String keyId({required Object id}) => '  Key ID: ${id}';
	@override String issuerId({required Object id}) => '  Issuer ID: ${id}';
	@override String privateKeySaved({required Object path}) => '  秘密鍵: ${path}';
	@override String get setupComplete => 'App Store Connect API キーのセットアップが完了しました。OpenCI に保存し、ローカルの鍵ファイルも保持しています。';
	@override String retrySave({required Object command}) => 'ローカルの鍵ファイルは保持しています。新しいキーを発行せずに保存を再試行できます:\n  ${command}';
	@override String get keyCreationStartFailed => 'asc のキー発行処理を起動できませんでした。新しいキーの発行はリクエストしていません。';
	@override String get keyCreationFailed => 'asc の API キー発行処理が正常に完了しませんでした。';
	@override String get keyCreationInvalid => 'キーの発行結果または保存された秘密鍵を確認できませんでした。';
	@override String get keyStorageFailed => 'API キーのファイルを保存または読み取りできませんでした。';
	@override String keyRecovery({required Object path}) => 'キーがすでに発行されている可能性があります。再実行する前に App Store Connect を確認してください。ダウンロード済みのファイルは次の場所に残しています: ${path}';
	@override String get notAuthenticated => 'Apple の認証を確認できませんでした。genuineci setup asc-keys を再実行してログインしてください。';
	@override String get authStatusFailed => 'asc で Apple の認証状態を確認できませんでした。セットアップを再試行してください。';
	@override String get authStatusTimedOut => 'Apple の認証状態の確認がタイムアウトしました。セットアップを再試行してください。';
	@override String get authStatusInvalid => 'asc の認証状態の応答が想定と異なります。セットアップを再試行してください。';
	@override String get cachedChecksumFailed => 'キャッシュ内の asc ファイルの SHA-256 が期待値と一致しなかったため、実行しませんでした。キャッシュファイルを削除して再試行してください。';
	@override String get executionFailed => 'asc version を正常に実行できませんでした。キャッシュ内の asc ファイルに実行権限があることを確認して再試行してください。';
	@override String get versionTimedOut => 'asc version がタイムアウトしました。再試行してください。';
	@override String versionMismatch({required Object version}) => 'asc version の出力が必要なバージョン（${version}）と一致しませんでした。キャッシュファイルを削除して再試行してください。';
	@override String get unsupportedPlatform => 'setup asc-keys は現在 Apple Silicon Mac（macOS arm64）のみに対応しています。';
	@override String get cacheFailed => 'asc のキャッシュにアクセスできませんでした。権限とディスクの空き容量を確認してください。';
	@override String get downloadFailed => 'asc をダウンロードできませんでした。ネットワーク接続を確認して再試行してください。';
	@override String get checksumFailed => 'ダウンロードした asc の SHA-256 が一致しないため、インストールしませんでした。再試行してください。';
	@override String get permissionFailed => 'asc に実行権限を設定できなかったため、インストールしませんでした。キャッシュディレクトリの権限を確認してください。';
}

// Path: switchCommand.team
class _Translations$switchCommand$team$ja extends Translations$switchCommand$team$en {
	_Translations$switchCommand$team$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '現在のプロファイルで使用するチームを対話式で切り替えます。';
	@override String get noArguments => 'switch teamに位置引数は指定できません。';
	@override String get loginRequired => 'チームを切り替える前に、genuineci login（またはgenuineci login --local）を実行してください。';
	@override String authenticationFailed({required Object status}) => '認証に失敗しました（HTTP ${status}）。使用中のサーバーにgenuineci login（またはgenuineci login --local）で再度ログインしてください。';
	@override String requestFailed({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。';
	@override String get fetchFailed => 'チーム一覧を取得できませんでした。現在のプロファイルのサーバーURLとネットワーク接続を確認してください。';
	@override String get invalidResponse => 'サーバーから不正なチーム一覧が返されました。現在のプロファイルが対応するOpenCIサーバーを指しているか確認してください。';
	@override String get empty => '所属するチームがありません。ダッシュボードでチームを作成するか、チームに参加してください。';
	@override String get prompt => 'チームを選択';
	@override String get current => '現在のチーム';
	@override String get controls => '上下キー: 移動 / Enter: 選択 / Esc・Ctrl+C: キャンセル';
	@override String get cancelled => 'チームの切り替えをキャンセルしました。チームは保存していません。';
	@override String get nonInteractive => 'チーム切り替えにはANSI対応の対話可能な端末が必要です。入力のパイプや出力のリダイレクトを外してgenuineci switch teamを実行してください。';
	@override String get inputFailed => 'チームを選択できませんでした。対話可能な端末で再試行してください。';
	@override String success({required Object team}) => '${team}に切り替えました。';
	@override String alreadyCurrent({required Object team}) => '${team}は現在のチームです。';
	@override String get profileChanged => '選択中に現在のプロファイルまたは認証情報が変更されました。選択したチームは保存していません。genuineci switch teamを再実行してください。';
	@override String get saveFailed => '選択したチームを保存できませんでした。認証情報ファイル、権限、ディスクの空き容量を確認して再試行してください。';
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
	@override String get description => 'pubspec.yamlからopenci/generated/paths.g.dartだけを生成します。';
	@override String get projectRootNotFound => 'pubspec.yamlとopenciディレクトリのあるプロジェクトが見つかりません。ワークフローのあるプロジェクト内で実行してください。';
	@override String fileAccessFailed({required Object path}) => '${path}を読み書きできませんでした。ファイルの有無とアクセス権限を確認してください。';
	@override String saved({required Object path}) => 'ワークスペースのパスを生成しました: ${path}';
}

// Path: sync.secrets
class _Translations$sync$secrets$ja extends Translations$sync$secrets$en {
	_Translations$sync$secrets$ja._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get description => '現在のチームのシークレット名からopenci/generated/secrets.g.dartだけを生成します。';
	@override String get loginRequired => 'genuineci login（ローカルならgenuineci login --local）を実行してからシークレットを同期してください。';
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
			'cli.description' => 'GenuineCI - CI/CD およびシークレット管理コマンドラインツール',
			'cli.version' => ({required Object version}) => 'genuineci バージョン: ${version}',
			'cli.flags.version' => 'ツールのバージョンを表示します。',
			'cli.flags.verbose' => '詳細なログ出力を有効にします。',
			'cli.flags.checkUpdates' => '対話可能な端末で更新を確認し、インストールするか選択します。',
			'update.description' => 'GenuineCI CLIをpub.devの最新安定版に更新します。',
			'update.noArguments' => 'updateに位置引数は指定できません。',
			'update.available' => ({required Object current, required Object latest}) => 'アップデートがあります！ ${current} → ${latest}',
			'update.confirm' => '今すぐ更新しますか？',
			'update.updating' => ({required Object version}) => 'GenuineCI CLIを${version}に更新中...',
			'update.updated' => ({required Object version}) => 'GenuineCI CLIを${version}に更新しました。',
			'update.upToDate' => ({required Object version}) => 'GenuineCI CLI ${version}は最新です。',
			'update.checkFailed' => '更新を確認できませんでした。pub.devへの接続を確認して再実行してください。',
			'update.installFailed' => 'GenuineCI CLIを更新できませんでした。上記のDartの出力を確認して再実行してください。',
			'update.dartUnavailable' => 'Dartを起動できませんでした。Dart SDKがインストールされ、dartがPATHに含まれていることを確認してください。',
			'update.rerunCommand' => '更新したCLIを使うには、元のコマンドを再実行してください。',
			'login.description' => 'ローカルまたはリモートのOpenCIサーバーにログインします。',
			'login.flags.local' => 'Auth Emulator（127.0.0.1:9099）のユーザーのメールアドレスとパスワードでローカルAPI（http://localhost:8080）にログインします。',
			'login.flags.server' => 'リモートのOpenCIサーバーURL（HTTPS）。',
			'login.flags.teamId' => '複数チームに所属している場合に選択するチームID。',
			'login.flags.firebaseApiKey' => 'Firebase Web APIキー（独自のFirebaseプロジェクトを使う場合に指定）。',
			'login.loggingIn' => 'OpenCI にログイン中...',
			'login.savedSuccess' => ({required Object profile}) => 'プロファイル「${profile}」を保存し、有効にしました。',
			'login.noArguments' => 'loginに位置引数は指定できません。',
			'login.authenticationFailed' => 'ローカルサーバーの認証に失敗しました。genuineci dev start で起動したサーバーを確認してください。',
			'login.requestFailed' => ({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。',
			'login.localTeamRequired' => 'このユーザーはtest-teamを利用できません。チームが初期データとして作成され、このAuth Emulatorユーザーが所属していることを確認してください。',
			'login.invalidResponse' => 'サーバーから返されたチーム一覧が不正です。',
			'login.connectionFailed' => 'ローカルサーバーに接続できませんでした。genuineci dev start の起動状態を確認してください。',
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
			'status.description' => '現在のプロファイル、サーバー、チーム名とIDを表示します。',
			'status.noArguments' => 'statusに位置引数は指定できません。',
			'status.profile' => ({required Object value}) => 'プロファイル: ${value}',
			'status.server' => ({required Object value}) => 'サーバー: ${value}',
			'status.team' => ({required Object value}) => '選択中のチームID: ${value}',
			'status.notSet' => '未設定',
			'status.noActiveProfile' => 'プロファイルが未設定です。genuineci login（ローカルなら genuineci login --local）を実行してください。',
			'status.profileMissing' => ({required Object profile}) => '現在のプロファイル「${profile}」が見つかりません。genuineci login（ローカルなら genuineci login --local）を実行してください。',
			'status.invalidServer' => '不正なサーバーURL',
			'status.readFailed' => '保存済みのプロファイルを読み取れませんでした。認証情報ファイルの形式と権限を確認してください。',
			'status.profileChanged' => '確認中に現在のプロファイルまたは選択中のチームが変更されました。genuineci statusを再実行してください。',
			'status.loginRequired' => '現在のチームを確認するには、genuineci login（またはgenuineci login --local）を実行してください。',
			'status.noTeamSelected' => 'チームが選択されていません。genuineci switch teamでチームを選択してください。',
			'status.noTeams' => '所属するチームがありません。ダッシュボードでチームを作成するか、チームに参加してください。',
			'status.teamNotFound' => '選択中のチームは利用できなくなりました。genuineci switch teamで利用可能なチームを選択してください。',
			'status.requestFailed' => ({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。',
			'status.fetchFailed' => 'チーム一覧を取得できませんでした。現在のプロファイルのサーバーURLとネットワーク接続を確認してください。',
			'status.invalidResponse' => 'サーバーから不正なチーム一覧が返されました。現在のプロファイルが対応するOpenCIサーバーを指しているか確認してください。',
			'status.teamName' => ({required Object value}) => 'チーム名: ${value}',
			'list.description' => 'OpenCIのリソースを一覧表示します。',
			'list.teams.description' => '所属チームの名前とIDを一覧表示します。*は現在のチームです。',
			'list.teams.noArguments' => 'list teamsに位置引数は指定できません。',
			'list.teams.loginRequired' => 'genuineci login（ローカルならgenuineci login --local）を実行してからチームを一覧表示してください。',
			'list.teams.requestFailed' => ({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。',
			'list.teams.fetchFailed' => 'チーム一覧を取得できませんでした。現在のプロファイルのサーバーURLとネットワーク接続を確認してください。',
			'list.teams.invalidResponse' => 'サーバーから返されたチーム一覧が不正です。',
			'list.teams.empty' => '所属チームがありません。ダッシュボードでチームを作成するか参加してください。',
			'list.secrets.description' => '現在のチームのシークレット名を名前順に一覧表示します。',
			'list.secrets.noArguments' => 'list secretsに位置引数は指定できません。',
			'list.secrets.loginRequired' => 'genuineci login（ローカルならgenuineci login --local）を実行してからシークレットを一覧表示してください。',
			'list.secrets.requestFailed' => ({required Object status}) => 'シークレット名を取得できませんでした（HTTP ${status}）。',
			'list.secrets.fetchFailed' => 'シークレット名を取得できませんでした。サーバーの接続状態とレスポンスを確認してください。',
			'list.secrets.empty' => '現在のチームにはシークレットが登録されていません。',
			'register.description' => 'OpenCIにリソースを登録します。',
			'register.secret.description' => '現在のチームのシークレットを登録・更新します。名前と値を順に入力します。値は入力中は非表示で、Enterで確定すると******と表示します。',
			'register.secret.noArguments' => 'register secretに位置引数は指定できません。名前と値は対話入力で指定してください。',
			'register.secret.invalidName' => 'シークレット名には英数字とアンダースコアを使い、数字で始めないでください。',
			'register.secret.loginRequired' => 'genuineci login（ローカルならgenuineci login --local）を実行してからシークレットを登録してください。',
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
			'setup.description' => 'OpenCI の外部サービス連携をセットアップします。',
			'setup.ascKeys.description' => 'App Store Connect API キーを発行して OpenCI に保存します。',
			'setup.ascKeys.noArguments' => 'setup asc-keys は位置引数を受け付けません。',
			'setup.ascKeys.keyDirectoryHelp' => 'key.json と .p8 があるディレクトリから発行済みのキーを保存します。新しいキーは発行しません。',
			'setup.ascKeys.keyDirectoryRequired' => '--key-directory には空でないディレクトリのパスを指定してください。',
			'setup.ascKeys.saveDestination' => ({required Object server, required Object team, required Object name}) => 'OpenCI の保存先: ${server}\n  Team ID: ${team}\n  Secret: ${name}',
			'setup.ascKeys.secretWillReplace' => ({required Object name}) => '続行すると、既存の ${name} シークレットを置き換えます。',
			'setup.ascKeys.savePreflightFailed' => 'OpenCI チームのシークレットへのアクセスを確認できませんでした。キーを発行する前にサーバーと接続を確認してください。',
			'setup.ascKeys.saveProfileChanged' => 'セットアップ中に OpenCI のプロファイルまたは認証情報が変更されました。キーは保存していません。保存先のプロファイルとチームを確認して再試行してください。',
			'setup.ascKeys.savedKeyInvalid' => '有効な保存済みキーを読み取れませんでした。保存先の key.json と対応する .p8 ファイルを確認してください。',
			'setup.ascKeys.cacheFound' => ({required Object version, required Object path}) => 'asc ${version} 用のキャッシュファイルが見つかりました: ${path}',
			'setup.ascKeys.installing' => ({required Object version}) => 'Apple Silicon Mac 用の asc ${version} をダウンロードしてインストールしています...',
			'setup.ascKeys.installed' => ({required Object version, required Object path}) => 'asc ${version} をインストールしました: ${path}',
			'setup.ascKeys.versionVerified' => ({required Object version}) => 'asc ${version} の動作を確認しました。',
			'setup.ascKeys.appleIdPrompt' => 'Apple ID（メールアドレス）: ',
			'setup.ascKeys.appleIdReceived' => 'Apple ID を受け付けました。',
			'setup.ascKeys.appleIdRequired' => 'Apple ID が入力されなかったため、セットアップを中止しました。',
			'setup.ascKeys.terminalRequired' => 'Apple ID の入力には対話可能な端末が必要です。端末で genuineci setup asc-keys を実行してください。',
			'setup.ascKeys.appleIdInputFailed' => 'Apple ID を読み取れませんでした。対話可能な端末で再試行してください。',
			'setup.ascKeys.loginStartFailed' => 'asc のログイン処理を起動できませんでした。キャッシュ内の asc ファイルに実行権限があることを確認して再試行してください。',
			'setup.ascKeys.authenticationVerified' => 'Apple の認証状態を確認しました。',
			'setup.ascKeys.selectedProvider' => '選択中の App Store Connect Provider:',
			'setup.ascKeys.providerId' => ({required Object id}) => '  Provider ID: ${id}',
			'setup.ascKeys.publicProviderId' => ({required Object id}) => '  Public Provider ID: ${id}',
			'setup.ascKeys.providerUnavailable' => '選択中の App Store Connect Provider を取得できませんでした。',
			'setup.ascKeys.confirmKeyCreation' => 'この Provider の全アプリにアクセスできる APP_MANAGER 権限の GenuineCI キーを新規発行し、上記の OpenCI 保存先に保存しますか？ [y/N] ',
			'setup.ascKeys.confirmKeySave' => 'このキーを上記の OpenCI 保存先に保存しますか？ [y/N] ',
			'setup.ascKeys.keySaveCancelled' => 'キーの保存を中止しました。OpenCI のシークレットは変更していません。',
			'setup.ascKeys.keyCreationCancelled' => 'キーの発行を中止しました。新しいキーの発行はリクエストしていません。',
			'setup.ascKeys.keyConfirmationFailed' => '確認の入力を読み取れませんでした。対話可能な端末で genuineci setup asc-keys を実行してください。',
			'setup.ascKeys.keyDirectoryFailed' => 'キーの保存先を準備できませんでした。権限とディスクの空き容量を確認してください。新しいキーの発行はリクエストしていません。',
			'setup.ascKeys.keyOutputDirectory' => ({required Object path}) => 'キーの保存先: ${path}',
			'setup.ascKeys.keyCreated' => 'APP_MANAGER 権限の GenuineCI API キーを発行しました。',
			'setup.ascKeys.keyId' => ({required Object id}) => '  Key ID: ${id}',
			'setup.ascKeys.issuerId' => ({required Object id}) => '  Issuer ID: ${id}',
			'setup.ascKeys.privateKeySaved' => ({required Object path}) => '  秘密鍵: ${path}',
			'setup.ascKeys.setupComplete' => 'App Store Connect API キーのセットアップが完了しました。OpenCI に保存し、ローカルの鍵ファイルも保持しています。',
			'setup.ascKeys.retrySave' => ({required Object command}) => 'ローカルの鍵ファイルは保持しています。新しいキーを発行せずに保存を再試行できます:\n  ${command}',
			'setup.ascKeys.keyCreationStartFailed' => 'asc のキー発行処理を起動できませんでした。新しいキーの発行はリクエストしていません。',
			'setup.ascKeys.keyCreationFailed' => 'asc の API キー発行処理が正常に完了しませんでした。',
			'setup.ascKeys.keyCreationInvalid' => 'キーの発行結果または保存された秘密鍵を確認できませんでした。',
			'setup.ascKeys.keyStorageFailed' => 'API キーのファイルを保存または読み取りできませんでした。',
			'setup.ascKeys.keyRecovery' => ({required Object path}) => 'キーがすでに発行されている可能性があります。再実行する前に App Store Connect を確認してください。ダウンロード済みのファイルは次の場所に残しています: ${path}',
			'setup.ascKeys.notAuthenticated' => 'Apple の認証を確認できませんでした。genuineci setup asc-keys を再実行してログインしてください。',
			'setup.ascKeys.authStatusFailed' => 'asc で Apple の認証状態を確認できませんでした。セットアップを再試行してください。',
			'setup.ascKeys.authStatusTimedOut' => 'Apple の認証状態の確認がタイムアウトしました。セットアップを再試行してください。',
			'setup.ascKeys.authStatusInvalid' => 'asc の認証状態の応答が想定と異なります。セットアップを再試行してください。',
			'setup.ascKeys.cachedChecksumFailed' => 'キャッシュ内の asc ファイルの SHA-256 が期待値と一致しなかったため、実行しませんでした。キャッシュファイルを削除して再試行してください。',
			'setup.ascKeys.executionFailed' => 'asc version を正常に実行できませんでした。キャッシュ内の asc ファイルに実行権限があることを確認して再試行してください。',
			'setup.ascKeys.versionTimedOut' => 'asc version がタイムアウトしました。再試行してください。',
			'setup.ascKeys.versionMismatch' => ({required Object version}) => 'asc version の出力が必要なバージョン（${version}）と一致しませんでした。キャッシュファイルを削除して再試行してください。',
			'setup.ascKeys.unsupportedPlatform' => 'setup asc-keys は現在 Apple Silicon Mac（macOS arm64）のみに対応しています。',
			'setup.ascKeys.cacheFailed' => 'asc のキャッシュにアクセスできませんでした。権限とディスクの空き容量を確認してください。',
			'setup.ascKeys.downloadFailed' => 'asc をダウンロードできませんでした。ネットワーク接続を確認して再試行してください。',
			'setup.ascKeys.checksumFailed' => 'ダウンロードした asc の SHA-256 が一致しないため、インストールしませんでした。再試行してください。',
			'setup.ascKeys.permissionFailed' => 'asc に実行権限を設定できなかったため、インストールしませんでした。キャッシュディレクトリの権限を確認してください。',
			'switchCommand.description' => 'OpenCIで使用するチームを切り替えます。',
			'switchCommand.team.description' => '現在のプロファイルで使用するチームを対話式で切り替えます。',
			'switchCommand.team.noArguments' => 'switch teamに位置引数は指定できません。',
			'switchCommand.team.loginRequired' => 'チームを切り替える前に、genuineci login（またはgenuineci login --local）を実行してください。',
			'switchCommand.team.authenticationFailed' => ({required Object status}) => '認証に失敗しました（HTTP ${status}）。使用中のサーバーにgenuineci login（またはgenuineci login --local）で再度ログインしてください。',
			'switchCommand.team.requestFailed' => ({required Object status}) => 'チーム一覧を取得できませんでした（HTTP ${status}）。',
			'switchCommand.team.fetchFailed' => 'チーム一覧を取得できませんでした。現在のプロファイルのサーバーURLとネットワーク接続を確認してください。',
			'switchCommand.team.invalidResponse' => 'サーバーから不正なチーム一覧が返されました。現在のプロファイルが対応するOpenCIサーバーを指しているか確認してください。',
			'switchCommand.team.empty' => '所属するチームがありません。ダッシュボードでチームを作成するか、チームに参加してください。',
			'switchCommand.team.prompt' => 'チームを選択',
			'switchCommand.team.current' => '現在のチーム',
			'switchCommand.team.controls' => '上下キー: 移動 / Enter: 選択 / Esc・Ctrl+C: キャンセル',
			'switchCommand.team.cancelled' => 'チームの切り替えをキャンセルしました。チームは保存していません。',
			'switchCommand.team.nonInteractive' => 'チーム切り替えにはANSI対応の対話可能な端末が必要です。入力のパイプや出力のリダイレクトを外してgenuineci switch teamを実行してください。',
			'switchCommand.team.inputFailed' => 'チームを選択できませんでした。対話可能な端末で再試行してください。',
			'switchCommand.team.success' => ({required Object team}) => '${team}に切り替えました。',
			'switchCommand.team.alreadyCurrent' => ({required Object team}) => '${team}は現在のチームです。',
			'switchCommand.team.profileChanged' => '選択中に現在のプロファイルまたは認証情報が変更されました。選択したチームは保存していません。genuineci switch teamを再実行してください。',
			'switchCommand.team.saveFailed' => '選択したチームを保存できませんでした。認証情報ファイル、権限、ディスクの空き容量を確認して再試行してください。',
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
			'sync.description' => 'シークレット定義とワークスペースパスをopenci/generatedに生成します。',
			'sync.paths.description' => 'pubspec.yamlからopenci/generated/paths.g.dartだけを生成します。',
			'sync.paths.projectRootNotFound' => 'pubspec.yamlとopenciディレクトリのあるプロジェクトが見つかりません。ワークフローのあるプロジェクト内で実行してください。',
			'sync.paths.fileAccessFailed' => ({required Object path}) => '${path}を読み書きできませんでした。ファイルの有無とアクセス権限を確認してください。',
			'sync.paths.saved' => ({required Object path}) => 'ワークスペースのパスを生成しました: ${path}',
			'sync.secrets.description' => '現在のチームのシークレット名からopenci/generated/secrets.g.dartだけを生成します。',
			'sync.secrets.loginRequired' => 'genuineci login（ローカルならgenuineci login --local）を実行してからシークレットを同期してください。',
			'sync.secrets.workflowDirectoryNotFound' => 'openciディレクトリが見つかりません。ワークフローのあるプロジェクト内で実行してください。',
			'sync.secrets.requestFailed' => ({required Object status}) => 'シークレット名を取得できませんでした（HTTP ${status}）。',
			'sync.secrets.fetchFailed' => 'シークレット名を取得できませんでした。サーバーの接続状態とレスポンスを確認してください。',
			'sync.secrets.saveFailed' => 'secrets.g.dartを保存できませんでした。保存先とファイルの権限を確認してください。',
			'sync.secrets.saved' => ({required Object path}) => 'シークレット定義を生成しました: ${path}',
			'sync.noArguments' => 'syncに位置引数は指定できません。生成対象を選ぶには--secretsまたは--pathsを指定してください。',
			'common.error' => ({required Object error}) => 'エラー: ${error}',
			_ => null,
		};
	}
}
