// Japanese-only application strings.
// ignore_for_file: library_private_types_in_public_api, unnecessary_brace_in_string_interps

final t = AppStrings();

class AppStrings {
  AppStrings();

  late final AppStrings _root = this; // ignore: unused_field

  late final AppStringsCommon common = AppStringsCommon._(_root);
  late final AppStringsTimeAgo timeAgo = AppStringsTimeAgo._(_root);
  late final AppStringsNav nav = AppStringsNav._(_root);
  late final AppStringsAuth auth = AppStringsAuth._(_root);
  late final AppStringsWorkflow workflow = AppStringsWorkflow._(_root);
  late final AppStringsBuildLogs buildLogs = AppStringsBuildLogs._(_root);
  late final AppStringsVariables variables = AppStringsVariables._(_root);
  late final AppStringsSecrets secrets = AppStringsSecrets._(_root);
  late final AppStringsEnvVars envVars = AppStringsEnvVars._(_root);
  late final AppStringsSettings settings = AppStringsSettings._(_root);
  late final AppStringsNotifications notifications = AppStringsNotifications._(
    _root,
  );
  late final AppStringsTeam team = AppStringsTeam._(_root);
  late final AppStringsGithub github = AppStringsGithub._(_root);
  late final AppStringsSubscription subscription = AppStringsSubscription._(
    _root,
  );
  late final AppStringsStoreRelease storeRelease = AppStringsStoreRelease._(
    _root,
  );
}

class AppStringsCommon {
  AppStringsCommon._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get save => '保存';
  String get cancel => 'キャンセル';
  String get delete => '削除';
  String get add => '追加';
  String get edit => '編集';
  String get close => '閉じる';
  String error({required Object error}) => 'エラー: ${error}';
  String get loading => '読み込み中...';
  String get invite => '招待';
  late final AppStringsCommonFunctionErrors functionErrors =
      AppStringsCommonFunctionErrors._(_root);
}

// Path: timeAgo
class AppStringsTimeAgo {
  AppStringsTimeAgo._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String secsAgo({required Object count}) => '${count}秒前';
  String secsAgoPlural({required Object count}) => '${count}秒前';
  String minsAgo({required Object count}) => '${count}分前';
  String minsAgoPlural({required Object count}) => '${count}分前';
  String hoursAgo({required Object count}) => '${count}時間前';
  String daysAgo({required Object count}) => '${count}日前';
  String monthsAgo({required Object count}) => '${count}ヶ月前';
}

// Path: nav
class AppStringsNav {
  AppStringsNav._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get workflows => 'CI/CD設定';
  String get variables => 'シークレット';
  String get logs => 'ログ';
  String get release => 'リリース';
  String get settings => '設定';
}

// Path: auth
class AppStringsAuth {
  AppStringsAuth._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get signInSubtitle => 'アカウントにサインイン';
  String get email => 'メールアドレス';
  String get password => 'パスワード';
  String get login => 'ログイン';
  String get createAccount => 'アカウント作成';
  String get useYourFirebase => '自分のFirebaseを使用';
  String get resetFirebase => 'Firebaseをリセット';
  String get resetSuccess => 'Firebaseがリセットされました。アプリを再起動してください。';
  String get agreePrefix => '利用規約に同意する ';
  String get termsOfService => '利用規約';
  String get enterEmail => 'メールアドレスを入力してください';
  String get enterPassword => 'パスワードを入力してください';
  late final AppStringsAuthFirebaseForm firebaseForm =
      AppStringsAuthFirebaseForm._(_root);
}

