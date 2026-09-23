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
	late final Translations$login$en login = Translations$login$en.internal(_root);
	late final Translations$list$en list = Translations$list$en.internal(_root);
	late final Translations$register$en register = Translations$register$en.internal(_root);
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

// Path: login
class Translations$login$en {
	Translations$login$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Log in to a local or remote GenuineCI server.'
	String get description => 'Log in to a local or remote GenuineCI server.';

	late final Translations$login$flags$en flags = Translations$login$flags$en.internal(_root);

	/// en: 'Logging in to GenuineCI...'
	String get loggingIn => 'Logging in to GenuineCI...';

	/// en: 'Successfully saved and activated profile "${profile}".'
	String savedSuccess({required Object profile}) => 'Successfully saved and activated profile "${profile}".';

	/// en: 'Login does not accept positional arguments.'
	String get noArguments => 'Login does not accept positional arguments.';

	/// en: 'Could not read the local server's API key. Run genuineci dev start --seed and retry.'
	String get localServerUnavailable => 'Could not read the local server\'s API key. Run genuineci dev start --seed and retry.';

	/// en: 'Local server authentication failed. Check the server started by genuineci dev start.'
	String get authenticationFailed => 'Local server authentication failed. Check the server started by genuineci dev start.';

	/// en: 'Could not fetch teams (HTTP ${status}).'
	String requestFailed({required Object status}) => 'Could not fetch teams (HTTP ${status}).';

	/// en: 'Team test-team was not found. Run genuineci dev start --seed before logging in.'
	String get seedRequired => 'Team test-team was not found. Run genuineci dev start --seed before logging in.';

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

	/// en: 'Could not connect to the remote server. Check the server URL and connection.'
	String get remoteConnectionFailed => 'Could not connect to the remote server. Check the server URL and connection.';

	/// en: 'No teams found. Create or join a team in the dashboard first.'
	String get noTeams => 'No teams found. Create or join a team in the dashboard first.';

	/// en: 'Multiple teams found. Run login again with --team-id from the list above.'
	String get teamRequired => 'Multiple teams found. Run login again with --team-id from the list above.';

	/// en: 'You do not belong to the specified team.'
	String get teamNotFound => 'You do not belong to the specified team.';
}

// Path: list
class Translations$list$en {
	Translations$list$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'List resources in GenuineCI.'
	String get description => 'List resources in GenuineCI.';

	late final Translations$list$secrets$en secrets = Translations$list$secrets$en.internal(_root);
}

// Path: register
class Translations$register$en {
	Translations$register$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Register resources with GenuineCI.'
	String get description => 'Register resources with GenuineCI.';

	late final Translations$register$secret$en secret = Translations$register$secret$en.internal(_root);
	late final Translations$register$secretFile$en secretFile = Translations$register$secretFile$en.internal(_root);
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

	/// en: 'Sync local workflow definitions with GenuineCI.'
	String get description => 'Sync local workflow definitions with GenuineCI.';

	late final Translations$sync$paths$en paths = Translations$sync$paths$en.internal(_root);
	late final Translations$sync$secrets$en secrets = Translations$sync$secrets$en.internal(_root);
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
}

