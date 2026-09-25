// Japanese-only application strings.

final t = AppStrings();

class AppStrings {
  AppStrings();

  late final AppStringsCommon common = AppStringsCommon._();
  late final AppStringsAuth auth = AppStringsAuth._();
  late final AppStringsSecrets secrets = AppStringsSecrets._();
  late final AppStringsSettings settings = AppStringsSettings._();
  late final AppStringsTeam team = AppStringsTeam._();
  late final AppStringsSubscription subscription = AppStringsSubscription._();
}

class AppStringsCommon {
  AppStringsCommon._();

  String get save => '保存';
  String get cancel => 'キャンセル';
  String get delete => '削除';
  String get close => '閉じる';
  String error({required Object error}) => 'エラー: $error';
  String get invite => '招待';
}

class AppStringsAuth {
  AppStringsAuth._();

  String get signInSubtitle => 'アカウントにサインイン';
  String get email => 'メールアドレス';
  String get password => 'パスワード';
  String get login => 'ログイン';
  String get createAccount => 'アカウント作成';
  String get useYourFirebase => '自分のFirebaseを使用';
  String get agreePrefix => '利用規約に同意する ';
  String get termsOfService => '利用規約';
  String get enterEmail => 'メールアドレスを入力してください';
  String get enterPassword => 'パスワードを入力してください';
  late final AppStringsAuthFirebaseForm firebaseForm =
      AppStringsAuthFirebaseForm._();
}

class AppStringsSecrets {
  AppStringsSecrets._();

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
  String get inputModeText => 'テキスト';
  String get inputModeFile => 'ファイル';
  String get uploadFile => 'ファイルをアップロード';
  String get orUploadFile => 'クリックしてファイルを選択';
  String get enterValueOrUpload => '値を入力するかファイルをアップロードしてください';
  String get lastUpdated => '最終更新';
  String get viewSecretValue => '値を表示';
  String get secretValueTitle => 'シークレット値';
  String get secretValueLoading => 'シークレット値を読み込み中';
  String get copySecretValue => '値をコピー';
  String get copiedSecretValue => 'シークレット値をコピーしました';
}

class AppStringsSettings {
  AppStringsSettings._();

  String get title => '設定';
  String get preferences => '環境設定';
  String get checkForUpdates => 'アップデートを確認';
  String get checkForUpdatesDescription => 'macOSアプリの新しいバージョンを手動で確認';
  String checkForUpdatesFailed({required Object error}) =>
      'アップデート確認に失敗: $error';
  String get subscription => 'サブスクリプション';
  String get manageSubscription => 'サブスクリプションプランを管理';
  String get returnToCloud => 'OpenCI Cloudに戻す';
  String get appVersion => 'アプリバージョン';
  String get logout => 'ログアウト';
  String get logoutSuccess => 'ログアウトしました';
  String logoutFailed({required Object error}) => 'ログアウトに失敗: $error';
  String get deleteAccount => 'アカウント削除';
  String get deleteConfirmTitle => 'アカウント削除';
  String get deleteConfirmMessage =>
      '本当にアカウントを削除しますか？この操作は元に戻せません。すべてのデータが完全に削除されます。';
  String get deleteSuccess => 'アカウントが削除されました';
  String get noUserSignedIn => '現在サインインしているユーザーがいません';
  String get requiresRecentLogin => 'アカウンを削除する前に、一度ログアウトしてから再度ログインしてください';
  String deleteFailed({required Object error}) => 'アカウントの削除に失敗: $error';
}

class AppStringsTeam {
  AppStringsTeam._();