// Path: workflow
class AppStringsWorkflow {
  AppStringsWorkflow._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => 'CI/CD設定';
  String get tabWorkflows => 'CI/CD設定';
  String get tabRuns => 'CI/CDログ';
  String get addWorkflow => 'CI/CD設定を作成';
  String get noWorkflowFiles => 'ワークフローファイルが見つかりません';
  String get addYamlHint => 'リポジトリの .openci/ にYAMLファイルを追加してください。';
  String get selectRepo => 'リポジトリを選択';
  String get selectRepoHint => 'CI/CD設定を管理するGitHubリポジトリを選択してください。';
  String get selectRepoButton => 'リポジトリを選択';
  String get enabled => '有効';
  String get disabled => '無効';
  String get enabledDescription => 'トリガーされるとワークフローが実行されます。';
  String get disabledDescription => 'ワークフローは一時停止中で実行されません。';
  String get enable => 'ワークフローを有効にする';
  String get disable => 'ワークフローを無効にする';
  String get triggers => 'トリガー';
  String triggerBranch({required Object type}) => '${type} ブランチ';
  String triggerBranchLoading({required Object type}) =>
      '${type} ブランチ (読み込み中...)';
  String get selectBranch => 'ブランチを選択';
  String get selectBranchHint => 'ワークフローを表示するブランチを選択してください。';
  String get noBranches => 'ブランチが見つかりません';
  String get selectRepository => 'リポジトリを選択';
  String get selectRepositoryHint => 'CI/CD設定を管理するGitHubリポジトリを選択してください。';
  String get searchRepositories => 'リポジトリを検索...';
  String get noRepositories =>
      'リポジトリが見つかりません。\nOpenCI GitHub Appをインストールしてください。';
  String noMatchingRepositories({required Object query}) =>
      '「${query}」に一致するリポジトリはありません';
  String defaultBranch({required Object branch}) => 'デフォルト: ${branch}';
  late final AppStringsWorkflowEditor editor = AppStringsWorkflowEditor._(
    _root,
  );
}

// Path: buildLogs
class AppStringsBuildLogs {
  AppStringsBuildLogs._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String title({required Object date}) => 'ビルドログ - ${date}';
  String get noJobs => 'ビルドジョブが見つかりません';
  String get overviewTitle => '直近24時間の実行';
  String latestRun({required Object time}) => '最新 ${time}';
  String get summaryRuns => '実行';
  String get summarySuccess => '成功';
  String get summaryRunning => '実行中';
  String get summaryFailed => '失敗';
  late final AppStringsBuildLogsStatus status = AppStringsBuildLogsStatus._(
    _root,
  );
  late final AppStringsBuildLogsDetail detail = AppStringsBuildLogsDetail._(
    _root,
  );
  late final AppStringsBuildLogsDuration duration =
      AppStringsBuildLogsDuration._(_root);
}

// Path: variables
class AppStringsVariables {
  AppStringsVariables._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => 'シークレット';
  String get envVarsTab => '環境変数';
  String get secretsTab => 'シークレット';
}

// Path: secrets
class AppStringsSecrets {
  AppStringsSecrets._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => 'シークレットマネージャー';
  String get noSecrets => 'シークレットが見つかりません';
  String get addSecret => 'シークレット追加';
  String get editSecret => 'シークレット編集';
  String get secretName => 'シークレット名';
  String get secretValue => 'シークレット値';
  String get newSecretValue => '新しいシークレット値（空欄で現在の値を維持）';
  String get enterSecretName => 'シークレット名を入力してください';
  String get enterSecretValue => 'シークレット値を入力してください';
  String get adding => 'シークレットを追加中...';
  String get addedSuccess => 'シークレットが追加されました';
  String get updatedSuccess => 'シークレットが更新されました';
  String get deleteConfirm => 'このシークレットを削除しますか？この操作は元に戻せません。';
  String get deletedSuccess => 'シークレットが削除されました';
  String get unusedSecrets => '未使用のシークレット';
  String get notUsedInWorkflows => 'ワークフローで使用されていません';
  String get inputModeText => 'テキスト';
  String get inputModeFile => 'ファイル';
  String get uploadFile => 'ファイルをアップロード';
  String fileSelected({required Object fileName}) => '${fileName} を選択中';
  String get orUploadFile => 'クリックしてファイルを選択';
  String get enterValueOrUpload => '値を入力するかファイルをアップロードしてください';
  String get lastUpdated => '最終更新';
  String get viewSecretValue => '値を表示';
  String get secretValueTitle => 'シークレット値';
  String get secretValueLoading => 'シークレット値を読み込み中';
  String get copySecretValue => '値をコピー';
  String get copiedSecretValue => 'シークレット値をコピーしました';
}

