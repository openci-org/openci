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
	late final TranslationsNavEn nav = TranslationsNavEn._(_root);
	late final TranslationsAuthEn auth = TranslationsAuthEn._(_root);
	late final TranslationsWorkflowEn workflow = TranslationsWorkflowEn._(_root);
	late final TranslationsBuildLogsEn buildLogs = TranslationsBuildLogsEn._(_root);
	late final TranslationsSecretsEn secrets = TranslationsSecretsEn._(_root);
	late final TranslationsEnvVarsEn envVars = TranslationsEnvVarsEn._(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn._(_root);
	late final TranslationsNotificationsEn notifications = TranslationsNotificationsEn._(_root);
	late final TranslationsTeamEn team = TranslationsTeamEn._(_root);
	late final TranslationsSubscriptionEn subscription = TranslationsSubscriptionEn._(_root);
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

// Path: nav
class TranslationsNavEn {
	TranslationsNavEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Workflows'
	String get workflows => 'Workflows';

	/// en: 'Secrets'
	String get secrets => 'Secrets';

	/// en: 'Env Vars'
	String get envVars => 'Env Vars';

	/// en: 'Logs'
	String get logs => 'Logs';

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

	/// en: 'Triggers'
	String get triggers => 'Triggers';

	/// en: '$type branch'
	String triggerBranch({required Object type}) => '${type} branch';

	/// en: '$type branch (loading...)'
	String triggerBranchLoading({required Object type}) => '${type} branch (loading...)';

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

	/// en: 'Invite Team Member'
	String get inviteTeamMember => 'Invite Team Member';

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

	/// en: 'Pick Firebase config'
	String get pickConfig => 'Pick Firebase config';
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
			'nav.workflows' => 'Workflows',
			'nav.secrets' => 'Secrets',
			'nav.envVars' => 'Env Vars',
			'nav.logs' => 'Logs',
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
			'auth.firebaseForm.pickConfig' => 'Pick Firebase config',
			'workflow.title' => 'Workflows',
			'workflow.addWorkflow' => 'Add Workflow',
			'workflow.noWorkflowFiles' => 'No workflow files found',
			'workflow.addYamlHint' => 'Add YAML files to .openci/ in your repository.',
			'workflow.selectRepo' => 'Select a repository',
			'workflow.selectRepoHint' => 'Choose a GitHub repository to manage workflows.',
			'workflow.selectRepoButton' => 'Select Repository',
			'workflow.triggers' => 'Triggers',
			'workflow.triggerBranch' => ({required Object type}) => '${type} branch',
			'workflow.triggerBranchLoading' => ({required Object type}) => '${type} branch (loading...)',
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
			'buildLogs.title' => ({required Object date}) => 'Build Logs - ${date}',
			'buildLogs.noJobs' => 'No build jobs found',
			'buildLogs.status.success' => 'Success',
			'buildLogs.status.failed' => 'Failed',
			'buildLogs.status.inProgress' => 'In Progress',
			'buildLogs.status.queued' => 'Queued',
			'buildLogs.status.cancelled' => 'Cancelled',
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
			'settings.buildNotifications' => 'Build Notifications',
			'settings.configureNotifications' => 'Configure when to receive notifications',
			'settings.subscription' => 'Subscription',
			'settings.manageSubscription' => 'Manage your subscription plan',
			'settings.firebaseAppName' => ({required Object name}) => 'Firebase App Name: ${name}',
			'settings.inviteTeamMember' => 'Invite Team Member',
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
			'subscription.perWeek' => 'per week',
			'subscription.perMonth' => 'per month',
			'subscription.per3Months' => 'per 3 months',
			'subscription.per6Months' => 'per 6 months',
			'subscription.perYear' => 'per year',
			_ => null,
		};
	}
}
