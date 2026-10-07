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
	late final Translations$cli$en cli = Translations$cli$en.internal(_root);
	late final Translations$update$en update = Translations$update$en.internal(_root);
	late final Translations$login$en login = Translations$login$en.internal(_root);
	late final Translations$status$en status = Translations$status$en.internal(_root);
	late final Translations$list$en list = Translations$list$en.internal(_root);
	late final Translations$register$en register = Translations$register$en.internal(_root);
	late final Translations$setup$en setup = Translations$setup$en.internal(_root);
	late final Translations$switchCommand$en switchCommand = Translations$switchCommand$en.internal(_root);
	late final Translations$use$en use = Translations$use$en.internal(_root);
	late final Translations$dev$en dev = Translations$dev$en.internal(_root);
	late final Translations$sync$en sync = Translations$sync$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
}

// Path: cli
class Translations$cli$en {
	Translations$cli$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'GenuineCI command-line tool for managing CI/CD and secrets.'
	String get description => 'GenuineCI command-line tool for managing CI/CD and secrets.';

	/// en: 'genuineci version: ${version}'
	String version({required Object version}) => 'genuineci version: ${version}';

	late final Translations$cli$flags$en flags = Translations$cli$flags$en.internal(_root);
}

// Path: update
class Translations$update$en {
	Translations$update$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Update GenuineCI CLI to the latest stable version on pub.dev.'
	String get description => 'Update GenuineCI CLI to the latest stable version on pub.dev.';

	/// en: 'update does not accept positional arguments.'
	String get noArguments => 'update does not accept positional arguments.';

	/// en: 'An update is available! ${current} → ${latest}'
	String available({required Object current, required Object latest}) => 'An update is available! ${current} → ${latest}';

	/// en: 'Update now?'
	String get confirm => 'Update now?';

	/// en: 'Updating GenuineCI CLI to ${version}...'
	String updating({required Object version}) => 'Updating GenuineCI CLI to ${version}...';

	/// en: 'Updated GenuineCI CLI to ${version}.'
	String updated({required Object version}) => 'Updated GenuineCI CLI to ${version}.';

	/// en: 'GenuineCI CLI ${version} is already up to date.'
	String upToDate({required Object version}) => 'GenuineCI CLI ${version} is already up to date.';

	/// en: 'Could not check for updates. Check your connection to pub.dev and try again.'
	String get checkFailed => 'Could not check for updates. Check your connection to pub.dev and try again.';

	/// en: 'Could not update GenuineCI CLI. Check the Dart installation output above and try again.'
	String get installFailed => 'Could not update GenuineCI CLI. Check the Dart installation output above and try again.';

	/// en: 'Could not start Dart. Make sure the Dart SDK is installed and dart is on PATH.'
	String get dartUnavailable => 'Could not start Dart. Make sure the Dart SDK is installed and dart is on PATH.';

	/// en: 'Run your command again to use the updated CLI.'
	String get rerunCommand => 'Run your command again to use the updated CLI.';
}

// Path: login
class Translations$login$en {
	Translations$login$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Log in to a local or remote OpenCI server.'
	String get description => 'Log in to a local or remote OpenCI server.';

	late final Translations$login$flags$en flags = Translations$login$flags$en.internal(_root);

	/// en: 'Logging in to OpenCI...'
	String get loggingIn => 'Logging in to OpenCI...';

	/// en: 'Successfully saved and activated profile "${profile}".'
	String savedSuccess({required Object profile}) => 'Successfully saved and activated profile "${profile}".';

	/// en: 'Login does not accept positional arguments.'
	String get noArguments => 'Login does not accept positional arguments.';

	/// en: 'Local server authentication failed. Check the server started by genuineci dev start.'
	String get authenticationFailed => 'Local server authentication failed. Check the server started by genuineci dev start.';

	/// en: 'Could not fetch teams (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not fetch teams (HTTP ${status}).';

	/// en: 'test-team is not available for this user. Check that the team is seeded and this Auth Emulator user belongs to it.'
	String get localTeamRequired => 'test-team is not available for this user. Check that the team is seeded and this Auth Emulator user belongs to it.';

	/// en: 'The server returned an invalid team list.'
	String get invalidResponse => 'The server returned an invalid team list.';

	/// en: 'Could not connect to the local server. Check that genuineci dev start is running.'
	String get connectionFailed => 'Could not connect to the local server. Check that genuineci dev start is running.';

	/// en: 'Could not save credentials. Check the local credentials file and its permissions.'
	String get saveFailed => 'Could not save credentials. Check the local credentials file and its permissions.';

	/// en: '--local cannot be combined with remote login options.'
	String get localOptionsConflict => '--local cannot be combined with remote login options.';

	/// en: '--server must be a valid HTTPS URL without credentials, a query or a fragment. Use --local for local development.'
	String get serverRequired => '--server must be a valid HTTPS URL without credentials, a query or a fragment. Use --local for local development.';

	/// en: 'Firebase API key and team ID must not be empty.'
	String get emptyOptions => 'Firebase API key and team ID must not be empty.';

	/// en: 'Email: '
	String get emailPrompt => 'Email: ';

	/// en: 'Password: '
	String get passwordPrompt => 'Password: ';

	/// en: 'Login requires an interactive terminal, email and password. Login was cancelled.'
	String get inputRequired => 'Login requires an interactive terminal, email and password. Login was cancelled.';

	/// en: 'Firebase login failed. Check your email, password, Firebase API key and network connection.'
	String get firebaseAuthenticationFailed => 'Firebase login failed. Check your email, password, Firebase API key and network connection.';

	/// en: 'Auth Emulator login failed. Check that the emulator is running, the user exists in demo-openci, and the email/password are correct.'
	String get emulatorAuthenticationFailed => 'Auth Emulator login failed. Check that the emulator is running, the user exists in demo-openci, and the email/password are correct.';

	/// en: 'Could not connect to the remote server. Check the server URL and connection.'
	String get remoteConnectionFailed => 'Could not connect to the remote server. Check the server URL and connection.';

	/// en: 'No teams found. Create or join a team in the dashboard first.'
	String get noTeams => 'No teams found. Create or join a team in the dashboard first.';

	/// en: 'Multiple teams found. Run login again with --team-id from the list above.'
	String get teamRequired => 'Multiple teams found. Run login again with --team-id from the list above.';

	/// en: 'You do not belong to the specified team.'
	String get teamNotFound => 'You do not belong to the specified team.';
}

// Path: status
class Translations$status$en {
	Translations$status$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Show the active profile, server, and current team's name and ID.'
	String get description => 'Show the active profile, server, and current team\'s name and ID.';

	/// en: 'status does not accept positional arguments.'
	String get noArguments => 'status does not accept positional arguments.';

	/// en: 'Profile: ${value}'
	String profile({required Object value}) => 'Profile: ${value}';

	/// en: 'Server: ${value}'
	String server({required Object value}) => 'Server: ${value}';

	/// en: 'Selected team ID: ${value}'
	String team({required Object value}) => 'Selected team ID: ${value}';