// Path: envVars
class AppStringsEnvVars {
  AppStringsEnvVars._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => '環境変数';
  String get noEnvVars => '環境変数が見つかりません';
  String get noCustomEnvVars => 'カスタム環境変数がありません';
  String get addEnvVar => '環境変数追加';
  String get editEnvVar => '環境変数編集';
  String get editRunNumber => '実行番号を編集';
  String get keyName => 'キー名';
  String get value => '値';
  String get keyHint => '例: MY_VARIABLE';
  String get valueHint => '例: hello';
  String get enterKeyName => 'キー名を入力してください';
  String get enterValue => '値を入力してください';
  String get invalidKey => '英字、数字、アンダースコアのみ使用できます';
  String get valueMustBeNumber => '値は数値である必要があります';
  String get addedSuccess => '環境変数が追加されました';
  String get updatedSuccess => '環境変数が更新されました';
  String get deletedSuccess => '削除しました';
  String get runNumberUpdated => '実行番号が更新されました';
}

// Path: settings
class AppStringsSettings {
  AppStringsSettings._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => '設定';
  String get general => '一般';
  String get preferences => '環境設定';
  String get buildNotifications => 'ビルド通知';
  String get configureNotifications => '通知を受け取るタイミングを設定';
  String get checkForUpdates => 'アップデートを確認';
  String get checkForUpdatesDescription => 'macOSアプリの新しいバージョンを手動で確認';
  String get checkForUpdatesStarted => 'アップデート確認を開始しました';
  String checkForUpdatesFailed({required Object error}) =>
      'アップデート確認に失敗: ${error}';
  String get subscription => 'サブスクリプション';
  String get manageSubscription => 'サブスクリプションプランを管理';
  String firebaseAppName({required Object name}) => 'Firebaseアプリ名: ${name}';
  String get resetToCloud => 'OpenCI Cloudにリセット';
  String get resetToCloudSuccess => '設定をクリアしました。アプリを再起動してください。';
  String get selfHostedActive => 'セルフホストFirebase';
  String selfHostedProject({required Object projectId}) =>
      'プロジェクト: ${projectId}';
  String get inviteTeamMember => 'チームメンバーを招待';
  String get appVersion => 'アプリバージョン';
  String get logout => 'ログアウト';
  String get logoutSuccess => 'ログアウトしました';
  String logoutFailed({required Object error}) => 'ログアウトに失敗: ${error}';
  String get deleteAccount => 'アカウント削除';
  String get deleteConfirmTitle => 'アカウント削除';
  String get deleteConfirmMessage =>
      '本当にアカウントを削除しますか？この操作は元に戻せません。すべてのデータが完全に削除されます。';
  String get deleteSuccess => 'アカウントが削除されました';
  String get noUserSignedIn => '現在サインインしているユーザーがいません';
  String get requiresRecentLogin => 'アカウンを削除する前に、一度ログアウトしてから再度ログインしてください';
  String deleteFailed({required Object error}) => 'アカウントの削除に失敗: ${error}';
  late final AppStringsSettingsAiFeatures aiFeatures =
      AppStringsSettingsAiFeatures._(_root);
  late final AppStringsSettingsLanguage language = AppStringsSettingsLanguage._(
    _root,
  );
}

// Path: notifications
class AppStringsNotifications {
  AppStringsNotifications._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => 'ビルド通知';
  String get all => 'すべて';
  String get allDesc => '成功時と失敗時の両方で通知';
  String get successOnly => '成功時のみ';
  String get successOnlyDesc => 'ビルド成功時のみ通知';
  String get failureOnly => '失敗時のみ';
  String get failureOnlyDesc => 'ビルド失敗時のみ通知';
  String get none => 'なし';
  String get noneDesc => '通知を送信しない';
  String get updated => '通知設定が更新されました';
  String updateFailed({required Object error}) => '更新に失敗: ${error}';
  String errorLoading({required Object error}) => '設定の読み込みエラー: ${error}';
}

