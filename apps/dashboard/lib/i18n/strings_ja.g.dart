///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsJa extends Translations
    with BaseTranslations<AppLocale, Translations> {
  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  TranslationsJa({
    Map<String, Node>? overrides,
    PluralResolver? cardinalResolver,
    PluralResolver? ordinalResolver,
    TranslationMetadata<AppLocale, Translations>? meta,
  }) : assert(
         overrides == null,
         'Set "translation_overrides: true" in order to enable this feature.',
       ),
       $meta =
           meta ??
           TranslationMetadata(
             locale: AppLocale.ja,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ),
       super(
         cardinalResolver: cardinalResolver,
         ordinalResolver: ordinalResolver,
       ) {
    super.$meta.setFlatMapFunction(
      $meta.getTranslation,
    ); // copy base translations to super.$meta
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <ja>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  @override
  dynamic operator [](String key) =>
      $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

  late final TranslationsJa _root = this; // ignore: unused_field

  @override
  TranslationsJa $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => TranslationsJa(meta: meta ?? this.$meta);

  // Translations
  @override
  late final _Translations$common$ja common = _Translations$common$ja._(_root);
  @override
  late final _Translations$auth$ja auth = _Translations$auth$ja._(_root);
  @override
  late final _Translations$secrets$ja secrets = _Translations$secrets$ja._(
    _root,
  );
  @override
  late final _Translations$settings$ja settings = _Translations$settings$ja._(
    _root,
  );
  @override
  late final _Translations$team$ja team = _Translations$team$ja._(_root);
  @override
  late final _Translations$subscription$ja subscription =
      _Translations$subscription$ja._(_root);
  @override
  late final _Translations$logs$ja logs = _Translations$logs$ja._(_root);
  @override
  late final _Translations$billing$ja billing = _Translations$billing$ja._(
    _root,
  );
  @override
  late final _Translations$language$ja language = _Translations$language$ja._(
    _root,
  );
  @override
  late final _Translations$connection$ja connection =
      _Translations$connection$ja._(_root);
  @override
  late final _Translations$config$ja config = _Translations$config$ja._(_root);
}

// Path: common
class _Translations$common$ja extends Translations$common$en {
  _Translations$common$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get save => '保存';
  @override
  String get cancel => 'キャンセル';
  @override
  String get delete => '削除';
  @override
  String get close => '閉じる';
  @override
  String error({required Object error}) => 'エラー: ${error}';
  @override
  String get invite => '招待';
  @override
  String get retry => '再試行';
  @override
  String get loading => '読み込み中...';
  @override
  String get errorOccurred => 'エラーが発生しました';
  @override
  String get reload => '再読み込み';
  @override
  String get networkFailed => '接続できませんでした。ネットワークを確認して、もう一度お試しください。';
  @override
  String get operationFailed => '操作を完了できませんでした。もう一度お試しください。';
}

// Path: auth
class _Translations$auth$ja extends Translations$auth$en {
  _Translations$auth$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get signInSubtitle => 'アカウントにサインイン';
  @override
  String get email => 'メールアドレス';
  @override
  String get password => 'パスワード';
  @override
  String get login => 'ログイン';
  @override
  String get createAccount => 'アカウント作成';
  @override
  String get useYourFirebase => '自分のFirebaseを使用';
  @override
  String get agreePrefix => '利用規約に同意する ';
  @override
  String get termsOfService => '利用規約';
  @override
  String get enterEmail => 'メールアドレスを入力してください';
  @override
  String get enterPassword => 'パスワードを入力してください';
  @override
  late final _Translations$auth$firebaseForm$ja firebaseForm =
      _Translations$auth$firebaseForm$ja._(_root);
  @override
  String get stateError => '認証状態を確認できませんでした。';
  @override
  String get signOutAndRetry => 'ログアウトして再ログイン';
  @override
  String get binaryPlistUnsupported =>
      'バイナリ形式の plist はサポートしていません。XML形式に変換した GoogleService-Info.plist を選択してください。';
  @override
  String get unsupportedConfigFile =>
      '未対応のファイル形式です。JSON (google-services.json) または plist (GoogleService-Info.plist) を選択してください。';
  @override
  String configFileReadFailed({required Object error}) =>
      'ファイルの読み込みに失敗しました: ${error}';
  @override
  String get invalidCredentials => 'メールアドレスまたはパスワードを確認してください。';
  @override
  String get emailInUse => 'このメールアドレスはすでに登録されています。ログインしてください。';
  @override
  String get weakPassword => 'より強固なパスワードを入力してください。';
  @override
  String get accountDisabled => 'このアカウントは無効になっています。';
  @override
  String get operationFailed => '認証を完了できませんでした。もう一度お試しください。';
  @override
  String get advancedOptions => '詳細設定';
}

// Path: secrets
class _Translations$secrets$ja extends Translations$secrets$en {
  _Translations$secrets$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get noSecrets => 'シークレットが見つかりません';
  @override
  String get addSecret => 'シークレット追加';
  @override
  String get editSecret => 'シークレット編集';
  @override
  String get secretName => 'シークレット名';
  @override
  String get secretValue => 'シークレット値';
  @override
  String get newSecretValue => '新しいシークレット値（空欄で現在の値を維持）';
  @override
  String get enterSecretName => 'シークレット名を入力してください';
  @override
  String get enterSecretValue => 'シークレット値を入力してください';
  @override
  String get adding => 'シークレットを追加中...';
  @override
  String get addedSuccess => 'シークレットが追加されました';
  @override
  String get updatedSuccess => 'シークレットが更新されました';
  @override
  String get inputModeText => 'テキスト';
  @override
  String get inputModeFile => 'ファイル';
  @override
  String get uploadFile => 'ファイルをアップロード';
  @override
  String get orUploadFile => 'クリックしてファイルを選択';
  @override
  String get enterValueOrUpload => '値を入力するかファイルをアップロードしてください';
  @override
  String get lastUpdated => '最終更新';
  @override
  String get viewSecretValue => '値を表示';
  @override
  String get secretValueTitle => 'シークレット値';
  @override
  String get secretValueLoading => 'シークレット値を読み込み中';
  @override
  String get copySecretValue => '値をコピー';
  @override
  String get copiedSecretValue => 'シークレット値をコピーしました';
  @override
  String get title => 'シークレット';
  @override
  String get loading => 'シークレットを読み込み中';
  @override
  String get fileLoaded => 'ファイル読み込み済み';
  @override
  String get keepCurrentValue => '値を空欄にすると現在のシークレットを維持します';
  @override
  String get codeSigningTitle => 'iOSコード署名';
  @override
  String get certificateExplanation => 'iOSビルド用の証明書秘密鍵を生成します。自動コード署名に必要です。';
  @override
  String get certificateGenerated => '証明書秘密鍵を生成しました';
  @override
  String get generateCertificate => '証明書秘密鍵を生成';
  @override
  String get signInRequired => 'シークレットを管理するにはログインしてください。';
  @override
  String get contextChanged => 'アカウントまたはチームが変わりました。もう一度お試しください。';
  @override
  String get invalidInput => 'シークレットの名前と値を確認してください。';
  @override
  String get notFound => 'シークレットが見つかりません。再読み込みしてください。';
  @override
  String get deleteConfirm => 'このシークレットを削除しますか？';
  @override
  String get deletedSuccess => 'シークレットを削除しました';
}

// Path: settings
class _Translations$settings$ja extends Translations$settings$en {
  _Translations$settings$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '設定';
  @override
  String get preferences => '環境設定';
  @override
  String get emailVerification => 'メールアドレスの確認';
  @override
  String get emailVerified => '確認済み';
  @override
  String get emailVerificationRequired =>
      '他のチームに参加するにはメールアドレスの確認が必要です。確認メール内のリンクを開いてください。';
  @override
  String get sendVerificationEmail => '確認メールを送信';
  @override
  String get refreshEmailVerification => '確認状態を更新';
  @override
  String get verificationEmailSent => '確認メールを送信しました。受信トレイを確認してください。';
  @override
  String get emailStillUnverified => 'まだ確認できていません。確認メール内のリンクを開いてください。';
  @override
  String get emailVerificationFailed => 'メール確認の操作に失敗しました。もう一度お試しください。';
  @override
  String get emailVerificationRateLimited => '操作が多すぎます。しばらく待ってからお試しください。';
  @override
  String get checkForUpdates => 'アップデートを確認';
  @override
  String get checkForUpdatesDescription => 'macOSアプリの新しいバージョンを手動で確認';
  @override
  String checkForUpdatesFailed({required Object error}) =>
      'アップデート確認に失敗しました: ${error}';
  @override
  String get subscription => 'サブスクリプション';
  @override
  String get manageSubscription => 'サブスクリプションプランを管理';
  @override
  String get returnToCloud => 'OpenCI Cloudに戻す';
  @override
  String get appVersion => 'アプリバージョン';
  @override
  String get logout => 'ログアウト';
  @override
  String get logoutSuccess => 'ログアウトしました';
  @override
  String logoutFailed({required Object error}) => 'ログアウトに失敗: ${error}';
  @override
  String get deleteAccount => 'アカウント削除';
  @override
  String get deleteConfirmTitle => 'アカウント削除';
  @override
  String get deleteConfirmMessage =>
      '本当にアカウントを削除しますか？この操作は元に戻せません。すべてのデータが完全に削除されます。';
  @override
  String get deleteSuccess => 'アカウントが削除されました';
  @override
  String get noUserSignedIn => '現在サインインしているユーザーがいません';
  @override
  String get requiresRecentLogin => 'アカウンを削除する前に、一度ログアウトしてから再度ログインしてください';
  @override
  String deleteFailed({required Object error}) => 'アカウントの削除に失敗: ${error}';
  @override
  String get manageBilling => '課金を管理';
  @override
  String get billingDescription => 'チームのプラン・請求・支払い方法';
  @override
  String get checkingUpdates => 'アップデートを確認しています...';
  @override
  String get teamSection => 'カンバン';
  @override
  String get account => 'アカウント';
  @override
  String get logoutDescription => '現在のアカウントからサインアウト';
  @override
  String get updateAvailable => '新しいアップデートがあります';
  @override
  String updateVersionAvailable({required Object version}) =>
      '新しいアップデートがあります: v${version}';
  @override
  String get noUpdate => '利用可能なアップデートはありません';
  @override
  String get updateCheckFailed => 'アップデート確認に失敗しました';
  @override
  String get teamLoadFailed => 'チーム情報を読み込めませんでした';
}

// Path: team
class _Translations$team$ja extends Translations$team$en {
  _Translations$team$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get editTeam => 'チーム編集';
  @override
  String get createTeam => 'チーム作成';
  @override
  String get teamName => 'チーム名';
  @override
  String get newTeamName => '新しいチーム名';
  @override
  String get selectTeam => 'チームを選択';
  @override
  String get selectTeamLabel => 'チーム';
  @override
  String get connectGitHub => 'GitHubと連携';
  @override
  String get gitHubConnectionFailed => 'GitHub連携を開始できませんでした。もう一度お試しください。';
  @override
  String get gitHubConnectionVerified => 'GitHub認証を確認しました。チームへの連携はまだ確定していません。';
  @override
  String get gitHubConnectionCandidates => '連携できるGitHubアカウント';
  @override
  String get gitHubConnectionNoCandidates =>
      '連携できるGitHubアカウントが見つかりませんでした。GitHub Appのインストールと権限を確認した後、もう一度連携してください。';
  @override
  String get gitHubAppInstallation => 'GitHub Appのインストール・設定を開く';
  @override
  String get gitHubAppInstallationUrlUnavailable =>
      'GitHub Appの案内リンクを利用できません。OpenCIサーバーの管理者に設定を確認してください。';
  @override
  String get gitHubAppInstallationOpenFailed =>
      'GitHub Appのページを開けませんでした。もう一度お試しください。';
  @override
  String gitHubConnectionTeam({required Object name}) => '連携するチーム: ${name}';
  @override
  String get gitHubConnectionConfirm => '連携を確定';
  @override
  String get gitHubConnectionConfirming => '連携中…';
  @override
  String get gitHubConnectionCompleted => 'GitHubとの連携が完了しました';
  @override
  String get gitHubConnectionConfirmFailed =>
      'GitHub連携の完了を確認できませんでした。もう一度お試しください。';
  @override
  String get gitHubConnectionCancelled => 'GitHubの認可がキャンセルされました。';
  @override
  String get gitHubConnectionRestartRequired =>
      '連携を再開できませんでした。この画面を閉じて、チーム画面からもう一度お試しください。';
  @override
  String get gitHubConnectionCheckFailed =>
      'GitHub連携の確認に失敗しました。この画面を閉じて、もう一度お試しください。';
  @override
  String get enterTeamName => 'チーム名を入力してください';
  @override
  String get createdSuccess => 'チームが作成されました';
  @override
  String get updatedSuccess => 'チーム名が更新されました';
  @override
  String get selectedSuccess => 'チームが選択されました';
  @override
  String get inviteTitle => 'チームメンバーを招待';
  @override
  String get inviteEmail => 'メールアドレス';
  @override
  String get enterEmail => 'メールアドレスを入力してください';
  @override
  String get addedSuccess => 'メンバーをチームに追加しました';
  @override
  String get removeMember => 'メンバーを削除';
  @override
  String removeMemberConfirm({
    required Object name,
    required Object teamName,
  }) => '「${name}」を「${teamName}」から削除しますか？';
  @override
  String get removedSuccess => 'メンバーをチームから削除しました';
  @override
  String get accessDenied => 'チームにアクセスできません。ログインと接続先を確認してください。';
  @override
  String get memberAlreadyAdded => 'このユーザーはすでにチームのメンバーです。';
  @override
  String get memberNotRegistered => '追加するユーザーは先にDashboardへ登録してください。';
  @override
  String get memberEmailNotVerified =>
      '追加するユーザーのメールアドレスが未確認です。本人にDashboardの「設定」→「アカウント」でメール確認を済ませてもらい、もう一度追加してください。';
  @override
  String get memberUnavailable => 'このアカウントは利用できません。';
  @override
  String get enterValidEmail => '有効なメールアドレスを入力してください。';
  @override
  String get operationFailed => 'チームの操作に失敗しました。もう一度お試しください。';
  @override
  String get members => 'メンバー';
  @override
  String membersCount({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(
        count,
        other: '${count}人のメンバー',
      );
  @override
  String get you => 'あなた';
  @override
  String get noEmail => 'メールなし';
  @override
  String get deleteTeam => 'チーム削除';
  @override
  String deleteTeamConfirm({required Object teamName}) =>
      '本当に「${teamName}」を削除しますか？この操作は元に戻せません。このチームに関連するすべてのワークフロー、シークレット、環境変数が完全に削除されます。';
  @override
  String get deletedSuccess => 'チームが削除されました';
  @override
  String get cannotDeleteLastTeam => '最後のチームは削除できません。先に別のチームを作成してください。';
}

// Path: subscription
class _Translations$subscription$ja extends Translations$subscription$en {
  _Translations$subscription$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'サブスクリプション';
  @override
  String get noOfferings => '利用可能なプランがありません';
  @override
  String get noPackages => '利用可能なパッケージがありません';
  @override
  String get plans => 'プラン';
  @override
  String get restorePurchases => '購入を復元';
  @override
  String get purchaseSuccess => '購入が完了しました！';
  @override
  String purchaseFailed({required Object error}) => '購入に失敗: ${error}';
  @override
  String get restoreSuccess => '購入が正常に復元されました';
  @override
  String restoreFailed({required Object error}) => '復元に失敗: ${error}';
  @override
  String get activeSubscription => 'アクティブなサブスクリプション';
  @override
  String get active => '有効';
  @override
  String get termsOfUse => '利用規約';
  @override
  String get privacyPolicy => 'プライバシーポリシー';
  @override
  String get subscriptionTerms =>
      'サブスクリプションは、現在の期間の終了の少なくとも24時間前までにキャンセルしない限り、自動的に更新されます。Apple IDアカウントには、現在の期間の終了前24時間以内に更新料金が請求されます。購入後は、App Storeのアカウント設定からサブスクリプションの管理・キャンセルが可能です。';
  @override
  String get subscriptionTermsWeb =>
      'サブスクリプションは、現在の請求期間の終了前にキャンセルしない限り、自動的に更新されます。アカウント設定からサブスクリプションの管理・キャンセルが可能です。お支払いはStripeにより安全に処理されます。';
  @override
  String get perWeek => '週額';
  @override
  String get perMonth => '月額';
  @override
  String get per3Months => '3ヶ月ごと';
  @override
  String get per6Months => '6ヶ月ごと';
  @override
  String get perYear => '年額';
}

// Path: logs
class _Translations$logs$ja extends Translations$logs$en {
  _Translations$logs$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => 'CI/CDログ';
  @override
  String get empty => 'アクティブなCI/CDログはありません';
  @override
  String loadFailed({required Object error}) => 'ログの取得中にエラーが発生しました: ${error}';
  @override
  String get jobNotFound => 'ビルドジョブが見つかりません';
  @override
  String get detailTitle => 'CI/CD詳細ログ';
  @override
  String get copyAll => '全体のログをコピー';
  @override
  String get nothingToCopy => 'コピーするログがありません';
  @override
  String get copiedAll => '全体のログをクリップボードにコピーしました';
  @override
  String copyFailed({required Object error}) => 'ログのコピーに失敗しました: ${error}';
  @override
  String get noSteps => 'ログステップがありません';
  @override
  String get failureReason => 'ビルドの失敗理由';
  @override
  String get unavailable => 'ログがありません。保存期間を過ぎたログと移行前のログは表示されません。';
  @override
  String get copy => 'ログをコピー';
  @override
  String get copied => 'ログをクリップボードにコピーしました';
  @override
  String durationMinutesSeconds({
    required Object minutes,
    required Object seconds,
  }) => '${minutes}分${seconds}秒';
  @override
  String durationSeconds({required Object seconds}) => '${seconds}秒';
}

// Path: billing
class _Translations$billing$ja extends Translations$billing$en {
  _Translations$billing$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '課金';
  @override
  String get signInRequired => 'Cloudにサインインすると、このページを利用できます。';
  @override
  String get teamLoadFailed => 'チームを読み込めませんでした。';
  @override
  String get teamAccessDenied => 'このチームにアクセスできません。ダッシュボードでチームを確認してください。';
  @override
  String get disabled => '現在、この接続先では課金機能を利用できません。';
  @override
  String get returnedFromStripe =>
      'Stripeから戻りました。変更の反映には時間がかかることがあります。反映されない場合は「再読み込み」を押してください。';
  @override
  String get ciAvailable => 'CIを利用できます';
  @override
  String get monthlyPostpaid => 'CIの月次後払い';
  @override
  String get monthlyExplanation =>
      'CI実行1分につき税込1円。利用料は月ごとに集計し、翌月に登録カードで自動決済します。';
  @override
  String get continueCardSetup => 'カード登録を続ける';
  @override
  String get setupCard => '支払い方法を登録';
  @override
  String get cardRegistered => '後払い用のカードは登録済みです。';
  @override
  String get setCardInPortal => '「支払い方法・請求履歴を開く」から請求用のカードを設定してください。';
  @override
  String get openPortal => '支払い方法・請求履歴を開く';
  @override
  String monthlyUsage({required Object month}) => '今月の利用状況（${month}）';
  @override
  String minutes({required Object minutes}) => '利用時間 ${minutes}分';
  @override
  String estimatedAmount({required Object amount}) => '税込見込額 ${amount}円';
  @override
  String nextInvoiceDate({required Object date}) => '次回請求予定日 ${date}（日本時間）';
  @override
  String get usdExplanation => 'USDでの請求額は、月締め時に円建ての利用料を換算して確定します。';
  @override
  String get usageUnavailable => '今月の利用額を取得できませんでした。「再読み込み」で再度確認できます。';
  @override
  String get openingStripe => 'Stripeを開く準備をしています…';
  @override
  String get consentTitle => '月次後払いに同意しますか？';
  @override
  String consentMessage({required Object teamName}) =>
      'チーム「${teamName}」のCI利用料は1分1円（税込）です。月の利用時間を合計し、翌月に登録カードから自動決済します。カード登録時の利用料は0円です。';
  @override
  String get agreeAndContinue => '同意してStripeへ';
  @override
  String get paymentRequired => 'CIを開始するには、このチームの請求用カードを登録してください。';
  @override
  String get allowanceExhausted => '新しいCIを開始できる利用枠がありません。';
  @override
  String get subscriptionEnded => '契約が終了しています。';
  @override
  String get paymentPending => 'カード登録の完了を待っています。';
  @override
  String get ciUnavailable => '現在、CIを開始できません。時間をおいて再読み込みしてください。';
  @override
  String get authenticationRequired => 'もう一度サインインしてください。';
  @override
  String get forbidden => 'このチームの課金情報にアクセスできません。';
  @override
  String get cardConsentRequired => '最新の料金条件を読み込み直して、もう一度同意してください。';
  @override
  String get contextChanged => '接続先またはアカウントが変わりました。画面を開き直してください。';
  @override
  String get subscriptionExists => '契約がすでにあります。再読み込みして契約を確認してください。';
  @override
  String get checkoutPending => '決済を確認しています。時間をおいて再読み込みしてください。';
  @override
  String get customerMissing => '管理できる契約がありません。再読み込みしてください。';
  @override
  String get launchFailed => 'Stripeを開けませんでした。もう一度お試しください。';
  @override
  String get operationFailed => '課金処理を完了できませんでした。時間をおいてもう一度お試しください。';
}

// Path: language
class _Translations$language$ja extends Translations$language$en {
  _Translations$language$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get label => '言語 / Language';
  @override
  String get system => '端末の設定に合わせる';
  @override
  String get saveFailed => '言語設定を保存できませんでした。もう一度お試しください。';
}

// Path: connection
class _Translations$connection$ja extends Translations$connection$en {
  _Translations$connection$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get saveFailed => '接続設定を保存できませんでした。';
  @override
  String get configMismatch =>
      '同じ接続先IDで異なるFirebase設定は使用できません。新しい接続先として登録してください。';
  @override
  String platformConfigMissing({
    required Object name,
    required Object platform,
  }) => '${name} の ${platform} 用Firebase設定がありません。';
}

// Path: config
class _Translations$config$ja extends Translations$config$en {
  _Translations$config$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String jsonParseFailed({required Object error}) =>
      'JSONのパースに失敗しました: ${error}';
  @override
  String xmlParseFailed({required Object error}) => 'XMLのパースに失敗しました: ${error}';
  @override
  String missingKeys({required Object file, required Object keys}) =>
      '${file}の必須キーが不足しています: ${keys}';
  @override
  String get unsupportedFormat =>
      '未対応の形式です。Web用のFirebase設定(JSON)、Android用のgoogle-services.json、あるいはiOS用のGoogleService-Info.plistを選択してください。';
  @override
  String get plistDictMissing => 'plist内に <dict> 要素が見つかりません。';
}

// Path: auth.firebaseForm
class _Translations$auth$firebaseForm$ja
    extends Translations$auth$firebaseForm$en {
  _Translations$auth$firebaseForm$ja._(TranslationsJa root)
    : this._root = root,
      super.internal(root);

  final TranslationsJa _root; // ignore: unused_field

  // Translations
  @override
  String get title => '自分のFirebaseを使用';
  @override
  String get profileName => '接続先名';
  @override
  String get profileNameHint => '例：会社用、開発環境、本番環境';
  @override
  String get apiKey => 'APIキー';
  @override
  String get appId => 'アプリID';
  @override
  String get projectId => 'プロジェクトID';
  @override
  String get pickConfig => '設定を保存';
  @override
  String get profileSaved => '接続設定を保存しました。';
  @override
  String get requiredProfileFields =>
      '接続先名、APIサーバーURL、APIキー、アプリID、プロジェクトIDを入力してください。';
  @override
  String get invalidAppId => 'このプラットフォーム用の有効なFirebaseアプリIDを入力してください。';
  @override
  String get importFile => 'ファイルから読み込み';
  @override
  String get importFileHint =>
      'JSON (google-services.json) または plist (GoogleService-Info.plist)';
  @override
  String get invalidFile => '選択されたファイルを解析できませんでした。形式を確認してください。';
  @override
  String get fileLoaded => 'ファイルから設定を読み込みました。内容を確認して保存してください。';
  @override
  String get savedProjects => '保存済み接続先';
  @override
  String get active => '有効';
  @override
  String get useProject => 'この接続先を使用';
  @override
  String get setupSubtitle => 'APIサーバーとFirebaseプロジェクトを接続します。';
  @override
  String get setupPreview => '入力内容のプレビューです。まだ接続・登録・保存は行いません。';
  @override
  String get apiUrl => 'APIサーバーURL';
  @override
  String get apiUrlHint => '稼働中のセルフホストAPIサーバーのURL';
  @override
  String get invalidApiUrl => '有効なHTTPまたはHTTPSのURLを入力してください。';
  @override
  String get serviceAccount => 'サービスアカウントJSON';
  @override
  String get selectServiceAccount => 'JSONファイルを選択';
  @override
  String get replaceServiceAccount => '別のJSONファイルを選択';
  @override
  String get serviceAccountHint => 'Firebaseの「プロジェクトの設定 → サービスアカウント」から取得できます。';
  @override
  String get serviceAccountRequired => 'サービスアカウントJSONを選択してください。';
  @override
  String get invalidServiceAccount =>
      'サービスアカウントJSONを読み込めませんでした。google-services.jsonではなく、秘密鍵を含むサービスアカウントのファイルを選択してください。';
  @override
  String get removeServiceAccount => '選択したファイルを解除';
  @override
  String get credentialsNotSaved => 'サービスアカウントの秘密鍵は接続先に保存しません。';
  @override
  String get optionalProfileName => '接続先名（任意）';
  @override
  String get automaticProfileName => '未入力の場合はプロジェクトIDを使用します。';
  @override
  String get reviewSetup => '入力内容を確認';
  @override
  String get reviewTitle => '接続内容の確認';
  @override
  String get editSetup => '入力内容を編集';
  @override
  String get setupPlatforms => 'まとめて設定するプラットフォーム';
  @override
  String get setupExplanation =>
      '登録済みのアプリを再利用し、不足するアプリを登録して、各プラットフォームの設定を取得します。';
  @override
  String get startSetup => 'Firebase設定を取得して保存';
  @override
  String get manualSetup => '設定ファイルから手動で追加';
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
      'common.close' => '閉じる',
      'common.error' => ({required Object error}) => 'エラー: ${error}',
      'common.invite' => '招待',
      'common.retry' => '再試行',
      'common.loading' => '読み込み中...',
      'common.errorOccurred' => 'エラーが発生しました',
      'common.reload' => '再読み込み',
      'common.networkFailed' => '接続できませんでした。ネットワークを確認して、もう一度お試しください。',
      'common.operationFailed' => '操作を完了できませんでした。もう一度お試しください。',
      'auth.signInSubtitle' => 'アカウントにサインイン',
      'auth.email' => 'メールアドレス',
      'auth.password' => 'パスワード',
      'auth.login' => 'ログイン',
      'auth.createAccount' => 'アカウント作成',
      'auth.useYourFirebase' => '自分のFirebaseを使用',
      'auth.agreePrefix' => '利用規約に同意する ',
      'auth.termsOfService' => '利用規約',
      'auth.enterEmail' => 'メールアドレスを入力してください',
      'auth.enterPassword' => 'パスワードを入力してください',
      'auth.firebaseForm.title' => '自分のFirebaseを使用',
      'auth.firebaseForm.profileName' => '接続先名',
      'auth.firebaseForm.profileNameHint' => '例：会社用、開発環境、本番環境',
      'auth.firebaseForm.apiKey' => 'APIキー',
      'auth.firebaseForm.appId' => 'アプリID',
      'auth.firebaseForm.projectId' => 'プロジェクトID',
      'auth.firebaseForm.pickConfig' => '設定を保存',
      'auth.firebaseForm.profileSaved' => '接続設定を保存しました。',
      'auth.firebaseForm.requiredProfileFields' =>
        '接続先名、APIサーバーURL、APIキー、アプリID、プロジェクトIDを入力してください。',
      'auth.firebaseForm.invalidAppId' =>
        'このプラットフォーム用の有効なFirebaseアプリIDを入力してください。',
      'auth.firebaseForm.importFile' => 'ファイルから読み込み',
      'auth.firebaseForm.importFileHint' =>
        'JSON (google-services.json) または plist (GoogleService-Info.plist)',
      'auth.firebaseForm.invalidFile' => '選択されたファイルを解析できませんでした。形式を確認してください。',
      'auth.firebaseForm.fileLoaded' => 'ファイルから設定を読み込みました。内容を確認して保存してください。',
      'auth.firebaseForm.savedProjects' => '保存済み接続先',
      'auth.firebaseForm.active' => '有効',
      'auth.firebaseForm.useProject' => 'この接続先を使用',
      'auth.firebaseForm.setupSubtitle' => 'APIサーバーとFirebaseプロジェクトを接続します。',
      'auth.firebaseForm.setupPreview' => '入力内容のプレビューです。まだ接続・登録・保存は行いません。',
      'auth.firebaseForm.apiUrl' => 'APIサーバーURL',
      'auth.firebaseForm.apiUrlHint' => '稼働中のセルフホストAPIサーバーのURL',
      'auth.firebaseForm.invalidApiUrl' => '有効なHTTPまたはHTTPSのURLを入力してください。',
      'auth.firebaseForm.serviceAccount' => 'サービスアカウントJSON',
      'auth.firebaseForm.selectServiceAccount' => 'JSONファイルを選択',
      'auth.firebaseForm.replaceServiceAccount' => '別のJSONファイルを選択',
      'auth.firebaseForm.serviceAccountHint' =>
        'Firebaseの「プロジェクトの設定 → サービスアカウント」から取得できます。',
      'auth.firebaseForm.serviceAccountRequired' => 'サービスアカウントJSONを選択してください。',
      'auth.firebaseForm.invalidServiceAccount' =>
        'サービスアカウントJSONを読み込めませんでした。google-services.jsonではなく、秘密鍵を含むサービスアカウントのファイルを選択してください。',
      'auth.firebaseForm.removeServiceAccount' => '選択したファイルを解除',
      'auth.firebaseForm.credentialsNotSaved' => 'サービスアカウントの秘密鍵は接続先に保存しません。',
      'auth.firebaseForm.optionalProfileName' => '接続先名（任意）',
      'auth.firebaseForm.automaticProfileName' => '未入力の場合はプロジェクトIDを使用します。',
      'auth.firebaseForm.reviewSetup' => '入力内容を確認',
      'auth.firebaseForm.reviewTitle' => '接続内容の確認',
      'auth.firebaseForm.editSetup' => '入力内容を編集',
      'auth.firebaseForm.setupPlatforms' => 'まとめて設定するプラットフォーム',
      'auth.firebaseForm.setupExplanation' =>
        '登録済みのアプリを再利用し、不足するアプリを登録して、各プラットフォームの設定を取得します。',
      'auth.firebaseForm.startSetup' => 'Firebase設定を取得して保存',
      'auth.firebaseForm.manualSetup' => '設定ファイルから手動で追加',
      'auth.stateError' => '認証状態を確認できませんでした。',
      'auth.signOutAndRetry' => 'ログアウトして再ログイン',
      'auth.binaryPlistUnsupported' =>
        'バイナリ形式の plist はサポートしていません。XML形式に変換した GoogleService-Info.plist を選択してください。',
      'auth.unsupportedConfigFile' =>
        '未対応のファイル形式です。JSON (google-services.json) または plist (GoogleService-Info.plist) を選択してください。',
      'auth.configFileReadFailed' =>
        ({required Object error}) => 'ファイルの読み込みに失敗しました: ${error}',
      'auth.invalidCredentials' => 'メールアドレスまたはパスワードを確認してください。',
      'auth.emailInUse' => 'このメールアドレスはすでに登録されています。ログインしてください。',
      'auth.weakPassword' => 'より強固なパスワードを入力してください。',
      'auth.accountDisabled' => 'このアカウントは無効になっています。',
      'auth.operationFailed' => '認証を完了できませんでした。もう一度お試しください。',
      'auth.advancedOptions' => '詳細設定',
      'secrets.noSecrets' => 'シークレットが見つかりません',
      'secrets.addSecret' => 'シークレット追加',
      'secrets.editSecret' => 'シークレット編集',
      'secrets.secretName' => 'シークレット名',
      'secrets.secretValue' => 'シークレット値',
      'secrets.newSecretValue' => '新しいシークレット値（空欄で現在の値を維持）',
      'secrets.enterSecretName' => 'シークレット名を入力してください',
      'secrets.enterSecretValue' => 'シークレット値を入力してください',
      'secrets.adding' => 'シークレットを追加中...',
      'secrets.addedSuccess' => 'シークレットが追加されました',
      'secrets.updatedSuccess' => 'シークレットが更新されました',
      'secrets.inputModeText' => 'テキスト',
      'secrets.inputModeFile' => 'ファイル',
      'secrets.uploadFile' => 'ファイルをアップロード',
      'secrets.orUploadFile' => 'クリックしてファイルを選択',
      'secrets.enterValueOrUpload' => '値を入力するかファイルをアップロードしてください',
      'secrets.lastUpdated' => '最終更新',
      'secrets.viewSecretValue' => '値を表示',
      'secrets.secretValueTitle' => 'シークレット値',
      'secrets.secretValueLoading' => 'シークレット値を読み込み中',
      'secrets.copySecretValue' => '値をコピー',
      'secrets.copiedSecretValue' => 'シークレット値をコピーしました',
      'secrets.title' => 'シークレット',
      'secrets.loading' => 'シークレットを読み込み中',
      'secrets.fileLoaded' => 'ファイル読み込み済み',
      'secrets.keepCurrentValue' => '値を空欄にすると現在のシークレットを維持します',
      'secrets.codeSigningTitle' => 'iOSコード署名',
      'secrets.certificateExplanation' => 'iOSビルド用の証明書秘密鍵を生成します。自動コード署名に必要です。',
      'secrets.certificateGenerated' => '証明書秘密鍵を生成しました',
      'secrets.generateCertificate' => '証明書秘密鍵を生成',
      'secrets.signInRequired' => 'シークレットを管理するにはログインしてください。',
      'secrets.contextChanged' => 'アカウントまたはチームが変わりました。もう一度お試しください。',
      'secrets.invalidInput' => 'シークレットの名前と値を確認してください。',
      'secrets.notFound' => 'シークレットが見つかりません。再読み込みしてください。',
      'secrets.deleteConfirm' => 'このシークレットを削除しますか？',
      'secrets.deletedSuccess' => 'シークレットを削除しました',
      'settings.title' => '設定',
      'settings.preferences' => '環境設定',
      'settings.emailVerification' => 'メールアドレスの確認',
      'settings.emailVerified' => '確認済み',
      'settings.emailVerificationRequired' =>
        '他のチームに参加するにはメールアドレスの確認が必要です。確認メール内のリンクを開いてください。',
      'settings.sendVerificationEmail' => '確認メールを送信',
      'settings.refreshEmailVerification' => '確認状態を更新',
      'settings.verificationEmailSent' => '確認メールを送信しました。受信トレイを確認してください。',
      'settings.emailStillUnverified' => 'まだ確認できていません。確認メール内のリンクを開いてください。',
      'settings.emailVerificationFailed' => 'メール確認の操作に失敗しました。もう一度お試しください。',
      'settings.emailVerificationRateLimited' => '操作が多すぎます。しばらく待ってからお試しください。',
      'settings.checkForUpdates' => 'アップデートを確認',
      'settings.checkForUpdatesDescription' => 'macOSアプリの新しいバージョンを手動で確認',
      'settings.checkForUpdatesFailed' =>
        ({required Object error}) => 'アップデート確認に失敗しました: ${error}',
      'settings.subscription' => 'サブスクリプション',
      'settings.manageSubscription' => 'サブスクリプションプランを管理',
      'settings.returnToCloud' => 'OpenCI Cloudに戻す',
      'settings.appVersion' => 'アプリバージョン',
      'settings.logout' => 'ログアウト',
      'settings.logoutSuccess' => 'ログアウトしました',
      'settings.logoutFailed' =>
        ({required Object error}) => 'ログアウトに失敗: ${error}',
      'settings.deleteAccount' => 'アカウント削除',
      'settings.deleteConfirmTitle' => 'アカウント削除',
      'settings.deleteConfirmMessage' =>
        '本当にアカウントを削除しますか？この操作は元に戻せません。すべてのデータが完全に削除されます。',
      'settings.deleteSuccess' => 'アカウントが削除されました',
      'settings.noUserSignedIn' => '現在サインインしているユーザーがいません',
      'settings.requiresRecentLogin' => 'アカウンを削除する前に、一度ログアウトしてから再度ログインしてください',
      'settings.deleteFailed' =>
        ({required Object error}) => 'アカウントの削除に失敗: ${error}',
      'settings.manageBilling' => '課金を管理',
      'settings.billingDescription' => 'チームのプラン・請求・支払い方法',
      'settings.checkingUpdates' => 'アップデートを確認しています...',
      'settings.teamSection' => 'カンバン',
      'settings.account' => 'アカウント',
      'settings.logoutDescription' => '現在のアカウントからサインアウト',
      'settings.updateAvailable' => '新しいアップデートがあります',
      'settings.updateVersionAvailable' =>
        ({required Object version}) => '新しいアップデートがあります: v${version}',
      'settings.noUpdate' => '利用可能なアップデートはありません',
      'settings.updateCheckFailed' => 'アップデート確認に失敗しました',
      'settings.teamLoadFailed' => 'チーム情報を読み込めませんでした',
      'team.editTeam' => 'チーム編集',
      'team.createTeam' => 'チーム作成',
      'team.teamName' => 'チーム名',
      'team.newTeamName' => '新しいチーム名',
      'team.selectTeam' => 'チームを選択',
      'team.selectTeamLabel' => 'チーム',
      'team.connectGitHub' => 'GitHubと連携',
      'team.gitHubConnectionFailed' => 'GitHub連携を開始できませんでした。もう一度お試しください。',
      'team.gitHubConnectionVerified' => 'GitHub認証を確認しました。チームへの連携はまだ確定していません。',
      'team.gitHubConnectionCandidates' => '連携できるGitHubアカウント',
      'team.gitHubConnectionNoCandidates' =>
        '連携できるGitHubアカウントが見つかりませんでした。GitHub Appのインストールと権限を確認した後、もう一度連携してください。',
      'team.gitHubAppInstallation' => 'GitHub Appのインストール・設定を開く',
      'team.gitHubAppInstallationUrlUnavailable' =>
        'GitHub Appの案内リンクを利用できません。OpenCIサーバーの管理者に設定を確認してください。',
      'team.gitHubAppInstallationOpenFailed' =>
        'GitHub Appのページを開けませんでした。もう一度お試しください。',
      'team.gitHubConnectionTeam' =>
        ({required Object name}) => '連携するチーム: ${name}',
      'team.gitHubConnectionConfirm' => '連携を確定',
      'team.gitHubConnectionConfirming' => '連携中…',
      'team.gitHubConnectionCompleted' => 'GitHubとの連携が完了しました',
      'team.gitHubConnectionConfirmFailed' =>
        'GitHub連携の完了を確認できませんでした。もう一度お試しください。',
      'team.gitHubConnectionCancelled' => 'GitHubの認可がキャンセルされました。',
      'team.gitHubConnectionRestartRequired' =>
        '連携を再開できませんでした。この画面を閉じて、チーム画面からもう一度お試しください。',
      'team.gitHubConnectionCheckFailed' =>
        'GitHub連携の確認に失敗しました。この画面を閉じて、もう一度お試しください。',
      'team.enterTeamName' => 'チーム名を入力してください',
      'team.createdSuccess' => 'チームが作成されました',
      'team.updatedSuccess' => 'チーム名が更新されました',
      'team.selectedSuccess' => 'チームが選択されました',
      'team.inviteTitle' => 'チームメンバーを招待',
      'team.inviteEmail' => 'メールアドレス',
      'team.enterEmail' => 'メールアドレスを入力してください',
      'team.addedSuccess' => 'メンバーをチームに追加しました',
      'team.removeMember' => 'メンバーを削除',
      'team.removeMemberConfirm' =>
        ({required Object name, required Object teamName}) =>
            '「${name}」を「${teamName}」から削除しますか？',
      'team.removedSuccess' => 'メンバーをチームから削除しました',
      'team.accessDenied' => 'チームにアクセスできません。ログインと接続先を確認してください。',
      'team.memberAlreadyAdded' => 'このユーザーはすでにチームのメンバーです。',
      'team.memberNotRegistered' => '追加するユーザーは先にDashboardへ登録してください。',
      'team.memberEmailNotVerified' =>
        '追加するユーザーのメールアドレスが未確認です。本人にDashboardの「設定」→「アカウント」でメール確認を済ませてもらい、もう一度追加してください。',
      'team.memberUnavailable' => 'このアカウントは利用できません。',
      'team.enterValidEmail' => '有効なメールアドレスを入力してください。',
      'team.operationFailed' => 'チームの操作に失敗しました。もう一度お試しください。',
      'team.members' => 'メンバー',
      'team.membersCount' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('ja'))(
              count,
              other: '${count}人のメンバー',
            ),
      'team.you' => 'あなた',
      'team.noEmail' => 'メールなし',
      'team.deleteTeam' => 'チーム削除',
      'team.deleteTeamConfirm' =>
        ({required Object teamName}) =>
            '本当に「${teamName}」を削除しますか？この操作は元に戻せません。このチームに関連するすべてのワークフロー、シークレット、環境変数が完全に削除されます。',
      'team.deletedSuccess' => 'チームが削除されました',
      'team.cannotDeleteLastTeam' => '最後のチームは削除できません。先に別のチームを作成してください。',
      'subscription.title' => 'サブスクリプション',
      'subscription.noOfferings' => '利用可能なプランがありません',
      'subscription.noPackages' => '利用可能なパッケージがありません',
      'subscription.plans' => 'プラン',
      'subscription.restorePurchases' => '購入を復元',
      'subscription.purchaseSuccess' => '購入が完了しました！',
      'subscription.purchaseFailed' =>
        ({required Object error}) => '購入に失敗: ${error}',
      'subscription.restoreSuccess' => '購入が正常に復元されました',
      'subscription.restoreFailed' =>
        ({required Object error}) => '復元に失敗: ${error}',
      'subscription.activeSubscription' => 'アクティブなサブスクリプション',
      'subscription.active' => '有効',
      'subscription.termsOfUse' => '利用規約',
      'subscription.privacyPolicy' => 'プライバシーポリシー',
      'subscription.subscriptionTerms' =>
        'サブスクリプションは、現在の期間の終了の少なくとも24時間前までにキャンセルしない限り、自動的に更新されます。Apple IDアカウントには、現在の期間の終了前24時間以内に更新料金が請求されます。購入後は、App Storeのアカウント設定からサブスクリプションの管理・キャンセルが可能です。',
      'subscription.subscriptionTermsWeb' =>
        'サブスクリプションは、現在の請求期間の終了前にキャンセルしない限り、自動的に更新されます。アカウント設定からサブスクリプションの管理・キャンセルが可能です。お支払いはStripeにより安全に処理されます。',
      'subscription.perWeek' => '週額',
      'subscription.perMonth' => '月額',
      'subscription.per3Months' => '3ヶ月ごと',
      'subscription.per6Months' => '6ヶ月ごと',
      'subscription.perYear' => '年額',
      'logs.title' => 'CI/CDログ',
      'logs.empty' => 'アクティブなCI/CDログはありません',
      'logs.loadFailed' =>
        ({required Object error}) => 'ログの取得中にエラーが発生しました: ${error}',
      'logs.jobNotFound' => 'ビルドジョブが見つかりません',
      'logs.detailTitle' => 'CI/CD詳細ログ',
      'logs.copyAll' => '全体のログをコピー',
      'logs.nothingToCopy' => 'コピーするログがありません',
      'logs.copiedAll' => '全体のログをクリップボードにコピーしました',
      'logs.copyFailed' =>
        ({required Object error}) => 'ログのコピーに失敗しました: ${error}',
      'logs.noSteps' => 'ログステップがありません',
      'logs.failureReason' => 'ビルドの失敗理由',
      'logs.unavailable' => 'ログがありません。保存期間を過ぎたログと移行前のログは表示されません。',
      'logs.copy' => 'ログをコピー',
      'logs.copied' => 'ログをクリップボードにコピーしました',
      'logs.durationMinutesSeconds' =>
        ({required Object minutes, required Object seconds}) =>
            '${minutes}分${seconds}秒',
      'logs.durationSeconds' => ({required Object seconds}) => '${seconds}秒',
      'billing.title' => '課金',
      'billing.signInRequired' => 'Cloudにサインインすると、このページを利用できます。',
      'billing.teamLoadFailed' => 'チームを読み込めませんでした。',
      'billing.teamAccessDenied' => 'このチームにアクセスできません。ダッシュボードでチームを確認してください。',
      'billing.disabled' => '現在、この接続先では課金機能を利用できません。',
      'billing.returnedFromStripe' =>
        'Stripeから戻りました。変更の反映には時間がかかることがあります。反映されない場合は「再読み込み」を押してください。',
      'billing.ciAvailable' => 'CIを利用できます',
      'billing.monthlyPostpaid' => 'CIの月次後払い',
      'billing.monthlyExplanation' =>
        'CI実行1分につき税込1円。利用料は月ごとに集計し、翌月に登録カードで自動決済します。',
      'billing.continueCardSetup' => 'カード登録を続ける',
      'billing.setupCard' => '支払い方法を登録',
      'billing.cardRegistered' => '後払い用のカードは登録済みです。',
      'billing.setCardInPortal' => '「支払い方法・請求履歴を開く」から請求用のカードを設定してください。',
      'billing.openPortal' => '支払い方法・請求履歴を開く',
      'billing.monthlyUsage' =>
        ({required Object month}) => '今月の利用状況（${month}）',
      'billing.minutes' => ({required Object minutes}) => '利用時間 ${minutes}分',
      'billing.estimatedAmount' =>
        ({required Object amount}) => '税込見込額 ${amount}円',
      'billing.nextInvoiceDate' =>
        ({required Object date}) => '次回請求予定日 ${date}（日本時間）',
      'billing.usdExplanation' => 'USDでの請求額は、月締め時に円建ての利用料を換算して確定します。',
      'billing.usageUnavailable' => '今月の利用額を取得できませんでした。「再読み込み」で再度確認できます。',
      'billing.openingStripe' => 'Stripeを開く準備をしています…',
      'billing.consentTitle' => '月次後払いに同意しますか？',
      'billing.consentMessage' =>
        ({required Object teamName}) =>
            'チーム「${teamName}」のCI利用料は1分1円（税込）です。月の利用時間を合計し、翌月に登録カードから自動決済します。カード登録時の利用料は0円です。',
      'billing.agreeAndContinue' => '同意してStripeへ',
      'billing.paymentRequired' => 'CIを開始するには、このチームの請求用カードを登録してください。',
      'billing.allowanceExhausted' => '新しいCIを開始できる利用枠がありません。',
      'billing.subscriptionEnded' => '契約が終了しています。',
      'billing.paymentPending' => 'カード登録の完了を待っています。',
      'billing.ciUnavailable' => '現在、CIを開始できません。時間をおいて再読み込みしてください。',
      'billing.authenticationRequired' => 'もう一度サインインしてください。',
      'billing.forbidden' => 'このチームの課金情報にアクセスできません。',
      'billing.cardConsentRequired' => '最新の料金条件を読み込み直して、もう一度同意してください。',
      'billing.contextChanged' => '接続先またはアカウントが変わりました。画面を開き直してください。',
      'billing.subscriptionExists' => '契約がすでにあります。再読み込みして契約を確認してください。',
      'billing.checkoutPending' => '決済を確認しています。時間をおいて再読み込みしてください。',
      'billing.customerMissing' => '管理できる契約がありません。再読み込みしてください。',
      'billing.launchFailed' => 'Stripeを開けませんでした。もう一度お試しください。',
      'billing.operationFailed' => '課金処理を完了できませんでした。時間をおいてもう一度お試しください。',
      'language.label' => '言語 / Language',
      'language.system' => '端末の設定に合わせる',
      'language.saveFailed' => '言語設定を保存できませんでした。もう一度お試しください。',
      'connection.saveFailed' => '接続設定を保存できませんでした。',
      'connection.configMismatch' =>
        '同じ接続先IDで異なるFirebase設定は使用できません。新しい接続先として登録してください。',
      'connection.platformConfigMissing' =>
        ({required Object name, required Object platform}) =>
            '${name} の ${platform} 用Firebase設定がありません。',
      'config.jsonParseFailed' =>
        ({required Object error}) => 'JSONのパースに失敗しました: ${error}',
      'config.xmlParseFailed' =>
        ({required Object error}) => 'XMLのパースに失敗しました: ${error}',
      'config.missingKeys' =>
        ({required Object file, required Object keys}) =>
            '${file}の必須キーが不足しています: ${keys}',
      'config.unsupportedFormat' =>
        '未対応の形式です。Web用のFirebase設定(JSON)、Android用のgoogle-services.json、あるいはiOS用のGoogleService-Info.plistを選択してください。',
      'config.plistDictMissing' => 'plist内に <dict> 要素が見つかりません。',
      _ => null,
    };
  }
}
