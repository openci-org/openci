///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element

class Translations with BaseTranslations<AppLocale, Translations> {
  /// Returns the current translations of the given [context].
  ///
  /// Usage:
  /// final t = Translations.of(context);
  static Translations of(BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations({
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
             locale: AppLocale.en,
             overrides: overrides ?? {},
             cardinalResolver: cardinalResolver,
             ordinalResolver: ordinalResolver,
           ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  Translations $copyWith({
    TranslationMetadata<AppLocale, Translations>? meta,
  }) => Translations(meta: meta ?? this.$meta);

  // Translations
  late final Translations$common$en common = Translations$common$en.internal(
    _root,
  );
  late final Translations$auth$en auth = Translations$auth$en.internal(_root);
  late final Translations$secrets$en secrets = Translations$secrets$en.internal(
    _root,
  );
  late final Translations$settings$en settings =
      Translations$settings$en.internal(_root);
  late final Translations$team$en team = Translations$team$en.internal(_root);
  late final Translations$subscription$en subscription =
      Translations$subscription$en.internal(_root);
  late final Translations$logs$en logs = Translations$logs$en.internal(_root);
  late final Translations$billing$en billing = Translations$billing$en.internal(
    _root,
  );
  late final Translations$language$en language =
      Translations$language$en.internal(_root);
  late final Translations$connection$en connection =
      Translations$connection$en.internal(_root);
  late final Translations$config$en config = Translations$config$en.internal(
    _root,
  );
}

// Path: common
class Translations$common$en {
  Translations$common$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Save'
  String get save => 'Save';

  /// en: 'Cancel'
  String get cancel => 'Cancel';

  /// en: 'Delete'
  String get delete => 'Delete';

  /// en: 'Close'
  String get close => 'Close';

  /// en: 'Error: ${error}'
  String error({required Object error}) => 'Error: ${error}';

  /// en: 'Invite'
  String get invite => 'Invite';

  /// en: 'Retry'
  String get retry => 'Retry';

  /// en: 'Loading…'
  String get loading => 'Loading…';

  /// en: 'An error occurred'
  String get errorOccurred => 'An error occurred';

  /// en: 'Reload'
  String get reload => 'Reload';

  /// en: 'Could not connect. Check your network and try again.'
  String get networkFailed =>
      'Could not connect. Check your network and try again.';

  /// en: 'Could not complete the operation. Please try again.'
  String get operationFailed =>
      'Could not complete the operation. Please try again.';
}

// Path: auth
class Translations$auth$en {
  Translations$auth$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Sign in to your account'
  String get signInSubtitle => 'Sign in to your account';

  /// en: 'Email address'
  String get email => 'Email address';

  /// en: 'Password'
  String get password => 'Password';

  /// en: 'Sign in'
  String get login => 'Sign in';

  /// en: 'Create account'
  String get createAccount => 'Create account';

  /// en: 'Use your own Firebase'
  String get useYourFirebase => 'Use your own Firebase';

  /// en: 'I agree to the '
  String get agreePrefix => 'I agree to the ';

  /// en: 'Terms of Service'
  String get termsOfService => 'Terms of Service';

  /// en: 'Enter your email address'
  String get enterEmail => 'Enter your email address';

  /// en: 'Enter your password'
  String get enterPassword => 'Enter your password';

  late final Translations$auth$firebaseForm$en firebaseForm =
      Translations$auth$firebaseForm$en.internal(_root);

  /// en: 'Could not check your sign-in status.'
  String get stateError => 'Could not check your sign-in status.';

  /// en: 'Sign out and sign in again'
  String get signOutAndRetry => 'Sign out and sign in again';

  /// en: 'Convert your plist to XML format, then select GoogleService-Info.plist.'
  String get binaryPlistUnsupported =>
      'Convert your plist to XML format, then select GoogleService-Info.plist.';

  /// en: 'Select a JSON file (google-services.json) or a plist file (GoogleService-Info.plist).'
  String get unsupportedConfigFile =>
      'Select a JSON file (google-services.json) or a plist file (GoogleService-Info.plist).';

  /// en: 'Could not read the file: ${error}'
  String configFileReadFailed({required Object error}) =>
      'Could not read the file: ${error}';

  /// en: 'Check your email address and password.'
  String get invalidCredentials => 'Check your email address and password.';

  /// en: 'This email address is already registered. Please sign in.'
  String get emailInUse =>
      'This email address is already registered. Please sign in.';

  /// en: 'Choose a stronger password.'
  String get weakPassword => 'Choose a stronger password.';

  /// en: 'This account is disabled.'
  String get accountDisabled => 'This account is disabled.';

  /// en: 'Could not complete authentication. Please try again.'
  String get operationFailed =>
      'Could not complete authentication. Please try again.';

  /// en: 'Advanced options'
  String get advancedOptions => 'Advanced options';
}

// Path: secrets
class Translations$secrets$en {
  Translations$secrets$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'No secrets found'
  String get noSecrets => 'No secrets found';

  /// en: 'Add secret'
  String get addSecret => 'Add secret';

  /// en: 'Edit secret'
  String get editSecret => 'Edit secret';

  /// en: 'Secret name'
  String get secretName => 'Secret name';

  /// en: 'Secret value'
  String get secretValue => 'Secret value';

  /// en: 'New secret value (leave empty to keep the current value)'
  String get newSecretValue =>
      'New secret value (leave empty to keep the current value)';

  /// en: 'Enter a secret name'
  String get enterSecretName => 'Enter a secret name';

  /// en: 'Enter a secret value'
  String get enterSecretValue => 'Enter a secret value';

  /// en: 'Adding secret…'
  String get adding => 'Adding secret…';

  /// en: 'Secret added'
  String get addedSuccess => 'Secret added';

  /// en: 'Secret updated'
  String get updatedSuccess => 'Secret updated';

  /// en: 'Text'
  String get inputModeText => 'Text';

  /// en: 'File'
  String get inputModeFile => 'File';

  /// en: 'Upload a file'
  String get uploadFile => 'Upload a file';

  /// en: 'Click to select a file'
  String get orUploadFile => 'Click to select a file';

  /// en: 'Enter a value or upload a file'
  String get enterValueOrUpload => 'Enter a value or upload a file';

  /// en: 'Last updated'
  String get lastUpdated => 'Last updated';

  /// en: 'View secret value'
  String get viewSecretValue => 'View secret value';

  /// en: 'Secret value'
  String get secretValueTitle => 'Secret value';

  /// en: 'Loading secret value'
  String get secretValueLoading => 'Loading secret value';

  /// en: 'Copy secret value'
  String get copySecretValue => 'Copy secret value';

  /// en: 'Secret value copied'
  String get copiedSecretValue => 'Secret value copied';

  /// en: 'Secrets'
  String get title => 'Secrets';

  /// en: 'Loading secrets'
  String get loading => 'Loading secrets';

  /// en: 'File loaded'
  String get fileLoaded => 'File loaded';

  /// en: 'Leave the value empty to keep the current secret'
  String get keepCurrentValue =>
      'Leave the value empty to keep the current secret';

  /// en: 'iOS Code Signing'
  String get codeSigningTitle => 'iOS Code Signing';

  /// en: 'Generate a certificate private key for iOS builds. This is required for automatic code signing.'
  String get certificateExplanation =>
      'Generate a certificate private key for iOS builds. This is required for automatic code signing.';

  /// en: 'Certificate key generated'
  String get certificateGenerated => 'Certificate key generated';

  /// en: 'Generate certificate key'
  String get generateCertificate => 'Generate certificate key';

  /// en: 'Sign in to manage secrets.'
  String get signInRequired => 'Sign in to manage secrets.';

  /// en: 'Your account or team has changed. Please try again.'
  String get contextChanged =>
      'Your account or team has changed. Please try again.';

  /// en: 'Check the secret name and value.'
  String get invalidInput => 'Check the secret name and value.';

  /// en: 'Secret not found. Please reload.'
  String get notFound => 'Secret not found. Please reload.';

  /// en: 'Delete this secret?'
  String get deleteConfirm => 'Delete this secret?';

  /// en: 'Secret deleted'
  String get deletedSuccess => 'Secret deleted';
}

// Path: settings
class Translations$settings$en {
  Translations$settings$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Settings'
  String get title => 'Settings';

  /// en: 'Preferences'
  String get preferences => 'Preferences';

  /// en: 'Email verification'
  String get emailVerification => 'Email verification';

  /// en: 'Verified'
  String get emailVerified => 'Verified';

  /// en: 'Verify your email address to join other teams. Follow the instructions in the verification email.'
  String get emailVerificationRequired =>
      'Verify your email address to join other teams. Follow the instructions in the verification email.';

  /// en: 'Send verification email'
  String get sendVerificationEmail => 'Send verification email';

  /// en: 'Check verification status'
  String get refreshEmailVerification => 'Check verification status';

  /// en: 'Verification email sent. Check your inbox.'
  String get verificationEmailSent =>
      'Verification email sent. Check your inbox.';

  /// en: 'Your email address is still unverified. Follow the link in the verification email.'
  String get emailStillUnverified =>
      'Your email address is still unverified. Follow the link in the verification email.';

  /// en: 'Could not verify your email address. Please try again.'
  String get emailVerificationFailed =>
      'Could not verify your email address. Please try again.';

  /// en: 'Too many requests. Please try again later.'
  String get emailVerificationRateLimited =>
      'Too many requests. Please try again later.';

  /// en: 'Check for updates'
  String get checkForUpdates => 'Check for updates';

  /// en: 'Check for a new version of the macOS app'
  String get checkForUpdatesDescription =>
      'Check for a new version of the macOS app';

  /// en: 'Could not check for updates: ${error}'
  String checkForUpdatesFailed({required Object error}) =>
      'Could not check for updates: ${error}';

  /// en: 'Subscription'
  String get subscription => 'Subscription';

  /// en: 'Manage your subscription plan'
  String get manageSubscription => 'Manage your subscription plan';

  /// en: 'Return to OpenCI Cloud'
  String get returnToCloud => 'Return to OpenCI Cloud';

  /// en: 'App version'
  String get appVersion => 'App version';

  /// en: 'Sign out'
  String get logout => 'Sign out';

  /// en: 'Signed out'
  String get logoutSuccess => 'Signed out';

  /// en: 'Could not sign out: ${error}'
  String logoutFailed({required Object error}) =>
      'Could not sign out: ${error}';

  /// en: 'Delete account'
  String get deleteAccount => 'Delete account';

  /// en: 'Delete account'
  String get deleteConfirmTitle => 'Delete account';

  /// en: 'Delete your account? This action is permanent and will delete all your data.'
  String get deleteConfirmMessage =>
      'Delete your account? This action is permanent and will delete all your data.';

  /// en: 'Account deleted'
  String get deleteSuccess => 'Account deleted';

  /// en: 'No user is currently signed in'
  String get noUserSignedIn => 'No user is currently signed in';

  /// en: 'Sign out and sign in again before deleting your account.'
  String get requiresRecentLogin =>
      'Sign out and sign in again before deleting your account.';

  /// en: 'Could not delete your account: ${error}'
  String deleteFailed({required Object error}) =>
      'Could not delete your account: ${error}';

  /// en: 'Manage billing'
  String get manageBilling => 'Manage billing';

  /// en: 'Team plan, invoices, and payment methods'
  String get billingDescription => 'Team plan, invoices, and payment methods';

  /// en: 'Checking for updates…'
  String get checkingUpdates => 'Checking for updates…';

  /// en: 'Team'
  String get teamSection => 'Team';

  /// en: 'Account'
  String get account => 'Account';

  /// en: 'Sign out of your current account'
  String get logoutDescription => 'Sign out of your current account';

  /// en: 'An update is available'
  String get updateAvailable => 'An update is available';

  /// en: 'An update is available: v${version}'
  String updateVersionAvailable({required Object version}) =>
      'An update is available: v${version}';

  /// en: 'You are up to date'
  String get noUpdate => 'You are up to date';

  /// en: 'Could not check for updates'
  String get updateCheckFailed => 'Could not check for updates';

  /// en: 'Could not load team details'
  String get teamLoadFailed => 'Could not load team details';
}

// Path: team
class Translations$team$en {
  Translations$team$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Edit team'
  String get editTeam => 'Edit team';

  /// en: 'Create team'
  String get createTeam => 'Create team';

  /// en: 'Team name'
  String get teamName => 'Team name';

  /// en: 'New team name'
  String get newTeamName => 'New team name';

  /// en: 'Select a team'
  String get selectTeam => 'Select a team';

  /// en: 'Team'
  String get selectTeamLabel => 'Team';

  /// en: 'Connect GitHub'
  String get connectGitHub => 'Connect GitHub';

  /// en: 'Could not start the GitHub connection. Please try again.'
  String get gitHubConnectionFailed =>
      'Could not start the GitHub connection. Please try again.';

  /// en: 'GitHub authorization verified. Confirm below to connect it to your team.'
  String get gitHubConnectionVerified =>
      'GitHub authorization verified. Confirm below to connect it to your team.';

  /// en: 'Available GitHub accounts'
  String get gitHubConnectionCandidates => 'Available GitHub accounts';

  /// en: 'No available GitHub accounts found. Check the GitHub App installation and permissions, then try connecting again.'
  String get gitHubConnectionNoCandidates =>
      'No available GitHub accounts found. Check the GitHub App installation and permissions, then try connecting again.';

  /// en: 'Open GitHub App installation settings'
  String get gitHubAppInstallation => 'Open GitHub App installation settings';

  /// en: 'The GitHub App installation link is unavailable. Ask your OpenCI server administrator to check the configuration.'
  String get gitHubAppInstallationUrlUnavailable =>
      'The GitHub App installation link is unavailable. Ask your OpenCI server administrator to check the configuration.';

  /// en: 'Could not open the GitHub App page. Please try again.'
  String get gitHubAppInstallationOpenFailed =>
      'Could not open the GitHub App page. Please try again.';

  /// en: 'Team to connect: ${name}'
  String gitHubConnectionTeam({required Object name}) =>
      'Team to connect: ${name}';

  /// en: 'Confirm connection'
  String get gitHubConnectionConfirm => 'Confirm connection';

  /// en: 'Connecting…'
  String get gitHubConnectionConfirming => 'Connecting…';

  /// en: 'GitHub connected'
  String get gitHubConnectionCompleted => 'GitHub connected';

  /// en: 'Could not confirm the GitHub connection. Please try again.'
  String get gitHubConnectionConfirmFailed =>
      'Could not confirm the GitHub connection. Please try again.';

  /// en: 'GitHub authorization was cancelled.'
  String get gitHubConnectionCancelled => 'GitHub authorization was cancelled.';

  /// en: 'Could not resume the connection. Close this page and try again from the team screen.'
  String get gitHubConnectionRestartRequired =>
      'Could not resume the connection. Close this page and try again from the team screen.';

  /// en: 'Could not verify the GitHub connection. Close this page and try again.'
  String get gitHubConnectionCheckFailed =>
      'Could not verify the GitHub connection. Close this page and try again.';

  /// en: 'Enter a team name'
  String get enterTeamName => 'Enter a team name';

  /// en: 'Team created'
  String get createdSuccess => 'Team created';

  /// en: 'Team name updated'
  String get updatedSuccess => 'Team name updated';

  /// en: 'Team selected'
  String get selectedSuccess => 'Team selected';

  /// en: 'Invite a team member'
  String get inviteTitle => 'Invite a team member';

  /// en: 'Email address'
  String get inviteEmail => 'Email address';

  /// en: 'Enter an email address'
  String get enterEmail => 'Enter an email address';

  /// en: 'Member added to the team'
  String get addedSuccess => 'Member added to the team';

  /// en: 'Remove member'
  String get removeMember => 'Remove member';

  /// en: 'Remove ${name} from ${teamName}?'
  String removeMemberConfirm({
    required Object name,
    required Object teamName,
  }) => 'Remove ${name} from ${teamName}?';

  /// en: 'Member removed from the team'
  String get removedSuccess => 'Member removed from the team';

  /// en: 'Cannot access this team. Check your sign-in and connection settings.'
  String get accessDenied =>
      'Cannot access this team. Check your sign-in and connection settings.';

  /// en: 'This user is already a member of the team.'
  String get memberAlreadyAdded => 'This user is already a member of the team.';

  /// en: 'Ask this user to create a Dashboard account first.'
  String get memberNotRegistered =>
      'Ask this user to create a Dashboard account first.';

  /// en: 'This user has not verified their email address. Ask them to complete email verification under Settings → Account in the Dashboard, then try again.'
  String get memberEmailNotVerified =>
      'This user has not verified their email address. Ask them to complete email verification under Settings → Account in the Dashboard, then try again.';

  /// en: 'This account is unavailable.'
  String get memberUnavailable => 'This account is unavailable.';

  /// en: 'Enter a valid email address.'
  String get enterValidEmail => 'Enter a valid email address.';

  /// en: 'Could not complete the team operation. Please try again.'
  String get operationFailed =>
      'Could not complete the team operation. Please try again.';

  /// en: 'Members'
  String get members => 'Members';

  /// en: '(one) {${count} member} (other) {${count} members}'
  String membersCount({required num count}) =>
      (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
        count,
        one: '${count} member',
        other: '${count} members',
      );

  /// en: 'You'
  String get you => 'You';

  /// en: 'No email'
  String get noEmail => 'No email';

  /// en: 'Delete team'
  String get deleteTeam => 'Delete team';

  /// en: 'Delete ${teamName}? This action is permanent and will delete all workflows, secrets, and environment variables associated with this team.'
  String deleteTeamConfirm({required Object teamName}) =>
      'Delete ${teamName}? This action is permanent and will delete all workflows, secrets, and environment variables associated with this team.';

  /// en: 'Team deleted'
  String get deletedSuccess => 'Team deleted';

  /// en: 'Create another team before deleting your last team.'
  String get cannotDeleteLastTeam =>
      'Create another team before deleting your last team.';
}

// Path: subscription
class Translations$subscription$en {
  Translations$subscription$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Subscription'
  String get title => 'Subscription';

  /// en: 'No plans available'
  String get noOfferings => 'No plans available';

  /// en: 'No packages available'
  String get noPackages => 'No packages available';

  /// en: 'Plans'
  String get plans => 'Plans';

  /// en: 'Restore purchases'
  String get restorePurchases => 'Restore purchases';

  /// en: 'Purchase completed!'
  String get purchaseSuccess => 'Purchase completed!';

  /// en: 'Purchase failed: ${error}'
  String purchaseFailed({required Object error}) => 'Purchase failed: ${error}';

  /// en: 'Purchases restored'
  String get restoreSuccess => 'Purchases restored';

  /// en: 'Could not restore purchases: ${error}'
  String restoreFailed({required Object error}) =>
      'Could not restore purchases: ${error}';

  /// en: 'Active subscription'
  String get activeSubscription => 'Active subscription';

  /// en: 'Active'
  String get active => 'Active';

  /// en: 'Terms of Use'
  String get termsOfUse => 'Terms of Use';

  /// en: 'Privacy Policy'
  String get privacyPolicy => 'Privacy Policy';

  /// en: 'Your subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours before the current period ends. After purchase, you can manage or cancel your subscription in your App Store account settings.'
  String get subscriptionTerms =>
      'Your subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours before the current period ends. After purchase, you can manage or cancel your subscription in your App Store account settings.';

  /// en: 'Your subscription renews automatically unless cancelled before the current billing period ends. You can manage or cancel your subscription in your account settings. Payments are securely processed by Stripe.'
  String get subscriptionTermsWeb =>
      'Your subscription renews automatically unless cancelled before the current billing period ends. You can manage or cancel your subscription in your account settings. Payments are securely processed by Stripe.';

  /// en: 'per week'
  String get perWeek => 'per week';

  /// en: 'per month'
  String get perMonth => 'per month';

  /// en: 'every 3 months'
  String get per3Months => 'every 3 months';

  /// en: 'every 6 months'
  String get per6Months => 'every 6 months';

  /// en: 'per year'
  String get perYear => 'per year';
}

// Path: logs
class Translations$logs$en {
  Translations$logs$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'CI/CD logs'
  String get title => 'CI/CD logs';

  /// en: 'No active CI/CD logs'
  String get empty => 'No active CI/CD logs';

  /// en: 'Could not load logs: ${error}'
  String loadFailed({required Object error}) => 'Could not load logs: ${error}';

  /// en: 'Build job not found'
  String get jobNotFound => 'Build job not found';

  /// en: 'CI/CD log details'
  String get detailTitle => 'CI/CD log details';

  /// en: 'Copy all logs'
  String get copyAll => 'Copy all logs';

  /// en: 'No logs to copy'
  String get nothingToCopy => 'No logs to copy';

  /// en: 'All logs copied to the clipboard'
  String get copiedAll => 'All logs copied to the clipboard';

  /// en: 'Could not copy logs: ${error}'
  String copyFailed({required Object error}) => 'Could not copy logs: ${error}';

  /// en: 'No log steps'
  String get noSteps => 'No log steps';

  /// en: 'Build failure reason'
  String get failureReason => 'Build failure reason';

  /// en: 'No logs available. Logs from before the migration or beyond the retention period are unavailable.'
  String get unavailable =>
      'No logs available. Logs from before the migration or beyond the retention period are unavailable.';

  /// en: 'Copy logs'
  String get copy => 'Copy logs';

  /// en: 'Logs copied to the clipboard'
  String get copied => 'Logs copied to the clipboard';

  /// en: '${minutes}m ${seconds}s'
  String durationMinutesSeconds({
    required Object minutes,
    required Object seconds,
  }) => '${minutes}m ${seconds}s';

  /// en: '${seconds}s'
  String durationSeconds({required Object seconds}) => '${seconds}s';
}

// Path: billing
class Translations$billing$en {
  Translations$billing$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Billing'
  String get title => 'Billing';

  /// en: 'Sign in to Cloud to use this page.'
  String get signInRequired => 'Sign in to Cloud to use this page.';

  /// en: 'Could not load teams.'
  String get teamLoadFailed => 'Could not load teams.';

  /// en: 'Cannot access this team. Check your team selection in the dashboard.'
  String get teamAccessDenied =>
      'Cannot access this team. Check your team selection in the dashboard.';

  /// en: 'Billing is currently unavailable for this connection.'
  String get disabled =>
      'Billing is currently unavailable for this connection.';

  /// en: 'You have returned from Stripe. Changes may take a moment to appear. Select Reload if needed.'
  String get returnedFromStripe =>
      'You have returned from Stripe. Changes may take a moment to appear. Select Reload if needed.';

  /// en: 'CI is available'
  String get ciAvailable => 'CI is available';

  /// en: 'Monthly billing for CI usage'
  String get monthlyPostpaid => 'Monthly billing for CI usage';

  /// en: 'CI costs ¥1 per minute, including tax. Usage is totaled monthly and automatically charged to your registered card the following month.'
  String get monthlyExplanation =>
      'CI costs ¥1 per minute, including tax. Usage is totaled monthly and automatically charged to your registered card the following month.';

  /// en: 'Continue card setup'
  String get continueCardSetup => 'Continue card setup';

  /// en: 'Add payment method'
  String get setupCard => 'Add payment method';

  /// en: 'A card is registered for monthly billing.'
  String get cardRegistered => 'A card is registered for monthly billing.';

  /// en: 'Open Payment methods and billing history to set up a billing card.'
  String get setCardInPortal =>
      'Open Payment methods and billing history to set up a billing card.';

  /// en: 'Payment methods and billing history'
  String get openPortal => 'Payment methods and billing history';

  /// en: 'Usage this month (${month})'
  String monthlyUsage({required Object month}) => 'Usage this month (${month})';

  /// en: 'Usage: ${minutes} minutes'
  String minutes({required Object minutes}) => 'Usage: ${minutes} minutes';

  /// en: 'Estimated total including tax: ¥${amount}'
  String estimatedAmount({required Object amount}) =>
      'Estimated total including tax: ¥${amount}';

  /// en: 'Next invoice date: ${date} (Japan time)'
  String nextInvoiceDate({required Object date}) =>
      'Next invoice date: ${date} (Japan time)';

  /// en: 'The amount billed in USD is finalized by converting the yen usage total at month-end.'
  String get usdExplanation =>
      'The amount billed in USD is finalized by converting the yen usage total at month-end.';

  /// en: 'Could not load usage for this month. Select Reload to try again.'
  String get usageUnavailable =>
      'Could not load usage for this month. Select Reload to try again.';

  /// en: 'Preparing to open Stripe…'
  String get openingStripe => 'Preparing to open Stripe…';

  /// en: 'Agree to monthly billing?'
  String get consentTitle => 'Agree to monthly billing?';

  /// en: 'CI usage for team ${teamName} costs ¥1 per minute, including tax. Monthly usage is automatically charged to your registered card the following month. Registering a card costs ¥0.'
  String consentMessage({required Object teamName}) =>
      'CI usage for team ${teamName} costs ¥1 per minute, including tax. Monthly usage is automatically charged to your registered card the following month. Registering a card costs ¥0.';

  /// en: 'Agree and continue to Stripe'
  String get agreeAndContinue => 'Agree and continue to Stripe';

  /// en: 'Register a billing card for this team to start CI.'
  String get paymentRequired =>
      'Register a billing card for this team to start CI.';

  /// en: 'No usage allowance is available to start a new CI run.'
  String get allowanceExhausted =>
      'No usage allowance is available to start a new CI run.';

  /// en: 'Your subscription has ended.'
  String get subscriptionEnded => 'Your subscription has ended.';

  /// en: 'Waiting for card setup to complete.'
  String get paymentPending => 'Waiting for card setup to complete.';

  /// en: 'CI is currently unavailable. Wait a moment and reload.'
  String get ciUnavailable =>
      'CI is currently unavailable. Wait a moment and reload.';

  /// en: 'Please sign in again.'
  String get authenticationRequired => 'Please sign in again.';

  /// en: 'Cannot access billing information for this team.'
  String get forbidden => 'Cannot access billing information for this team.';

  /// en: 'Reload the latest pricing terms and confirm your agreement again.'
  String get cardConsentRequired =>
      'Reload the latest pricing terms and confirm your agreement again.';

  /// en: 'Your connection or account has changed. Reopen this page.'
  String get contextChanged =>
      'Your connection or account has changed. Reopen this page.';

  /// en: 'A subscription already exists. Reload to check its details.'
  String get subscriptionExists =>
      'A subscription already exists. Reload to check its details.';

  /// en: 'Your payment is being checked. Wait a moment and reload.'
  String get checkoutPending =>
      'Your payment is being checked. Wait a moment and reload.';

  /// en: 'No subscription is available to manage. Please reload.'
  String get customerMissing =>
      'No subscription is available to manage. Please reload.';

  /// en: 'Could not open Stripe. Please try again.'
  String get launchFailed => 'Could not open Stripe. Please try again.';

  /// en: 'Could not complete the billing operation. Please try again later.'
  String get operationFailed =>
      'Could not complete the billing operation. Please try again later.';
}

// Path: language
class Translations$language$en {
  Translations$language$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Language'
  String get label => 'Language';

  /// en: 'System default'
  String get system => 'System default';

  /// en: 'Could not save your language preference. Please try again.'
  String get saveFailed =>
      'Could not save your language preference. Please try again.';
}

// Path: connection
class Translations$connection$en {
  Translations$connection$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Could not save connection settings.'
  String get saveFailed => 'Could not save connection settings.';

  /// en: 'This connection ID already uses different Firebase settings. Register a new connection.'
  String get configMismatch =>
      'This connection ID already uses different Firebase settings. Register a new connection.';

  /// en: 'Firebase settings for ${platform} are missing from ${name}.'
  String platformConfigMissing({
    required Object platform,
    required Object name,
  }) => 'Firebase settings for ${platform} are missing from ${name}.';
}

// Path: config
class Translations$config$en {
  Translations$config$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Could not parse JSON: ${error}'
  String jsonParseFailed({required Object error}) =>
      'Could not parse JSON: ${error}';

  /// en: 'Could not parse XML: ${error}'
  String xmlParseFailed({required Object error}) =>
      'Could not parse XML: ${error}';

  /// en: 'Required keys are missing from ${file}: ${keys}'
  String missingKeys({required Object file, required Object keys}) =>
      'Required keys are missing from ${file}: ${keys}';

  /// en: 'Select a Firebase web configuration JSON file, an Android google-services.json file, or an iOS GoogleService-Info.plist file.'
  String get unsupportedFormat =>
      'Select a Firebase web configuration JSON file, an Android google-services.json file, or an iOS GoogleService-Info.plist file.';

  /// en: 'No <dict> element found in the plist.'
  String get plistDictMissing => 'No <dict> element found in the plist.';
}

// Path: auth.firebaseForm
class Translations$auth$firebaseForm$en {
  Translations$auth$firebaseForm$en.internal(this._root);

  final Translations _root; // ignore: unused_field

  // Translations

  /// en: 'Use your own Firebase'
  String get title => 'Use your own Firebase';

  /// en: 'Connection name'
  String get profileName => 'Connection name';

  /// en: 'e.g. Work, Development, Production'
  String get profileNameHint => 'e.g. Work, Development, Production';

  /// en: 'API key'
  String get apiKey => 'API key';

  /// en: 'App ID'
  String get appId => 'App ID';

  /// en: 'Project ID'
  String get projectId => 'Project ID';

  /// en: 'Save configuration'
  String get pickConfig => 'Save configuration';

  /// en: 'Connection settings saved.'
  String get profileSaved => 'Connection settings saved.';

  /// en: 'Enter a connection name, API server URL, API key, app ID, and project ID.'
  String get requiredProfileFields =>
      'Enter a connection name, API server URL, API key, app ID, and project ID.';

  /// en: 'Enter a valid Firebase app ID for this platform.'
  String get invalidAppId => 'Enter a valid Firebase app ID for this platform.';

  /// en: 'Import from file'
  String get importFile => 'Import from file';

  /// en: 'JSON (google-services.json) or plist (GoogleService-Info.plist)'
  String get importFileHint =>
      'JSON (google-services.json) or plist (GoogleService-Info.plist)';

  /// en: 'Could not parse the selected file. Check its format.'
  String get invalidFile =>
      'Could not parse the selected file. Check its format.';

  /// en: 'Configuration loaded. Review the details and save.'
  String get fileLoaded => 'Configuration loaded. Review the details and save.';

  /// en: 'Saved connections'
  String get savedProjects => 'Saved connections';

  /// en: 'Active'
  String get active => 'Active';

  /// en: 'Use this connection'
  String get useProject => 'Use this connection';

  /// en: 'Connect your API server and Firebase project.'
  String get setupSubtitle => 'Connect your API server and Firebase project.';

  /// en: 'Review the entered details before connecting, registering apps, or saving.'
  String get setupPreview =>
      'Review the entered details before connecting, registering apps, or saving.';

  /// en: 'API server URL'
  String get apiUrl => 'API server URL';

  /// en: 'URL of your running self-hosted API server'
  String get apiUrlHint => 'URL of your running self-hosted API server';

  /// en: 'Enter a valid HTTP or HTTPS URL.'
  String get invalidApiUrl => 'Enter a valid HTTP or HTTPS URL.';

  /// en: 'Service account JSON'
  String get serviceAccount => 'Service account JSON';

  /// en: 'Select a JSON file'
  String get selectServiceAccount => 'Select a JSON file';

  /// en: 'Select another JSON file'
  String get replaceServiceAccount => 'Select another JSON file';

  /// en: 'Download it from Project settings → Service accounts in Firebase.'
  String get serviceAccountHint =>
      'Download it from Project settings → Service accounts in Firebase.';

  /// en: 'Select a service account JSON file.'
  String get serviceAccountRequired => 'Select a service account JSON file.';

  /// en: 'Could not read the service account JSON. Select a service account file containing a private key.'
  String get invalidServiceAccount =>
      'Could not read the service account JSON. Select a service account file containing a private key.';

  /// en: 'Remove selected file'
  String get removeServiceAccount => 'Remove selected file';

  /// en: 'The service account private key will not be saved in the connection profile.'
  String get credentialsNotSaved =>
      'The service account private key will not be saved in the connection profile.';

  /// en: 'Connection name (optional)'
  String get optionalProfileName => 'Connection name (optional)';

  /// en: 'Defaults to the project ID.'
  String get automaticProfileName => 'Defaults to the project ID.';

  /// en: 'Review details'
  String get reviewSetup => 'Review details';

  /// en: 'Review connection'
  String get reviewTitle => 'Review connection';

  /// en: 'Edit details'
  String get editSetup => 'Edit details';

  /// en: 'Platforms to configure'
  String get setupPlatforms => 'Platforms to configure';

  /// en: 'Reuse registered apps, register any missing apps, and fetch the configuration for each platform.'
  String get setupExplanation =>
      'Reuse registered apps, register any missing apps, and fetch the configuration for each platform.';

  /// en: 'Fetch and save Firebase configuration'
  String get startSetup => 'Fetch and save Firebase configuration';

  /// en: 'Add manually from a configuration file'
  String get manualSetup => 'Add manually from a configuration file';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
  dynamic _flatMapFunction(String path) {
    return switch (path) {
      'common.save' => 'Save',
      'common.cancel' => 'Cancel',
      'common.delete' => 'Delete',
      'common.close' => 'Close',
      'common.error' => ({required Object error}) => 'Error: ${error}',
      'common.invite' => 'Invite',
      'common.retry' => 'Retry',
      'common.loading' => 'Loading…',
      'common.errorOccurred' => 'An error occurred',
      'common.reload' => 'Reload',
      'common.networkFailed' =>
        'Could not connect. Check your network and try again.',
      'common.operationFailed' =>
        'Could not complete the operation. Please try again.',
      'auth.signInSubtitle' => 'Sign in to your account',
      'auth.email' => 'Email address',
      'auth.password' => 'Password',
      'auth.login' => 'Sign in',
      'auth.createAccount' => 'Create account',
      'auth.useYourFirebase' => 'Use your own Firebase',
      'auth.agreePrefix' => 'I agree to the ',
      'auth.termsOfService' => 'Terms of Service',
      'auth.enterEmail' => 'Enter your email address',
      'auth.enterPassword' => 'Enter your password',
      'auth.firebaseForm.title' => 'Use your own Firebase',
      'auth.firebaseForm.profileName' => 'Connection name',
      'auth.firebaseForm.profileNameHint' =>
        'e.g. Work, Development, Production',
      'auth.firebaseForm.apiKey' => 'API key',
      'auth.firebaseForm.appId' => 'App ID',
      'auth.firebaseForm.projectId' => 'Project ID',
      'auth.firebaseForm.pickConfig' => 'Save configuration',
      'auth.firebaseForm.profileSaved' => 'Connection settings saved.',
      'auth.firebaseForm.requiredProfileFields' =>
        'Enter a connection name, API server URL, API key, app ID, and project ID.',
      'auth.firebaseForm.invalidAppId' =>
        'Enter a valid Firebase app ID for this platform.',
      'auth.firebaseForm.importFile' => 'Import from file',
      'auth.firebaseForm.importFileHint' =>
        'JSON (google-services.json) or plist (GoogleService-Info.plist)',
      'auth.firebaseForm.invalidFile' =>
        'Could not parse the selected file. Check its format.',
      'auth.firebaseForm.fileLoaded' =>
        'Configuration loaded. Review the details and save.',
      'auth.firebaseForm.savedProjects' => 'Saved connections',
      'auth.firebaseForm.active' => 'Active',
      'auth.firebaseForm.useProject' => 'Use this connection',
      'auth.firebaseForm.setupSubtitle' =>
        'Connect your API server and Firebase project.',
      'auth.firebaseForm.setupPreview' =>
        'Review the entered details before connecting, registering apps, or saving.',
      'auth.firebaseForm.apiUrl' => 'API server URL',
      'auth.firebaseForm.apiUrlHint' =>
        'URL of your running self-hosted API server',
      'auth.firebaseForm.invalidApiUrl' => 'Enter a valid HTTP or HTTPS URL.',
      'auth.firebaseForm.serviceAccount' => 'Service account JSON',
      'auth.firebaseForm.selectServiceAccount' => 'Select a JSON file',
      'auth.firebaseForm.replaceServiceAccount' => 'Select another JSON file',
      'auth.firebaseForm.serviceAccountHint' =>
        'Download it from Project settings → Service accounts in Firebase.',
      'auth.firebaseForm.serviceAccountRequired' =>
        'Select a service account JSON file.',
      'auth.firebaseForm.invalidServiceAccount' =>
        'Could not read the service account JSON. Select a service account file containing a private key.',
      'auth.firebaseForm.removeServiceAccount' => 'Remove selected file',
      'auth.firebaseForm.credentialsNotSaved' =>
        'The service account private key will not be saved in the connection profile.',
      'auth.firebaseForm.optionalProfileName' => 'Connection name (optional)',
      'auth.firebaseForm.automaticProfileName' => 'Defaults to the project ID.',
      'auth.firebaseForm.reviewSetup' => 'Review details',
      'auth.firebaseForm.reviewTitle' => 'Review connection',
      'auth.firebaseForm.editSetup' => 'Edit details',
      'auth.firebaseForm.setupPlatforms' => 'Platforms to configure',
      'auth.firebaseForm.setupExplanation' =>
        'Reuse registered apps, register any missing apps, and fetch the configuration for each platform.',
      'auth.firebaseForm.startSetup' => 'Fetch and save Firebase configuration',
      'auth.firebaseForm.manualSetup' =>
        'Add manually from a configuration file',
      'auth.stateError' => 'Could not check your sign-in status.',
      'auth.signOutAndRetry' => 'Sign out and sign in again',
      'auth.binaryPlistUnsupported' =>
        'Convert your plist to XML format, then select GoogleService-Info.plist.',
      'auth.unsupportedConfigFile' =>
        'Select a JSON file (google-services.json) or a plist file (GoogleService-Info.plist).',
      'auth.configFileReadFailed' =>
        ({required Object error}) => 'Could not read the file: ${error}',
      'auth.invalidCredentials' => 'Check your email address and password.',
      'auth.emailInUse' =>
        'This email address is already registered. Please sign in.',
      'auth.weakPassword' => 'Choose a stronger password.',
      'auth.accountDisabled' => 'This account is disabled.',
      'auth.operationFailed' =>
        'Could not complete authentication. Please try again.',
      'auth.advancedOptions' => 'Advanced options',
      'secrets.noSecrets' => 'No secrets found',
      'secrets.addSecret' => 'Add secret',
      'secrets.editSecret' => 'Edit secret',
      'secrets.secretName' => 'Secret name',
      'secrets.secretValue' => 'Secret value',
      'secrets.newSecretValue' =>
        'New secret value (leave empty to keep the current value)',
      'secrets.enterSecretName' => 'Enter a secret name',
      'secrets.enterSecretValue' => 'Enter a secret value',
      'secrets.adding' => 'Adding secret…',
      'secrets.addedSuccess' => 'Secret added',
      'secrets.updatedSuccess' => 'Secret updated',
      'secrets.inputModeText' => 'Text',
      'secrets.inputModeFile' => 'File',
      'secrets.uploadFile' => 'Upload a file',
      'secrets.orUploadFile' => 'Click to select a file',
      'secrets.enterValueOrUpload' => 'Enter a value or upload a file',
      'secrets.lastUpdated' => 'Last updated',
      'secrets.viewSecretValue' => 'View secret value',
      'secrets.secretValueTitle' => 'Secret value',
      'secrets.secretValueLoading' => 'Loading secret value',
      'secrets.copySecretValue' => 'Copy secret value',
      'secrets.copiedSecretValue' => 'Secret value copied',
      'secrets.title' => 'Secrets',
      'secrets.loading' => 'Loading secrets',
      'secrets.fileLoaded' => 'File loaded',
      'secrets.keepCurrentValue' =>
        'Leave the value empty to keep the current secret',
      'secrets.codeSigningTitle' => 'iOS Code Signing',
      'secrets.certificateExplanation' =>
        'Generate a certificate private key for iOS builds. This is required for automatic code signing.',
      'secrets.certificateGenerated' => 'Certificate key generated',
      'secrets.generateCertificate' => 'Generate certificate key',
      'secrets.signInRequired' => 'Sign in to manage secrets.',
      'secrets.contextChanged' =>
        'Your account or team has changed. Please try again.',
      'secrets.invalidInput' => 'Check the secret name and value.',
      'secrets.notFound' => 'Secret not found. Please reload.',
      'secrets.deleteConfirm' => 'Delete this secret?',
      'secrets.deletedSuccess' => 'Secret deleted',
      'settings.title' => 'Settings',
      'settings.preferences' => 'Preferences',
      'settings.emailVerification' => 'Email verification',
      'settings.emailVerified' => 'Verified',
      'settings.emailVerificationRequired' =>
        'Verify your email address to join other teams. Follow the instructions in the verification email.',
      'settings.sendVerificationEmail' => 'Send verification email',
      'settings.refreshEmailVerification' => 'Check verification status',
      'settings.verificationEmailSent' =>
        'Verification email sent. Check your inbox.',
      'settings.emailStillUnverified' =>
        'Your email address is still unverified. Follow the link in the verification email.',
      'settings.emailVerificationFailed' =>
        'Could not verify your email address. Please try again.',
      'settings.emailVerificationRateLimited' =>
        'Too many requests. Please try again later.',
      'settings.checkForUpdates' => 'Check for updates',
      'settings.checkForUpdatesDescription' =>
        'Check for a new version of the macOS app',
      'settings.checkForUpdatesFailed' =>
        ({required Object error}) => 'Could not check for updates: ${error}',
      'settings.subscription' => 'Subscription',
      'settings.manageSubscription' => 'Manage your subscription plan',
      'settings.returnToCloud' => 'Return to OpenCI Cloud',
      'settings.appVersion' => 'App version',
      'settings.logout' => 'Sign out',
      'settings.logoutSuccess' => 'Signed out',
      'settings.logoutFailed' =>
        ({required Object error}) => 'Could not sign out: ${error}',
      'settings.deleteAccount' => 'Delete account',
      'settings.deleteConfirmTitle' => 'Delete account',
      'settings.deleteConfirmMessage' =>
        'Delete your account? This action is permanent and will delete all your data.',
      'settings.deleteSuccess' => 'Account deleted',
      'settings.noUserSignedIn' => 'No user is currently signed in',
      'settings.requiresRecentLogin' =>
        'Sign out and sign in again before deleting your account.',
      'settings.deleteFailed' =>
        ({required Object error}) => 'Could not delete your account: ${error}',
      'settings.manageBilling' => 'Manage billing',
      'settings.billingDescription' =>
        'Team plan, invoices, and payment methods',
      'settings.checkingUpdates' => 'Checking for updates…',
      'settings.teamSection' => 'Team',
      'settings.account' => 'Account',
      'settings.logoutDescription' => 'Sign out of your current account',
      'settings.updateAvailable' => 'An update is available',
      'settings.updateVersionAvailable' =>
        ({required Object version}) => 'An update is available: v${version}',
      'settings.noUpdate' => 'You are up to date',
      'settings.updateCheckFailed' => 'Could not check for updates',
      'settings.teamLoadFailed' => 'Could not load team details',
      'team.editTeam' => 'Edit team',
      'team.createTeam' => 'Create team',
      'team.teamName' => 'Team name',
      'team.newTeamName' => 'New team name',
      'team.selectTeam' => 'Select a team',
      'team.selectTeamLabel' => 'Team',
      'team.connectGitHub' => 'Connect GitHub',
      'team.gitHubConnectionFailed' =>
        'Could not start the GitHub connection. Please try again.',
      'team.gitHubConnectionVerified' =>
        'GitHub authorization verified. Confirm below to connect it to your team.',
      'team.gitHubConnectionCandidates' => 'Available GitHub accounts',
      'team.gitHubConnectionNoCandidates' =>
        'No available GitHub accounts found. Check the GitHub App installation and permissions, then try connecting again.',
      'team.gitHubAppInstallation' => 'Open GitHub App installation settings',
      'team.gitHubAppInstallationUrlUnavailable' =>
        'The GitHub App installation link is unavailable. Ask your OpenCI server administrator to check the configuration.',
      'team.gitHubAppInstallationOpenFailed' =>
        'Could not open the GitHub App page. Please try again.',
      'team.gitHubConnectionTeam' =>
        ({required Object name}) => 'Team to connect: ${name}',
      'team.gitHubConnectionConfirm' => 'Confirm connection',
      'team.gitHubConnectionConfirming' => 'Connecting…',
      'team.gitHubConnectionCompleted' => 'GitHub connected',
      'team.gitHubConnectionConfirmFailed' =>
        'Could not confirm the GitHub connection. Please try again.',
      'team.gitHubConnectionCancelled' => 'GitHub authorization was cancelled.',
      'team.gitHubConnectionRestartRequired' =>
        'Could not resume the connection. Close this page and try again from the team screen.',
      'team.gitHubConnectionCheckFailed' =>
        'Could not verify the GitHub connection. Close this page and try again.',
      'team.enterTeamName' => 'Enter a team name',
      'team.createdSuccess' => 'Team created',
      'team.updatedSuccess' => 'Team name updated',
      'team.selectedSuccess' => 'Team selected',
      'team.inviteTitle' => 'Invite a team member',
      'team.inviteEmail' => 'Email address',
      'team.enterEmail' => 'Enter an email address',
      'team.addedSuccess' => 'Member added to the team',
      'team.removeMember' => 'Remove member',
      'team.removeMemberConfirm' =>
        ({required Object name, required Object teamName}) =>
            'Remove ${name} from ${teamName}?',
      'team.removedSuccess' => 'Member removed from the team',
      'team.accessDenied' =>
        'Cannot access this team. Check your sign-in and connection settings.',
      'team.memberAlreadyAdded' => 'This user is already a member of the team.',
      'team.memberNotRegistered' =>
        'Ask this user to create a Dashboard account first.',
      'team.memberEmailNotVerified' =>
        'This user has not verified their email address. Ask them to complete email verification under Settings → Account in the Dashboard, then try again.',
      'team.memberUnavailable' => 'This account is unavailable.',
      'team.enterValidEmail' => 'Enter a valid email address.',
      'team.operationFailed' =>
        'Could not complete the team operation. Please try again.',
      'team.members' => 'Members',
      'team.membersCount' =>
        ({required num count}) =>
            (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(
              count,
              one: '${count} member',
              other: '${count} members',
            ),
      'team.you' => 'You',
      'team.noEmail' => 'No email',
      'team.deleteTeam' => 'Delete team',
      'team.deleteTeamConfirm' =>
        ({required Object teamName}) =>
            'Delete ${teamName}? This action is permanent and will delete all workflows, secrets, and environment variables associated with this team.',
      'team.deletedSuccess' => 'Team deleted',
      'team.cannotDeleteLastTeam' =>
        'Create another team before deleting your last team.',
      'subscription.title' => 'Subscription',
      'subscription.noOfferings' => 'No plans available',
      'subscription.noPackages' => 'No packages available',
      'subscription.plans' => 'Plans',
      'subscription.restorePurchases' => 'Restore purchases',
      'subscription.purchaseSuccess' => 'Purchase completed!',
      'subscription.purchaseFailed' =>
        ({required Object error}) => 'Purchase failed: ${error}',
      'subscription.restoreSuccess' => 'Purchases restored',
      'subscription.restoreFailed' =>
        ({required Object error}) => 'Could not restore purchases: ${error}',
      'subscription.activeSubscription' => 'Active subscription',
      'subscription.active' => 'Active',
      'subscription.termsOfUse' => 'Terms of Use',
      'subscription.privacyPolicy' => 'Privacy Policy',
      'subscription.subscriptionTerms' =>
        'Your subscription renews automatically unless cancelled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours before the current period ends. After purchase, you can manage or cancel your subscription in your App Store account settings.',
      'subscription.subscriptionTermsWeb' =>
        'Your subscription renews automatically unless cancelled before the current billing period ends. You can manage or cancel your subscription in your account settings. Payments are securely processed by Stripe.',
      'subscription.perWeek' => 'per week',
      'subscription.perMonth' => 'per month',
      'subscription.per3Months' => 'every 3 months',
      'subscription.per6Months' => 'every 6 months',
      'subscription.perYear' => 'per year',
      'logs.title' => 'CI/CD logs',
      'logs.empty' => 'No active CI/CD logs',
      'logs.loadFailed' =>
        ({required Object error}) => 'Could not load logs: ${error}',
      'logs.jobNotFound' => 'Build job not found',
      'logs.detailTitle' => 'CI/CD log details',
      'logs.copyAll' => 'Copy all logs',
      'logs.nothingToCopy' => 'No logs to copy',
      'logs.copiedAll' => 'All logs copied to the clipboard',
      'logs.copyFailed' =>
        ({required Object error}) => 'Could not copy logs: ${error}',
      'logs.noSteps' => 'No log steps',
      'logs.failureReason' => 'Build failure reason',
      'logs.unavailable' =>
        'No logs available. Logs from before the migration or beyond the retention period are unavailable.',
      'logs.copy' => 'Copy logs',
      'logs.copied' => 'Logs copied to the clipboard',
      'logs.durationMinutesSeconds' =>
        ({required Object minutes, required Object seconds}) =>
            '${minutes}m ${seconds}s',
      'logs.durationSeconds' => ({required Object seconds}) => '${seconds}s',
      'billing.title' => 'Billing',
      'billing.signInRequired' => 'Sign in to Cloud to use this page.',
      'billing.teamLoadFailed' => 'Could not load teams.',
      'billing.teamAccessDenied' =>
        'Cannot access this team. Check your team selection in the dashboard.',
      'billing.disabled' =>
        'Billing is currently unavailable for this connection.',
      'billing.returnedFromStripe' =>
        'You have returned from Stripe. Changes may take a moment to appear. Select Reload if needed.',
      'billing.ciAvailable' => 'CI is available',
      'billing.monthlyPostpaid' => 'Monthly billing for CI usage',
      'billing.monthlyExplanation' =>
        'CI costs ¥1 per minute, including tax. Usage is totaled monthly and automatically charged to your registered card the following month.',
      'billing.continueCardSetup' => 'Continue card setup',
      'billing.setupCard' => 'Add payment method',
      'billing.cardRegistered' => 'A card is registered for monthly billing.',
      'billing.setCardInPortal' =>
        'Open Payment methods and billing history to set up a billing card.',
      'billing.openPortal' => 'Payment methods and billing history',
      'billing.monthlyUsage' =>
        ({required Object month}) => 'Usage this month (${month})',
      'billing.minutes' =>
        ({required Object minutes}) => 'Usage: ${minutes} minutes',
      'billing.estimatedAmount' =>
        ({required Object amount}) =>
            'Estimated total including tax: ¥${amount}',
      'billing.nextInvoiceDate' =>
        ({required Object date}) => 'Next invoice date: ${date} (Japan time)',
      'billing.usdExplanation' =>
        'The amount billed in USD is finalized by converting the yen usage total at month-end.',
      'billing.usageUnavailable' =>
        'Could not load usage for this month. Select Reload to try again.',
      'billing.openingStripe' => 'Preparing to open Stripe…',
      'billing.consentTitle' => 'Agree to monthly billing?',
      'billing.consentMessage' =>
        ({required Object teamName}) =>
            'CI usage for team ${teamName} costs ¥1 per minute, including tax. Monthly usage is automatically charged to your registered card the following month. Registering a card costs ¥0.',
      'billing.agreeAndContinue' => 'Agree and continue to Stripe',
      'billing.paymentRequired' =>
        'Register a billing card for this team to start CI.',
      'billing.allowanceExhausted' =>
        'No usage allowance is available to start a new CI run.',
      'billing.subscriptionEnded' => 'Your subscription has ended.',
      'billing.paymentPending' => 'Waiting for card setup to complete.',
      'billing.ciUnavailable' =>
        'CI is currently unavailable. Wait a moment and reload.',
      'billing.authenticationRequired' => 'Please sign in again.',
      'billing.forbidden' => 'Cannot access billing information for this team.',
      'billing.cardConsentRequired' =>
        'Reload the latest pricing terms and confirm your agreement again.',
      'billing.contextChanged' =>
        'Your connection or account has changed. Reopen this page.',
      'billing.subscriptionExists' =>
        'A subscription already exists. Reload to check its details.',
      'billing.checkoutPending' =>
        'Your payment is being checked. Wait a moment and reload.',
      'billing.customerMissing' =>
        'No subscription is available to manage. Please reload.',
      'billing.launchFailed' => 'Could not open Stripe. Please try again.',
      'billing.operationFailed' =>
        'Could not complete the billing operation. Please try again later.',
      'language.label' => 'Language',
      'language.system' => 'System default',
      'language.saveFailed' =>
        'Could not save your language preference. Please try again.',
      'connection.saveFailed' => 'Could not save connection settings.',
      'connection.configMismatch' =>
        'This connection ID already uses different Firebase settings. Register a new connection.',
      'connection.platformConfigMissing' =>
        ({required Object platform, required Object name}) =>
            'Firebase settings for ${platform} are missing from ${name}.',
      'config.jsonParseFailed' =>
        ({required Object error}) => 'Could not parse JSON: ${error}',
      'config.xmlParseFailed' =>
        ({required Object error}) => 'Could not parse XML: ${error}',
      'config.missingKeys' =>
        ({required Object file, required Object keys}) =>
            'Required keys are missing from ${file}: ${keys}',
      'config.unsupportedFormat' =>
        'Select a Firebase web configuration JSON file, an Android google-services.json file, or an iOS GoogleService-Info.plist file.',
      'config.plistDictMissing' => 'No <dict> element found in the plist.',
      _ => null,
    };
  }
}