// Path: team
class AppStringsTeam {
  AppStringsTeam._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get switchTeam => 'チーム切替';
  String get editTeam => 'チーム編集';
  String get createTeam => 'チーム作成';
  String get createNewTeam => '新しいチームを作成';
  String get teamName => 'チーム名';
  String get newTeamName => '新しいチーム名';
  String get selectTeam => 'チームを選択';
  String get selectTeamLabel => 'チーム';
  String get enterTeamName => 'チーム名を入力してください';
  String get selectTeamValidation => 'チームを選択してください';
  String get createdSuccess => 'チームが作成されました';
  String get updatedSuccess => 'チーム名が更新されました';
  String get selectedSuccess => 'チームが選択されました';
  String get inviteTitle => 'チームメンバーを招待';
  String get inviteEmail => 'メールアドレス';
  String get enterEmail => 'メールアドレスを入力してください';
  String get invitedSuccess => 'チームメンバーが招待されました';
  String get addedSuccess => 'メンバーをチームに追加しました';
  String get invitationSent => '招待メールを送信しました 📧';
  String get processingInvitation => '招待を処理中...';
  String get invitationFailed => '招待の処理に失敗しました';
  String get invitationAccepted => '参加しました！🎉';
  String get alreadyMemberTitle => 'すでにメンバーです';
  String alreadyMemberMessage({required Object teamName}) =>
      'すでに「${teamName}」のメンバーです。';
  String joinedTeamMessage({required Object teamName}) =>
      '「${teamName}」チームに参加しました。';
  String get goToDashboard => 'ダッシュボードへ';
  String get members => 'メンバー';
  String membersCount({required Object count}) => '${count}人のメンバー';
  String get you => 'あなた';
  String get noEmail => 'メールなし';
  String get deleteTeam => 'チーム削除';
  String deleteTeamConfirm({required Object teamName}) =>
      '本当に「${teamName}」を削除しますか？この操作は元に戻せません。このチームに関連するすべてのワークフロー、シークレット、環境変数が完全に削除されます。';
  String get deletedSuccess => 'チームが削除されました';
  String get cannotDeleteLastTeam => '最後のチームは削除できません。先に別のチームを作成してください。';
}

// Path: github
class AppStringsGithub {
  AppStringsGithub._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get connectTitle => 'GitHubと連携';
  String get connectDescription => 'GitHubアカウントを連携して\nリポジトリを自動的に選択できるようにします。';
  String get connectButton => 'GitHubと連携する';
}

// Path: subscription
class AppStringsSubscription {
  AppStringsSubscription._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => 'サブスクリプション';
  String get noOfferings => '利用可能なプランがありません';
  String get noPackages => '利用可能なパッケージがありません';
  String get plans => 'プラン';
  String get restorePurchases => '購入を復元';
  String get purchaseSuccess => '購入が完了しました！';
  String purchaseFailed({required Object error}) => '購入に失敗: ${error}';
  String get restoreSuccess => '購入が正常に復元されました';
  String restoreFailed({required Object error}) => '復元に失敗: ${error}';
  String get activeSubscription => 'アクティブなサブスクリプション';
  String get active => '有効';
  String get termsOfUse => '利用規約';
  String get privacyPolicy => 'プライバシーポリシー';
  String get subscriptionTerms =>
      'サブスクリプションは、現在の期間の終了の少なくとも24時間前までにキャンセルしない限り、自動的に更新されます。Apple IDアカウントには、現在の期間の終了前24時間以内に更新料金が請求されます。購入後は、App Storeのアカウント設定からサブスクリプションの管理・キャンセルが可能です。';
  String get subscriptionTermsWeb =>
      'サブスクリプションは、現在の請求期間の終了前にキャンセルしない限り、自動的に更新されます。アカウント設定からサブスクリプションの管理・キャンセルが可能です。お支払いはStripeにより安全に処理されます。';
  String get perWeek => '週額';
  String get perMonth => '月額';
  String get per3Months => '3ヶ月ごと';
  String get per6Months => '6ヶ月ごと';
  String get perYear => '年額';
}