	/// en: 'Not set'
	String get notSet => 'Not set';

	/// en: 'No profile is configured. Run genuineci login (or genuineci login --local).'
	String get noActiveProfile => 'No profile is configured. Run genuineci login (or genuineci login --local).';

	/// en: 'Active profile "${profile}" is missing. Run genuineci login (or genuineci login --local).'
	String profileMissing({required Object profile}) => 'Active profile "${profile}" is missing. Run genuineci login (or genuineci login --local).';

	/// en: 'Invalid server URL'
	String get invalidServer => 'Invalid server URL';

	/// en: 'Could not read the saved profile. Check the credentials file format and permissions.'
	String get readFailed => 'Could not read the saved profile. Check the credentials file format and permissions.';

	/// en: 'The active profile or selected team changed while checking status. Run genuineci status again.'
	String get profileChanged => 'The active profile or selected team changed while checking status. Run genuineci status again.';

	/// en: 'Run genuineci login (or genuineci login --local) to check your current team.'
	String get loginRequired => 'Run genuineci login (or genuineci login --local) to check your current team.';

	/// en: 'No team is selected. Run genuineci switch team to select a team.'
	String get noTeamSelected => 'No team is selected. Run genuineci switch team to select a team.';

	/// en: 'No teams found. Create or join a team in the dashboard first.'
	String get noTeams => 'No teams found. Create or join a team in the dashboard first.';

	/// en: 'The selected team is no longer available. Run genuineci switch team to select an available team.'
	String get teamNotFound => 'The selected team is no longer available. Run genuineci switch team to select an available team.';

	/// en: 'Could not fetch teams (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not fetch teams (HTTP ${status}).';

	/// en: 'Could not fetch teams. Check the active profile's server URL and network connection.'
	String get fetchFailed => 'Could not fetch teams. Check the active profile\'s server URL and network connection.';

	/// en: 'The server returned an invalid team list. Check that the active profile points to a compatible OpenCI server.'
	String get invalidResponse => 'The server returned an invalid team list. Check that the active profile points to a compatible OpenCI server.';

	/// en: 'Team name: ${value}'
	String teamName({required Object value}) => 'Team name: ${value}';
}

// Path: list
class Translations$list$en {
	Translations$list$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'List resources in OpenCI.'
	String get description => 'List resources in OpenCI.';

	late final Translations$list$teams$en teams = Translations$list$teams$en.internal(_root);
	late final Translations$list$secrets$en secrets = Translations$list$secrets$en.internal(_root);
}

// Path: register
class Translations$register$en {
	Translations$register$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Register resources with OpenCI.'
	String get description => 'Register resources with OpenCI.';

	late final Translations$register$secret$en secret = Translations$register$secret$en.internal(_root);
	late final Translations$register$secretFile$en secretFile = Translations$register$secretFile$en.internal(_root);
}

// Path: setup
class Translations$setup$en {
	Translations$setup$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Set up integrations for OpenCI.'
	String get description => 'Set up integrations for OpenCI.';

	late final Translations$setup$ascKeys$en ascKeys = Translations$setup$ascKeys$en.internal(_root);
}

// Path: switchCommand
class Translations$switchCommand$en {
	Translations$switchCommand$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Switch the active team in OpenCI.'
	String get description => 'Switch the active team in OpenCI.';

	late final Translations$switchCommand$team$en team = Translations$switchCommand$team$en.internal(_root);
}

// Path: use
class Translations$use$en {
	Translations$use$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Set the default display language (japanese, english).'
	String get description => 'Set the default display language (japanese, english).';

	/// en: 'Language set to ${language}.'
	String success({required Object language}) => 'Language set to ${language}.';

	/// en: 'Invalid language "${input}". Supported languages: japanese, english.'
	String invalidLanguage({required Object input}) => 'Invalid language "${input}". Supported languages: japanese, english.';
}

// Path: dev
class Translations$dev$en {
	Translations$dev$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Manage local development environment (Docker, Tart, DB, Server).'
	String get description => 'Manage local development environment (Docker, Tart, DB, Server).';

	late final Translations$dev$start$en start = Translations$dev$start$en.internal(_root);
}

// Path: sync
class Translations$sync$en {
	Translations$sync$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Generate secret definitions and workspace paths in openci/generated.'
	String get description => 'Generate secret definitions and workspace paths in openci/generated.';

	late final Translations$sync$paths$en paths = Translations$sync$paths$en.internal(_root);
	late final Translations$sync$secrets$en secrets = Translations$sync$secrets$en.internal(_root);

	/// en: 'sync does not accept positional arguments. Use --secrets or --paths to select what to generate.'
	String get noArguments => 'sync does not accept positional arguments. Use --secrets or --paths to select what to generate.';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Error: ${error}'
	String error({required Object error}) => 'Error: ${error}';
}

// Path: cli.flags
class Translations$cli$flags$en {
	Translations$cli$flags$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Print the current tool version.'
	String get version => 'Print the current tool version.';

	/// en: 'Enable verbose logging output.'
	String get verbose => 'Enable verbose logging output.';

	/// en: 'Check for updates and offer to install them in interactive terminals.'
	String get checkUpdates => 'Check for updates and offer to install them in interactive terminals.';
}

// Path: login.flags
class Translations$login$flags$en {
	Translations$login$flags$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Log in to the local API (http://localhost:8080) with an Auth Emulator user's email/password (127.0.0.1:9099).'
	String get local => 'Log in to the local API (http://localhost:8080) with an Auth Emulator user\'s email/password (127.0.0.1:9099).';

	/// en: 'Remote OpenCI server URL (HTTPS).'
	String get server => 'Remote OpenCI server URL (HTTPS).';

	/// en: 'Team to select when you belong to more than one team.'
	String get teamId => 'Team to select when you belong to more than one team.';

	/// en: 'Firebase Web API key (override for a self-hosted Firebase project).'
	String get firebaseApiKey => 'Firebase Web API key (override for a self-hosted Firebase project).';
}

// Path: list.teams
class Translations$list$teams$en {
	Translations$list$teams$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'List your teams by name and ID. * marks the current team.'
	String get description => 'List your teams by name and ID. * marks the current team.';

	/// en: 'list teams does not accept positional arguments.'
	String get noArguments => 'list teams does not accept positional arguments.';

	/// en: 'Run genuineci login (or genuineci login --local) before listing teams.'
	String get loginRequired => 'Run genuineci login (or genuineci login --local) before listing teams.';

	/// en: 'Could not fetch teams (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not fetch teams (HTTP ${status}).';

	/// en: 'Could not fetch teams. Check the active profile's server URL and network connection.'
	String get fetchFailed => 'Could not fetch teams. Check the active profile\'s server URL and network connection.';

	/// en: 'The server returned an invalid team list.'
	String get invalidResponse => 'The server returned an invalid team list.';

