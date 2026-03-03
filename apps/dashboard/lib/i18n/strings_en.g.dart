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
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsAuthEn auth = TranslationsAuthEn.internal(_root);
	late final TranslationsNavigationEn navigation = TranslationsNavigationEn.internal(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn.internal(_root);
	late final TranslationsVariablesEn variables = TranslationsVariablesEn.internal(_root);
	late final TranslationsLogsEn logs = TranslationsLogsEn.internal(_root);
	late final TranslationsWorkflowsEn workflows = TranslationsWorkflowsEn.internal(_root);
	late final TranslationsLocaleEn locale = TranslationsLocaleEn.internal(_root);
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Error: $error'
	String error({required Object error}) => 'Error: ${error}';

	/// en: 'Open Source CI/CD'
	String get openSource => 'Open Source CI/CD';
}

// Path: auth
class TranslationsAuthEn {
	TranslationsAuthEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Please enter your email'
	String get pleaseEnterEmail => 'Please enter your email';

	/// en: 'Please enter a valid email'
	String get pleaseEnterValidEmail => 'Please enter a valid email';

	/// en: 'Please enter your password'
	String get pleaseEnterPassword => 'Please enter your password';

	/// en: 'Password must be at least 6 characters'
	String get passwordTooShort => 'Password must be at least 6 characters';

	/// en: 'Sign in'
	String get signIn => 'Sign in';

	/// en: 'Sign up'
	String get signUp => 'Sign up';

	/// en: 'Don't have an account? Sign up'
	String get switchToSignUp => 'Don\'t have an account? Sign up';

	/// en: 'Already have an account? Sign in'
	String get switchToSignIn => 'Already have an account? Sign in';

	/// en: 'I agree to the '
	String get agreePrefix => 'I agree to the ';

	/// en: 'Terms of Service'
	String get termsOfService => 'Terms of Service';

	/// en: 'Authentication failed.'
	String get authFailed => 'Authentication failed.';

	/// en: 'This email is already registered.'
	String get emailAlreadyInUse => 'This email is already registered.';

	/// en: 'Invalid email or password.'
	String get invalidCredential => 'Invalid email or password.';

	/// en: 'No account found with this email.'
	String get userNotFound => 'No account found with this email.';

	/// en: 'Password is too weak. Use at least 6 characters.'
	String get weakPassword => 'Password is too weak. Use at least 6 characters.';

	/// en: 'Too many attempts. Please try again later.'
	String get tooManyRequests => 'Too many attempts. Please try again later.';
}

// Path: navigation
class TranslationsNavigationEn {
	TranslationsNavigationEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Workflows'
	String get workflows => 'Workflows';

	/// en: 'Variables'
	String get variables => 'Variables';

	/// en: 'Logs'
	String get logs => 'Logs';

	/// en: 'Settings'
	String get settings => 'Settings';
}

// Path: settings
class TranslationsSettingsEn {
	TranslationsSettingsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'General'
	String get general => 'General';

	/// en: 'Build Notifications'
	String get buildNotifications => 'Build Notifications';

	/// en: 'Configure when to receive alerts'
	String get buildNotificationsDesc => 'Configure when to receive alerts';

	/// en: 'Subscription'
	String get subscription => 'Subscription';

	/// en: 'Manage your plan & billing'
	String get subscriptionDesc => 'Manage your plan & billing';

	/// en: 'Support'
	String get support => 'Support';

	/// en: 'GitHub Repository'
	String get githubRepo => 'GitHub Repository';

	/// en: 'Star & contribute to OpenCI'
	String get githubRepoDesc => 'Star & contribute to OpenCI';

	/// en: 'Opening GitHub...'
	String get openingGithub => 'Opening GitHub...';

	/// en: 'Report a Bug'
	String get reportBug => 'Report a Bug';

	/// en: 'Help us improve OpenCI'
	String get reportBugDesc => 'Help us improve OpenCI';