// Path: storeRelease
class AppStringsStoreRelease {
  AppStringsStoreRelease._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => 'ストアリリース';
  String get setupTitle => 'App Store Connectを接続';
  String get setupDescription =>
      'App Store Connect APIの認証情報を入力して、OpenCIから直接リリースを管理しましょう。';
  String get issuerId => 'Issuer ID';
  String get keyId => 'Key ID';
  String get privateKey => '秘密鍵 (.p8)';
  String get privateKeyHint => '.p8ファイルの内容を貼り付けてください';
  String get connect => '接続';
  String get connecting => '接続中...';
  String get setupSuccess => 'App Store Connectが正常に接続されました';
  String setupFailed({required Object error}) => '接続に失敗: ${error}';
  String get enterIssuerId => 'Issuer IDを入力してください';
  String get enterKeyId => 'Key IDを入力してください';
  String get enterPrivateKey => '秘密鍵を入力してください';
  String get selectApp => 'アプリを選択';
  String get selectAppHint => 'リリースを管理するアプリを選択してください';
  String get noApps => 'アプリが見つかりません';
  String get noAppsHint => 'App Store Connectアカウントにアプリが見つかりませんでした。';
  String get loadingApps => 'アプリを読み込み中...';
  String get ascLoadingHint => 'App Store Connect APIの応答に少し時間がかかる場合があります';
  String get builds => 'ビルド';
  String get noBuilds => 'ビルドが見つかりません';
  String get noBuildsHint => 'App Store Connectにビルドをアップロードしてください。';
  String version({required Object version}) => 'v${version}';
  String buildNumber({required Object number}) => 'ビルド ${number}';
  String get processing => '処理中';
  String get readyForSale => '販売準備完了';
  String get valid => '準備完了';
  String get invalid => '無効';
  String get testFlight => 'TestFlight';
  String get submitToTestFlight => 'TestFlightに送信';
  String get submitToTestFlightConfirm => 'このビルドをTestFlightの外部テスターに送信しますか？';
  String testFlightSuccess({required Object group}) =>
      'TestFlightグループにビルドが送信されました: ${group}';
  String testFlightFailed({required Object error}) =>
      'TestFlightへの送信に失敗: ${error}';
  String get appStoreReview => 'App Storeレビュー';
  String get submitForReview => 'レビューに提出';
  String submitForReviewConfirm({required Object version}) =>
      'このビルドをApp Storeレビューに提出しますか？\n\nバージョン: ${version}';
  String get reviewSuccess => 'App Storeレビューにビルドが提出されました';
  String reviewFailed({required Object error}) => 'レビューへの提出に失敗: ${error}';
  String get versionString => 'バージョン文字列';
  String get enterVersionString => '例: 1.0.0';
  String get versionRequired => 'バージョン文字列を入力してください';
  String get whatsNew => '新機能';
  String get whatsNewHint => 'このバージョンの新機能を説明してください';
  String get whatsNewRequired => 'リリースノートを入力してください';
  String get changeApp => 'アプリを変更';
  String get reconfigure => '再設定';
  String get howToGetCredentials => '認証情報の取得方法';
  String get credentialsHelp =>
      'App Store Connect > ユーザーとアクセス > 統合 > App Store Connect API でAPIキーを生成してください。';
  String get waitingForReview => '審査待ち';
  String get inReview => '審査中';
  String get pendingRelease => 'リリース待ち';
  String get readyForDistribution => '配信準備完了';
  String get developerRejected => 'デベロッパが却下';
  String get rejected => '却下';
  String get prepareForSubmission => '提出準備中';
  String get submitted => '提出済み';
  String get stepBuild => 'ビルド';
  String get stepDetails => '詳細';
  String get stepReview => '確認';
  String get selectBuildTitle => 'ビルドを選択';
  String get selectBuildHint => 'App Storeレビューに提出するビルドを選択してください';
  String get releaseDetailsTitle => 'リリース情報';
  String get releaseDetailsHint => 'バージョンとリリースノートを設定';
  String get reviewTitle => '確認 & 提出';
  String get reviewHint => '提出前にすべての情報を確認してください';
  String get next => '次へ';
  String get back => '戻る';
  String get confirmSubmit => 'レビューに提出';
  String get submittingReview => '提出中...';
  String get selectedBuildLabel => '選択されたビルド';
  String get screenshotsTitle => 'スクリーンショット';
  String get noScreenshots => 'スクリーンショットがありません';
  String get screenshotsHint => 'App Store Connectでスクリーンショットを管理してください';
  String screenshotCount({required Object count}) => '${count}枚のスクリーンショット';
  String get appDescription => '説明';
  String get keywordsLabel => 'キーワード';
  String get noVersionInfo => '既存のバージョン情報が見つかりません';
  String get existingInfo => '現在のApp Store情報';
  String get summarySection => '提出サマリー';
  String get underReview => '審査中';
  String get underReviewDescription =>
      'アプリは現在Appleによる審査中です。審査が完了するまで変更を行うことはできません。';
  String get waitingForReviewDescription => 'アプリは提出済みで、Appleの審査開始を待っています。';
  String get pendingReleaseTitle => '承認済み';
  String get pendingReleaseDescription => 'アプリが承認されました！App Storeへのリリースを待っています。';
  String get submittedBuild => '提出されたビルド';
  String get submittedOn => '提出日';
  String get estimatedWait => '審査は通常24〜48時間かかります';
  String get viewInAsc => 'App Store Connectで確認';
}