	/// en: 'No teams found. Create or join a team in the dashboard.'
	String get empty => 'No teams found. Create or join a team in the dashboard.';
}

// Path: list.secrets
class Translations$list$secrets$en {
	Translations$list$secrets$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'List the active team's secret names, sorted by name.'
	String get description => 'List the active team\'s secret names, sorted by name.';

	/// en: 'list secrets does not accept positional arguments.'
	String get noArguments => 'list secrets does not accept positional arguments.';

	/// en: 'Run genuineci login (or genuineci login --local) before listing secrets.'
	String get loginRequired => 'Run genuineci login (or genuineci login --local) before listing secrets.';

	/// en: 'Could not fetch secret names (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not fetch secret names (HTTP ${status}).';

	/// en: 'Could not fetch secret names. Check the server connection and response.'
	String get fetchFailed => 'Could not fetch secret names. Check the server connection and response.';

	/// en: 'No secrets registered for the active team.'
	String get empty => 'No secrets registered for the active team.';
}

// Path: register.secret
class Translations$register$secret$en {
	Translations$register$secret$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create or update a secret for the active team. Enter its name, then its value. The value is hidden while typing and shown as ****** after Enter.'
	String get description => 'Create or update a secret for the active team. Enter its name, then its value. The value is hidden while typing and shown as ****** after Enter.';

	/// en: 'register secret does not accept positional arguments. Enter the name and value at the prompts.'
	String get noArguments => 'register secret does not accept positional arguments. Enter the name and value at the prompts.';

	/// en: 'Secret names must use letters, digits and underscores, and must not start with a digit.'
	String get invalidName => 'Secret names must use letters, digits and underscores, and must not start with a digit.';

	/// en: 'Run genuineci login (or genuineci login --local) before registering secrets.'
	String get loginRequired => 'Run genuineci login (or genuineci login --local) before registering secrets.';

	/// en: 'Secret name:'
	String get namePrompt => 'Secret name:';

	/// en: 'Secret value:'
	String get valuePrompt => 'Secret value:';

	/// en: 'No secret was registered. Enter a name and a non-empty value in an interactive terminal.'
	String get inputRequired => 'No secret was registered. Enter a name and a non-empty value in an interactive terminal.';

	/// en: 'Could not read the secret name or value. Retry in an interactive terminal.'
	String get inputFailed => 'Could not read the secret name or value. Retry in an interactive terminal.';

	/// en: 'Could not register the secret (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not register the secret (HTTP ${status}).';

	/// en: 'Could not register the secret. Check the server connection.'
	String get saveFailed => 'Could not register the secret. Check the server connection.';

	/// en: 'Saved secret ${name} for team ${teamId}.'
	String saved({required Object name, required Object teamId}) => 'Saved secret ${name} for team ${teamId}.';
}

// Path: register.secretFile
class Translations$register$secretFile$en {
	Translations$register$secretFile$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose a file interactively and register its Base64 contents for the active team.'
	String get description => 'Choose a file interactively and register its Base64 contents for the active team.';

	/// en: 'register secretFile does not accept positional arguments. Choose a file at the prompt.'
	String get noArguments => 'register secretFile does not accept positional arguments. Choose a file at the prompt.';

	/// en: 'Select a secret file'
	String get filePrompt => 'Select a secret file';

	/// en: 'Type to filter / Tab, arrows: complete / Enter: open or select / Esc: cancel'
	String get controls => 'Type to filter / Tab, arrows: complete / Enter: open or select / Esc: cancel';

	/// en: 'No matching files. Enter a path, or type . to show hidden files.'
	String get noMatches => 'No matching files. Enter a path, or type . to show hidden files.';

	/// en: 'File not found. Choose an existing file.'
	String get notFound => 'File not found. Choose an existing file.';

	/// en: 'No file was registered. Choose a file in an interactive terminal.'
	String get cancelled => 'No file was registered. Choose a file in an interactive terminal.';

	/// en: 'Could not select the file. Retry in an interactive terminal.'
	String get inputFailed => 'Could not select the file. Retry in an interactive terminal.';

	/// en: 'Could not read the selected file. Check that it is a regular file and that you have permission to read it.'
	String get readFailed => 'Could not read the selected file. Check that it is a regular file and that you have permission to read it.';

	/// en: 'The selected file is empty. No secret was registered.'
	String get emptyFile => 'The selected file is empty. No secret was registered.';
}

// Path: setup.ascKeys
class Translations$setup$ascKeys$en {
	Translations$setup$ascKeys$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create an App Store Connect API key and save it locally.'
	String get description => 'Create an App Store Connect API key and save it locally.';

	/// en: 'setup asc-keys does not accept positional arguments.'
	String get noArguments => 'setup asc-keys does not accept positional arguments.';

	/// en: 'Found a cached file for asc ${version}: ${path}'
	String cacheFound({required Object version, required Object path}) => 'Found a cached file for asc ${version}: ${path}';

	/// en: 'Downloading and installing asc ${version} for Apple Silicon Mac...'
	String installing({required Object version}) => 'Downloading and installing asc ${version} for Apple Silicon Mac...';

	/// en: 'Installed asc ${version}: ${path}'
	String installed({required Object version, required Object path}) => 'Installed asc ${version}: ${path}';

	/// en: 'Verified asc ${version}.'
	String versionVerified({required Object version}) => 'Verified asc ${version}.';

	/// en: 'Apple ID (email address): '
	String get appleIdPrompt => 'Apple ID (email address): ';

	/// en: 'Apple ID received.'
	String get appleIdReceived => 'Apple ID received.';

	/// en: 'No Apple ID was entered. Setup was stopped.'
	String get appleIdRequired => 'No Apple ID was entered. Setup was stopped.';

	/// en: 'Entering an Apple ID requires an interactive terminal. Run genuineci setup asc-keys in a terminal.'
	String get terminalRequired => 'Entering an Apple ID requires an interactive terminal. Run genuineci setup asc-keys in a terminal.';

	/// en: 'Could not read the Apple ID. Retry in an interactive terminal.'
	String get appleIdInputFailed => 'Could not read the Apple ID. Retry in an interactive terminal.';

	/// en: 'Could not start asc login. Check that the cached asc file is executable and retry.'
	String get loginStartFailed => 'Could not start asc login. Check that the cached asc file is executable and retry.';

	/// en: 'Apple authentication verified.'
	String get authenticationVerified => 'Apple authentication verified.';

	/// en: 'Selected App Store Connect provider:'
	String get selectedProvider => 'Selected App Store Connect provider:';

	/// en: ' Provider ID: ${id}'
	String providerId({required Object id}) => '  Provider ID: ${id}';

	/// en: ' Public Provider ID: ${id}'
	String publicProviderId({required Object id}) => '  Public Provider ID: ${id}';

	/// en: 'Could not determine the selected App Store Connect provider.'
	String get providerUnavailable => 'Could not determine the selected App Store Connect provider.';

	/// en: 'Create a new GenuineCI key with APP_MANAGER access to all apps for this provider? [y/N] '
	String get confirmKeyCreation => 'Create a new GenuineCI key with APP_MANAGER access to all apps for this provider? [y/N] ';