// Path: login.flags
class Translations$login$flags$en {
	Translations$login$flags$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Log in to local Docker environment (http://localhost:8080).'
	String get local => 'Log in to local Docker environment (http://localhost:8080).';

	/// en: 'Remote GenuineCI server URL (HTTPS).'
	String get server => 'Remote GenuineCI server URL (HTTPS).';

	/// en: 'Team to select when you belong to more than one team.'
	String get teamId => 'Team to select when you belong to more than one team.';

	/// en: 'Firebase Web API key (override for a self-hosted Firebase project).'
	String get firebaseApiKey => 'Firebase Web API key (override for a self-hosted Firebase project).';
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

	/// en: 'Step 5: Starting Docker containers...'
	String get stepDockerCompose => 'Step 5: Starting Docker containers...';

	/// en: 'Error: Failed to start Docker containers.'
	String get stepDockerComposeFailed => 'Error: Failed to start Docker containers.';

	/// en: 'Docker containers started.'
	String get stepDockerComposeStarted => 'Docker containers started.';

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

	/// en: 'Generate openci/paths.g.dart from the pubspec.yaml workspace.'
	String get description => 'Generate openci/paths.g.dart from the pubspec.yaml workspace.';

	/// en: 'sync paths does not accept positional arguments.'
	String get noArguments => 'sync paths does not accept positional arguments.';

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

	/// en: 'Generate openci/secrets.g.dart from the active team's secret names.'
	String get description => 'Generate openci/secrets.g.dart from the active team\'s secret names.';

	/// en: 'sync secrets does not accept positional arguments.'
	String get noArguments => 'sync secrets does not accept positional arguments.';

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
			'login.description' => 'Log in to a local or remote GenuineCI server.',
			'login.flags.local' => 'Log in to local Docker environment (http://localhost:8080).',
			'login.flags.server' => 'Remote GenuineCI server URL (HTTPS).',
			'login.flags.teamId' => 'Team to select when you belong to more than one team.',
			'login.flags.firebaseApiKey' => 'Firebase Web API key (override for a self-hosted Firebase project).',
			'login.loggingIn' => 'Logging in to GenuineCI...',
			'login.savedSuccess' => ({required Object profile}) => 'Successfully saved and activated profile "${profile}".',
			'login.noArguments' => 'Login does not accept positional arguments.',
			'login.localServerUnavailable' => 'Could not read the local server\'s API key. Run genuineci dev start --seed and retry.',
			'login.authenticationFailed' => 'Local server authentication failed. Check the server started by genuineci dev start.',
			'login.requestFailed' => ({required Object status}) => 'Could not fetch teams (HTTP ${status}).',
			'login.seedRequired' => 'Team test-team was not found. Run genuineci dev start --seed before logging in.',
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
			'login.remoteConnectionFailed' => 'Could not connect to the remote server. Check the server URL and connection.',
			'login.noTeams' => 'No teams found. Create or join a team in the dashboard first.',
			'login.teamRequired' => 'Multiple teams found. Run login again with --team-id from the list above.',
			'login.teamNotFound' => 'You do not belong to the specified team.',
			'list.description' => 'List resources in GenuineCI.',
			'list.secrets.description' => 'List the active team\'s secret names, sorted by name.',
			'list.secrets.noArguments' => 'list secrets does not accept positional arguments.',
			'list.secrets.loginRequired' => 'Run genuineci login (or genuineci login --local) before listing secrets.',
			'list.secrets.requestFailed' => ({required Object status}) => 'Could not fetch secret names (HTTP ${status}).',
			'list.secrets.fetchFailed' => 'Could not fetch secret names. Check the server connection and response.',
			'list.secrets.empty' => 'No secrets registered for the active team.',
			'register.description' => 'Register resources with GenuineCI.',
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
			'dev.start.stepDockerCompose' => 'Step 5: Starting Docker containers...',
			'dev.start.stepDockerComposeFailed' => 'Error: Failed to start Docker containers.',
			'dev.start.stepDockerComposeStarted' => 'Docker containers started.',
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
			'sync.description' => 'Sync local workflow definitions with GenuineCI.',
			'sync.paths.description' => 'Generate openci/paths.g.dart from the pubspec.yaml workspace.',
			'sync.paths.noArguments' => 'sync paths does not accept positional arguments.',
			'sync.paths.projectRootNotFound' => 'No project containing pubspec.yaml and an openci directory found. Run this command from your workflow project.',
			'sync.paths.fileAccessFailed' => ({required Object path}) => 'Could not read or write ${path}. Check that the file exists and you have permission to access it.',
			'sync.paths.saved' => ({required Object path}) => 'Generated workspace paths: ${path}',
			'sync.secrets.description' => 'Generate openci/secrets.g.dart from the active team\'s secret names.',
			'sync.secrets.noArguments' => 'sync secrets does not accept positional arguments.',
			'sync.secrets.loginRequired' => 'Run genuineci login (or genuineci login --local) before syncing secrets.',
			'sync.secrets.workflowDirectoryNotFound' => 'No openci directory found. Run this command from your workflow project.',
			'sync.secrets.requestFailed' => ({required Object status}) => 'Could not fetch secret names (HTTP ${status}).',
			'sync.secrets.fetchFailed' => 'Could not fetch secret names. Check the server connection and response.',
			'sync.secrets.saveFailed' => 'Could not save secrets.g.dart. Check the destination and file permissions.',
			'sync.secrets.saved' => ({required Object path}) => 'Generated secret definitions: ${path}',
			'common.error' => ({required Object error}) => 'Error: ${error}',
			_ => null,
		};
	}
}