// Path: common.functionErrors
class AppStringsCommonFunctionErrors {
  AppStringsCommonFunctionErrors._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get cancelled => '操作がキャンセルされました。';
  String get invalidArgument => '入力内容を確認してください。';
  String get failedPrecondition => '操作を完了できません。状態を確認してください。';
  String get notFound => '対象のデータが見つかりません。再読み込みしてください。';
  String get alreadyExists => 'すでに存在しています。';
  String get unauthenticated => 'ログインが必要です。もう一度ログインしてください。';
  String get permissionDenied => 'この操作を実行する権限がありません。';
  String get resourceExhausted => 'しばらく時間をおいてから再試行してください。';
  String get aborted => '処理が競合しました。もう一度お試しください。';
  String get unavailable => '一時的に接続できません。しばらくしてから再試行してください。';
  String get internal => 'サーバーで予期しないエラーが発生しました。時間をおいて再試行してください。';
  String get unknown => '原因不明のエラーが発生しました。時間をおいて再試行してください。';
  String get unexpected => '予期しないエラーが発生しました。時間をおいて再試行してください。';
}

// Path: auth.firebaseForm
class AppStringsAuthFirebaseForm {
  AppStringsAuthFirebaseForm._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => '自分のFirebaseを使用';
  String get name => '名前';
  String get apiKey => 'APIキー';
  String get appId => 'アプリID';
  String get messagingSenderId => 'メッセージ送信者ID';
  String get projectId => 'プロジェクトID';
  String get storageBucket => 'ストレージバケット';
  String get pickConfig => '設定を保存';
  String get configSaved => '設定を保存しました。アプリを再起動してください。';
  String get configActive => 'カスタムFirebaseプロジェクトが設定済みです。再起動で反映されます。';
  String get importFile => 'ファイルから読み込み';
  String get importFileHint =>
      'JSON (google-services.json) または plist (GoogleService-Info.plist)';
  String get invalidFile => '選択されたファイルを解析できませんでした。形式を確認してください。';
  String get fileLoaded => 'ファイルから設定を読み込みました。内容を確認して保存してください。';
  String get savedProjects => '保存済みプロジェクト';
  String get active => '有効';
  String get useProject => 'このプロジェクトを使用';
  String get editProject => 'プロジェクトを編集';
}

// Path: workflow.editor
class AppStringsWorkflowEditor {
  AppStringsWorkflowEditor._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get createTitle => 'CI/CD設定を作成';
  String get editTitle => 'CI/CD設定を編集';
  String get editorTab => 'エディター';
  String get yamlTab => 'YAML';
  String get basicInfo => '基本情報';
  String get workflowName => 'ワークフロー名';
  String get stepName => 'ステップ名';
  String get stepNameHint => '例: iOSアプリビルド';
  String get type => 'タイプ';
  String get command => 'コマンド';
  String get action => 'アクション';
  String get actionHint => 'タップしてアクションを検索';
  String get version => 'バージョン';
  String get kWith => 'with';
  String get loadingInputs => '入力を読み込み中...';
  String get couldNotLoadInputs => '入力を読み込めませんでした';
  String get noInputs => 'このアクションには入力が定義されていません';
  String get enterAction => 'アクションを入力して利用可能な入力を確認';
  String get loadingVersions => 'バージョンを読み込み中...';
  String get required => '必須';
  String get editStep => 'ステップ編集';
  String get deleteStep => 'ステップ削除';
  String get deleteStepConfirm => 'このステップを削除しますか？';
  String get saveToRepo => 'リポジトリに保存';
  String get fileName => 'ファイル名';
  String get fileNameHint => '例: build.yaml';
  String get howToSave => '保存方法';
  String get commitDirectly => '直接コミット';
  String commitToBranch({required Object branch}) => '${branch} ブランチにコミット';
  String get createPR => 'プルリクエストを作成';
  String get createPRSubtitle => '新しいブランチが作成され、PRが開かれます';
  String commitToBranchButton({required Object branch}) => '${branch} にコミット';
  String get createPRButton => 'プルリクエストを作成';
  String get enterFileName => 'ファイル名を入力してください';
  String get fileNameMustEndYaml => 'ファイル名は .yaml または .yml で終わる必要があります';
  String get prCreated => 'プルリクエスト作成完了';
  String prNumber({required Object number}) => 'PR #${number} が作成されました。';
  String get close => '閉じる';
  String get openInGitHub => 'GitHubで開く';
  String committedToBranch({required Object branch}) =>
      'ワークフローファイルが ${branch} にコミットされました';
  String get prCreatedSuccess => 'プルリクエストが作成されました';
  String get addSteps => 'ステップを追加';
  String get addJob => 'ジョブを追加';
  String get parallel => '並列実行';
}

