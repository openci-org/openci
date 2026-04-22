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
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

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
	late final TranslationsCommonEn common = TranslationsCommonEn._(_root);
	late final TranslationsTimeAgoEn timeAgo = TranslationsTimeAgoEn._(_root);
	late final TranslationsNavEn nav = TranslationsNavEn._(_root);
	late final TranslationsAuthEn auth = TranslationsAuthEn._(_root);
	late final TranslationsWorkflowEn workflow = TranslationsWorkflowEn._(_root);
	late final TranslationsBuildLogsEn buildLogs = TranslationsBuildLogsEn._(_root);
	late final TranslationsVariablesEn variables = TranslationsVariablesEn._(_root);
	late final TranslationsSecretsEn secrets = TranslationsSecretsEn._(_root);
	late final TranslationsEnvVarsEn envVars = TranslationsEnvVarsEn._(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn._(_root);
	late final TranslationsNotificationsEn notifications = TranslationsNotificationsEn._(_root);
	late final TranslationsTeamEn team = TranslationsTeamEn._(_root);
	late final TranslationsGithubEn github = TranslationsGithubEn._(_root);
	late final TranslationsSubscriptionEn subscription = TranslationsSubscriptionEn._(_root);
	late final TranslationsAiWorkflowEn aiWorkflow = TranslationsAiWorkflowEn._(_root);
	late final TranslationsStoreReleaseEn storeRelease = TranslationsStoreReleaseEn._(_root);
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Error: $error'
	String error({required Object error}) => 'Error: ${error}';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Invite'
	String get invite => 'Invite';
}

// Path: timeAgo
class TranslationsTimeAgoEn {
	TranslationsTimeAgoEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '${count} sec ago'
	String secsAgo({required Object count}) => '${count} sec ago';

	/// en: '${count} secs ago'
	String secsAgoPlural({required Object count}) => '${count} secs ago';

	/// en: '${count} min ago'
	String minsAgo({required Object count}) => '${count} min ago';

	/// en: '${count} mins ago'
	String minsAgoPlural({required Object count}) => '${count} mins ago';

	/// en: '${count}h ago'
	String hoursAgo({required Object count}) => '${count}h ago';

	/// en: '${count}d ago'
	String daysAgo({required Object count}) => '${count}d ago';

	/// en: '${count}mo ago'
	String monthsAgo({required Object count}) => '${count}mo ago';
}

// Path: nav
class TranslationsNavEn {
	TranslationsNavEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Workflows'
	String get workflows => 'Workflows';

	/// en: 'Variables'
	String get variables => 'Variables';

	/// en: 'Logs'
	String get logs => 'Logs';

	/// en: 'Release'
	String get release => 'Release';

	/// en: 'Settings'
	String get settings => 'Settings';
}

// Path: auth
class TranslationsAuthEn {
	TranslationsAuthEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Log in'
	String get login => 'Log in';

	/// en: 'Create new account'
	String get createAccount => 'Create new account';

	/// en: 'Use your Firebase'
	String get useYourFirebase => 'Use your Firebase';

	/// en: 'Reset Firebase'
	String get resetFirebase => 'Reset Firebase';

	/// en: 'Firebase reset successfully. Please restart the app.'
	String get resetSuccess => 'Firebase reset successfully. Please restart the app.';

	/// en: 'I agree to the '
	String get agreePrefix => 'I agree to the ';

	/// en: 'Terms of Service'
	String get termsOfService => 'Terms of Service';

	/// en: 'Please enter your email'
	String get enterEmail => 'Please enter your email';

	/// en: 'Please enter your password'
	String get enterPassword => 'Please enter your password';

	late final TranslationsAuthFirebaseFormEn firebaseForm = TranslationsAuthFirebaseFormEn._(_root);
}

// Path: workflow
class TranslationsWorkflowEn {
	TranslationsWorkflowEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Workflows'
	String get title => 'Workflows';

	/// en: 'Workflows'
	String get tabWorkflows => 'Workflows';

	/// en: 'Runs'
	String get tabRuns => 'Runs';

	/// en: 'Add Workflow'
	String get addWorkflow => 'Add Workflow';

	/// en: 'No workflow files found'
	String get noWorkflowFiles => 'No workflow files found';

	/// en: 'Add YAML files to .openci/ in your repository.'
	String get addYamlHint => 'Add YAML files to .openci/ in your repository.';

	/// en: 'Select a repository'
	String get selectRepo => 'Select a repository';

	/// en: 'Choose a GitHub repository to manage workflows.'
	String get selectRepoHint => 'Choose a GitHub repository to manage workflows.';

	/// en: 'Select Repository'
	String get selectRepoButton => 'Select Repository';

	/// en: 'Enabled'
	String get enabled => 'Enabled';

	/// en: 'Disabled'
	String get disabled => 'Disabled';

	/// en: 'This workflow will run when triggered.'
	String get enabledDescription => 'This workflow will run when triggered.';

	/// en: 'This workflow is paused and will not run.'
	String get disabledDescription => 'This workflow is paused and will not run.';

	/// en: 'Enable workflow'
	String get enable => 'Enable workflow';

	/// en: 'Disable workflow'
	String get disable => 'Disable workflow';

	/// en: 'Triggers'
	String get triggers => 'Triggers';

	/// en: '$type branch'
	String triggerBranch({required Object type}) => '${type} branch';

	/// en: '$type branch (loading...)'
	String triggerBranchLoading({required Object type}) => '${type} branch (loading...)';

	/// en: 'Select Branch'
	String get selectBranch => 'Select Branch';

	/// en: 'Choose a branch to view workflows from.'
	String get selectBranchHint => 'Choose a branch to view workflows from.';

	/// en: 'No branches found'
	String get noBranches => 'No branches found';

	/// en: 'Select Repository'
	String get selectRepository => 'Select Repository';

	/// en: 'Choose a GitHub repository to manage workflows.'
	String get selectRepositoryHint => 'Choose a GitHub repository to manage workflows.';

	/// en: 'Search repositories...'
	String get searchRepositories => 'Search repositories...';

	/// en: 'No repositories found. Please install the OpenCI GitHub App.'
	String get noRepositories => 'No repositories found.\nPlease install the OpenCI GitHub App.';

	/// en: 'No repositories matching "$query"'
	String noMatchingRepositories({required Object query}) => 'No repositories matching "${query}"';

	/// en: 'default: $branch'
	String defaultBranch({required Object branch}) => 'default: ${branch}';

	late final TranslationsWorkflowEditorEn editor = TranslationsWorkflowEditorEn._(_root);
}

// Path: buildLogs
class TranslationsBuildLogsEn {
	TranslationsBuildLogsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Build Logs - $date'
	String title({required Object date}) => 'Build Logs - ${date}';

	/// en: 'No build jobs found'
	String get noJobs => 'No build jobs found';

	late final TranslationsBuildLogsStatusEn status = TranslationsBuildLogsStatusEn._(_root);
	late final TranslationsBuildLogsDetailEn detail = TranslationsBuildLogsDetailEn._(_root);
	late final TranslationsBuildLogsDurationEn duration = TranslationsBuildLogsDurationEn._(_root);
}

// Path: variables
class TranslationsVariablesEn {
	TranslationsVariablesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Variables'
	String get title => 'Variables';

	/// en: 'Environment Variables'
	String get envVarsTab => 'Environment Variables';

	/// en: 'Secrets'
	String get secretsTab => 'Secrets';
}

// Path: secrets
class TranslationsSecretsEn {
	TranslationsSecretsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Secret Manager'
	String get title => 'Secret Manager';

	/// en: 'No secrets found'
	String get noSecrets => 'No secrets found';

	/// en: 'Add Secret'
	String get addSecret => 'Add Secret';

	/// en: 'Edit Secret'
	String get editSecret => 'Edit Secret';

	/// en: 'SECRET_NAME'
	String get secretName => 'SECRET_NAME';

	/// en: 'Secret Value'
	String get secretValue => 'Secret Value';

	/// en: 'New Secret Value (leave empty to keep current)'
	String get newSecretValue => 'New Secret Value (leave empty to keep current)';

	/// en: 'Please enter a secret name'
	String get enterSecretName => 'Please enter a secret name';

	/// en: 'Please enter a secret value'
	String get enterSecretValue => 'Please enter a secret value';

	/// en: 'Secret added successfully'
	String get addedSuccess => 'Secret added successfully';

	/// en: 'Secret updated successfully'
	String get updatedSuccess => 'Secret updated successfully';

	/// en: 'Are you sure you want to delete this secret? This action cannot be undone.'
	String get deleteConfirm => 'Are you sure you want to delete this secret? This action cannot be undone.';

	/// en: 'Secret deleted successfully'
	String get deletedSuccess => 'Secret deleted successfully';

	/// en: 'Unused Secrets'
	String get unusedSecrets => 'Unused Secrets';

	/// en: 'Not used in any workflow'
	String get notUsedInWorkflows => 'Not used in any workflow';

	/// en: 'Text'
	String get inputModeText => 'Text';

	/// en: 'File'
	String get inputModeFile => 'File';

	/// en: 'Upload file'
	String get uploadFile => 'Upload file';

	/// en: '$fileName selected'
	String fileSelected({required Object fileName}) => '${fileName} selected';