	/// en: 'Opening issue tracker...'
	String get openingIssueTracker => 'Opening issue tracker...';

	/// en: 'Account'
	String get account => 'Account';

	/// en: 'Logout'
	String get logout => 'Logout';

	/// en: 'Sign out from this device'
	String get logoutDesc => 'Sign out from this device';

	/// en: 'Logged out successfully'
	String get loggedOut => 'Logged out successfully';

	/// en: 'Failed to log out: $error'
	String logoutFailed({required Object error}) => 'Failed to log out: ${error}';

	/// en: 'Delete Account'
	String get deleteAccount => 'Delete Account';

	/// en: 'Permanently remove all your data'
	String get deleteAccountDesc => 'Permanently remove all your data';

	/// en: 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.'
	String get deleteConfirmation => 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.';

	/// en: 'Account deleted successfully'
	String get accountDeleted => 'Account deleted successfully';

	/// en: 'Failed to delete account: $error'
	String deleteAccountFailed({required Object error}) => 'Failed to delete account: ${error}';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Change the display language'
	String get languageDesc => 'Change the display language';
}

// Path: variables
class TranslationsVariablesEn {
	TranslationsVariablesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Variables'
	String get title => 'Variables';

	/// en: 'Secrets'
	String get secrets => 'Secrets';

	/// en: 'Environment'
	String get environment => 'Environment';

	/// en: 'No secrets yet'
	String get noSecretsYet => 'No secrets yet';

	/// en: 'Add encrypted secrets like API keys, tokens, and certificates.'
	String get noSecretsDesc => 'Add encrypted secrets like API keys,\ntokens, and certificates.';

	/// en: 'No environment variables'
	String get noEnvVars => 'No environment variables';

	/// en: 'Add variables that will be available during your CI/CD builds.'
	String get noEnvVarsDesc => 'Add variables that will be available\nduring your CI/CD builds.';

	/// en: 'Add Secret'
	String get addSecret => 'Add Secret';

	/// en: 'Edit Secret'
	String get editSecret => 'Edit Secret';

	/// en: 'SECRET_NAME'
	String get secretName => 'SECRET_NAME';

	/// en: 'e.g. API_KEY'
	String get secretNameHint => 'e.g. API_KEY';

	/// en: 'Secret Value'
	String get secretValue => 'Secret Value';

	/// en: 'Please enter a secret name'
	String get pleaseEnterSecretName => 'Please enter a secret name';

	/// en: 'Please enter a secret value'
	String get pleaseEnterSecretValue => 'Please enter a secret value';

	/// en: 'Secrets are encrypted and never exposed in logs.'
	String get secretsEncryptedNote => 'Secrets are encrypted and never exposed in logs.';

	/// en: 'Secret added'
	String get secretAdded => 'Secret added';

	/// en: 'Secret updated'
	String get secretUpdated => 'Secret updated';

	/// en: 'Save Changes'
	String get saveChanges => 'Save Changes';

	/// en: 'New Value (leave empty to keep current)'
	String get newValueHint => 'New Value (leave empty to keep current)';

	/// en: 'Add Variable'
	String get addEnvVar => 'Add Variable';

	/// en: 'Edit Variable'
	String get editEnvVar => 'Edit Variable';

	/// en: 'KEY'
	String get envKey => 'KEY';

	/// en: 'e.g. NODE_ENV'
	String get envKeyHint => 'e.g. NODE_ENV';

	/// en: 'Value'
	String get envValue => 'Value';

	/// en: 'e.g. production'
	String get envValueHint => 'e.g. production';

	/// en: 'Please enter a key'
	String get pleaseEnterKey => 'Please enter a key';

	/// en: 'Please enter a value'
	String get pleaseEnterValue => 'Please enter a value';

	/// en: 'Variable added'
	String get variableAdded => 'Variable added';

	/// en: 'Variable updated'
	String get variableUpdated => 'Variable updated';