// Path: buildLogs.status
class AppStringsBuildLogsStatus {
  AppStringsBuildLogsStatus._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get success => '成功';
  String get failed => '失敗';
  String get inProgress => '実行中';
  String get queued => '待機中';
  String get cancelled => 'キャンセル';
}

// Path: buildLogs.detail
class AppStringsBuildLogsDetail {
  AppStringsBuildLogsDetail._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get viewDetails => '詳細を表示';
  String get retry => '再実行';
  String get retryConfirm => '本当にこのビルドジョブを再実行しますか？';
  String get retryNo => 'いいえ';
  String get cancelBuild => 'ビルドをキャンセル';
  String get cancelConfirm => '本当にこのビルドをキャンセルしますか？';
  String get cancelNo => 'いいえ';
  String get cancelling => 'ビルドをキャンセル中...';
  String get buildCancelled => 'ビルドがキャンセルされました';
  String failedToCancel({required Object error}) => 'キャンセルに失敗: ${error}';
  String get retrying => 'ビルドジョブを再実行中...';
  String get retrySuccess => 'ビルドジョブがキューに追加されました';
  String failedToRetry({required Object error}) => '再実行に失敗: ${error}';
  String get noRuns => 'まだ実行がありません';
  String get waitingForLogs => 'ログを待機中...';
  String get noLogsAvailable => '利用可能なログはありません';
  String logEntries({required Object count}) => '${count}件のログ';
  String get copyAll => 'すべてのログをコピー';
  String get logsCopied => 'ログがクリップボードにコピーされました';
  String lines({required Object count}) => '${count}行';
  String get generatingSummary => 'AI要約を生成中...';
  String get failureSummaryTitle => 'AI 失敗要約';
  String get aiFixTitle => 'CI/CDの修正案を作る';
  String get aiFixDescription => '失敗ログとCI/CD設定を読み取り、修正ブランチまたはPRの作成につなげます。';
  String get aiFixButton => '修正を依頼';
  String get aiFixDialogTitle => 'CI/CD修正の入口';
  String get aiFixDialogBody =>
      'この実行ログをもとに、失敗原因を特定してCI/CD設定の修正案を作る予定です。次の実装で、ログ収集、設定ファイル取得、修正PR作成に接続します。';
  String get aiFixDialogPrimary => '準備中';
}

// Path: buildLogs.duration
class AppStringsBuildLogsDuration {
  AppStringsBuildLogsDuration._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get lessThanMinute => '<1分';
  String minutes({required Object count}) => '${count}分';
  String hoursAndMinutes({required Object hours, required Object minutes}) =>
      '${hours}時間${minutes}分';
  String hours({required Object count}) => '${count}時間';
}

// Path: settings.aiFeatures
class AppStringsSettingsAiFeatures {
  AppStringsSettingsAiFeatures._(this._root);

  final AppStrings _root; // ignore: unused_field

  String get title => 'AI機能';
  String get subtitle => '失敗要約などのAI機能を有効にする';
  String get enabled => 'AI機能が有効です';
  String get disabled => 'AI機能が無効です';
  String get updated => 'AI機能の設定が更新されました';
}

class AppStringsSettingsLanguage {
  AppStringsSettingsLanguage._(this._root);

  final AppStrings _root; // ignore: unused_field

  // Translations
  String get title => '言語';
  String get subtitle => '表示言語を変更';
  String get system => 'システムのデフォルト';
  String get english => 'English';
  String get japanese => '日本語';
  String get spanish => 'Español';
}