	/// en: 'Click to select a file'
	String get orUploadFile => 'Click to select a file';

	/// en: 'Please enter a value or upload a file'
	String get enterValueOrUpload => 'Please enter a value or upload a file';
}

// Path: envVars
class TranslationsEnvVarsEn {
	TranslationsEnvVarsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Environment Variables'
	String get title => 'Environment Variables';

	/// en: 'No environment variables found'
	String get noEnvVars => 'No environment variables found';

	/// en: 'No custom environment variables'
	String get noCustomEnvVars => 'No custom environment variables';

	/// en: 'Add Environment Variable'
	String get addEnvVar => 'Add Environment Variable';

	/// en: 'Edit Environment Variable'
	String get editEnvVar => 'Edit Environment Variable';

	/// en: 'Edit Run Number'
	String get editRunNumber => 'Edit Run Number';

	/// en: 'KEY_NAME'
	String get keyName => 'KEY_NAME';

	/// en: 'Value'
	String get value => 'Value';

	/// en: 'e.g. MY_VARIABLE'
	String get keyHint => 'e.g. MY_VARIABLE';

	/// en: 'e.g. hello'
	String get valueHint => 'e.g. hello';

	/// en: 'Please enter a key name'
	String get enterKeyName => 'Please enter a key name';

	/// en: 'Please enter a value'
	String get enterValue => 'Please enter a value';

	/// en: 'Use only letters, numbers, and underscores'
	String get invalidKey => 'Use only letters, numbers, and underscores';

	/// en: 'Value must be a number'
	String get valueMustBeNumber => 'Value must be a number';

	/// en: 'Environment variable added'
	String get addedSuccess => 'Environment variable added';

	/// en: 'Environment variable updated'
	String get updatedSuccess => 'Environment variable updated';

	/// en: 'Deleted successfully'
	String get deletedSuccess => 'Deleted successfully';

	/// en: 'Run number updated'
	String get runNumberUpdated => 'Run number updated';
}

// Path: settings
class TranslationsSettingsEn {
	TranslationsSettingsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'General'
	String get general => 'General';

	/// en: 'Preferences'
	String get preferences => 'Preferences';

	/// en: 'Build Notifications'
	String get buildNotifications => 'Build Notifications';

	/// en: 'Configure when to receive notifications'
	String get configureNotifications => 'Configure when to receive notifications';

	/// en: 'Subscription'
	String get subscription => 'Subscription';

	/// en: 'Manage your subscription plan'
	String get manageSubscription => 'Manage your subscription plan';

	/// en: 'Firebase App Name: $name'
	String firebaseAppName({required Object name}) => 'Firebase App Name: ${name}';

	/// en: 'Reset to OpenCI Cloud'
	String get resetToCloud => 'Reset to OpenCI Cloud';

	/// en: 'Configuration cleared. Please restart the app.'
	String get resetToCloudSuccess => 'Configuration cleared. Please restart the app.';

	/// en: 'Self-hosted Firebase'
	String get selfHostedActive => 'Self-hosted Firebase';

	/// en: 'Project: $projectId'
	String selfHostedProject({required Object projectId}) => 'Project: ${projectId}';

	/// en: 'Invite Team Member'
	String get inviteTeamMember => 'Invite Team Member';

	/// en: 'App Version'
	String get appVersion => 'App Version';

	/// en: 'Logout'
	String get logout => 'Logout';

	/// en: 'Logged out successfully'
	String get logoutSuccess => 'Logged out successfully';

	/// en: 'Failed to log out: $error'
	String logoutFailed({required Object error}) => 'Failed to log out: ${error}';

	/// en: 'Delete Account'
	String get deleteAccount => 'Delete Account';

	/// en: 'Delete Account'
	String get deleteConfirmTitle => 'Delete Account';

	/// en: 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.'
	String get deleteConfirmMessage => 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.';

	/// en: 'Account deleted successfully'
	String get deleteSuccess => 'Account deleted successfully';

	/// en: 'No user is currently signed in'
	String get noUserSignedIn => 'No user is currently signed in';

	/// en: 'Please sign out and sign in again before deleting your account'
	String get requiresRecentLogin => 'Please sign out and sign in again before deleting your account';

	/// en: 'Failed to delete account: $error'
	String deleteFailed({required Object error}) => 'Failed to delete account: ${error}';

	late final TranslationsSettingsAiFeaturesEn aiFeatures = TranslationsSettingsAiFeaturesEn._(_root);
	late final TranslationsSettingsLanguageEn language = TranslationsSettingsLanguageEn._(_root);
}

// Path: notifications
class TranslationsNotificationsEn {
	TranslationsNotificationsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Build Notifications'
	String get title => 'Build Notifications';

	/// en: 'All'
	String get all => 'All';

	/// en: 'Notify on both success and failure'
	String get allDesc => 'Notify on both success and failure';

	/// en: 'Success Only'
	String get successOnly => 'Success Only';

	/// en: 'Notify only when build succeeds'
	String get successOnlyDesc => 'Notify only when build succeeds';

	/// en: 'Failure Only'
	String get failureOnly => 'Failure Only';

	/// en: 'Notify only when build fails'
	String get failureOnlyDesc => 'Notify only when build fails';

	/// en: 'None'
	String get none => 'None';

	/// en: 'Do not send any notifications'
	String get noneDesc => 'Do not send any notifications';

	/// en: 'Notification preference updated'
	String get updated => 'Notification preference updated';

	/// en: 'Failed to update: $error'
	String updateFailed({required Object error}) => 'Failed to update: ${error}';

	/// en: 'Error loading settings: $error'
	String errorLoading({required Object error}) => 'Error loading settings: ${error}';
}

// Path: team
class TranslationsTeamEn {
	TranslationsTeamEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Switch Team'
	String get switchTeam => 'Switch Team';

	/// en: 'Edit Team'
	String get editTeam => 'Edit Team';

	/// en: 'Create Team'
	String get createTeam => 'Create Team';

	/// en: 'Create New Team'
	String get createNewTeam => 'Create New Team';

	/// en: 'Team Name'
	String get teamName => 'Team Name';

	/// en: 'New Team Name'
	String get newTeamName => 'New Team Name';

	/// en: 'Select a team'
	String get selectTeam => 'Select a team';

	/// en: 'Team'
	String get selectTeamLabel => 'Team';

	/// en: 'Please enter a team name'
	String get enterTeamName => 'Please enter a team name';

	/// en: 'Please select a team'
	String get selectTeamValidation => 'Please select a team';

	/// en: 'Team created successfully'
	String get createdSuccess => 'Team created successfully';

	/// en: 'Team name updated successfully'
	String get updatedSuccess => 'Team name updated successfully';

	/// en: 'Team selected successfully'
	String get selectedSuccess => 'Team selected successfully';

	/// en: 'Invite Team Member'
	String get inviteTitle => 'Invite Team Member';

	/// en: 'Email'
	String get inviteEmail => 'Email';

	/// en: 'Please enter an email'
	String get enterEmail => 'Please enter an email';

	/// en: 'Team member invited successfully'
	String get invitedSuccess => 'Team member invited successfully';

	/// en: 'Member added to team'
	String get addedSuccess => 'Member added to team';

	/// en: 'Invitation email sent 📧'
	String get invitationSent => 'Invitation email sent 📧';

	/// en: 'Processing invitation...'
	String get processingInvitation => 'Processing invitation...';

	/// en: 'Invitation Failed'
	String get invitationFailed => 'Invitation Failed';

	/// en: 'You're in! 🎉'
	String get invitationAccepted => 'You\'re in! 🎉';

	/// en: 'Already a Member'
	String get alreadyMemberTitle => 'Already a Member';

	/// en: 'You're already a member of "$teamName".'
	String alreadyMemberMessage({required Object teamName}) => 'You\'re already a member of "${teamName}".';

	/// en: 'You've joined the "$teamName" team.'
	String joinedTeamMessage({required Object teamName}) => 'You\'ve joined the "${teamName}" team.';

	/// en: 'Go to Dashboard'
	String get goToDashboard => 'Go to Dashboard';

	/// en: 'Members'
	String get members => 'Members';

	/// en: '$count members'
	String membersCount({required Object count}) => '${count} members';

	/// en: 'You'
	String get you => 'You';

	/// en: 'No email'
	String get noEmail => 'No email';

	/// en: 'Delete Team'
	String get deleteTeam => 'Delete Team';

	/// en: 'Are you sure you want to delete "$teamName"? This action cannot be undone. All workflows, secrets, and environment variables associated with this team will be permanently deleted.'
	String deleteTeamConfirm({required Object teamName}) => 'Are you sure you want to delete "${teamName}"? This action cannot be undone. All workflows, secrets, and environment variables associated with this team will be permanently deleted.';

	/// en: 'Team deleted successfully'
	String get deletedSuccess => 'Team deleted successfully';

	/// en: 'You cannot delete your last team. Please create another team first.'
	String get cannotDeleteLastTeam => 'You cannot delete your last team. Please create another team first.';
}

// Path: github
class TranslationsGithubEn {
	TranslationsGithubEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Connect GitHub'
	String get connectTitle => 'Connect GitHub';

	/// en: 'Connect your GitHub account to select repositories automatically.'
	String get connectDescription => 'Connect your GitHub account to\nselect repositories automatically.';