	/// en: 'Key creation cancelled. No new key was requested.'
	String get keyCreationCancelled => 'Key creation cancelled. No new key was requested.';

	/// en: 'Could not read confirmation. Run genuineci setup asc-keys in an interactive terminal.'
	String get keyConfirmationFailed => 'Could not read confirmation. Run genuineci setup asc-keys in an interactive terminal.';

	/// en: 'Could not prepare the key directory. Check permissions and available disk space. No new key was requested.'
	String get keyDirectoryFailed => 'Could not prepare the key directory. Check permissions and available disk space. No new key was requested.';

	/// en: 'Key output directory: ${path}'
	String keyOutputDirectory({required Object path}) => 'Key output directory: ${path}';

	/// en: 'Created a GenuineCI API key with APP_MANAGER access.'
	String get keyCreated => 'Created a GenuineCI API key with APP_MANAGER access.';

	/// en: ' Key ID: ${id}'
	String keyId({required Object id}) => '  Key ID: ${id}';

	/// en: ' Issuer ID: ${id}'
	String issuerId({required Object id}) => '  Issuer ID: ${id}';

	/// en: ' Private key: ${path}'
	String privateKeySaved({required Object path}) => '  Private key: ${path}';

	/// en: 'The key and key.json are saved locally. Saving to OpenCI is not implemented yet.'
	String get serverStoragePending => 'The key and key.json are saved locally. Saving to OpenCI is not implemented yet.';

	/// en: 'Could not start asc key creation. No new key was requested.'
	String get keyCreationStartFailed => 'Could not start asc key creation. No new key was requested.';

	/// en: 'asc did not complete API key creation successfully.'
	String get keyCreationFailed => 'asc did not complete API key creation successfully.';

	/// en: 'Could not verify the key creation result or the saved private key.'
	String get keyCreationInvalid => 'Could not verify the key creation result or the saved private key.';

	/// en: 'Could not save or read the API key files.'
	String get keyStorageFailed => 'Could not save or read the API key files.';

	/// en: 'A key may already have been created. Check App Store Connect before running setup again. Any downloaded files are retained in: ${path}'
	String keyRecovery({required Object path}) => 'A key may already have been created. Check App Store Connect before running setup again. Any downloaded files are retained in: ${path}';

	/// en: 'Apple login could not be confirmed. Run genuineci setup asc-keys to sign in again.'
	String get notAuthenticated => 'Apple login could not be confirmed. Run genuineci setup asc-keys to sign in again.';

	/// en: 'Could not check Apple authentication with asc. Retry setup.'
	String get authStatusFailed => 'Could not check Apple authentication with asc. Retry setup.';

	/// en: 'Checking Apple authentication timed out. Retry setup.'
	String get authStatusTimedOut => 'Checking Apple authentication timed out. Retry setup.';

	/// en: 'asc returned an unexpected authentication status. Retry setup.'
	String get authStatusInvalid => 'asc returned an unexpected authentication status. Retry setup.';

	/// en: 'The cached asc file did not match the expected SHA-256. It was not run. Remove the cached file and retry the command.'
	String get cachedChecksumFailed => 'The cached asc file did not match the expected SHA-256. It was not run. Remove the cached file and retry the command.';

	/// en: 'Could not run asc version successfully. Check that the cached asc file is executable and retry.'
	String get executionFailed => 'Could not run asc version successfully. Check that the cached asc file is executable and retry.';

	/// en: 'asc version timed out. Retry the command.'
	String get versionTimedOut => 'asc version timed out. Retry the command.';

	/// en: 'asc version did not report the required version (${version}). Remove the cached file and retry the command.'
	String versionMismatch({required Object version}) => 'asc version did not report the required version (${version}). Remove the cached file and retry the command.';

	/// en: 'setup asc-keys currently supports only Apple Silicon Macs (macOS arm64).'
	String get unsupportedPlatform => 'setup asc-keys currently supports only Apple Silicon Macs (macOS arm64).';

	/// en: 'Could not access the asc cache. Check its permissions and available disk space.'
	String get cacheFailed => 'Could not access the asc cache. Check its permissions and available disk space.';

	/// en: 'Could not download asc. Check your network connection and retry.'
	String get downloadFailed => 'Could not download asc. Check your network connection and retry.';

	/// en: 'The downloaded asc file did not match the expected SHA-256. It was not installed. Retry the command.'
	String get checksumFailed => 'The downloaded asc file did not match the expected SHA-256. It was not installed. Retry the command.';

	/// en: 'Could not set the asc executable permissions. It was not installed. Check the cache directory permissions.'
	String get permissionFailed => 'Could not set the asc executable permissions. It was not installed. Check the cache directory permissions.';
}

// Path: switchCommand.team
class Translations$switchCommand$team$en {
	Translations$switchCommand$team$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Interactively switch the team used by the active profile.'
	String get description => 'Interactively switch the team used by the active profile.';

	/// en: 'switch team does not accept positional arguments.'
	String get noArguments => 'switch team does not accept positional arguments.';

	/// en: 'Run genuineci login (or genuineci login --local) before switching teams.'
	String get loginRequired => 'Run genuineci login (or genuineci login --local) before switching teams.';

	/// en: 'Authentication failed (HTTP ${status}). Log in again with genuineci login (or genuineci login --local) for the active server.'
	String authenticationFailed({required Object status}) => 'Authentication failed (HTTP ${status}). Log in again with genuineci login (or genuineci login --local) for the active server.';

	/// en: 'Could not fetch teams (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not fetch teams (HTTP ${status}).';

	/// en: 'Could not fetch teams. Check the active profile's server URL and network connection.'
	String get fetchFailed => 'Could not fetch teams. Check the active profile\'s server URL and network connection.';

	/// en: 'The server returned an invalid team list. Check that the active profile points to a compatible OpenCI server.'
	String get invalidResponse => 'The server returned an invalid team list. Check that the active profile points to a compatible OpenCI server.';

	/// en: 'No teams found. Create or join a team in the dashboard first.'
	String get empty => 'No teams found. Create or join a team in the dashboard first.';

	/// en: 'Select a team'
	String get prompt => 'Select a team';

	/// en: 'current'
	String get current => 'current';

	/// en: 'Up/Down: move / Enter: select / Esc, Ctrl+C: cancel'
	String get controls => 'Up/Down: move / Enter: select / Esc, Ctrl+C: cancel';

	/// en: 'Team switching cancelled. No team was saved.'
	String get cancelled => 'Team switching cancelled. No team was saved.';

	/// en: 'Team switching requires an interactive terminal with ANSI support. Run genuineci switch team without piping input or redirecting output.'
	String get nonInteractive => 'Team switching requires an interactive terminal with ANSI support. Run genuineci switch team without piping input or redirecting output.';

	/// en: 'Could not select a team. Retry in an interactive terminal.'
	String get inputFailed => 'Could not select a team. Retry in an interactive terminal.';