	/// en: 'Delete Variable'
	String get deleteVariable => 'Delete Variable';

	/// en: 'Delete "$key"?'
	String deleteVariableConfirm({required Object key}) => 'Delete "${key}"?';

	/// en: 'Deleted successfully'
	String get deletedSuccessfully => 'Deleted successfully';
}

// Path: logs
class TranslationsLogsEn {
	TranslationsLogsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Build Logs'
	String get title => 'Build Logs';

	/// en: 'No builds yet'
	String get noBuildsYet => 'No builds yet';

	/// en: 'Build logs will appear here when workflows are triggered.'
	String get noBuildsDesc => 'Build logs will appear here\nwhen workflows are triggered.';

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Recent'
	String get recent => 'Recent';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Retrying build...'
	String get retrying => 'Retrying build...';

	/// en: 'Build queued successfully'
	String get buildQueued => 'Build queued successfully';

	/// en: 'Failed to retry: $error'
	String retryFailed({required Object error}) => 'Failed to retry: ${error}';

	/// en: 'Cancel Build'
	String get cancelBuild => 'Cancel Build';

	/// en: 'Are you sure you want to cancel this build?'
	String get cancelBuildConfirm => 'Are you sure you want to cancel this build?';

	/// en: 'No'
	String get no => 'No';

	/// en: 'Cancelling build...'
	String get cancelling => 'Cancelling build...';

	/// en: 'Build cancelled'
	String get buildCancelled => 'Build cancelled';

	/// en: 'Failed to cancel: $error'
	String cancelFailed({required Object error}) => 'Failed to cancel: ${error}';

	/// en: 'Fix with AI'
	String get fixWithAI => 'Fix with AI';

	/// en: 'Passed'
	String get passed => 'Passed';

	/// en: 'Failed'
	String get failed => 'Failed';

	/// en: 'Running'
	String get running => 'Running';

	/// en: 'Queued'
	String get queued => 'Queued';

	/// en: 'Cancelled'
	String get cancelled => 'Cancelled';

	/// en: 'Unknown'
	String get unknown => 'Unknown';
}

// Path: workflows
class TranslationsWorkflowsEn {
	TranslationsWorkflowsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Workflows'
	String get title => 'Workflows';

	/// en: 'No workflows yet'
	String get noWorkflows => 'No workflows yet';

	/// en: 'Create your first CI/CD workflow to start automating builds and deployments.'
	String get noWorkflowsDesc => 'Create your first CI/CD workflow to start\nautomating builds and deployments.';

	/// en: 'Create Workflow'
	String get createWorkflow => 'Create Workflow';

	/// en: '$count steps'
	String steps({required Object count}) => '${count} steps';

	/// en: 'Duplicate'
	String get duplicate => 'Duplicate';

	/// en: 'Workflow duplicated'
	String get duplicated => 'Workflow duplicated';

	/// en: 'Failed to duplicate: $error'
	String duplicateFailed({required Object error}) => 'Failed to duplicate: ${error}';

	/// en: 'Delete Workflow'
	String get deleteWorkflow => 'Delete Workflow';

	/// en: 'Are you sure you want to delete "$name"?'
	String deleteWorkflowConfirm({required Object name}) => 'Are you sure you want to delete "${name}"?';

	/// en: 'Workflow deleted'
	String get workflowDeleted => 'Workflow deleted';

	/// en: 'Failed to delete: $error'
	String deleteFailed({required Object error}) => 'Failed to delete: ${error}';

	/// en: 'Switch Team'
	String get switchTeam => 'Switch Team';

	/// en: 'Edit Team'
	String get editTeam => 'Edit Team';

	/// en: 'Create Team'
	String get createTeam => 'Create Team';

	/// en: 'Switch Branch & Commit'
	String get switchBranchCommit => 'Switch Branch & Commit';

	/// en: 'Branch'
	String get branch => 'Branch';