	/// en: 'Connect with GitHub'
	String get connectButton => 'Connect with GitHub';
}

// Path: subscription
class TranslationsSubscriptionEn {
	TranslationsSubscriptionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Subscription'
	String get title => 'Subscription';

	/// en: 'No offerings available'
	String get noOfferings => 'No offerings available';

	/// en: 'No packages available'
	String get noPackages => 'No packages available';

	/// en: 'Plans'
	String get plans => 'Plans';

	/// en: 'Restore Purchases'
	String get restorePurchases => 'Restore Purchases';

	/// en: 'Purchase successful!'
	String get purchaseSuccess => 'Purchase successful!';

	/// en: 'Purchase failed: $error'
	String purchaseFailed({required Object error}) => 'Purchase failed: ${error}';

	/// en: 'Purchases restored successfully'
	String get restoreSuccess => 'Purchases restored successfully';

	/// en: 'Restore failed: $error'
	String restoreFailed({required Object error}) => 'Restore failed: ${error}';

	/// en: 'Active Subscription'
	String get activeSubscription => 'Active Subscription';

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Terms of Use'
	String get termsOfUse => 'Terms of Use';

	/// en: 'Privacy Policy'
	String get privacyPolicy => 'Privacy Policy';

	/// en: 'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.'
	String get subscriptionTerms => 'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.';

	/// en: 'Subscriptions automatically renew unless canceled before the end of the current billing period. You can manage and cancel your subscription from your account settings. Payments are processed securely via Stripe.'
	String get subscriptionTermsWeb => 'Subscriptions automatically renew unless canceled before the end of the current billing period. You can manage and cancel your subscription from your account settings. Payments are processed securely via Stripe.';

	/// en: 'per week'
	String get perWeek => 'per week';

	/// en: 'per month'
	String get perMonth => 'per month';

	/// en: 'per 3 months'
	String get per3Months => 'per 3 months';

	/// en: 'per 6 months'
	String get per6Months => 'per 6 months';

	/// en: 'per year'
	String get perYear => 'per year';
}

// Path: aiWorkflow
class TranslationsAiWorkflowEn {
	TranslationsAiWorkflowEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'AI Workflow Builder'
	String get title => 'AI Workflow Builder';

	/// en: 'Describe your workflow...'
	String get inputHint => 'Describe your workflow...';

	/// en: 'Generated Workflow'
	String get generatedWorkflow => 'Generated Workflow';

	/// en: 'Use this workflow'
	String get useThisWorkflow => 'Use this workflow';

	late final TranslationsAiWorkflowChatEn chat = TranslationsAiWorkflowChatEn._(_root);
	late final TranslationsAiWorkflowSuggestionEn suggestion = TranslationsAiWorkflowSuggestionEn._(_root);
	late final TranslationsAiWorkflowProjectLabelEn projectLabel = TranslationsAiWorkflowProjectLabelEn._(_root);
	late final TranslationsAiWorkflowGoalLabelEn goalLabel = TranslationsAiWorkflowGoalLabelEn._(_root);
	late final TranslationsAiWorkflowTriggerLabelEn triggerLabel = TranslationsAiWorkflowTriggerLabelEn._(_root);
}

// Path: storeRelease
class TranslationsStoreReleaseEn {
	TranslationsStoreReleaseEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Store Release'
	String get title => 'Store Release';

	/// en: 'Connect App Store Connect'
	String get setupTitle => 'Connect App Store Connect';

	/// en: 'Enter your App Store Connect API credentials to manage releases directly from OpenCI.'
	String get setupDescription => 'Enter your App Store Connect API credentials to manage releases directly from OpenCI.';

	/// en: 'Issuer ID'
	String get issuerId => 'Issuer ID';

	/// en: 'Key ID'
	String get keyId => 'Key ID';

	/// en: 'Private Key (.p8)'
	String get privateKey => 'Private Key (.p8)';

	/// en: 'Paste the contents of your .p8 file'
	String get privateKeyHint => 'Paste the contents of your .p8 file';

	/// en: 'Connect'
	String get connect => 'Connect';

	/// en: 'Connecting...'
	String get connecting => 'Connecting...';

	/// en: 'App Store Connect connected successfully'
	String get setupSuccess => 'App Store Connect connected successfully';

	/// en: 'Failed to connect: $error'
	String setupFailed({required Object error}) => 'Failed to connect: ${error}';

	/// en: 'Please enter the Issuer ID'
	String get enterIssuerId => 'Please enter the Issuer ID';

	/// en: 'Please enter the Key ID'
	String get enterKeyId => 'Please enter the Key ID';

	/// en: 'Please enter the private key'
	String get enterPrivateKey => 'Please enter the private key';

	/// en: 'Select App'
	String get selectApp => 'Select App';

	/// en: 'Choose an app to manage releases'
	String get selectAppHint => 'Choose an app to manage releases';

	/// en: 'No apps found'
	String get noApps => 'No apps found';

	/// en: 'No apps were found in your App Store Connect account.'
	String get noAppsHint => 'No apps were found in your App Store Connect account.';

	/// en: 'Loading apps...'
	String get loadingApps => 'Loading apps...';

	/// en: 'App Store Connect API may take a moment to respond'
	String get ascLoadingHint => 'App Store Connect API may take a moment to respond';

	/// en: 'Builds'
	String get builds => 'Builds';

	/// en: 'No builds found'
	String get noBuilds => 'No builds found';

	/// en: 'Upload a build to App Store Connect to get started.'
	String get noBuildsHint => 'Upload a build to App Store Connect to get started.';

	/// en: 'v$version'
	String version({required Object version}) => 'v${version}';

	/// en: 'Build $number'
	String buildNumber({required Object number}) => 'Build ${number}';

	/// en: 'Processing'
	String get processing => 'Processing';

	/// en: 'Ready for Sale'
	String get readyForSale => 'Ready for Sale';

	/// en: 'Ready'
	String get valid => 'Ready';

	/// en: 'Invalid'
	String get invalid => 'Invalid';

	/// en: 'TestFlight'
	String get testFlight => 'TestFlight';

	/// en: 'Submit to TestFlight'
	String get submitToTestFlight => 'Submit to TestFlight';

	/// en: 'Submit this build to external testers via TestFlight?'
	String get submitToTestFlightConfirm => 'Submit this build to external testers via TestFlight?';

	/// en: 'Build submitted to TestFlight group: $group'
	String testFlightSuccess({required Object group}) => 'Build submitted to TestFlight group: ${group}';

	/// en: 'Failed to submit to TestFlight: $error'
	String testFlightFailed({required Object error}) => 'Failed to submit to TestFlight: ${error}';

	/// en: 'App Store Review'
	String get appStoreReview => 'App Store Review';

	/// en: 'Submit for Review'
	String get submitForReview => 'Submit for Review';

	/// en: 'Submit this build for App Store Review? Version: $version'
	String submitForReviewConfirm({required Object version}) => 'Submit this build for App Store Review?\n\nVersion: ${version}';

	/// en: 'Build submitted for App Store Review'
	String get reviewSuccess => 'Build submitted for App Store Review';

	/// en: 'Failed to submit for review: $error'
	String reviewFailed({required Object error}) => 'Failed to submit for review: ${error}';

	/// en: 'Version String'
	String get versionString => 'Version String';

	/// en: 'e.g. 1.0.0'
	String get enterVersionString => 'e.g. 1.0.0';

	/// en: 'Please enter a version string'
	String get versionRequired => 'Please enter a version string';

	/// en: 'What's New'
	String get whatsNew => 'What\'s New';

	/// en: 'Describe what's new in this version'
	String get whatsNewHint => 'Describe what\'s new in this version';

	/// en: 'Please enter release notes'
	String get whatsNewRequired => 'Please enter release notes';

	/// en: 'Change App'
	String get changeApp => 'Change App';

	/// en: 'Reconfigure'
	String get reconfigure => 'Reconfigure';

	/// en: 'How to get credentials'
	String get howToGetCredentials => 'How to get credentials';

	/// en: 'Go to App Store Connect > Users and Access > Integrations > App Store Connect API to generate an API key.'
	String get credentialsHelp => 'Go to App Store Connect > Users and Access > Integrations > App Store Connect API to generate an API key.';

	/// en: 'Waiting for Review'
	String get waitingForReview => 'Waiting for Review';

	/// en: 'In Review'
	String get inReview => 'In Review';

	/// en: 'Pending Release'
	String get pendingRelease => 'Pending Release';

	/// en: 'Ready for Distribution'
	String get readyForDistribution => 'Ready for Distribution';

	/// en: 'Developer Rejected'
	String get developerRejected => 'Developer Rejected';

	/// en: 'Rejected'
	String get rejected => 'Rejected';

	/// en: 'Prepare for Submission'
	String get prepareForSubmission => 'Prepare for Submission';

	/// en: 'Submitted'
	String get submitted => 'Submitted';

	/// en: 'Build'
	String get stepBuild => 'Build';

	/// en: 'Details'
	String get stepDetails => 'Details';

	/// en: 'Review'
	String get stepReview => 'Review';

	/// en: 'Select a Build'
	String get selectBuildTitle => 'Select a Build';