	/// en: 'Switched to ${team}.'
	String success({required Object team}) => 'Switched to ${team}.';

	/// en: 'Already using ${team}.'
	String alreadyCurrent({required Object team}) => 'Already using ${team}.';

	/// en: 'The active profile or its credentials changed during selection. The selected team was not saved. Run genuineci switch team again.'
	String get profileChanged => 'The active profile or its credentials changed during selection. The selected team was not saved. Run genuineci switch team again.';

	/// en: 'Could not save the selected team. Check the credentials file, its permissions, and available disk space, then retry.'
	String get saveFailed => 'Could not save the selected team. Check the credentials file, its permissions, and available disk space, then retry.';
}

// Path: dev.start
class Translations$dev$start$en {
	Translations$dev$start$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Start local services and run the Mac Orchard Worker until Ctrl+C.'
	String get description => 'Start local services and run the Mac Orchard Worker until Ctrl+C.';

	late final Translations$dev$start$flags$en flags = Translations$dev$start$flags$en.internal(_root);

	/// en: 'Starting OpenCI Local Development Environment...'
	String get starting => 'Starting OpenCI Local Development Environment...';

	/// en: 'Step 1: Checking Tart VM base image...'
	String get stepTart => 'Step 1: Checking Tart VM base image...';

	/// en: 'Error: Tart VM image "base-macos" not found. Please run the following commands to setup the base image: tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos'
	String get stepTartNotFound => 'Error: Tart VM image "base-macos" not found.\nPlease run the following commands to setup the base image:\n  tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5\n  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos';

	/// en: 'Tart VM (base-macos) exists.'
	String get stepTartExists => 'Tart VM (base-macos) exists.';

	/// en: 'Starting Firebase Auth Emulator and waiting for readiness...'
	String get stepAuthEmulator => 'Starting Firebase Auth Emulator and waiting for readiness...';

	/// en: 'Error: Failed to start or verify Firebase Auth Emulator.'
	String get stepAuthEmulatorFailed => 'Error: Failed to start or verify Firebase Auth Emulator.';

	/// en: 'Step 5: Starting Docker containers...'
	String get stepDockerCompose => 'Step 5: Starting Docker containers...';

	/// en: 'Error: Failed to start Docker containers.'
	String get stepDockerComposeFailed => 'Error: Failed to start Docker containers.';

	/// en: 'Docker containers started.'
	String get stepDockerComposeStarted => 'Docker containers started.';

	/// en: 'Stopping and removing local Docker containers (keeping data volumes)...'
	String get stepDockerComposeDown => 'Stopping and removing local Docker containers (keeping data volumes)...';

	/// en: 'Error: Failed to shut down local Docker containers. Run docker compose -f docker-compose.yml -f docker-compose.local.yml -f docker-compose.local-api.yml down --remove-orphans from the checkout to retry.'
	String get stepDockerComposeDownFailed => 'Error: Failed to shut down local Docker containers. Run docker compose -f docker-compose.yml -f docker-compose.local.yml -f docker-compose.local-api.yml down --remove-orphans from the checkout to retry.';

	/// en: 'Step 3: Waiting for Orchard Controller to initialize...'
	String get stepOrchardWaiting => 'Step 3: Waiting for Orchard Controller to initialize...';

	/// en: 'Error: Orchard Controller did not become ready.'
	String get stepOrchardNotReady => 'Error: Orchard Controller did not become ready.';

	/// en: 'Step 4: Registering Orchard CLI context...'
	String get stepOrchardContext => 'Step 4: Registering Orchard CLI context...';

	/// en: 'Error: Failed to register Orchard CLI context.'
	String get stepOrchardContextFailed => 'Error: Failed to register Orchard CLI context.';

	/// en: 'Orchard CLI context authenticated.'
	String get stepOrchardContextRegistered => 'Orchard CLI context authenticated.';

	/// en: 'Starting Orchard Worker on this Mac. Press Ctrl+C to stop it. Docker containers will keep running.'
	String get stepOrchardWorker => 'Starting Orchard Worker on this Mac. Press Ctrl+C to stop it. Docker containers will keep running.';

	/// en: 'Error: Orchard Worker could not start or exited with an error.'
	String get stepOrchardWorkerFailed => 'Error: Orchard Worker could not start or exited with an error.';

	/// en: 'Step 6: Seeding local test data...'
	String get stepSeed => 'Step 6: Seeding local test data...';

	/// en: 'Error: Failed to seed local test data.'
	String get stepSeedFailed => 'Error: Failed to seed local test data.';

	/// en: 'Local test data seeded.'
	String get stepSeedCompleted => 'Local test data seeded.';

	/// en: 'Error: OpenCI project root not found.'
	String get projectRootNotFound => 'Error: OpenCI project root not found.';

	/// en: 'Step 2: Starting Orchard Controller...'
	String get stepOrchardController => 'Step 2: Starting Orchard Controller...';

	/// en: 'Waiting for the current build job to finish before restarting services...'
	String get stepBuildJobWorkerWaiting => 'Waiting for the current build job to finish before restarting services...';
}

// Path: sync.paths
class Translations$sync$paths$en {
	Translations$sync$paths$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Generate only openci/generated/paths.g.dart from pubspec.yaml.'
	String get description => 'Generate only openci/generated/paths.g.dart from pubspec.yaml.';

	/// en: 'No project containing pubspec.yaml and an openci directory found. Run this command from your workflow project.'
	String get projectRootNotFound => 'No project containing pubspec.yaml and an openci directory found. Run this command from your workflow project.';

	/// en: 'Could not read or write ${path}. Check that the file exists and you have permission to access it.'
	String fileAccessFailed({required Object path}) => 'Could not read or write ${path}. Check that the file exists and you have permission to access it.';

	/// en: 'Generated workspace paths: ${path}'
	String saved({required Object path}) => 'Generated workspace paths: ${path}';
}

// Path: sync.secrets
class Translations$sync$secrets$en {
	Translations$sync$secrets$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Generate only openci/generated/secrets.g.dart from the active team's secret names.'
	String get description => 'Generate only openci/generated/secrets.g.dart from the active team\'s secret names.';

	/// en: 'Run genuineci login (or genuineci login --local) before syncing secrets.'
	String get loginRequired => 'Run genuineci login (or genuineci login --local) before syncing secrets.';

	/// en: 'No openci directory found. Run this command from your workflow project.'
	String get workflowDirectoryNotFound => 'No openci directory found. Run this command from your workflow project.';

	/// en: 'Could not fetch secret names (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not fetch secret names (HTTP ${status}).';

	/// en: 'Could not fetch secret names. Check the server connection and response.'
	String get fetchFailed => 'Could not fetch secret names. Check the server connection and response.';

	/// en: 'Could not save secrets.g.dart. Check the destination and file permissions.'
	String get saveFailed => 'Could not save secrets.g.dart. Check the destination and file permissions.';