  String get editTeam => 'チーム編集';
  String get createTeam => 'チーム作成';
  String get teamName => 'チーム名';
  String get newTeamName => '新しいチーム名';
  String get selectTeam => 'チームを選択';
  String get selectTeamLabel => 'チーム';
  String get enterTeamName => 'チーム名を入力してください';
  String get createdSuccess => 'チームが作成されました';
  String get updatedSuccess => 'チーム名が更新されました';
  String get selectedSuccess => 'チームが選択されました';
  String get inviteTitle => 'チームメンバーを招待';
  String get inviteEmail => 'メールアドレス';
  String get enterEmail => 'メールアドレスを入力してください';
  String get addedSuccess => 'メンバーをチームに追加しました';
  String get members => 'メンバー';
  String membersCount({required Object count}) => '$count人のメンバー';
  String get you => 'あなた';
  String get noEmail => 'メールなし';
  String get deleteTeam => 'チーム削除';
  String deleteTeamConfirm({required Object teamName}) =>
      '本当に「$teamName」を削除しますか？この操作は元に戻せません。このチームに関連するすべてのワークフロー、シークレット、環境変数が完全に削除されます。';
  String get deletedSuccess => 'チームが削除されました';
  String get cannotDeleteLastTeam => '最後のチームは削除できません。先に別のチームを作成してください。';
}

class AppStringsSubscription {
  AppStringsSubscription._();

  String get title => 'サブスクリプション';
  String get noOfferings => '利用可能なプランがありません';
  String get noPackages => '利用可能なパッケージがありません';
  String get plans => 'プラン';
  String get restorePurchases => '購入を復元';
  String get purchaseSuccess => '購入が完了しました！';
  String purchaseFailed({required Object error}) => '購入に失敗: $error';
  String get restoreSuccess => '購入が正常に復元されました';
  String restoreFailed({required Object error}) => '復元に失敗: $error';
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

class AppStringsAuthFirebaseForm {
  AppStringsAuthFirebaseForm._();

  String get title => '自分のFirebaseを使用';
  String get profileName => '接続先名';
  String get profileNameHint => '例：会社用、開発環境、本番環境';
  String get apiKey => 'APIキー';
  String get appId => 'アプリID';
  String get projectId => 'プロジェクトID';
  String get pickConfig => '設定を保存';
  String get profileSaved => '接続設定を保存しました。';
  String get requiredProfileFields =>
      '接続先名、APIサーバーURL、APIキー、アプリID、プロジェクトIDを入力してください。';
  String get invalidAppId => 'このプラットフォーム用の有効なFirebaseアプリIDを入力してください。';
  String get importFile => 'ファイルから読み込み';
  String get importFileHint =>
      'JSON (google-services.json) または plist (GoogleService-Info.plist)';
  String get invalidFile => '選択されたファイルを解析できませんでした。形式を確認してください。';
  String get fileLoaded => 'ファイルから設定を読み込みました。内容を確認して保存してください。';
  String get savedProjects => '保存済み接続先';
  String get active => '有効';
  String get useProject => 'この接続先を使用';

  String get setupSubtitle => 'APIサーバーとFirebaseプロジェクトを接続します。';
  String get setupPreview => '入力内容のプレビューです。まだ接続・登録・保存は行いません。';
  String get apiUrl => 'APIサーバーURL';
  String get apiUrlHint => '稼働中のセルフホストAPIサーバーのURL';
  String get invalidApiUrl => '有効なHTTPまたはHTTPSのURLを入力してください。';
  String get serviceAccount => 'サービスアカウントJSON';
  String get selectServiceAccount => 'JSONファイルを選択';
  String get replaceServiceAccount => '別のJSONファイルを選択';
  String get serviceAccountHint => 'Firebaseの「プロジェクトの設定 → サービスアカウント」から取得できます。';
  String get serviceAccountRequired => 'サービスアカウントJSONを選択してください。';
  String get invalidServiceAccount =>
      'サービスアカウントJSONを読み込めませんでした。google-services.jsonではなく、秘密鍵を含むサービスアカウントのファイルを選択してください。';
  String get removeServiceAccount => '選択したファイルを解除';
  String get credentialsNotSaved => 'サービスアカウントの秘密鍵は接続先に保存しません。';
  String get optionalProfileName => '接続先名（任意）';
  String get automaticProfileName => '未入力の場合はプロジェクトIDを使用します。';
  String get reviewSetup => '入力内容を確認';
  String get reviewTitle => '接続内容の確認';
  String get editSetup => '入力内容を編集';
  String get setupPlatforms => 'まとめて設定するプラットフォーム';
  String get setupExplanation =>
      '登録済みのアプリを再利用し、不足するアプリを登録して、各プラットフォームの設定を取得します。';
  String get startSetup => 'Firebase設定を取得して保存';
  String get manualSetup => '設定ファイルから手動で追加';
}