	/// en: 'Choose a build to submit for App Store Review'
	String get selectBuildHint => 'Choose a build to submit for App Store Review';

	/// en: 'Release Details'
	String get releaseDetailsTitle => 'Release Details';

	/// en: 'Configure version and release notes'
	String get releaseDetailsHint => 'Configure version and release notes';

	/// en: 'Review & Submit'
	String get reviewTitle => 'Review & Submit';

	/// en: 'Confirm all details before submitting'
	String get reviewHint => 'Confirm all details before submitting';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Submit for Review'
	String get confirmSubmit => 'Submit for Review';

	/// en: 'Submitting...'
	String get submittingReview => 'Submitting...';

	/// en: 'Selected Build'
	String get selectedBuildLabel => 'Selected Build';

	/// en: 'Screenshots'
	String get screenshotsTitle => 'Screenshots';

	/// en: 'No screenshots available'
	String get noScreenshots => 'No screenshots available';

	/// en: 'Manage screenshots in App Store Connect'
	String get screenshotsHint => 'Manage screenshots in App Store Connect';

	/// en: '$count screenshots'
	String screenshotCount({required Object count}) => '${count} screenshots';

	/// en: 'Description'
	String get appDescription => 'Description';

	/// en: 'Keywords'
	String get keywordsLabel => 'Keywords';

	/// en: 'No existing version info found'
	String get noVersionInfo => 'No existing version info found';

	/// en: 'Current App Store Info'
	String get existingInfo => 'Current App Store Info';

	/// en: 'Submission Summary'
	String get summarySection => 'Submission Summary';

	/// en: 'Under Review'
	String get underReview => 'Under Review';

	/// en: 'Your app is currently being reviewed by Apple. No changes can be made until the review is complete.'
	String get underReviewDescription => 'Your app is currently being reviewed by Apple. No changes can be made until the review is complete.';

	/// en: 'Your app has been submitted and is waiting for Apple to begin the review.'
	String get waitingForReviewDescription => 'Your app has been submitted and is waiting for Apple to begin the review.';

	/// en: 'Approved'
	String get pendingReleaseTitle => 'Approved';

	/// en: 'Your app has been approved! It is pending release to the App Store.'
	String get pendingReleaseDescription => 'Your app has been approved! It is pending release to the App Store.';

	/// en: 'Submitted Build'
	String get submittedBuild => 'Submitted Build';

	/// en: 'Submitted'
	String get submittedOn => 'Submitted';

	/// en: 'Reviews typically take 24-48 hours'
	String get estimatedWait => 'Reviews typically take 24-48 hours';

	/// en: 'View in App Store Connect'
	String get viewInAsc => 'View in App Store Connect';
}

// Path: auth.firebaseForm
class TranslationsAuthFirebaseFormEn {
	TranslationsAuthFirebaseFormEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Use your Firebase'
	String get title => 'Use your Firebase';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'API Key'
	String get apiKey => 'API Key';

	/// en: 'App ID'
	String get appId => 'App ID';

	/// en: 'Messaging Sender ID'
	String get messagingSenderId => 'Messaging Sender ID';

	/// en: 'Project ID'
	String get projectId => 'Project ID';

	/// en: 'Storage Bucket'
	String get storageBucket => 'Storage Bucket';

	/// en: 'Save configuration'
	String get pickConfig => 'Save configuration';

	/// en: 'Cloud Run Hash'
	String get cloudRunHash => 'Cloud Run Hash';

	/// en: 'Cloud Run Region Code'
	String get cloudRunRegionCode => 'Cloud Run Region Code';

	/// en: 'Configuration saved. Please restart the app to apply.'
	String get configSaved => 'Configuration saved. Please restart the app to apply.';

	/// en: 'Custom Firebase project is configured. Restart to apply.'
	String get configActive => 'Custom Firebase project is configured. Restart to apply.';

	/// en: 'Import from file'
	String get importFile => 'Import from file';

	/// en: 'JSON (google-services.json) or plist (GoogleService-Info.plist)'
	String get importFileHint => 'JSON (google-services.json) or plist (GoogleService-Info.plist)';

	/// en: 'Could not parse the selected file. Please check the format.'
	String get invalidFile => 'Could not parse the selected file. Please check the format.';

	/// en: 'Config loaded from file. Review and save.'
	String get fileLoaded => 'Config loaded from file. Review and save.';
}

// Path: workflow.editor
class TranslationsWorkflowEditorEn {
	TranslationsWorkflowEditorEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create Workflow'
	String get createTitle => 'Create Workflow';

	/// en: 'Edit Workflow'
	String get editTitle => 'Edit Workflow';

	/// en: 'Editor'
	String get editorTab => 'Editor';

	/// en: 'YAML'
	String get yamlTab => 'YAML';

	/// en: 'Basic Info'
	String get basicInfo => 'Basic Info';

	/// en: 'Workflow Name'
	String get workflowName => 'Workflow Name';

	/// en: 'Step Name'
	String get stepName => 'Step Name';

	/// en: 'e.g. Build iOS App'
	String get stepNameHint => 'e.g. Build iOS App';

	/// en: 'Type'
	String get type => 'Type';

	/// en: 'Command'
	String get command => 'Command';

	/// en: 'Action'
	String get action => 'Action';

	/// en: 'Tap to search actions'
	String get actionHint => 'Tap to search actions';

	/// en: 'Version'
	String get version => 'Version';

	/// en: 'with'
	String get kWith => 'with';

	/// en: 'Loading inputs...'
	String get loadingInputs => 'Loading inputs...';

	/// en: 'Could not load inputs'
	String get couldNotLoadInputs => 'Could not load inputs';

	/// en: 'No inputs defined for this action'
	String get noInputs => 'No inputs defined for this action';

	/// en: 'Enter an action to see available inputs'
	String get enterAction => 'Enter an action to see available inputs';

	/// en: 'Loading versions...'
	String get loadingVersions => 'Loading versions...';

	/// en: 'required'
	String get required => 'required';

	/// en: 'Edit Step'
	String get editStep => 'Edit Step';

	/// en: 'Delete Step'
	String get deleteStep => 'Delete Step';

	/// en: 'Are you sure you want to delete this step?'
	String get deleteStepConfirm => 'Are you sure you want to delete this step?';

	/// en: 'Save to Repository'
	String get saveToRepo => 'Save to Repository';

	/// en: 'File Name'
	String get fileName => 'File Name';

	/// en: 'e.g. build.yaml'
	String get fileNameHint => 'e.g. build.yaml';

	/// en: 'How to save'
	String get howToSave => 'How to save';

	/// en: 'Commit directly'
	String get commitDirectly => 'Commit directly';

	/// en: 'Commit to the $branch branch'
	String commitToBranch({required Object branch}) => 'Commit to the ${branch} branch';

	/// en: 'Create a Pull Request'
	String get createPR => 'Create a Pull Request';

	/// en: 'A new branch will be created and a PR opened'
	String get createPRSubtitle => 'A new branch will be created and a PR opened';

	/// en: 'Commit to $branch'
	String commitToBranchButton({required Object branch}) => 'Commit to ${branch}';

	/// en: 'Create Pull Request'
	String get createPRButton => 'Create Pull Request';

	/// en: 'Please enter a file name'
	String get enterFileName => 'Please enter a file name';

	/// en: 'File name must end with .yaml or .yml'
	String get fileNameMustEndYaml => 'File name must end with .yaml or .yml';

	/// en: 'Pull Request Created'
	String get prCreated => 'Pull Request Created';

	/// en: 'PR #$number was created.'
	String prNumber({required Object number}) => 'PR #${number} was created.';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Open in GitHub'
	String get openInGitHub => 'Open in GitHub';

	/// en: 'Workflow file committed to $branch'
	String committedToBranch({required Object branch}) => 'Workflow file committed to ${branch}';

	/// en: 'Pull request created'
	String get prCreatedSuccess => 'Pull request created';

	/// en: 'Add step'
	String get addSteps => 'Add step';

	/// en: 'Add Job'
	String get addJob => 'Add Job';

	/// en: 'Parallel'
	String get parallel => 'Parallel';
}

// Path: buildLogs.status
class TranslationsBuildLogsStatusEn {
	TranslationsBuildLogsStatusEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Success'
	String get success => 'Success';

	/// en: 'Failed'
	String get failed => 'Failed';

	/// en: 'In Progress'
	String get inProgress => 'In Progress';

	/// en: 'Queued'
	String get queued => 'Queued';

	/// en: 'Cancelled'
	String get cancelled => 'Cancelled';
}

// Path: buildLogs.detail
class TranslationsBuildLogsDetailEn {
	TranslationsBuildLogsDetailEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'View Details'
	String get viewDetails => 'View Details';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Cancel Build'
	String get cancelBuild => 'Cancel Build';

	/// en: 'Are you sure you want to cancel this build?'
	String get cancelConfirm => 'Are you sure you want to cancel this build?';

	/// en: 'No'
	String get cancelNo => 'No';

	/// en: 'Cancelling build...'
	String get cancelling => 'Cancelling build...';

	/// en: 'Build cancelled'
	String get buildCancelled => 'Build cancelled';

	/// en: 'Failed to cancel: $error'
	String failedToCancel({required Object error}) => 'Failed to cancel: ${error}';