	/// en: 'Generated secret definitions: ${path}'
	String saved({required Object path}) => 'Generated secret definitions: ${path}';
}

// Path: dev.start.flags
class Translations$dev$start$flags$en {
	Translations$dev$start$flags$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Queue the default smoke-test build job after starting services.'
	String get seed => 'Queue the default smoke-test build job after starting services.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'cli.description' => 'GenuineCI command-line tool for managing CI/CD and secrets.',
			'cli.version' => ({required Object version}) => 'genuineci version: ${version}',
			'cli.flags.version' => 'Print the current tool version.',
			'cli.flags.verbose' => 'Enable verbose logging output.',
			'cli.flags.checkUpdates' => 'Check for updates and offer to install them in interactive terminals.',
			'update.description' => 'Update GenuineCI CLI to the latest stable version on pub.dev.',
			'update.noArguments' => 'update does not accept positional arguments.',
			'update.available' => ({required Object current, required Object latest}) => 'An update is available! ${current} → ${latest}',
			'update.confirm' => 'Update now?',
			'update.updating' => ({required Object version}) => 'Updating GenuineCI CLI to ${version}...',
			'update.updated' => ({required Object version}) => 'Updated GenuineCI CLI to ${version}.',
			'update.upToDate' => ({required Object version}) => 'GenuineCI CLI ${version} is already up to date.',
			'update.checkFailed' => 'Could not check for updates. Check your connection to pub.dev and try again.',
			'update.installFailed' => 'Could not update GenuineCI CLI. Check the Dart installation output above and try again.',
			'update.dartUnavailable' => 'Could not start Dart. Make sure the Dart SDK is installed and dart is on PATH.',
			'update.rerunCommand' => 'Run your command again to use the updated CLI.',
			'login.description' => 'Log in to a local or remote OpenCI server.',
			'login.flags.local' => 'Log in to the local API (http://localhost:8080) with an Auth Emulator user\'s email/password (127.0.0.1:9099).',
			'login.flags.server' => 'Remote OpenCI server URL (HTTPS).',
			'login.flags.teamId' => 'Team to select when you belong to more than one team.',
			'login.flags.firebaseApiKey' => 'Firebase Web API key (override for a self-hosted Firebase project).',
			'login.loggingIn' => 'Logging in to OpenCI...',
			'login.savedSuccess' => ({required Object profile}) => 'Successfully saved and activated profile "${profile}".',
			'login.noArguments' => 'Login does not accept positional arguments.',
			'login.authenticationFailed' => 'Local server authentication failed. Check the server started by genuineci dev start.',
			'login.requestFailed' => ({required Object status}) => 'Could not fetch teams (HTTP ${status}).',
			'login.localTeamRequired' => 'test-team is not available for this user. Check that the team is seeded and this Auth Emulator user belongs to it.',
			'login.invalidResponse' => 'The server returned an invalid team list.',
			'login.connectionFailed' => 'Could not connect to the local server. Check that genuineci dev start is running.',
			'login.saveFailed' => 'Could not save credentials. Check the local credentials file and its permissions.',
			'login.localOptionsConflict' => '--local cannot be combined with remote login options.',
			'login.serverRequired' => '--server must be a valid HTTPS URL without credentials, a query or a fragment. Use --local for local development.',
			'login.emptyOptions' => 'Firebase API key and team ID must not be empty.',
			'login.emailPrompt' => 'Email: ',
			'login.passwordPrompt' => 'Password: ',
			'login.inputRequired' => 'Login requires an interactive terminal, email and password. Login was cancelled.',
			'login.firebaseAuthenticationFailed' => 'Firebase login failed. Check your email, password, Firebase API key and network connection.',
			'login.emulatorAuthenticationFailed' => 'Auth Emulator login failed. Check that the emulator is running, the user exists in demo-openci, and the email/password are correct.',
			'login.remoteConnectionFailed' => 'Could not connect to the remote server. Check the server URL and connection.',
			'login.noTeams' => 'No teams found. Create or join a team in the dashboard first.',
			'login.teamRequired' => 'Multiple teams found. Run login again with --team-id from the list above.',
			'login.teamNotFound' => 'You do not belong to the specified team.',
			'status.description' => 'Show the active profile, server, and current team\'s name and ID.',
			'status.noArguments' => 'status does not accept positional arguments.',
			'status.profile' => ({required Object value}) => 'Profile: ${value}',
			'status.server' => ({required Object value}) => 'Server: ${value}',
			'status.team' => ({required Object value}) => 'Selected team ID: ${value}',
			'status.notSet' => 'Not set',
			'status.noActiveProfile' => 'No profile is configured. Run genuineci login (or genuineci login --local).',
			'status.profileMissing' => ({required Object profile}) => 'Active profile "${profile}" is missing. Run genuineci login (or genuineci login --local).',
			'status.invalidServer' => 'Invalid server URL',
			'status.readFailed' => 'Could not read the saved profile. Check the credentials file format and permissions.',
			'status.profileChanged' => 'The active profile or selected team changed while checking status. Run genuineci status again.',
			'status.loginRequired' => 'Run genuineci login (or genuineci login --local) to check your current team.',
			'status.noTeamSelected' => 'No team is selected. Run genuineci switch team to select a team.',
			'status.noTeams' => 'No teams found. Create or join a team in the dashboard first.',
			'status.teamNotFound' => 'The selected team is no longer available. Run genuineci switch team to select an available team.',
			'status.requestFailed' => ({required Object status}) => 'Could not fetch teams (HTTP ${status}).',
			'status.fetchFailed' => 'Could not fetch teams. Check the active profile\'s server URL and network connection.',
			'status.invalidResponse' => 'The server returned an invalid team list. Check that the active profile points to a compatible OpenCI server.',
			'status.teamName' => ({required Object value}) => 'Team name: ${value}',
			'list.description' => 'List resources in OpenCI.',
			'list.teams.description' => 'List your teams by name and ID. * marks the current team.',
			'list.teams.noArguments' => 'list teams does not accept positional arguments.',
			'list.teams.loginRequired' => 'Run genuineci login (or genuineci login --local) before listing teams.',
			'list.teams.requestFailed' => ({required Object status}) => 'Could not fetch teams (HTTP ${status}).',
			'list.teams.fetchFailed' => 'Could not fetch teams. Check the active profile\'s server URL and network connection.',
			'list.teams.invalidResponse' => 'The server returned an invalid team list.',
			'list.teams.empty' => 'No teams found. Create or join a team in the dashboard.',
			'list.secrets.description' => 'List the active team\'s secret names, sorted by name.',
			'list.secrets.noArguments' => 'list secrets does not accept positional arguments.',
			'list.secrets.loginRequired' => 'Run genuineci login (or genuineci login --local) before listing secrets.',
			'list.secrets.requestFailed' => ({required Object status}) => 'Could not fetch secret names (HTTP ${status}).',
			'list.secrets.fetchFailed' => 'Could not fetch secret names. Check the server connection and response.',
			'list.secrets.empty' => 'No secrets registered for the active team.',
			'register.description' => 'Register resources with OpenCI.',
			'register.secret.description' => 'Create or update a secret for the active team. Enter its name, then its value. The value is hidden while typing and shown as ****** after Enter.',
			'register.secret.noArguments' => 'register secret does not accept positional arguments. Enter the name and value at the prompts.',
			'register.secret.invalidName' => 'Secret names must use letters, digits and underscores, and must not start with a digit.',
			'register.secret.loginRequired' => 'Run genuineci login (or genuineci login --local) before registering secrets.',
			'register.secret.namePrompt' => 'Secret name:',
			'register.secret.valuePrompt' => 'Secret value:',
			'register.secret.inputRequired' => 'No secret was registered. Enter a name and a non-empty value in an interactive terminal.',
			'register.secret.inputFailed' => 'Could not read the secret name or value. Retry in an interactive terminal.',
			'register.secret.requestFailed' => ({required Object status}) => 'Could not register the secret (HTTP ${status}).',
			'register.secret.saveFailed' => 'Could not register the secret. Check the server connection.',
			'register.secret.saved' => ({required Object name, required Object teamId}) => 'Saved secret ${name} for team ${teamId}.',
			'register.secretFile.description' => 'Choose a file interactively and register its Base64 contents for the active team.',
			'register.secretFile.noArguments' => 'register secretFile does not accept positional arguments. Choose a file at the prompt.',
			'register.secretFile.filePrompt' => 'Select a secret file',
			'register.secretFile.controls' => 'Type to filter / Tab, arrows: complete / Enter: open or select / Esc: cancel',
			'register.secretFile.noMatches' => 'No matching files. Enter a path, or type . to show hidden files.',
			'register.secretFile.notFound' => 'File not found. Choose an existing file.',
			'register.secretFile.cancelled' => 'No file was registered. Choose a file in an interactive terminal.',
			'register.secretFile.inputFailed' => 'Could not select the file. Retry in an interactive terminal.',
			'register.secretFile.readFailed' => 'Could not read the selected file. Check that it is a regular file and that you have permission to read it.',
			'register.secretFile.emptyFile' => 'The selected file is empty. No secret was registered.',
			'setup.description' => 'Set up integrations for OpenCI.',
			'setup.ascKeys.description' => 'Create an App Store Connect API key and save it locally.',
			'setup.ascKeys.noArguments' => 'setup asc-keys does not accept positional arguments.',
			'setup.ascKeys.cacheFound' => ({required Object version, required Object path}) => 'Found a cached file for asc ${version}: ${path}',
			'setup.ascKeys.installing' => ({required Object version}) => 'Downloading and installing asc ${version} for Apple Silicon Mac...',
			'setup.ascKeys.installed' => ({required Object version, required Object path}) => 'Installed asc ${version}: ${path}',
			'setup.ascKeys.versionVerified' => ({required Object version}) => 'Verified asc ${version}.',
			'setup.ascKeys.appleIdPrompt' => 'Apple ID (email address): ',
			'setup.ascKeys.appleIdReceived' => 'Apple ID received.',
			'setup.ascKeys.appleIdRequired' => 'No Apple ID was entered. Setup was stopped.',
			'setup.ascKeys.terminalRequired' => 'Entering an Apple ID requires an interactive terminal. Run genuineci setup asc-keys in a terminal.',
			'setup.ascKeys.appleIdInputFailed' => 'Could not read the Apple ID. Retry in an interactive terminal.',
			'setup.ascKeys.loginStartFailed' => 'Could not start asc login. Check that the cached asc file is executable and retry.',
			'setup.ascKeys.authenticationVerified' => 'Apple authentication verified.',
			'setup.ascKeys.selectedProvider' => 'Selected App Store Connect provider:',
			'setup.ascKeys.providerId' => ({required Object id}) => '  Provider ID: ${id}',
			'setup.ascKeys.publicProviderId' => ({required Object id}) => '  Public Provider ID: ${id}',
			'setup.ascKeys.providerUnavailable' => 'Could not determine the selected App Store Connect provider.',
			'setup.ascKeys.confirmKeyCreation' => 'Create a new GenuineCI key with APP_MANAGER access to all apps for this provider? [y/N] ',
			'setup.ascKeys.keyCreationCancelled' => 'Key creation cancelled. No new key was requested.',
			'setup.ascKeys.keyConfirmationFailed' => 'Could not read confirmation. Run genuineci setup asc-keys in an interactive terminal.',
			'setup.ascKeys.keyDirectoryFailed' => 'Could not prepare the key directory. Check permissions and available disk space. No new key was requested.',
			'setup.ascKeys.keyOutputDirectory' => ({required Object path}) => 'Key output directory: ${path}',
			'setup.ascKeys.keyCreated' => 'Created a GenuineCI API key with APP_MANAGER access.',
			'setup.ascKeys.keyId' => ({required Object id}) => '  Key ID: ${id}',
			'setup.ascKeys.issuerId' => ({required Object id}) => '  Issuer ID: ${id}',
			'setup.ascKeys.privateKeySaved' => ({required Object path}) => '  Private key: ${path}',
			'setup.ascKeys.serverStoragePending' => 'The key and key.json are saved locally. Saving to OpenCI is not implemented yet.',
			'setup.ascKeys.keyCreationStartFailed' => 'Could not start asc key creation. No new key was requested.',
			'setup.ascKeys.keyCreationFailed' => 'asc did not complete API key creation successfully.',
			'setup.ascKeys.keyCreationInvalid' => 'Could not verify the key creation result or the saved private key.',
			'setup.ascKeys.keyStorageFailed' => 'Could not save or read the API key files.',
			'setup.ascKeys.keyRecovery' => ({required Object path}) => 'A key may already have been created. Check App Store Connect before running setup again. Any downloaded files are retained in: ${path}',
			'setup.ascKeys.notAuthenticated' => 'Apple login could not be confirmed. Run genuineci setup asc-keys to sign in again.',
			'setup.ascKeys.authStatusFailed' => 'Could not check Apple authentication with asc. Retry setup.',
			'setup.ascKeys.authStatusTimedOut' => 'Checking Apple authentication timed out. Retry setup.',
			'setup.ascKeys.authStatusInvalid' => 'asc returned an unexpected authentication status. Retry setup.',
			'setup.ascKeys.cachedChecksumFailed' => 'The cached asc file did not match the expected SHA-256. It was not run. Remove the cached file and retry the command.',
			'setup.ascKeys.executionFailed' => 'Could not run asc version successfully. Check that the cached asc file is executable and retry.',
			'setup.ascKeys.versionTimedOut' => 'asc version timed out. Retry the command.',
			'setup.ascKeys.versionMismatch' => ({required Object version}) => 'asc version did not report the required version (${version}). Remove the cached file and retry the command.',
			'setup.ascKeys.unsupportedPlatform' => 'setup asc-keys currently supports only Apple Silicon Macs (macOS arm64).',
			'setup.ascKeys.cacheFailed' => 'Could not access the asc cache. Check its permissions and available disk space.',
			'setup.ascKeys.downloadFailed' => 'Could not download asc. Check your network connection and retry.',
			'setup.ascKeys.checksumFailed' => 'The downloaded asc file did not match the expected SHA-256. It was not installed. Retry the command.',
			'setup.ascKeys.permissionFailed' => 'Could not set the asc executable permissions. It was not installed. Check the cache directory permissions.',
			'switchCommand.description' => 'Switch the active team in OpenCI.',
			'switchCommand.team.description' => 'Interactively switch the team used by the active profile.',
			'switchCommand.team.noArguments' => 'switch team does not accept positional arguments.',
			'switchCommand.team.loginRequired' => 'Run genuineci login (or genuineci login --local) before switching teams.',
			'switchCommand.team.authenticationFailed' => ({required Object status}) => 'Authentication failed (HTTP ${status}). Log in again with genuineci login (or genuineci login --local) for the active server.',
			'switchCommand.team.requestFailed' => ({required Object status}) => 'Could not fetch teams (HTTP ${status}).',
			'switchCommand.team.fetchFailed' => 'Could not fetch teams. Check the active profile\'s server URL and network connection.',
			'switchCommand.team.invalidResponse' => 'The server returned an invalid team list. Check that the active profile points to a compatible OpenCI server.',
			'switchCommand.team.empty' => 'No teams found. Create or join a team in the dashboard first.',
			'switchCommand.team.prompt' => 'Select a team',
			'switchCommand.team.current' => 'current',
			'switchCommand.team.controls' => 'Up/Down: move / Enter: select / Esc, Ctrl+C: cancel',
			'switchCommand.team.cancelled' => 'Team switching cancelled. No team was saved.',
			'switchCommand.team.nonInteractive' => 'Team switching requires an interactive terminal with ANSI support. Run genuineci switch team without piping input or redirecting output.',
			'switchCommand.team.inputFailed' => 'Could not select a team. Retry in an interactive terminal.',
			'switchCommand.team.success' => ({required Object team}) => 'Switched to ${team}.',
			'switchCommand.team.alreadyCurrent' => ({required Object team}) => 'Already using ${team}.',
			'switchCommand.team.profileChanged' => 'The active profile or its credentials changed during selection. The selected team was not saved. Run genuineci switch team again.',
			'switchCommand.team.saveFailed' => 'Could not save the selected team. Check the credentials file, its permissions, and available disk space, then retry.',
			'use.description' => 'Set the default display language (japanese, english).',
			'use.success' => ({required Object language}) => 'Language set to ${language}.',
			'use.invalidLanguage' => ({required Object input}) => 'Invalid language "${input}". Supported languages: japanese, english.',
			'dev.description' => 'Manage local development environment (Docker, Tart, DB, Server).',
			'dev.start.description' => 'Start local services and run the Mac Orchard Worker until Ctrl+C.',
			'dev.start.flags.seed' => 'Queue the default smoke-test build job after starting services.',
			'dev.start.starting' => 'Starting OpenCI Local Development Environment...',
			'dev.start.stepTart' => 'Step 1: Checking Tart VM base image...',
			'dev.start.stepTartNotFound' => 'Error: Tart VM image "base-macos" not found.\nPlease run the following commands to setup the base image:\n  tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5\n  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos',
			'dev.start.stepTartExists' => 'Tart VM (base-macos) exists.',
			'dev.start.stepAuthEmulator' => 'Starting Firebase Auth Emulator and waiting for readiness...',
			'dev.start.stepAuthEmulatorFailed' => 'Error: Failed to start or verify Firebase Auth Emulator.',
			'dev.start.stepDockerCompose' => 'Step 5: Starting Docker containers...',
			'dev.start.stepDockerComposeFailed' => 'Error: Failed to start Docker containers.',
			'dev.start.stepDockerComposeStarted' => 'Docker containers started.',
			'dev.start.stepDockerComposeDown' => 'Stopping and removing local Docker containers (keeping data volumes)...',
			'dev.start.stepDockerComposeDownFailed' => 'Error: Failed to shut down local Docker containers. Run docker compose -f docker-compose.yml -f docker-compose.local.yml -f docker-compose.local-api.yml down --remove-orphans from the checkout to retry.',
			'dev.start.stepOrchardWaiting' => 'Step 3: Waiting for Orchard Controller to initialize...',
			'dev.start.stepOrchardNotReady' => 'Error: Orchard Controller did not become ready.',
			'dev.start.stepOrchardContext' => 'Step 4: Registering Orchard CLI context...',
			'dev.start.stepOrchardContextFailed' => 'Error: Failed to register Orchard CLI context.',
			'dev.start.stepOrchardContextRegistered' => 'Orchard CLI context authenticated.',
			'dev.start.stepOrchardWorker' => 'Starting Orchard Worker on this Mac. Press Ctrl+C to stop it. Docker containers will keep running.',
			'dev.start.stepOrchardWorkerFailed' => 'Error: Orchard Worker could not start or exited with an error.',
			'dev.start.stepSeed' => 'Step 6: Seeding local test data...',
			'dev.start.stepSeedFailed' => 'Error: Failed to seed local test data.',
			'dev.start.stepSeedCompleted' => 'Local test data seeded.',
			'dev.start.projectRootNotFound' => 'Error: OpenCI project root not found.',
			'dev.start.stepOrchardController' => 'Step 2: Starting Orchard Controller...',
			'dev.start.stepBuildJobWorkerWaiting' => 'Waiting for the current build job to finish before restarting services...',
			'sync.description' => 'Generate secret definitions and workspace paths in openci/generated.',
			'sync.paths.description' => 'Generate only openci/generated/paths.g.dart from pubspec.yaml.',
			'sync.paths.projectRootNotFound' => 'No project containing pubspec.yaml and an openci directory found. Run this command from your workflow project.',
			'sync.paths.fileAccessFailed' => ({required Object path}) => 'Could not read or write ${path}. Check that the file exists and you have permission to access it.',
			'sync.paths.saved' => ({required Object path}) => 'Generated workspace paths: ${path}',
			'sync.secrets.description' => 'Generate only openci/generated/secrets.g.dart from the active team\'s secret names.',
			'sync.secrets.loginRequired' => 'Run genuineci login (or genuineci login --local) before syncing secrets.',
			'sync.secrets.workflowDirectoryNotFound' => 'No openci directory found. Run this command from your workflow project.',
			'sync.secrets.requestFailed' => ({required Object status}) => 'Could not fetch secret names (HTTP ${status}).',
			'sync.secrets.fetchFailed' => 'Could not fetch secret names. Check the server connection and response.',
			'sync.secrets.saveFailed' => 'Could not save secrets.g.dart. Check the destination and file permissions.',
			'sync.secrets.saved' => ({required Object path}) => 'Generated secret definitions: ${path}',
			'sync.noArguments' => 'sync does not accept positional arguments. Use --secrets or --paths to select what to generate.',
			'common.error' => ({required Object error}) => 'Error: ${error}',
			_ => null,
		};
	}
}