	/// en: 'Commits'
	String get commits => 'Commits';
}

// Path: locale
class TranslationsLocaleEn {
	TranslationsLocaleEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'English'
	String get en => 'English';

	/// en: '日本語'
	String get ja => '日本語';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.cancel' => 'Cancel',
			'common.delete' => 'Delete',
			'common.save' => 'Save',
			'common.add' => 'Add',
			'common.error' => ({required Object error}) => 'Error: ${error}',
			'common.openSource' => 'Open Source CI/CD',
			'auth.email' => 'Email',
			'auth.password' => 'Password',
			'auth.pleaseEnterEmail' => 'Please enter your email',
			'auth.pleaseEnterValidEmail' => 'Please enter a valid email',
			'auth.pleaseEnterPassword' => 'Please enter your password',
			'auth.passwordTooShort' => 'Password must be at least 6 characters',
			'auth.signIn' => 'Sign in',
			'auth.signUp' => 'Sign up',
			'auth.switchToSignUp' => 'Don\'t have an account? Sign up',
			'auth.switchToSignIn' => 'Already have an account? Sign in',
			'auth.agreePrefix' => 'I agree to the ',
			'auth.termsOfService' => 'Terms of Service',
			'auth.authFailed' => 'Authentication failed.',
			'auth.emailAlreadyInUse' => 'This email is already registered.',
			'auth.invalidCredential' => 'Invalid email or password.',
			'auth.userNotFound' => 'No account found with this email.',
			'auth.weakPassword' => 'Password is too weak. Use at least 6 characters.',
			'auth.tooManyRequests' => 'Too many attempts. Please try again later.',
			'navigation.workflows' => 'Workflows',
			'navigation.variables' => 'Variables',
			'navigation.logs' => 'Logs',
			'navigation.settings' => 'Settings',
			'settings.title' => 'Settings',
			'settings.general' => 'General',
			'settings.buildNotifications' => 'Build Notifications',
			'settings.buildNotificationsDesc' => 'Configure when to receive alerts',
			'settings.subscription' => 'Subscription',
			'settings.subscriptionDesc' => 'Manage your plan & billing',
			'settings.support' => 'Support',
			'settings.githubRepo' => 'GitHub Repository',
			'settings.githubRepoDesc' => 'Star & contribute to OpenCI',
			'settings.openingGithub' => 'Opening GitHub...',
			'settings.reportBug' => 'Report a Bug',
			'settings.reportBugDesc' => 'Help us improve OpenCI',
			'settings.openingIssueTracker' => 'Opening issue tracker...',
			'settings.account' => 'Account',
			'settings.logout' => 'Logout',
			'settings.logoutDesc' => 'Sign out from this device',
			'settings.loggedOut' => 'Logged out successfully',
			'settings.logoutFailed' => ({required Object error}) => 'Failed to log out: ${error}',
			'settings.deleteAccount' => 'Delete Account',
			'settings.deleteAccountDesc' => 'Permanently remove all your data',
			'settings.deleteConfirmation' => 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
			'settings.accountDeleted' => 'Account deleted successfully',
			'settings.deleteAccountFailed' => ({required Object error}) => 'Failed to delete account: ${error}',
			'settings.language' => 'Language',
			'settings.languageDesc' => 'Change the display language',
			'variables.title' => 'Variables',
			'variables.secrets' => 'Secrets',
			'variables.environment' => 'Environment',
			'variables.noSecretsYet' => 'No secrets yet',
			'variables.noSecretsDesc' => 'Add encrypted secrets like API keys,\ntokens, and certificates.',
			'variables.noEnvVars' => 'No environment variables',
			'variables.noEnvVarsDesc' => 'Add variables that will be available\nduring your CI/CD builds.',
			'variables.addSecret' => 'Add Secret',
			'variables.editSecret' => 'Edit Secret',
			'variables.secretName' => 'SECRET_NAME',
			'variables.secretNameHint' => 'e.g. API_KEY',
			'variables.secretValue' => 'Secret Value',
			'variables.pleaseEnterSecretName' => 'Please enter a secret name',
			'variables.pleaseEnterSecretValue' => 'Please enter a secret value',
			'variables.secretsEncryptedNote' => 'Secrets are encrypted and never exposed in logs.',
			'variables.secretAdded' => 'Secret added',
			'variables.secretUpdated' => 'Secret updated',
			'variables.saveChanges' => 'Save Changes',
			'variables.newValueHint' => 'New Value (leave empty to keep current)',
			'variables.addEnvVar' => 'Add Variable',
			'variables.editEnvVar' => 'Edit Variable',
			'variables.envKey' => 'KEY',
			'variables.envKeyHint' => 'e.g. NODE_ENV',
			'variables.envValue' => 'Value',
			'variables.envValueHint' => 'e.g. production',
			'variables.pleaseEnterKey' => 'Please enter a key',
			'variables.pleaseEnterValue' => 'Please enter a value',
			'variables.variableAdded' => 'Variable added',
			'variables.variableUpdated' => 'Variable updated',
			'variables.deleteVariable' => 'Delete Variable',
			'variables.deleteVariableConfirm' => ({required Object key}) => 'Delete "${key}"?',
			'variables.deletedSuccessfully' => 'Deleted successfully',
			'logs.title' => 'Build Logs',
			'logs.noBuildsYet' => 'No builds yet',
			'logs.noBuildsDesc' => 'Build logs will appear here\nwhen workflows are triggered.',
			'logs.active' => 'Active',
			'logs.recent' => 'Recent',
			'logs.retry' => 'Retry',
			'logs.retrying' => 'Retrying build...',
			'logs.buildQueued' => 'Build queued successfully',
			'logs.retryFailed' => ({required Object error}) => 'Failed to retry: ${error}',
			'logs.cancelBuild' => 'Cancel Build',
			'logs.cancelBuildConfirm' => 'Are you sure you want to cancel this build?',
			'logs.no' => 'No',
			'logs.cancelling' => 'Cancelling build...',
			'logs.buildCancelled' => 'Build cancelled',
			'logs.cancelFailed' => ({required Object error}) => 'Failed to cancel: ${error}',
			'logs.fixWithAI' => 'Fix with AI',
			'logs.passed' => 'Passed',
			'logs.failed' => 'Failed',
			'logs.running' => 'Running',
			'logs.queued' => 'Queued',
			'logs.cancelled' => 'Cancelled',
			'logs.unknown' => 'Unknown',
			'workflows.title' => 'Workflows',
			'workflows.noWorkflows' => 'No workflows yet',
			'workflows.noWorkflowsDesc' => 'Create your first CI/CD workflow to start\nautomating builds and deployments.',
			'workflows.createWorkflow' => 'Create Workflow',
			'workflows.steps' => ({required Object count}) => '${count} steps',
			'workflows.duplicate' => 'Duplicate',
			'workflows.duplicated' => 'Workflow duplicated',
			'workflows.duplicateFailed' => ({required Object error}) => 'Failed to duplicate: ${error}',
			'workflows.deleteWorkflow' => 'Delete Workflow',
			'workflows.deleteWorkflowConfirm' => ({required Object name}) => 'Are you sure you want to delete "${name}"?',
			'workflows.workflowDeleted' => 'Workflow deleted',
			'workflows.deleteFailed' => ({required Object error}) => 'Failed to delete: ${error}',
			'workflows.switchTeam' => 'Switch Team',
			'workflows.editTeam' => 'Edit Team',
			'workflows.createTeam' => 'Create Team',
			'workflows.switchBranchCommit' => 'Switch Branch & Commit',
			'workflows.branch' => 'Branch',
			'workflows.commits' => 'Commits',
			'locale.en' => 'English',
			'locale.ja' => '日本語',
			_ => null,
		};
	}
}