	/// en: 'Retrying build job...'
	String get retrying => 'Retrying build job...';

	/// en: 'Build job queued successfully'
	String get retrySuccess => 'Build job queued successfully';

	/// en: 'Failed to retry: $error'
	String failedToRetry({required Object error}) => 'Failed to retry: ${error}';

	/// en: 'No runs yet'
	String get noRuns => 'No runs yet';

	/// en: 'Waiting for logs...'
	String get waitingForLogs => 'Waiting for logs...';

	/// en: '$count log entries'
	String logEntries({required Object count}) => '${count} log entries';

	/// en: 'Copy all logs'
	String get copyAll => 'Copy all logs';

	/// en: 'Logs copied to clipboard'
	String get logsCopied => 'Logs copied to clipboard';

	/// en: '$count lines'
	String lines({required Object count}) => '${count} lines';

	/// en: 'Generating AI summary...'
	String get generatingSummary => 'Generating AI summary...';

	/// en: 'AI Failure Summary'
	String get failureSummaryTitle => 'AI Failure Summary';
}

// Path: buildLogs.duration
class TranslationsBuildLogsDurationEn {
	TranslationsBuildLogsDurationEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '<1m'
	String get lessThanMinute => '<1m';

	/// en: '${count}m'
	String minutes({required Object count}) => '${count}m';

	/// en: '${hours}h ${minutes}m'
	String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours}h ${minutes}m';

	/// en: '${count}h'
	String hours({required Object count}) => '${count}h';
}

// Path: settings.aiFeatures
class TranslationsSettingsAiFeaturesEn {
	TranslationsSettingsAiFeaturesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'AI Features'
	String get title => 'AI Features';

	/// en: 'Enable AI-powered features like workflow builder and failure summaries'
	String get subtitle => 'Enable AI-powered features like workflow builder and failure summaries';

	/// en: 'AI features are enabled'
	String get enabled => 'AI features are enabled';

	/// en: 'AI features are disabled'
	String get disabled => 'AI features are disabled';

	/// en: 'AI features setting updated'
	String get updated => 'AI features setting updated';
}

// Path: settings.language
class TranslationsSettingsLanguageEn {
	TranslationsSettingsLanguageEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Language'
	String get title => 'Language';

	/// en: 'Change the display language'
	String get subtitle => 'Change the display language';

	/// en: 'System Default'
	String get system => 'System Default';

	/// en: 'English'
	String get english => 'English';

	/// en: '日本語'
	String get japanese => '日本語';

	/// en: 'Español'
	String get spanish => 'Español';
}

// Path: aiWorkflow.chat
class TranslationsAiWorkflowChatEn {
	TranslationsAiWorkflowChatEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'What kind of workflow would you like to create? Tell me about your project and I'll help you set it up.'
	String get greeting => 'What kind of workflow would you like to create? Tell me about your project and I\'ll help you set it up.';

	/// en: 'Got it! A $project project. What would you like the workflow to do?'
	String projectSelected({required Object project}) => 'Got it! A ${project} project. What would you like the workflow to do?';

	/// en: 'When should this workflow run?'
	String get triggerQuestion => 'When should this workflow run?';

	/// en: 'I've generated your workflow! Here's what it includes: $plan You can use this workflow as-is, or tell me what you'd like to change.'
	String workflowGenerated({required Object plan}) => 'I\'ve generated your workflow! Here\'s what it includes:\n\n${plan}\n\nYou can use this workflow as-is, or tell me what you\'d like to change.';

	/// en: 'I've added a placeholder step. You can customize it in the editor after applying this workflow.'
	String get stepAdded => 'I\'ve added a placeholder step. You can customize it in the editor after applying this workflow.';

	/// en: 'Sure! When should this workflow run?'
	String get changeTriggerPrompt => 'Sure! When should this workflow run?';

	/// en: 'You can use the generated workflow by tapping 'Use this workflow', or tell me what changes you'd like.'
	String get followUp => 'You can use the generated workflow by tapping \'Use this workflow\', or tell me what changes you\'d like.';

	/// en: '- Project: $project - Steps: $steps - Trigger: $trigger'
	String planFormat({required Object project, required Object steps, required Object trigger}) => '- Project: ${project}\n- Steps: ${steps}\n- Trigger: ${trigger}';

	/// en: 'Sorry, something went wrong. Please try again or start over.'
	String get errorMessage => 'Sorry, something went wrong. Please try again or start over.';
}

// Path: aiWorkflow.suggestion
class TranslationsAiWorkflowSuggestionEn {
	TranslationsAiWorkflowSuggestionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flutter app CI/CD'
	String get flutterCiCd => 'Flutter app CI/CD';

	/// en: 'iOS app build & test'
	String get iosBuildTest => 'iOS app build & test';

	/// en: 'Android app build'
	String get androidBuild => 'Android app build';

	/// en: 'Run tests on PR'
	String get testOnPr => 'Run tests on PR';

	/// en: 'Custom workflow'
	String get customWorkflow => 'Custom workflow';

	/// en: 'Build & test'
	String get buildAndTest => 'Build & test';

	/// en: 'Run tests only'
	String get testOnly => 'Run tests only';

	/// en: 'Lint & analyze'
	String get lintAnalyze => 'Lint & analyze';

	/// en: 'Build & deploy'
	String get buildDeploy => 'Build & deploy';

	/// en: 'Run unit tests'
	String get unitTests => 'Run unit tests';

	/// en: 'Lint with SwiftLint'
	String get swiftlint => 'Lint with SwiftLint';

	/// en: 'Build archive'
	String get buildArchive => 'Build archive';

	/// en: 'Lint check'
	String get lintCheck => 'Lint check';

	/// en: 'Build APK'
	String get buildApk => 'Build APK';

	/// en: 'On push to main'
	String get pushToMain => 'On push to main';

	/// en: 'On pull request'
	String get onPullRequest => 'On pull request';

	/// en: 'On push to develop'
	String get pushToDevelop => 'On push to develop';

	/// en: 'On tag creation'
	String get tagCreation => 'On tag creation';

	/// en: 'On every push'
	String get everyPush => 'On every push';

	/// en: 'Looks good, use this!'
	String get looksGood => 'Looks good, use this!';

	/// en: 'Add more steps'
	String get addSteps => 'Add more steps';

	/// en: 'Change the trigger'
	String get changeTrigger => 'Change the trigger';

	/// en: 'Start over'
	String get startOver => 'Start over';
}

// Path: aiWorkflow.projectLabel
class TranslationsAiWorkflowProjectLabelEn {
	TranslationsAiWorkflowProjectLabelEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flutter'
	String get flutter => 'Flutter';

	/// en: 'iOS (Native)'
	String get ios => 'iOS (Native)';

	/// en: 'Android (Native)'
	String get android => 'Android (Native)';

	/// en: 'Node.js'
	String get node => 'Node.js';

	/// en: 'Custom'
	String get custom => 'Custom';
}

// Path: aiWorkflow.goalLabel
class TranslationsAiWorkflowGoalLabelEn {
	TranslationsAiWorkflowGoalLabelEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Run tests'
	String get test => 'Run tests';

	/// en: 'Build & Test'
	String get buildAndTest => 'Build & Test';

	/// en: 'Build & Deploy'
	String get deploy => 'Build & Deploy';

	/// en: 'Lint / Analyze'
	String get lint => 'Lint / Analyze';
}

// Path: aiWorkflow.triggerLabel
class TranslationsAiWorkflowTriggerLabelEn {
	TranslationsAiWorkflowTriggerLabelEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Pull Request'
	String get pullRequest => 'Pull Request';
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
			'common.add' => 'Add',
			'common.edit' => 'Edit',
			'common.error' => ({required Object error}) => 'Error: ${error}',
			'common.loading' => 'Loading...',
			'common.invite' => 'Invite',
			'timeAgo.secsAgo' => ({required Object count}) => '${count} sec ago',
			'timeAgo.secsAgoPlural' => ({required Object count}) => '${count} secs ago',
			'timeAgo.minsAgo' => ({required Object count}) => '${count} min ago',
			'timeAgo.minsAgoPlural' => ({required Object count}) => '${count} mins ago',
			'timeAgo.hoursAgo' => ({required Object count}) => '${count}h ago',
			'timeAgo.daysAgo' => ({required Object count}) => '${count}d ago',
			'timeAgo.monthsAgo' => ({required Object count}) => '${count}mo ago',
			'nav.workflows' => 'Workflows',
			'nav.variables' => 'Variables',
			'nav.logs' => 'Logs',
			'nav.release' => 'Release',
			'nav.settings' => 'Settings',
			'auth.email' => 'Email',
			'auth.password' => 'Password',
			'auth.login' => 'Log in',
			'auth.createAccount' => 'Create new account',
			'auth.useYourFirebase' => 'Use your Firebase',
			'auth.resetFirebase' => 'Reset Firebase',
			'auth.resetSuccess' => 'Firebase reset successfully. Please restart the app.',
			'auth.agreePrefix' => 'I agree to the ',
			'auth.termsOfService' => 'Terms of Service',
			'auth.enterEmail' => 'Please enter your email',
			'auth.enterPassword' => 'Please enter your password',
			'auth.firebaseForm.title' => 'Use your Firebase',
			'auth.firebaseForm.name' => 'Name',
			'auth.firebaseForm.apiKey' => 'API Key',
			'auth.firebaseForm.appId' => 'App ID',
			'auth.firebaseForm.messagingSenderId' => 'Messaging Sender ID',
			'auth.firebaseForm.projectId' => 'Project ID',
			'auth.firebaseForm.storageBucket' => 'Storage Bucket',
			'auth.firebaseForm.pickConfig' => 'Save configuration',
			'auth.firebaseForm.cloudRunHash' => 'Cloud Run Hash',
			'auth.firebaseForm.cloudRunRegionCode' => 'Cloud Run Region Code',
			'auth.firebaseForm.configSaved' => 'Configuration saved. Please restart the app to apply.',
			'auth.firebaseForm.configActive' => 'Custom Firebase project is configured. Restart to apply.',
			'auth.firebaseForm.importFile' => 'Import from file',
			'auth.firebaseForm.importFileHint' => 'JSON (google-services.json) or plist (GoogleService-Info.plist)',
			'auth.firebaseForm.invalidFile' => 'Could not parse the selected file. Please check the format.',
			'auth.firebaseForm.fileLoaded' => 'Config loaded from file. Review and save.',
			'workflow.title' => 'Workflows',
			'workflow.tabWorkflows' => 'Workflows',
			'workflow.tabRuns' => 'Runs',
			'workflow.addWorkflow' => 'Add Workflow',
			'workflow.noWorkflowFiles' => 'No workflow files found',
			'workflow.addYamlHint' => 'Add YAML files to .openci/ in your repository.',
			'workflow.selectRepo' => 'Select a repository',
			'workflow.selectRepoHint' => 'Choose a GitHub repository to manage workflows.',
			'workflow.selectRepoButton' => 'Select Repository',
			'workflow.enabled' => 'Enabled',
			'workflow.disabled' => 'Disabled',
			'workflow.enabledDescription' => 'This workflow will run when triggered.',
			'workflow.disabledDescription' => 'This workflow is paused and will not run.',
			'workflow.enable' => 'Enable workflow',
			'workflow.disable' => 'Disable workflow',
			'workflow.triggers' => 'Triggers',
			'workflow.triggerBranch' => ({required Object type}) => '${type} branch',
			'workflow.triggerBranchLoading' => ({required Object type}) => '${type} branch (loading...)',
			'workflow.selectBranch' => 'Select Branch',
			'workflow.selectBranchHint' => 'Choose a branch to view workflows from.',
			'workflow.noBranches' => 'No branches found',
			'workflow.selectRepository' => 'Select Repository',
			'workflow.selectRepositoryHint' => 'Choose a GitHub repository to manage workflows.',
			'workflow.searchRepositories' => 'Search repositories...',
			'workflow.noRepositories' => 'No repositories found.\nPlease install the OpenCI GitHub App.',
			'workflow.noMatchingRepositories' => ({required Object query}) => 'No repositories matching "${query}"',
			'workflow.defaultBranch' => ({required Object branch}) => 'default: ${branch}',
			'workflow.editor.createTitle' => 'Create Workflow',
			'workflow.editor.editTitle' => 'Edit Workflow',
			'workflow.editor.editorTab' => 'Editor',
			'workflow.editor.yamlTab' => 'YAML',
			'workflow.editor.basicInfo' => 'Basic Info',
			'workflow.editor.workflowName' => 'Workflow Name',
			'workflow.editor.stepName' => 'Step Name',
			'workflow.editor.stepNameHint' => 'e.g. Build iOS App',
			'workflow.editor.type' => 'Type',
			'workflow.editor.command' => 'Command',
			'workflow.editor.action' => 'Action',
			'workflow.editor.actionHint' => 'Tap to search actions',
			'workflow.editor.version' => 'Version',
			'workflow.editor.kWith' => 'with',
			'workflow.editor.loadingInputs' => 'Loading inputs...',
			'workflow.editor.couldNotLoadInputs' => 'Could not load inputs',
			'workflow.editor.noInputs' => 'No inputs defined for this action',
			'workflow.editor.enterAction' => 'Enter an action to see available inputs',
			'workflow.editor.loadingVersions' => 'Loading versions...',
			'workflow.editor.required' => 'required',
			'workflow.editor.editStep' => 'Edit Step',
			'workflow.editor.deleteStep' => 'Delete Step',
			'workflow.editor.deleteStepConfirm' => 'Are you sure you want to delete this step?',
			'workflow.editor.saveToRepo' => 'Save to Repository',
			'workflow.editor.fileName' => 'File Name',
			'workflow.editor.fileNameHint' => 'e.g. build.yaml',
			'workflow.editor.howToSave' => 'How to save',
			'workflow.editor.commitDirectly' => 'Commit directly',
			'workflow.editor.commitToBranch' => ({required Object branch}) => 'Commit to the ${branch} branch',
			'workflow.editor.createPR' => 'Create a Pull Request',
			'workflow.editor.createPRSubtitle' => 'A new branch will be created and a PR opened',
			'workflow.editor.commitToBranchButton' => ({required Object branch}) => 'Commit to ${branch}',
			'workflow.editor.createPRButton' => 'Create Pull Request',
			'workflow.editor.enterFileName' => 'Please enter a file name',
			'workflow.editor.fileNameMustEndYaml' => 'File name must end with .yaml or .yml',
			'workflow.editor.prCreated' => 'Pull Request Created',
			'workflow.editor.prNumber' => ({required Object number}) => 'PR #${number} was created.',
			'workflow.editor.close' => 'Close',
			'workflow.editor.openInGitHub' => 'Open in GitHub',
			'workflow.editor.committedToBranch' => ({required Object branch}) => 'Workflow file committed to ${branch}',
			'workflow.editor.prCreatedSuccess' => 'Pull request created',
			'workflow.editor.addSteps' => 'Add step',
			'workflow.editor.addJob' => 'Add Job',
			'workflow.editor.parallel' => 'Parallel',
			'buildLogs.title' => ({required Object date}) => 'Build Logs - ${date}',
			'buildLogs.noJobs' => 'No build jobs found',
			'buildLogs.status.success' => 'Success',
			'buildLogs.status.failed' => 'Failed',
			'buildLogs.status.inProgress' => 'In Progress',
			'buildLogs.status.queued' => 'Queued',
			'buildLogs.status.cancelled' => 'Cancelled',
			'buildLogs.detail.viewDetails' => 'View Details',
			'buildLogs.detail.retry' => 'Retry',
			'buildLogs.detail.cancelBuild' => 'Cancel Build',
			'buildLogs.detail.cancelConfirm' => 'Are you sure you want to cancel this build?',
			'buildLogs.detail.cancelNo' => 'No',
			'buildLogs.detail.cancelling' => 'Cancelling build...',
			'buildLogs.detail.buildCancelled' => 'Build cancelled',
			'buildLogs.detail.failedToCancel' => ({required Object error}) => 'Failed to cancel: ${error}',
			'buildLogs.detail.retrying' => 'Retrying build job...',
			'buildLogs.detail.retrySuccess' => 'Build job queued successfully',
			'buildLogs.detail.failedToRetry' => ({required Object error}) => 'Failed to retry: ${error}',
			'buildLogs.detail.noRuns' => 'No runs yet',
			'buildLogs.detail.waitingForLogs' => 'Waiting for logs...',
			'buildLogs.detail.logEntries' => ({required Object count}) => '${count} log entries',
			'buildLogs.detail.copyAll' => 'Copy all logs',
			'buildLogs.detail.logsCopied' => 'Logs copied to clipboard',
			'buildLogs.detail.lines' => ({required Object count}) => '${count} lines',
			'buildLogs.detail.generatingSummary' => 'Generating AI summary...',
			'buildLogs.detail.failureSummaryTitle' => 'AI Failure Summary',
			'buildLogs.duration.lessThanMinute' => '<1m',
			'buildLogs.duration.minutes' => ({required Object count}) => '${count}m',
			'buildLogs.duration.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours}h ${minutes}m',
			'buildLogs.duration.hours' => ({required Object count}) => '${count}h',
			'variables.title' => 'Variables',
			'variables.envVarsTab' => 'Environment Variables',
			'variables.secretsTab' => 'Secrets',
			'secrets.title' => 'Secret Manager',
			'secrets.noSecrets' => 'No secrets found',
			'secrets.addSecret' => 'Add Secret',
			'secrets.editSecret' => 'Edit Secret',
			'secrets.secretName' => 'SECRET_NAME',
			'secrets.secretValue' => 'Secret Value',
			'secrets.newSecretValue' => 'New Secret Value (leave empty to keep current)',
			'secrets.enterSecretName' => 'Please enter a secret name',
			'secrets.enterSecretValue' => 'Please enter a secret value',
			'secrets.addedSuccess' => 'Secret added successfully',
			'secrets.updatedSuccess' => 'Secret updated successfully',
			'secrets.deleteConfirm' => 'Are you sure you want to delete this secret? This action cannot be undone.',
			'secrets.deletedSuccess' => 'Secret deleted successfully',
			'secrets.unusedSecrets' => 'Unused Secrets',
			'secrets.notUsedInWorkflows' => 'Not used in any workflow',
			'secrets.inputModeText' => 'Text',
			'secrets.inputModeFile' => 'File',
			'secrets.uploadFile' => 'Upload file',
			'secrets.fileSelected' => ({required Object fileName}) => '${fileName} selected',
			'secrets.orUploadFile' => 'Click to select a file',
			'secrets.enterValueOrUpload' => 'Please enter a value or upload a file',
			'envVars.title' => 'Environment Variables',
			'envVars.noEnvVars' => 'No environment variables found',
			'envVars.noCustomEnvVars' => 'No custom environment variables',
			'envVars.addEnvVar' => 'Add Environment Variable',
			'envVars.editEnvVar' => 'Edit Environment Variable',
			'envVars.editRunNumber' => 'Edit Run Number',
			'envVars.keyName' => 'KEY_NAME',
			'envVars.value' => 'Value',
			'envVars.keyHint' => 'e.g. MY_VARIABLE',
			'envVars.valueHint' => 'e.g. hello',
			'envVars.enterKeyName' => 'Please enter a key name',
			'envVars.enterValue' => 'Please enter a value',
			'envVars.invalidKey' => 'Use only letters, numbers, and underscores',
			'envVars.valueMustBeNumber' => 'Value must be a number',
			'envVars.addedSuccess' => 'Environment variable added',
			'envVars.updatedSuccess' => 'Environment variable updated',
			'envVars.deletedSuccess' => 'Deleted successfully',
			'envVars.runNumberUpdated' => 'Run number updated',
			'settings.title' => 'Settings',
			'settings.general' => 'General',
			'settings.preferences' => 'Preferences',
			'settings.buildNotifications' => 'Build Notifications',
			'settings.configureNotifications' => 'Configure when to receive notifications',
			'settings.subscription' => 'Subscription',
			'settings.manageSubscription' => 'Manage your subscription plan',
			'settings.firebaseAppName' => ({required Object name}) => 'Firebase App Name: ${name}',
			'settings.resetToCloud' => 'Reset to OpenCI Cloud',
			'settings.resetToCloudSuccess' => 'Configuration cleared. Please restart the app.',
			'settings.selfHostedActive' => 'Self-hosted Firebase',
			'settings.selfHostedProject' => ({required Object projectId}) => 'Project: ${projectId}',
			'settings.inviteTeamMember' => 'Invite Team Member',
			'settings.appVersion' => 'App Version',
			'settings.logout' => 'Logout',
			'settings.logoutSuccess' => 'Logged out successfully',
			'settings.logoutFailed' => ({required Object error}) => 'Failed to log out: ${error}',
			'settings.deleteAccount' => 'Delete Account',
			'settings.deleteConfirmTitle' => 'Delete Account',
			'settings.deleteConfirmMessage' => 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
			'settings.deleteSuccess' => 'Account deleted successfully',
			'settings.noUserSignedIn' => 'No user is currently signed in',
			'settings.requiresRecentLogin' => 'Please sign out and sign in again before deleting your account',
			'settings.deleteFailed' => ({required Object error}) => 'Failed to delete account: ${error}',
			'settings.aiFeatures.title' => 'AI Features',
			'settings.aiFeatures.subtitle' => 'Enable AI-powered features like workflow builder and failure summaries',
			'settings.aiFeatures.enabled' => 'AI features are enabled',
			'settings.aiFeatures.disabled' => 'AI features are disabled',
			'settings.aiFeatures.updated' => 'AI features setting updated',
			'settings.language.title' => 'Language',
			'settings.language.subtitle' => 'Change the display language',
			'settings.language.system' => 'System Default',
			'settings.language.english' => 'English',
			'settings.language.japanese' => '日本語',
			'settings.language.spanish' => 'Español',
			'notifications.title' => 'Build Notifications',
			'notifications.all' => 'All',
			'notifications.allDesc' => 'Notify on both success and failure',
			'notifications.successOnly' => 'Success Only',
			'notifications.successOnlyDesc' => 'Notify only when build succeeds',
			'notifications.failureOnly' => 'Failure Only',
			'notifications.failureOnlyDesc' => 'Notify only when build fails',
			'notifications.none' => 'None',
			'notifications.noneDesc' => 'Do not send any notifications',
			'notifications.updated' => 'Notification preference updated',
			'notifications.updateFailed' => ({required Object error}) => 'Failed to update: ${error}',
			'notifications.errorLoading' => ({required Object error}) => 'Error loading settings: ${error}',
			'team.switchTeam' => 'Switch Team',
			'team.editTeam' => 'Edit Team',
			'team.createTeam' => 'Create Team',
			'team.createNewTeam' => 'Create New Team',
			'team.teamName' => 'Team Name',
			'team.newTeamName' => 'New Team Name',
			'team.selectTeam' => 'Select a team',
			'team.selectTeamLabel' => 'Team',
			'team.enterTeamName' => 'Please enter a team name',
			'team.selectTeamValidation' => 'Please select a team',
			'team.createdSuccess' => 'Team created successfully',
			'team.updatedSuccess' => 'Team name updated successfully',
			'team.selectedSuccess' => 'Team selected successfully',
			'team.inviteTitle' => 'Invite Team Member',
			'team.inviteEmail' => 'Email',
			'team.enterEmail' => 'Please enter an email',
			'team.invitedSuccess' => 'Team member invited successfully',
			'team.addedSuccess' => 'Member added to team',
			'team.invitationSent' => 'Invitation email sent 📧',
			'team.processingInvitation' => 'Processing invitation...',
			'team.invitationFailed' => 'Invitation Failed',
			'team.invitationAccepted' => 'You\'re in! 🎉',
			'team.alreadyMemberTitle' => 'Already a Member',
			'team.alreadyMemberMessage' => ({required Object teamName}) => 'You\'re already a member of "${teamName}".',
			'team.joinedTeamMessage' => ({required Object teamName}) => 'You\'ve joined the "${teamName}" team.',
			'team.goToDashboard' => 'Go to Dashboard',
			'team.members' => 'Members',
			'team.membersCount' => ({required Object count}) => '${count} members',
			'team.you' => 'You',
			'team.noEmail' => 'No email',
			'team.deleteTeam' => 'Delete Team',
			'team.deleteTeamConfirm' => ({required Object teamName}) => 'Are you sure you want to delete "${teamName}"? This action cannot be undone. All workflows, secrets, and environment variables associated with this team will be permanently deleted.',
			'team.deletedSuccess' => 'Team deleted successfully',
			'team.cannotDeleteLastTeam' => 'You cannot delete your last team. Please create another team first.',
			'github.connectTitle' => 'Connect GitHub',
			'github.connectDescription' => 'Connect your GitHub account to\nselect repositories automatically.',
			'github.connectButton' => 'Connect with GitHub',
			'subscription.title' => 'Subscription',
			'subscription.noOfferings' => 'No offerings available',
			'subscription.noPackages' => 'No packages available',
			'subscription.plans' => 'Plans',
			'subscription.restorePurchases' => 'Restore Purchases',
			'subscription.purchaseSuccess' => 'Purchase successful!',
			'subscription.purchaseFailed' => ({required Object error}) => 'Purchase failed: ${error}',
			'subscription.restoreSuccess' => 'Purchases restored successfully',
			'subscription.restoreFailed' => ({required Object error}) => 'Restore failed: ${error}',
			'subscription.activeSubscription' => 'Active Subscription',
			'subscription.active' => 'Active',
			'subscription.termsOfUse' => 'Terms of Use',
			'subscription.privacyPolicy' => 'Privacy Policy',
			'subscription.subscriptionTerms' => 'Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.',
			'subscription.subscriptionTermsWeb' => 'Subscriptions automatically renew unless canceled before the end of the current billing period. You can manage and cancel your subscription from your account settings. Payments are processed securely via Stripe.',
			'subscription.perWeek' => 'per week',
			'subscription.perMonth' => 'per month',
			'subscription.per3Months' => 'per 3 months',
			'subscription.per6Months' => 'per 6 months',
			'subscription.perYear' => 'per year',
			'aiWorkflow.title' => 'AI Workflow Builder',
			'aiWorkflow.inputHint' => 'Describe your workflow...',
			'aiWorkflow.generatedWorkflow' => 'Generated Workflow',
			'aiWorkflow.useThisWorkflow' => 'Use this workflow',
			'aiWorkflow.chat.greeting' => 'What kind of workflow would you like to create? Tell me about your project and I\'ll help you set it up.',
			'aiWorkflow.chat.projectSelected' => ({required Object project}) => 'Got it! A ${project} project. What would you like the workflow to do?',
			'aiWorkflow.chat.triggerQuestion' => 'When should this workflow run?',
			'aiWorkflow.chat.workflowGenerated' => ({required Object plan}) => 'I\'ve generated your workflow! Here\'s what it includes:\n\n${plan}\n\nYou can use this workflow as-is, or tell me what you\'d like to change.',
			'aiWorkflow.chat.stepAdded' => 'I\'ve added a placeholder step. You can customize it in the editor after applying this workflow.',
			'aiWorkflow.chat.changeTriggerPrompt' => 'Sure! When should this workflow run?',
			'aiWorkflow.chat.followUp' => 'You can use the generated workflow by tapping \'Use this workflow\', or tell me what changes you\'d like.',
			'aiWorkflow.chat.planFormat' => ({required Object project, required Object steps, required Object trigger}) => '- Project: ${project}\n- Steps: ${steps}\n- Trigger: ${trigger}',
			'aiWorkflow.chat.errorMessage' => 'Sorry, something went wrong. Please try again or start over.',
			'aiWorkflow.suggestion.flutterCiCd' => 'Flutter app CI/CD',
			'aiWorkflow.suggestion.iosBuildTest' => 'iOS app build & test',
			'aiWorkflow.suggestion.androidBuild' => 'Android app build',
			'aiWorkflow.suggestion.testOnPr' => 'Run tests on PR',
			'aiWorkflow.suggestion.customWorkflow' => 'Custom workflow',
			'aiWorkflow.suggestion.buildAndTest' => 'Build & test',
			'aiWorkflow.suggestion.testOnly' => 'Run tests only',
			'aiWorkflow.suggestion.lintAnalyze' => 'Lint & analyze',
			'aiWorkflow.suggestion.buildDeploy' => 'Build & deploy',
			'aiWorkflow.suggestion.unitTests' => 'Run unit tests',
			'aiWorkflow.suggestion.swiftlint' => 'Lint with SwiftLint',
			'aiWorkflow.suggestion.buildArchive' => 'Build archive',
			'aiWorkflow.suggestion.lintCheck' => 'Lint check',
			'aiWorkflow.suggestion.buildApk' => 'Build APK',
			'aiWorkflow.suggestion.pushToMain' => 'On push to main',
			'aiWorkflow.suggestion.onPullRequest' => 'On pull request',
			'aiWorkflow.suggestion.pushToDevelop' => 'On push to develop',
			'aiWorkflow.suggestion.tagCreation' => 'On tag creation',
			'aiWorkflow.suggestion.everyPush' => 'On every push',
			'aiWorkflow.suggestion.looksGood' => 'Looks good, use this!',
			'aiWorkflow.suggestion.addSteps' => 'Add more steps',
			'aiWorkflow.suggestion.changeTrigger' => 'Change the trigger',
			'aiWorkflow.suggestion.startOver' => 'Start over',
			'aiWorkflow.projectLabel.flutter' => 'Flutter',
			'aiWorkflow.projectLabel.ios' => 'iOS (Native)',
			'aiWorkflow.projectLabel.android' => 'Android (Native)',
			'aiWorkflow.projectLabel.node' => 'Node.js',
			'aiWorkflow.projectLabel.custom' => 'Custom',
			'aiWorkflow.goalLabel.test' => 'Run tests',
			'aiWorkflow.goalLabel.buildAndTest' => 'Build & Test',
			'aiWorkflow.goalLabel.deploy' => 'Build & Deploy',
			'aiWorkflow.goalLabel.lint' => 'Lint / Analyze',
			'aiWorkflow.triggerLabel.pullRequest' => 'Pull Request',
			'storeRelease.title' => 'Store Release',
			'storeRelease.setupTitle' => 'Connect App Store Connect',
			'storeRelease.setupDescription' => 'Enter your App Store Connect API credentials to manage releases directly from OpenCI.',
			'storeRelease.issuerId' => 'Issuer ID',
			'storeRelease.keyId' => 'Key ID',
			'storeRelease.privateKey' => 'Private Key (.p8)',
			'storeRelease.privateKeyHint' => 'Paste the contents of your .p8 file',
			'storeRelease.connect' => 'Connect',
			'storeRelease.connecting' => 'Connecting...',
			'storeRelease.setupSuccess' => 'App Store Connect connected successfully',
			'storeRelease.setupFailed' => ({required Object error}) => 'Failed to connect: ${error}',
			'storeRelease.enterIssuerId' => 'Please enter the Issuer ID',
			'storeRelease.enterKeyId' => 'Please enter the Key ID',
			'storeRelease.enterPrivateKey' => 'Please enter the private key',
			'storeRelease.selectApp' => 'Select App',
			'storeRelease.selectAppHint' => 'Choose an app to manage releases',
			'storeRelease.noApps' => 'No apps found',
			'storeRelease.noAppsHint' => 'No apps were found in your App Store Connect account.',
			'storeRelease.loadingApps' => 'Loading apps...',
			'storeRelease.ascLoadingHint' => 'App Store Connect API may take a moment to respond',
			'storeRelease.builds' => 'Builds',
			'storeRelease.noBuilds' => 'No builds found',
			'storeRelease.noBuildsHint' => 'Upload a build to App Store Connect to get started.',
			'storeRelease.version' => ({required Object version}) => 'v${version}',
			'storeRelease.buildNumber' => ({required Object number}) => 'Build ${number}',
			'storeRelease.processing' => 'Processing',
			'storeRelease.readyForSale' => 'Ready for Sale',
			'storeRelease.valid' => 'Ready',
			'storeRelease.invalid' => 'Invalid',
			'storeRelease.testFlight' => 'TestFlight',
			'storeRelease.submitToTestFlight' => 'Submit to TestFlight',
			'storeRelease.submitToTestFlightConfirm' => 'Submit this build to external testers via TestFlight?',
			'storeRelease.testFlightSuccess' => ({required Object group}) => 'Build submitted to TestFlight group: ${group}',
			'storeRelease.testFlightFailed' => ({required Object error}) => 'Failed to submit to TestFlight: ${error}',
			'storeRelease.appStoreReview' => 'App Store Review',
			'storeRelease.submitForReview' => 'Submit for Review',
			'storeRelease.submitForReviewConfirm' => ({required Object version}) => 'Submit this build for App Store Review?\n\nVersion: ${version}',
			'storeRelease.reviewSuccess' => 'Build submitted for App Store Review',
			'storeRelease.reviewFailed' => ({required Object error}) => 'Failed to submit for review: ${error}',
			'storeRelease.versionString' => 'Version String',
			'storeRelease.enterVersionString' => 'e.g. 1.0.0',
			'storeRelease.versionRequired' => 'Please enter a version string',
			'storeRelease.whatsNew' => 'What\'s New',
			'storeRelease.whatsNewHint' => 'Describe what\'s new in this version',
			'storeRelease.whatsNewRequired' => 'Please enter release notes',
			'storeRelease.changeApp' => 'Change App',
			'storeRelease.reconfigure' => 'Reconfigure',
			'storeRelease.howToGetCredentials' => 'How to get credentials',
			'storeRelease.credentialsHelp' => 'Go to App Store Connect > Users and Access > Integrations > App Store Connect API to generate an API key.',
			'storeRelease.waitingForReview' => 'Waiting for Review',
			'storeRelease.inReview' => 'In Review',
			'storeRelease.pendingRelease' => 'Pending Release',
			'storeRelease.readyForDistribution' => 'Ready for Distribution',
			'storeRelease.developerRejected' => 'Developer Rejected',
			'storeRelease.rejected' => 'Rejected',
			'storeRelease.prepareForSubmission' => 'Prepare for Submission',
			'storeRelease.submitted' => 'Submitted',
			'storeRelease.stepBuild' => 'Build',
			'storeRelease.stepDetails' => 'Details',
			'storeRelease.stepReview' => 'Review',
			'storeRelease.selectBuildTitle' => 'Select a Build',
			'storeRelease.selectBuildHint' => 'Choose a build to submit for App Store Review',
			'storeRelease.releaseDetailsTitle' => 'Release Details',
			'storeRelease.releaseDetailsHint' => 'Configure version and release notes',
			'storeRelease.reviewTitle' => 'Review & Submit',
			'storeRelease.reviewHint' => 'Confirm all details before submitting',
			'storeRelease.next' => 'Next',
			'storeRelease.back' => 'Back',
			'storeRelease.confirmSubmit' => 'Submit for Review',
			'storeRelease.submittingReview' => 'Submitting...',
			'storeRelease.selectedBuildLabel' => 'Selected Build',
			'storeRelease.screenshotsTitle' => 'Screenshots',
			'storeRelease.noScreenshots' => 'No screenshots available',
			'storeRelease.screenshotsHint' => 'Manage screenshots in App Store Connect',
			'storeRelease.screenshotCount' => ({required Object count}) => '${count} screenshots',
			'storeRelease.appDescription' => 'Description',
			'storeRelease.keywordsLabel' => 'Keywords',
			'storeRelease.noVersionInfo' => 'No existing version info found',
			'storeRelease.existingInfo' => 'Current App Store Info',
			'storeRelease.summarySection' => 'Submission Summary',
			'storeRelease.underReview' => 'Under Review',
			'storeRelease.underReviewDescription' => 'Your app is currently being reviewed by Apple. No changes can be made until the review is complete.',
			'storeRelease.waitingForReviewDescription' => 'Your app has been submitted and is waiting for Apple to begin the review.',
			'storeRelease.pendingReleaseTitle' => 'Approved',
			'storeRelease.pendingReleaseDescription' => 'Your app has been approved! It is pending release to the App Store.',
			'storeRelease.submittedBuild' => 'Submitted Build',
			'storeRelease.submittedOn' => 'Submitted',
			'storeRelease.estimatedWait' => 'Reviews typically take 24-48 hours',
			'storeRelease.viewInAsc' => 'View in App Store Connect',
			_ => null,
		};
	}
}
