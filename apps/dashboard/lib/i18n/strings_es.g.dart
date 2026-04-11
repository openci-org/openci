///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEs with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsCommonEs common = _TranslationsCommonEs._(_root);
	@override late final _TranslationsTimeAgoEs timeAgo = _TranslationsTimeAgoEs._(_root);
	@override late final _TranslationsNavEs nav = _TranslationsNavEs._(_root);
	@override late final _TranslationsAuthEs auth = _TranslationsAuthEs._(_root);
	@override late final _TranslationsWorkflowEs workflow = _TranslationsWorkflowEs._(_root);
	@override late final _TranslationsBuildLogsEs buildLogs = _TranslationsBuildLogsEs._(_root);
	@override late final _TranslationsVariablesEs variables = _TranslationsVariablesEs._(_root);
	@override late final _TranslationsSecretsEs secrets = _TranslationsSecretsEs._(_root);
	@override late final _TranslationsEnvVarsEs envVars = _TranslationsEnvVarsEs._(_root);
	@override late final _TranslationsSettingsEs settings = _TranslationsSettingsEs._(_root);
	@override late final _TranslationsNotificationsEs notifications = _TranslationsNotificationsEs._(_root);
	@override late final _TranslationsTeamEs team = _TranslationsTeamEs._(_root);
	@override late final _TranslationsGithubEs github = _TranslationsGithubEs._(_root);
	@override late final _TranslationsSubscriptionEs subscription = _TranslationsSubscriptionEs._(_root);
	@override late final _TranslationsAiWorkflowEs aiWorkflow = _TranslationsAiWorkflowEs._(_root);
	@override late final _TranslationsStoreReleaseEs storeRelease = _TranslationsStoreReleaseEs._(_root);
}

// Path: common
class _TranslationsCommonEs implements TranslationsCommonEn {
	_TranslationsCommonEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get save => 'Guardar';
	@override String get cancel => 'Cancelar';
	@override String get delete => 'Eliminar';
	@override String get add => 'Agregar';
	@override String get edit => 'Editar';
	@override String error({required Object error}) => 'Error: ${error}';
	@override String get loading => 'Cargando...';
	@override String get invite => 'Invitar';
}

// Path: timeAgo
class _TranslationsTimeAgoEs implements TranslationsTimeAgoEn {
	_TranslationsTimeAgoEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String secsAgo({required Object count}) => 'hace ${count} seg';
	@override String secsAgoPlural({required Object count}) => 'hace ${count} segs';
	@override String minsAgo({required Object count}) => 'hace ${count} min';
	@override String minsAgoPlural({required Object count}) => 'hace ${count} mins';
	@override String hoursAgo({required Object count}) => 'hace ${count}h';
	@override String daysAgo({required Object count}) => 'hace ${count}d';
	@override String monthsAgo({required Object count}) => 'hace ${count}m';
}

// Path: nav
class _TranslationsNavEs implements TranslationsNavEn {
	_TranslationsNavEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get workflows => 'Flujos de trabajo';
	@override String get variables => 'Variables';
	@override String get logs => 'Registros';
	@override String get release => 'Lanzamiento';
	@override String get settings => 'Configuración';
}

// Path: auth
class _TranslationsAuthEs implements TranslationsAuthEn {
	_TranslationsAuthEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get email => 'Correo electrónico';
	@override String get password => 'Contraseña';
	@override String get login => 'Iniciar sesión';
	@override String get createAccount => 'Crear nueva cuenta';
	@override String get useYourFirebase => 'Usar tu Firebase';
	@override String get resetFirebase => 'Restablecer Firebase';
	@override String get resetSuccess => 'Firebase se ha restablecido. Por favor, reinicia la aplicación.';
	@override String get agreePrefix => 'Acepto los ';
	@override String get termsOfService => 'Términos de servicio';
	@override String get enterEmail => 'Por favor, ingresa tu correo electrónico';
	@override String get enterPassword => 'Por favor, ingresa tu contraseña';
	@override late final _TranslationsAuthFirebaseFormEs firebaseForm = _TranslationsAuthFirebaseFormEs._(_root);
}

// Path: workflow
class _TranslationsWorkflowEs implements TranslationsWorkflowEn {
	_TranslationsWorkflowEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flujos de trabajo';
	@override String get tabWorkflows => 'Flujos de trabajo';
	@override String get tabRuns => 'Ejecuciones';
	@override String get addWorkflow => 'Agregar flujo de trabajo';
	@override String get noWorkflowFiles => 'No se encontraron archivos de flujo de trabajo';
	@override String get addYamlHint => 'Agrega archivos YAML a .openci/ en tu repositorio.';
	@override String get selectRepo => 'Seleccionar un repositorio';
	@override String get selectRepoHint => 'Elige un repositorio de GitHub para gestionar flujos de trabajo.';
	@override String get selectRepoButton => 'Seleccionar repositorio';
	@override String get enabled => 'Activo';
	@override String get disabled => 'Inactivo';
	@override String get enabledDescription => 'Este flujo de trabajo se ejecutará cuando se active.';
	@override String get disabledDescription => 'Este flujo de trabajo está pausado y no se ejecutará.';
	@override String get enable => 'Activar flujo de trabajo';
	@override String get disable => 'Desactivar flujo de trabajo';
	@override String get triggers => 'Disparadores';
	@override String triggerBranch({required Object type}) => 'Rama de ${type}';
	@override String triggerBranchLoading({required Object type}) => 'Rama de ${type} (cargando...)';
	@override late final _TranslationsWorkflowEditorEs editor = _TranslationsWorkflowEditorEs._(_root);
}

// Path: buildLogs
class _TranslationsBuildLogsEs implements TranslationsBuildLogsEn {
	_TranslationsBuildLogsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object date}) => 'Registros de compilación - ${date}';
	@override String get noJobs => 'No se encontraron trabajos de compilación';
	@override late final _TranslationsBuildLogsStatusEs status = _TranslationsBuildLogsStatusEs._(_root);
	@override late final _TranslationsBuildLogsDetailEs detail = _TranslationsBuildLogsDetailEs._(_root);
	@override late final _TranslationsBuildLogsDurationEs duration = _TranslationsBuildLogsDurationEs._(_root);
}

// Path: variables
class _TranslationsVariablesEs implements TranslationsVariablesEn {
	_TranslationsVariablesEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Variables';
	@override String get envVarsTab => 'Variables de entorno';
	@override String get secretsTab => 'Secretos';
}

// Path: secrets
class _TranslationsSecretsEs implements TranslationsSecretsEn {
	_TranslationsSecretsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gestor de secretos';
	@override String get noSecrets => 'No se encontraron secretos';
	@override String get addSecret => 'Agregar secreto';
	@override String get editSecret => 'Editar secreto';
	@override String get secretName => 'NOMBRE_SECRETO';
	@override String get secretValue => 'Valor del secreto';
	@override String get newSecretValue => 'Nuevo valor del secreto (dejar vacío para mantener el actual)';
	@override String get enterSecretName => 'Por favor, ingresa un nombre de secreto';
	@override String get enterSecretValue => 'Por favor, ingresa un valor de secreto';
	@override String get addedSuccess => 'Secreto agregado exitosamente';
	@override String get updatedSuccess => 'Secreto actualizado exitosamente';
	@override String get deleteConfirm => '¿Estás seguro de que quieres eliminar este secreto? Esta acción no se puede deshacer.';
	@override String get deletedSuccess => 'Secreto eliminado exitosamente';
	@override String get unusedSecrets => 'Secretos no utilizados';
	@override String get notUsedInWorkflows => 'No se usa en ningún flujo de trabajo';
}

// Path: envVars
class _TranslationsEnvVarsEs implements TranslationsEnvVarsEn {
	_TranslationsEnvVarsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Variables de entorno';
	@override String get noEnvVars => 'No se encontraron variables de entorno';
	@override String get noCustomEnvVars => 'Sin variables de entorno personalizadas';
	@override String get addEnvVar => 'Agregar variable de entorno';
	@override String get editEnvVar => 'Editar variable de entorno';
	@override String get editRunNumber => 'Editar número de ejecución';
	@override String get keyName => 'NOMBRE_CLAVE';
	@override String get value => 'Valor';
	@override String get keyHint => 'ej. MI_VARIABLE';
	@override String get valueHint => 'ej. hola';
	@override String get enterKeyName => 'Por favor, ingresa un nombre de clave';
	@override String get enterValue => 'Por favor, ingresa un valor';
	@override String get invalidKey => 'Usa solo letras, números y guiones bajos';
	@override String get valueMustBeNumber => 'El valor debe ser un número';
	@override String get addedSuccess => 'Variable de entorno agregada';
	@override String get updatedSuccess => 'Variable de entorno actualizada';
	@override String get deletedSuccess => 'Eliminado exitosamente';
	@override String get runNumberUpdated => 'Número de ejecución actualizado';
}

// Path: settings
class _TranslationsSettingsEs implements TranslationsSettingsEn {
	_TranslationsSettingsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configuración';
	@override String get buildNotifications => 'Notificaciones de compilación';
	@override String get configureNotifications => 'Configurar cuándo recibir notificaciones';
	@override String get subscription => 'Suscripción';
	@override String get manageSubscription => 'Gestionar tu plan de suscripción';
	@override String firebaseAppName({required Object name}) => 'Nombre de la app Firebase: ${name}';
	@override String get inviteTeamMember => 'Invitar miembro al equipo';
	@override String get appVersion => 'Versión de la app';
	@override String get logout => 'Cerrar sesión';
	@override String get logoutSuccess => 'Sesión cerrada exitosamente';
	@override String logoutFailed({required Object error}) => 'Error al cerrar sesión: ${error}';
	@override String get deleteAccount => 'Eliminar cuenta';
	@override String get deleteConfirmTitle => 'Eliminar cuenta';
	@override String get deleteConfirmMessage => '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y todos tus datos serán eliminados permanentemente.';
	@override String get deleteSuccess => 'Cuenta eliminada exitosamente';
	@override String get noUserSignedIn => 'No hay ningún usuario con sesión iniciada actualmente';
	@override String get requiresRecentLogin => 'Por favor, cierra sesión e inicia sesión de nuevo antes de eliminar tu cuenta';
	@override String deleteFailed({required Object error}) => 'Error al eliminar la cuenta: ${error}';
	@override late final _TranslationsSettingsAiFeaturesEs aiFeatures = _TranslationsSettingsAiFeaturesEs._(_root);
	@override late final _TranslationsSettingsLanguageEs language = _TranslationsSettingsLanguageEs._(_root);
}

// Path: notifications
class _TranslationsNotificationsEs implements TranslationsNotificationsEn {
	_TranslationsNotificationsEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Notificaciones de compilación';
	@override String get all => 'Todas';
	@override String get allDesc => 'Notificar en éxito y fracaso';
	@override String get successOnly => 'Solo éxitos';
	@override String get successOnlyDesc => 'Notificar solo cuando la compilación tiene éxito';
	@override String get failureOnly => 'Solo fallos';
	@override String get failureOnlyDesc => 'Notificar solo cuando la compilación falla';
	@override String get none => 'Ninguna';
	@override String get noneDesc => 'No enviar ninguna notificación';
	@override String get updated => 'Preferencia de notificación actualizada';
	@override String updateFailed({required Object error}) => 'Error al actualizar: ${error}';
	@override String errorLoading({required Object error}) => 'Error al cargar configuración: ${error}';
}

// Path: team
class _TranslationsTeamEs implements TranslationsTeamEn {
	_TranslationsTeamEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get switchTeam => 'Cambiar equipo';
	@override String get editTeam => 'Editar equipo';
	@override String get createTeam => 'Crear equipo';
	@override String get createNewTeam => 'Crear nuevo equipo';
	@override String get teamName => 'Nombre del equipo';
	@override String get newTeamName => 'Nuevo nombre del equipo';
	@override String get selectTeam => 'Seleccionar un equipo';
	@override String get selectTeamLabel => 'Equipo';
	@override String get enterTeamName => 'Por favor, ingresa un nombre de equipo';
	@override String get selectTeamValidation => 'Por favor, selecciona un equipo';
	@override String get createdSuccess => 'Equipo creado exitosamente';
	@override String get updatedSuccess => 'Nombre del equipo actualizado exitosamente';
	@override String get selectedSuccess => 'Equipo seleccionado exitosamente';
	@override String get inviteTitle => 'Invitar miembro al equipo';
	@override String get inviteEmail => 'Correo electrónico';
	@override String get enterEmail => 'Por favor, ingresa un correo electrónico';
	@override String get invitedSuccess => 'Miembro del equipo invitado exitosamente';
	@override String get addedSuccess => 'Miembro agregado al equipo';
	@override String get invitationSent => 'Correo de invitación enviado 📧';
	@override String get processingInvitation => 'Procesando invitación...';
	@override String get invitationFailed => 'Error en la invitación';
	@override String get invitationAccepted => '¡Te has unido! 🎉';
	@override String get alreadyMemberTitle => 'Ya eres miembro';
	@override String alreadyMemberMessage({required Object teamName}) => 'Ya eres miembro de "${teamName}".';
	@override String joinedTeamMessage({required Object teamName}) => 'Te has unido al equipo "${teamName}".';
	@override String get goToDashboard => 'Ir al panel';
	@override String get members => 'Miembros';
	@override String membersCount({required Object count}) => '${count} miembros';
	@override String get you => 'Tú';
	@override String get noEmail => 'Sin correo';
	@override String get deleteTeam => 'Eliminar equipo';
	@override String deleteTeamConfirm({required Object teamName}) => '¿Estás seguro de que quieres eliminar "${teamName}"? Esta acción no se puede deshacer. Todos los flujos de trabajo, secretos y variables de entorno asociados con este equipo serán eliminados permanentemente.';
	@override String get deletedSuccess => 'Equipo eliminado exitosamente';
	@override String get cannotDeleteLastTeam => 'No puedes eliminar tu último equipo. Primero crea otro equipo.';
}

// Path: github
class _TranslationsGithubEs implements TranslationsGithubEn {
	_TranslationsGithubEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get connectTitle => 'Conectar GitHub';
	@override String get connectDescription => 'Conecta tu cuenta de GitHub para\nseleccionar repositorios automáticamente.';
	@override String get connectButton => 'Conectar con GitHub';
}

// Path: subscription
class _TranslationsSubscriptionEs implements TranslationsSubscriptionEn {
	_TranslationsSubscriptionEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Suscripción';
	@override String get noOfferings => 'No hay ofertas disponibles';
	@override String get noPackages => 'No hay paquetes disponibles';
	@override String get plans => 'Planes';
	@override String get restorePurchases => 'Restaurar compras';
	@override String get purchaseSuccess => '¡Compra exitosa!';
	@override String purchaseFailed({required Object error}) => 'Error en la compra: ${error}';
	@override String get restoreSuccess => 'Compras restauradas exitosamente';
	@override String restoreFailed({required Object error}) => 'Error al restaurar: ${error}';
	@override String get activeSubscription => 'Suscripción activa';
	@override String get active => 'Activa';
	@override String get termsOfUse => 'Términos de uso';
	@override String get privacyPolicy => 'Política de privacidad';
	@override String get subscriptionTerms => 'Las suscripciones se renuevan automáticamente a menos que se cancelen al menos 24 horas antes del final del período actual. Se cobrará a tu cuenta de Apple ID la renovación dentro de las 24 horas anteriores al final del período actual. Puedes gestionar y cancelar tus suscripciones en la configuración de tu cuenta en la App Store después de la compra.';
	@override String get subscriptionTermsWeb => 'Las suscripciones se renuevan automáticamente a menos que se cancelen antes del final del período de facturación actual. Puedes gestionar y cancelar tu suscripción desde la configuración de tu cuenta. Los pagos se procesan de forma segura a través de Stripe.';
	@override String get perWeek => 'por semana';
	@override String get perMonth => 'por mes';
	@override String get per3Months => 'por 3 meses';
	@override String get per6Months => 'por 6 meses';
	@override String get perYear => 'por año';
}

// Path: aiWorkflow
class _TranslationsAiWorkflowEs implements TranslationsAiWorkflowEn {
	_TranslationsAiWorkflowEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Constructor de flujo de trabajo con IA';
	@override String get inputHint => 'Describe tu flujo de trabajo...';
	@override String get generatedWorkflow => 'Flujo de trabajo generado';
	@override String get useThisWorkflow => 'Usar este flujo de trabajo';
	@override late final _TranslationsAiWorkflowChatEs chat = _TranslationsAiWorkflowChatEs._(_root);
	@override late final _TranslationsAiWorkflowSuggestionEs suggestion = _TranslationsAiWorkflowSuggestionEs._(_root);
	@override late final _TranslationsAiWorkflowProjectLabelEs projectLabel = _TranslationsAiWorkflowProjectLabelEs._(_root);
	@override late final _TranslationsAiWorkflowGoalLabelEs goalLabel = _TranslationsAiWorkflowGoalLabelEs._(_root);
	@override late final _TranslationsAiWorkflowTriggerLabelEs triggerLabel = _TranslationsAiWorkflowTriggerLabelEs._(_root);
}

// Path: storeRelease
class _TranslationsStoreReleaseEs implements TranslationsStoreReleaseEn {
	_TranslationsStoreReleaseEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lanzamiento en tienda';
	@override String get setupTitle => 'Conectar App Store Connect';
	@override String get setupDescription => 'Ingresa tus credenciales de la API de App Store Connect para gestionar lanzamientos directamente desde OpenCI.';
	@override String get issuerId => 'Issuer ID';
	@override String get keyId => 'Key ID';
	@override String get privateKey => 'Clave privada (.p8)';
	@override String get privateKeyHint => 'Pega el contenido de tu archivo .p8';
	@override String get connect => 'Conectar';
	@override String get connecting => 'Conectando...';
	@override String get setupSuccess => 'App Store Connect conectado exitosamente';
	@override String setupFailed({required Object error}) => 'Error al conectar: ${error}';
	@override String get enterIssuerId => 'Por favor ingresa el Issuer ID';
	@override String get enterKeyId => 'Por favor ingresa el Key ID';
	@override String get enterPrivateKey => 'Por favor ingresa la clave privada';
	@override String get selectApp => 'Seleccionar app';
	@override String get selectAppHint => 'Elige una app para gestionar sus lanzamientos';
	@override String get noApps => 'No se encontraron apps';
	@override String get noAppsHint => 'No se encontraron apps en tu cuenta de App Store Connect.';
	@override String get loadingApps => 'Cargando apps...';
	@override String get ascLoadingHint => 'La API de App Store Connect puede tardar un momento en responder';
	@override String get builds => 'Compilaciones';
	@override String get noBuilds => 'No se encontraron compilaciones';
	@override String get noBuildsHint => 'Sube una compilación a App Store Connect para comenzar.';
	@override String version({required Object version}) => 'v${version}';
	@override String buildNumber({required Object number}) => 'Compilación ${number}';
	@override String get processing => 'Procesando';
	@override String get readyForSale => 'Listo para la venta';
	@override String get valid => 'Listo';
	@override String get invalid => 'Inválido';
	@override String get testFlight => 'TestFlight';
	@override String get submitToTestFlight => 'Enviar a TestFlight';
	@override String get submitToTestFlightConfirm => '¿Enviar esta compilación a los testers externos a través de TestFlight?';
	@override String testFlightSuccess({required Object group}) => 'Compilación enviada al grupo TestFlight: ${group}';
	@override String testFlightFailed({required Object error}) => 'Error al enviar a TestFlight: ${error}';
	@override String get appStoreReview => 'Revisión de App Store';
	@override String get submitForReview => 'Enviar para revisión';
	@override String submitForReviewConfirm({required Object version}) => '¿Enviar esta compilación para revisión en App Store?\n\nVersión: ${version}';
	@override String get reviewSuccess => 'Compilación enviada para revisión en App Store';
	@override String reviewFailed({required Object error}) => 'Error al enviar para revisión: ${error}';
	@override String get versionString => 'Cadena de versión';
	@override String get enterVersionString => 'ej. 1.0.0';
	@override String get versionRequired => 'Por favor ingresa una cadena de versión';
	@override String get whatsNew => 'Novedades';
	@override String get whatsNewHint => 'Describe las novedades de esta versión';
	@override String get whatsNewRequired => 'Por favor ingresa las notas de la versión';
	@override String get changeApp => 'Cambiar app';
	@override String get reconfigure => 'Reconfigurar';
	@override String get howToGetCredentials => 'Cómo obtener credenciales';
	@override String get credentialsHelp => 'Ve a App Store Connect > Usuarios y acceso > Integraciones > API de App Store Connect para generar una clave API.';
	@override String get waitingForReview => 'Esperando revisión';
	@override String get inReview => 'En revisión';
	@override String get pendingRelease => 'Pendiente de lanzamiento';
	@override String get readyForDistribution => 'Listo para distribución';
	@override String get developerRejected => 'Rechazado por el desarrollador';
	@override String get rejected => 'Rechazado';
	@override String get prepareForSubmission => 'Preparar para envío';
	@override String get submitted => 'Enviado';
	@override String get stepBuild => 'Compilación';
	@override String get stepDetails => 'Detalles';
	@override String get stepReview => 'Revisión';
	@override String get selectBuildTitle => 'Seleccionar compilación';
	@override String get selectBuildHint => 'Elige una compilación para enviar a revisión en App Store';
	@override String get releaseDetailsTitle => 'Detalles del lanzamiento';
	@override String get releaseDetailsHint => 'Configurar versión y notas de lanzamiento';
	@override String get reviewTitle => 'Revisar y enviar';
	@override String get reviewHint => 'Confirma todos los detalles antes de enviar';
	@override String get next => 'Siguiente';
	@override String get back => 'Atrás';
	@override String get confirmSubmit => 'Enviar para revisión';
	@override String get submittingReview => 'Enviando...';
	@override String get selectedBuildLabel => 'Compilación seleccionada';
	@override String get screenshotsTitle => 'Capturas de pantalla';
	@override String get noScreenshots => 'No hay capturas disponibles';
	@override String get screenshotsHint => 'Gestiona las capturas en App Store Connect';
	@override String screenshotCount({required Object count}) => '${count} capturas';
	@override String get appDescription => 'Descripción';
	@override String get keywordsLabel => 'Palabras clave';
	@override String get noVersionInfo => 'No se encontró información de versión existente';
	@override String get existingInfo => 'Información actual del App Store';
	@override String get summarySection => 'Resumen del envío';
	@override String get underReview => 'En revisión';
	@override String get underReviewDescription => 'Tu app está siendo revisada por Apple. No se pueden hacer cambios hasta que se complete la revisión.';
	@override String get waitingForReviewDescription => 'Tu app ha sido enviada y está esperando a que Apple inicie la revisión.';
	@override String get pendingReleaseTitle => 'Aprobada';
	@override String get pendingReleaseDescription => '¡Tu app ha sido aprobada! Está pendiente de lanzamiento en el App Store.';
	@override String get submittedBuild => 'Compilación enviada';
	@override String get submittedOn => 'Enviado';
	@override String get estimatedWait => 'Las revisiones suelen tardar entre 24 y 48 horas';
	@override String get viewInAsc => 'Ver en App Store Connect';
}

// Path: auth.firebaseForm
class _TranslationsAuthFirebaseFormEs implements TranslationsAuthFirebaseFormEn {
	_TranslationsAuthFirebaseFormEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Usar tu Firebase';
	@override String get name => 'Nombre';
	@override String get apiKey => 'Clave API';
	@override String get appId => 'ID de aplicación';
	@override String get messagingSenderId => 'ID de remitente de mensajes';
	@override String get projectId => 'ID de proyecto';
	@override String get storageBucket => 'Depósito de almacenamiento';
	@override String get pickConfig => 'Seleccionar configuración de Firebase';
}

// Path: workflow.editor
class _TranslationsWorkflowEditorEs implements TranslationsWorkflowEditorEn {
	_TranslationsWorkflowEditorEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get createTitle => 'Crear flujo de trabajo';
	@override String get editTitle => 'Editar flujo de trabajo';
	@override String get editorTab => 'Editor';
	@override String get yamlTab => 'YAML';
	@override String get basicInfo => 'Información básica';
	@override String get workflowName => 'Nombre del flujo de trabajo';
	@override String get stepName => 'Nombre del paso';
	@override String get stepNameHint => 'ej. Compilar app iOS';
	@override String get type => 'Tipo';
	@override String get command => 'Comando';
	@override String get action => 'Acción';
	@override String get actionHint => 'Toca para buscar acciones';
	@override String get version => 'Versión';
	@override String get kWith => 'with';
	@override String get loadingInputs => 'Cargando entradas...';
	@override String get couldNotLoadInputs => 'No se pudieron cargar las entradas';
	@override String get noInputs => 'No se definieron entradas para esta acción';
	@override String get enterAction => 'Ingresa una acción para ver las entradas disponibles';
	@override String get loadingVersions => 'Cargando versiones...';
	@override String get required => 'requerido';
	@override String get editStep => 'Editar paso';
	@override String get deleteStep => 'Eliminar paso';
	@override String get deleteStepConfirm => '¿Estás seguro de que quieres eliminar este paso?';
	@override String get saveToRepo => 'Guardar en repositorio';
	@override String get fileName => 'Nombre del archivo';
	@override String get fileNameHint => 'ej. build.yaml';
	@override String get howToSave => 'Cómo guardar';
	@override String get commitDirectly => 'Confirmar directamente';
	@override String commitToBranch({required Object branch}) => 'Confirmar en la rama ${branch}';
	@override String get createPR => 'Crear un Pull Request';
	@override String get createPRSubtitle => 'Se creará una nueva rama y se abrirá un PR';
	@override String commitToBranchButton({required Object branch}) => 'Confirmar en ${branch}';
	@override String get createPRButton => 'Crear Pull Request';
	@override String get enterFileName => 'Por favor, ingresa un nombre de archivo';
	@override String get fileNameMustEndYaml => 'El nombre del archivo debe terminar en .yaml o .yml';
	@override String get prCreated => 'Pull Request creado';
	@override String prNumber({required Object number}) => 'PR #${number} fue creado.';
	@override String get close => 'Cerrar';
	@override String get openInGitHub => 'Abrir en GitHub';
	@override String committedToBranch({required Object branch}) => 'Archivo de flujo de trabajo confirmado en ${branch}';
	@override String get prCreatedSuccess => 'Pull request creado';
}

// Path: buildLogs.status
class _TranslationsBuildLogsStatusEs implements TranslationsBuildLogsStatusEn {
	_TranslationsBuildLogsStatusEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get success => 'Exitoso';
	@override String get failed => 'Fallido';
	@override String get inProgress => 'En progreso';
	@override String get queued => 'En cola';
	@override String get cancelled => 'Cancelado';
}

// Path: buildLogs.detail
class _TranslationsBuildLogsDetailEs implements TranslationsBuildLogsDetailEn {
	_TranslationsBuildLogsDetailEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get viewDetails => 'Ver detalles';
	@override String get retry => 'Reintentar';
	@override String get cancelBuild => 'Cancelar compilación';
	@override String get cancelConfirm => '¿Estás seguro de que quieres cancelar esta compilación?';
	@override String get cancelNo => 'No';
	@override String get cancelling => 'Cancelando compilación...';
	@override String get buildCancelled => 'Compilación cancelada';
	@override String failedToCancel({required Object error}) => 'Error al cancelar: ${error}';
	@override String get retrying => 'Reintentando trabajo de compilación...';
	@override String get retrySuccess => 'Trabajo de compilación añadido a la cola';
	@override String failedToRetry({required Object error}) => 'Error al reintentar: ${error}';
	@override String get noRuns => 'Sin ejecuciones aún';
	@override String get waitingForLogs => 'Esperando registros...';
	@override String logEntries({required Object count}) => '${count} entradas de registro';
	@override String get copyAll => 'Copiar todos los registros';
	@override String get logsCopied => 'Registros copiados al portapapeles';
	@override String lines({required Object count}) => '${count} líneas';
	@override String get generatingSummary => 'Generando resumen con IA...';
	@override String get failureSummaryTitle => 'Resumen de fallo con IA';
}

// Path: buildLogs.duration
class _TranslationsBuildLogsDurationEs implements TranslationsBuildLogsDurationEn {
	_TranslationsBuildLogsDurationEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get lessThanMinute => '<1m';
	@override String minutes({required Object count}) => '${count}m';
	@override String hoursAndMinutes({required Object hours, required Object minutes}) => '${hours}h ${minutes}m';
	@override String hours({required Object count}) => '${count}h';
}

// Path: settings.aiFeatures
class _TranslationsSettingsAiFeaturesEs implements TranslationsSettingsAiFeaturesEn {
	_TranslationsSettingsAiFeaturesEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Funciones de IA';
	@override String get subtitle => 'Habilitar funciones impulsadas por IA como el constructor de flujos de trabajo y los resúmenes de fallos';
	@override String get enabled => 'Las funciones de IA están habilitadas';
	@override String get disabled => 'Las funciones de IA están deshabilitadas';
	@override String get updated => 'Configuración de funciones de IA actualizada';
}

// Path: settings.language
class _TranslationsSettingsLanguageEs implements TranslationsSettingsLanguageEn {
	_TranslationsSettingsLanguageEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Idioma';
	@override String get subtitle => 'Cambiar el idioma de visualización';
	@override String get system => 'Predeterminado del sistema';
	@override String get english => 'English';
	@override String get japanese => '日本語';
	@override String get spanish => 'Español';
}

// Path: aiWorkflow.chat
class _TranslationsAiWorkflowChatEs implements TranslationsAiWorkflowChatEn {
	_TranslationsAiWorkflowChatEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get greeting => '¿Qué tipo de flujo de trabajo te gustaría crear? Cuéntame sobre tu proyecto y te ayudaré a configurarlo.';
	@override String projectSelected({required Object project}) => '¡Entendido! Un proyecto ${project}. ¿Qué te gustaría que haga el flujo de trabajo?';
	@override String get triggerQuestion => '¿Cuándo debería ejecutarse este flujo de trabajo?';
	@override String workflowGenerated({required Object plan}) => '¡He generado tu flujo de trabajo! Esto es lo que incluye:\n\n${plan}\n\nPuedes usarlo tal cual o decirme qué te gustaría cambiar.';
	@override String get stepAdded => 'He agregado un paso de ejemplo. Puedes personalizarlo en el editor después de aplicar este flujo de trabajo.';
	@override String get changeTriggerPrompt => '¡Claro! ¿Cuándo debería ejecutarse este flujo de trabajo?';
	@override String get followUp => 'Puedes usar el flujo generado tocando \'Usar este flujo de trabajo\', o dime qué cambios deseas.';
	@override String planFormat({required Object project, required Object steps, required Object trigger}) => '- Proyecto: ${project}\n- Pasos: ${steps}\n- Disparador: ${trigger}';
	@override String get errorMessage => 'Lo siento, algo salió mal. Inténtalo de nuevo o empieza de nuevo.';
}

// Path: aiWorkflow.suggestion
class _TranslationsAiWorkflowSuggestionEs implements TranslationsAiWorkflowSuggestionEn {
	_TranslationsAiWorkflowSuggestionEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get flutterCiCd => 'CI/CD de app Flutter';
	@override String get iosBuildTest => 'Compilar y probar app iOS';
	@override String get androidBuild => 'Compilar app Android';
	@override String get testOnPr => 'Ejecutar pruebas en PR';
	@override String get customWorkflow => 'Flujo personalizado';
	@override String get buildAndTest => 'Compilar y probar';
	@override String get testOnly => 'Solo pruebas';
	@override String get lintAnalyze => 'Lint y análisis';
	@override String get buildDeploy => 'Compilar y desplegar';
	@override String get unitTests => 'Pruebas unitarias';
	@override String get swiftlint => 'Lint con SwiftLint';
	@override String get buildArchive => 'Compilar archivo';
	@override String get lintCheck => 'Verificación de Lint';
	@override String get buildApk => 'Compilar APK';
	@override String get pushToMain => 'Al hacer push a main';
	@override String get onPullRequest => 'En pull request';
	@override String get pushToDevelop => 'Al hacer push a develop';
	@override String get tagCreation => 'Al crear un tag';
	@override String get everyPush => 'En cada push';
	@override String get looksGood => '¡Se ve bien, usar esto!';
	@override String get addSteps => 'Agregar más pasos';
	@override String get changeTrigger => 'Cambiar el disparador';
	@override String get startOver => 'Empezar de nuevo';
}

// Path: aiWorkflow.projectLabel
class _TranslationsAiWorkflowProjectLabelEs implements TranslationsAiWorkflowProjectLabelEn {
	_TranslationsAiWorkflowProjectLabelEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get flutter => 'Flutter';
	@override String get ios => 'iOS (Nativo)';
	@override String get android => 'Android (Nativo)';
	@override String get node => 'Node.js';
	@override String get custom => 'Personalizado';
}

// Path: aiWorkflow.goalLabel
class _TranslationsAiWorkflowGoalLabelEs implements TranslationsAiWorkflowGoalLabelEn {
	_TranslationsAiWorkflowGoalLabelEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get test => 'Ejecutar pruebas';
	@override String get buildAndTest => 'Compilar y probar';
	@override String get deploy => 'Compilar y desplegar';
	@override String get lint => 'Lint / Análisis';
}

// Path: aiWorkflow.triggerLabel
class _TranslationsAiWorkflowTriggerLabelEs implements TranslationsAiWorkflowTriggerLabelEn {
	_TranslationsAiWorkflowTriggerLabelEs._(this._root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get pullRequest => 'Pull Request';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'common.save' => 'Guardar',
			'common.cancel' => 'Cancelar',
			'common.delete' => 'Eliminar',
			'common.add' => 'Agregar',
			'common.edit' => 'Editar',
			'common.error' => ({required Object error}) => 'Error: ${error}',
			'common.loading' => 'Cargando...',
			'common.invite' => 'Invitar',
			'timeAgo.secsAgo' => ({required Object count}) => 'hace ${count} seg',
			'timeAgo.secsAgoPlural' => ({required Object count}) => 'hace ${count} segs',
			'timeAgo.minsAgo' => ({required Object count}) => 'hace ${count} min',
			'timeAgo.minsAgoPlural' => ({required Object count}) => 'hace ${count} mins',
			'timeAgo.hoursAgo' => ({required Object count}) => 'hace ${count}h',
			'timeAgo.daysAgo' => ({required Object count}) => 'hace ${count}d',
			'timeAgo.monthsAgo' => ({required Object count}) => 'hace ${count}m',
			'nav.workflows' => 'Flujos de trabajo',
			'nav.variables' => 'Variables',
			'nav.logs' => 'Registros',
			'nav.release' => 'Lanzamiento',
			'nav.settings' => 'Configuración',
			'auth.email' => 'Correo electrónico',
			'auth.password' => 'Contraseña',
			'auth.login' => 'Iniciar sesión',
			'auth.createAccount' => 'Crear nueva cuenta',
			'auth.useYourFirebase' => 'Usar tu Firebase',
			'auth.resetFirebase' => 'Restablecer Firebase',
			'auth.resetSuccess' => 'Firebase se ha restablecido. Por favor, reinicia la aplicación.',
			'auth.agreePrefix' => 'Acepto los ',
			'auth.termsOfService' => 'Términos de servicio',
			'auth.enterEmail' => 'Por favor, ingresa tu correo electrónico',
			'auth.enterPassword' => 'Por favor, ingresa tu contraseña',
			'auth.firebaseForm.title' => 'Usar tu Firebase',
			'auth.firebaseForm.name' => 'Nombre',
			'auth.firebaseForm.apiKey' => 'Clave API',
			'auth.firebaseForm.appId' => 'ID de aplicación',
			'auth.firebaseForm.messagingSenderId' => 'ID de remitente de mensajes',
			'auth.firebaseForm.projectId' => 'ID de proyecto',
			'auth.firebaseForm.storageBucket' => 'Depósito de almacenamiento',
			'auth.firebaseForm.pickConfig' => 'Seleccionar configuración de Firebase',
			'workflow.title' => 'Flujos de trabajo',
			'workflow.tabWorkflows' => 'Flujos de trabajo',
			'workflow.tabRuns' => 'Ejecuciones',
			'workflow.addWorkflow' => 'Agregar flujo de trabajo',
			'workflow.noWorkflowFiles' => 'No se encontraron archivos de flujo de trabajo',
			'workflow.addYamlHint' => 'Agrega archivos YAML a .openci/ en tu repositorio.',
			'workflow.selectRepo' => 'Seleccionar un repositorio',
			'workflow.selectRepoHint' => 'Elige un repositorio de GitHub para gestionar flujos de trabajo.',
			'workflow.selectRepoButton' => 'Seleccionar repositorio',
			'workflow.enabled' => 'Activo',
			'workflow.disabled' => 'Inactivo',
			'workflow.enabledDescription' => 'Este flujo de trabajo se ejecutará cuando se active.',
			'workflow.disabledDescription' => 'Este flujo de trabajo está pausado y no se ejecutará.',
			'workflow.enable' => 'Activar flujo de trabajo',
			'workflow.disable' => 'Desactivar flujo de trabajo',
			'workflow.triggers' => 'Disparadores',
			'workflow.triggerBranch' => ({required Object type}) => 'Rama de ${type}',
			'workflow.triggerBranchLoading' => ({required Object type}) => 'Rama de ${type} (cargando...)',
			'workflow.editor.createTitle' => 'Crear flujo de trabajo',
			'workflow.editor.editTitle' => 'Editar flujo de trabajo',
			'workflow.editor.editorTab' => 'Editor',
			'workflow.editor.yamlTab' => 'YAML',
			'workflow.editor.basicInfo' => 'Información básica',
			'workflow.editor.workflowName' => 'Nombre del flujo de trabajo',
			'workflow.editor.stepName' => 'Nombre del paso',
			'workflow.editor.stepNameHint' => 'ej. Compilar app iOS',
			'workflow.editor.type' => 'Tipo',
			'workflow.editor.command' => 'Comando',
			'workflow.editor.action' => 'Acción',
			'workflow.editor.actionHint' => 'Toca para buscar acciones',
			'workflow.editor.version' => 'Versión',
			'workflow.editor.kWith' => 'with',
			'workflow.editor.loadingInputs' => 'Cargando entradas...',
			'workflow.editor.couldNotLoadInputs' => 'No se pudieron cargar las entradas',
			'workflow.editor.noInputs' => 'No se definieron entradas para esta acción',
			'workflow.editor.enterAction' => 'Ingresa una acción para ver las entradas disponibles',
			'workflow.editor.loadingVersions' => 'Cargando versiones...',
			'workflow.editor.required' => 'requerido',
			'workflow.editor.editStep' => 'Editar paso',
			'workflow.editor.deleteStep' => 'Eliminar paso',
			'workflow.editor.deleteStepConfirm' => '¿Estás seguro de que quieres eliminar este paso?',
			'workflow.editor.saveToRepo' => 'Guardar en repositorio',
			'workflow.editor.fileName' => 'Nombre del archivo',
			'workflow.editor.fileNameHint' => 'ej. build.yaml',
			'workflow.editor.howToSave' => 'Cómo guardar',
			'workflow.editor.commitDirectly' => 'Confirmar directamente',
			'workflow.editor.commitToBranch' => ({required Object branch}) => 'Confirmar en la rama ${branch}',
			'workflow.editor.createPR' => 'Crear un Pull Request',
			'workflow.editor.createPRSubtitle' => 'Se creará una nueva rama y se abrirá un PR',
			'workflow.editor.commitToBranchButton' => ({required Object branch}) => 'Confirmar en ${branch}',
			'workflow.editor.createPRButton' => 'Crear Pull Request',
			'workflow.editor.enterFileName' => 'Por favor, ingresa un nombre de archivo',
			'workflow.editor.fileNameMustEndYaml' => 'El nombre del archivo debe terminar en .yaml o .yml',
			'workflow.editor.prCreated' => 'Pull Request creado',
			'workflow.editor.prNumber' => ({required Object number}) => 'PR #${number} fue creado.',
			'workflow.editor.close' => 'Cerrar',
			'workflow.editor.openInGitHub' => 'Abrir en GitHub',
			'workflow.editor.committedToBranch' => ({required Object branch}) => 'Archivo de flujo de trabajo confirmado en ${branch}',
			'workflow.editor.prCreatedSuccess' => 'Pull request creado',
			'buildLogs.title' => ({required Object date}) => 'Registros de compilación - ${date}',
			'buildLogs.noJobs' => 'No se encontraron trabajos de compilación',
			'buildLogs.status.success' => 'Exitoso',
			'buildLogs.status.failed' => 'Fallido',
			'buildLogs.status.inProgress' => 'En progreso',
			'buildLogs.status.queued' => 'En cola',
			'buildLogs.status.cancelled' => 'Cancelado',
			'buildLogs.detail.viewDetails' => 'Ver detalles',
			'buildLogs.detail.retry' => 'Reintentar',
			'buildLogs.detail.cancelBuild' => 'Cancelar compilación',
			'buildLogs.detail.cancelConfirm' => '¿Estás seguro de que quieres cancelar esta compilación?',
			'buildLogs.detail.cancelNo' => 'No',
			'buildLogs.detail.cancelling' => 'Cancelando compilación...',
			'buildLogs.detail.buildCancelled' => 'Compilación cancelada',
			'buildLogs.detail.failedToCancel' => ({required Object error}) => 'Error al cancelar: ${error}',
			'buildLogs.detail.retrying' => 'Reintentando trabajo de compilación...',
			'buildLogs.detail.retrySuccess' => 'Trabajo de compilación añadido a la cola',
			'buildLogs.detail.failedToRetry' => ({required Object error}) => 'Error al reintentar: ${error}',
			'buildLogs.detail.noRuns' => 'Sin ejecuciones aún',
			'buildLogs.detail.waitingForLogs' => 'Esperando registros...',
			'buildLogs.detail.logEntries' => ({required Object count}) => '${count} entradas de registro',
			'buildLogs.detail.copyAll' => 'Copiar todos los registros',
			'buildLogs.detail.logsCopied' => 'Registros copiados al portapapeles',
			'buildLogs.detail.lines' => ({required Object count}) => '${count} líneas',
			'buildLogs.detail.generatingSummary' => 'Generando resumen con IA...',
			'buildLogs.detail.failureSummaryTitle' => 'Resumen de fallo con IA',
			'buildLogs.duration.lessThanMinute' => '<1m',
			'buildLogs.duration.minutes' => ({required Object count}) => '${count}m',
			'buildLogs.duration.hoursAndMinutes' => ({required Object hours, required Object minutes}) => '${hours}h ${minutes}m',
			'buildLogs.duration.hours' => ({required Object count}) => '${count}h',
			'variables.title' => 'Variables',
			'variables.envVarsTab' => 'Variables de entorno',
			'variables.secretsTab' => 'Secretos',
			'secrets.title' => 'Gestor de secretos',
			'secrets.noSecrets' => 'No se encontraron secretos',
			'secrets.addSecret' => 'Agregar secreto',
			'secrets.editSecret' => 'Editar secreto',
			'secrets.secretName' => 'NOMBRE_SECRETO',
			'secrets.secretValue' => 'Valor del secreto',
			'secrets.newSecretValue' => 'Nuevo valor del secreto (dejar vacío para mantener el actual)',
			'secrets.enterSecretName' => 'Por favor, ingresa un nombre de secreto',
			'secrets.enterSecretValue' => 'Por favor, ingresa un valor de secreto',
			'secrets.addedSuccess' => 'Secreto agregado exitosamente',
			'secrets.updatedSuccess' => 'Secreto actualizado exitosamente',
			'secrets.deleteConfirm' => '¿Estás seguro de que quieres eliminar este secreto? Esta acción no se puede deshacer.',
			'secrets.deletedSuccess' => 'Secreto eliminado exitosamente',
			'secrets.unusedSecrets' => 'Secretos no utilizados',
			'secrets.notUsedInWorkflows' => 'No se usa en ningún flujo de trabajo',
			'envVars.title' => 'Variables de entorno',
			'envVars.noEnvVars' => 'No se encontraron variables de entorno',
			'envVars.noCustomEnvVars' => 'Sin variables de entorno personalizadas',
			'envVars.addEnvVar' => 'Agregar variable de entorno',
			'envVars.editEnvVar' => 'Editar variable de entorno',
			'envVars.editRunNumber' => 'Editar número de ejecución',
			'envVars.keyName' => 'NOMBRE_CLAVE',
			'envVars.value' => 'Valor',
			'envVars.keyHint' => 'ej. MI_VARIABLE',
			'envVars.valueHint' => 'ej. hola',
			'envVars.enterKeyName' => 'Por favor, ingresa un nombre de clave',
			'envVars.enterValue' => 'Por favor, ingresa un valor',
			'envVars.invalidKey' => 'Usa solo letras, números y guiones bajos',
			'envVars.valueMustBeNumber' => 'El valor debe ser un número',
			'envVars.addedSuccess' => 'Variable de entorno agregada',
			'envVars.updatedSuccess' => 'Variable de entorno actualizada',
			'envVars.deletedSuccess' => 'Eliminado exitosamente',
			'envVars.runNumberUpdated' => 'Número de ejecución actualizado',
			'settings.title' => 'Configuración',
			'settings.buildNotifications' => 'Notificaciones de compilación',
			'settings.configureNotifications' => 'Configurar cuándo recibir notificaciones',
			'settings.subscription' => 'Suscripción',
			'settings.manageSubscription' => 'Gestionar tu plan de suscripción',
			'settings.firebaseAppName' => ({required Object name}) => 'Nombre de la app Firebase: ${name}',
			'settings.inviteTeamMember' => 'Invitar miembro al equipo',
			'settings.appVersion' => 'Versión de la app',
			'settings.logout' => 'Cerrar sesión',
			'settings.logoutSuccess' => 'Sesión cerrada exitosamente',
			'settings.logoutFailed' => ({required Object error}) => 'Error al cerrar sesión: ${error}',
			'settings.deleteAccount' => 'Eliminar cuenta',
			'settings.deleteConfirmTitle' => 'Eliminar cuenta',
			'settings.deleteConfirmMessage' => '¿Estás seguro de que quieres eliminar tu cuenta? Esta acción no se puede deshacer y todos tus datos serán eliminados permanentemente.',
			'settings.deleteSuccess' => 'Cuenta eliminada exitosamente',
			'settings.noUserSignedIn' => 'No hay ningún usuario con sesión iniciada actualmente',
			'settings.requiresRecentLogin' => 'Por favor, cierra sesión e inicia sesión de nuevo antes de eliminar tu cuenta',
			'settings.deleteFailed' => ({required Object error}) => 'Error al eliminar la cuenta: ${error}',
			'settings.aiFeatures.title' => 'Funciones de IA',
			'settings.aiFeatures.subtitle' => 'Habilitar funciones impulsadas por IA como el constructor de flujos de trabajo y los resúmenes de fallos',
			'settings.aiFeatures.enabled' => 'Las funciones de IA están habilitadas',
			'settings.aiFeatures.disabled' => 'Las funciones de IA están deshabilitadas',
			'settings.aiFeatures.updated' => 'Configuración de funciones de IA actualizada',
			'settings.language.title' => 'Idioma',
			'settings.language.subtitle' => 'Cambiar el idioma de visualización',
			'settings.language.system' => 'Predeterminado del sistema',
			'settings.language.english' => 'English',
			'settings.language.japanese' => '日本語',
			'settings.language.spanish' => 'Español',
			'notifications.title' => 'Notificaciones de compilación',
			'notifications.all' => 'Todas',
			'notifications.allDesc' => 'Notificar en éxito y fracaso',
			'notifications.successOnly' => 'Solo éxitos',
			'notifications.successOnlyDesc' => 'Notificar solo cuando la compilación tiene éxito',
			'notifications.failureOnly' => 'Solo fallos',
			'notifications.failureOnlyDesc' => 'Notificar solo cuando la compilación falla',
			'notifications.none' => 'Ninguna',
			'notifications.noneDesc' => 'No enviar ninguna notificación',
			'notifications.updated' => 'Preferencia de notificación actualizada',
			'notifications.updateFailed' => ({required Object error}) => 'Error al actualizar: ${error}',
			'notifications.errorLoading' => ({required Object error}) => 'Error al cargar configuración: ${error}',
			'team.switchTeam' => 'Cambiar equipo',
			'team.editTeam' => 'Editar equipo',
			'team.createTeam' => 'Crear equipo',
			'team.createNewTeam' => 'Crear nuevo equipo',
			'team.teamName' => 'Nombre del equipo',
			'team.newTeamName' => 'Nuevo nombre del equipo',
			'team.selectTeam' => 'Seleccionar un equipo',
			'team.selectTeamLabel' => 'Equipo',
			'team.enterTeamName' => 'Por favor, ingresa un nombre de equipo',
			'team.selectTeamValidation' => 'Por favor, selecciona un equipo',
			'team.createdSuccess' => 'Equipo creado exitosamente',
			'team.updatedSuccess' => 'Nombre del equipo actualizado exitosamente',
			'team.selectedSuccess' => 'Equipo seleccionado exitosamente',
			'team.inviteTitle' => 'Invitar miembro al equipo',
			'team.inviteEmail' => 'Correo electrónico',
			'team.enterEmail' => 'Por favor, ingresa un correo electrónico',
			'team.invitedSuccess' => 'Miembro del equipo invitado exitosamente',
			'team.addedSuccess' => 'Miembro agregado al equipo',
			'team.invitationSent' => 'Correo de invitación enviado 📧',
			'team.processingInvitation' => 'Procesando invitación...',
			'team.invitationFailed' => 'Error en la invitación',
			'team.invitationAccepted' => '¡Te has unido! 🎉',
			'team.alreadyMemberTitle' => 'Ya eres miembro',
			'team.alreadyMemberMessage' => ({required Object teamName}) => 'Ya eres miembro de "${teamName}".',
			'team.joinedTeamMessage' => ({required Object teamName}) => 'Te has unido al equipo "${teamName}".',
			'team.goToDashboard' => 'Ir al panel',
			'team.members' => 'Miembros',
			'team.membersCount' => ({required Object count}) => '${count} miembros',
			'team.you' => 'Tú',
			'team.noEmail' => 'Sin correo',
			'team.deleteTeam' => 'Eliminar equipo',
			'team.deleteTeamConfirm' => ({required Object teamName}) => '¿Estás seguro de que quieres eliminar "${teamName}"? Esta acción no se puede deshacer. Todos los flujos de trabajo, secretos y variables de entorno asociados con este equipo serán eliminados permanentemente.',
			'team.deletedSuccess' => 'Equipo eliminado exitosamente',
			'team.cannotDeleteLastTeam' => 'No puedes eliminar tu último equipo. Primero crea otro equipo.',
			'github.connectTitle' => 'Conectar GitHub',
			'github.connectDescription' => 'Conecta tu cuenta de GitHub para\nseleccionar repositorios automáticamente.',
			'github.connectButton' => 'Conectar con GitHub',
			'subscription.title' => 'Suscripción',
			'subscription.noOfferings' => 'No hay ofertas disponibles',
			'subscription.noPackages' => 'No hay paquetes disponibles',
			'subscription.plans' => 'Planes',
			'subscription.restorePurchases' => 'Restaurar compras',
			'subscription.purchaseSuccess' => '¡Compra exitosa!',
			'subscription.purchaseFailed' => ({required Object error}) => 'Error en la compra: ${error}',
			'subscription.restoreSuccess' => 'Compras restauradas exitosamente',
			'subscription.restoreFailed' => ({required Object error}) => 'Error al restaurar: ${error}',
			'subscription.activeSubscription' => 'Suscripción activa',
			'subscription.active' => 'Activa',
			'subscription.termsOfUse' => 'Términos de uso',
			'subscription.privacyPolicy' => 'Política de privacidad',
			'subscription.subscriptionTerms' => 'Las suscripciones se renuevan automáticamente a menos que se cancelen al menos 24 horas antes del final del período actual. Se cobrará a tu cuenta de Apple ID la renovación dentro de las 24 horas anteriores al final del período actual. Puedes gestionar y cancelar tus suscripciones en la configuración de tu cuenta en la App Store después de la compra.',
			'subscription.subscriptionTermsWeb' => 'Las suscripciones se renuevan automáticamente a menos que se cancelen antes del final del período de facturación actual. Puedes gestionar y cancelar tu suscripción desde la configuración de tu cuenta. Los pagos se procesan de forma segura a través de Stripe.',
			'subscription.perWeek' => 'por semana',
			'subscription.perMonth' => 'por mes',
			'subscription.per3Months' => 'por 3 meses',
			'subscription.per6Months' => 'por 6 meses',
			'subscription.perYear' => 'por año',
			'aiWorkflow.title' => 'Constructor de flujo de trabajo con IA',
			'aiWorkflow.inputHint' => 'Describe tu flujo de trabajo...',
			'aiWorkflow.generatedWorkflow' => 'Flujo de trabajo generado',
			'aiWorkflow.useThisWorkflow' => 'Usar este flujo de trabajo',
			'aiWorkflow.chat.greeting' => '¿Qué tipo de flujo de trabajo te gustaría crear? Cuéntame sobre tu proyecto y te ayudaré a configurarlo.',
			'aiWorkflow.chat.projectSelected' => ({required Object project}) => '¡Entendido! Un proyecto ${project}. ¿Qué te gustaría que haga el flujo de trabajo?',
			'aiWorkflow.chat.triggerQuestion' => '¿Cuándo debería ejecutarse este flujo de trabajo?',
			'aiWorkflow.chat.workflowGenerated' => ({required Object plan}) => '¡He generado tu flujo de trabajo! Esto es lo que incluye:\n\n${plan}\n\nPuedes usarlo tal cual o decirme qué te gustaría cambiar.',
			'aiWorkflow.chat.stepAdded' => 'He agregado un paso de ejemplo. Puedes personalizarlo en el editor después de aplicar este flujo de trabajo.',
			'aiWorkflow.chat.changeTriggerPrompt' => '¡Claro! ¿Cuándo debería ejecutarse este flujo de trabajo?',
			'aiWorkflow.chat.followUp' => 'Puedes usar el flujo generado tocando \'Usar este flujo de trabajo\', o dime qué cambios deseas.',
			'aiWorkflow.chat.planFormat' => ({required Object project, required Object steps, required Object trigger}) => '- Proyecto: ${project}\n- Pasos: ${steps}\n- Disparador: ${trigger}',
			'aiWorkflow.chat.errorMessage' => 'Lo siento, algo salió mal. Inténtalo de nuevo o empieza de nuevo.',
			'aiWorkflow.suggestion.flutterCiCd' => 'CI/CD de app Flutter',
			'aiWorkflow.suggestion.iosBuildTest' => 'Compilar y probar app iOS',
			'aiWorkflow.suggestion.androidBuild' => 'Compilar app Android',
			'aiWorkflow.suggestion.testOnPr' => 'Ejecutar pruebas en PR',
			'aiWorkflow.suggestion.customWorkflow' => 'Flujo personalizado',
			'aiWorkflow.suggestion.buildAndTest' => 'Compilar y probar',
			'aiWorkflow.suggestion.testOnly' => 'Solo pruebas',
			'aiWorkflow.suggestion.lintAnalyze' => 'Lint y análisis',
			'aiWorkflow.suggestion.buildDeploy' => 'Compilar y desplegar',
			'aiWorkflow.suggestion.unitTests' => 'Pruebas unitarias',
			'aiWorkflow.suggestion.swiftlint' => 'Lint con SwiftLint',
			'aiWorkflow.suggestion.buildArchive' => 'Compilar archivo',
			'aiWorkflow.suggestion.lintCheck' => 'Verificación de Lint',
			'aiWorkflow.suggestion.buildApk' => 'Compilar APK',
			'aiWorkflow.suggestion.pushToMain' => 'Al hacer push a main',
			'aiWorkflow.suggestion.onPullRequest' => 'En pull request',
			'aiWorkflow.suggestion.pushToDevelop' => 'Al hacer push a develop',
			'aiWorkflow.suggestion.tagCreation' => 'Al crear un tag',
			'aiWorkflow.suggestion.everyPush' => 'En cada push',
			'aiWorkflow.suggestion.looksGood' => '¡Se ve bien, usar esto!',
			'aiWorkflow.suggestion.addSteps' => 'Agregar más pasos',
			'aiWorkflow.suggestion.changeTrigger' => 'Cambiar el disparador',
			'aiWorkflow.suggestion.startOver' => 'Empezar de nuevo',
			'aiWorkflow.projectLabel.flutter' => 'Flutter',
			'aiWorkflow.projectLabel.ios' => 'iOS (Nativo)',
			'aiWorkflow.projectLabel.android' => 'Android (Nativo)',
			'aiWorkflow.projectLabel.node' => 'Node.js',
			'aiWorkflow.projectLabel.custom' => 'Personalizado',
			'aiWorkflow.goalLabel.test' => 'Ejecutar pruebas',
			'aiWorkflow.goalLabel.buildAndTest' => 'Compilar y probar',
			'aiWorkflow.goalLabel.deploy' => 'Compilar y desplegar',
			'aiWorkflow.goalLabel.lint' => 'Lint / Análisis',
			'aiWorkflow.triggerLabel.pullRequest' => 'Pull Request',
			'storeRelease.title' => 'Lanzamiento en tienda',
			'storeRelease.setupTitle' => 'Conectar App Store Connect',
			'storeRelease.setupDescription' => 'Ingresa tus credenciales de la API de App Store Connect para gestionar lanzamientos directamente desde OpenCI.',
			'storeRelease.issuerId' => 'Issuer ID',
			'storeRelease.keyId' => 'Key ID',
			'storeRelease.privateKey' => 'Clave privada (.p8)',
			'storeRelease.privateKeyHint' => 'Pega el contenido de tu archivo .p8',
			'storeRelease.connect' => 'Conectar',
			'storeRelease.connecting' => 'Conectando...',
			'storeRelease.setupSuccess' => 'App Store Connect conectado exitosamente',
			'storeRelease.setupFailed' => ({required Object error}) => 'Error al conectar: ${error}',
			'storeRelease.enterIssuerId' => 'Por favor ingresa el Issuer ID',
			'storeRelease.enterKeyId' => 'Por favor ingresa el Key ID',
			'storeRelease.enterPrivateKey' => 'Por favor ingresa la clave privada',
			'storeRelease.selectApp' => 'Seleccionar app',
			'storeRelease.selectAppHint' => 'Elige una app para gestionar sus lanzamientos',
			'storeRelease.noApps' => 'No se encontraron apps',
			'storeRelease.noAppsHint' => 'No se encontraron apps en tu cuenta de App Store Connect.',
			'storeRelease.loadingApps' => 'Cargando apps...',
			'storeRelease.ascLoadingHint' => 'La API de App Store Connect puede tardar un momento en responder',
			'storeRelease.builds' => 'Compilaciones',
			'storeRelease.noBuilds' => 'No se encontraron compilaciones',
			'storeRelease.noBuildsHint' => 'Sube una compilación a App Store Connect para comenzar.',
			'storeRelease.version' => ({required Object version}) => 'v${version}',
			'storeRelease.buildNumber' => ({required Object number}) => 'Compilación ${number}',
			'storeRelease.processing' => 'Procesando',
			'storeRelease.readyForSale' => 'Listo para la venta',
			'storeRelease.valid' => 'Listo',
			'storeRelease.invalid' => 'Inválido',
			'storeRelease.testFlight' => 'TestFlight',
			'storeRelease.submitToTestFlight' => 'Enviar a TestFlight',
			'storeRelease.submitToTestFlightConfirm' => '¿Enviar esta compilación a los testers externos a través de TestFlight?',
			'storeRelease.testFlightSuccess' => ({required Object group}) => 'Compilación enviada al grupo TestFlight: ${group}',
			'storeRelease.testFlightFailed' => ({required Object error}) => 'Error al enviar a TestFlight: ${error}',
			'storeRelease.appStoreReview' => 'Revisión de App Store',
			'storeRelease.submitForReview' => 'Enviar para revisión',
			'storeRelease.submitForReviewConfirm' => ({required Object version}) => '¿Enviar esta compilación para revisión en App Store?\n\nVersión: ${version}',
			'storeRelease.reviewSuccess' => 'Compilación enviada para revisión en App Store',
			'storeRelease.reviewFailed' => ({required Object error}) => 'Error al enviar para revisión: ${error}',
			'storeRelease.versionString' => 'Cadena de versión',
			'storeRelease.enterVersionString' => 'ej. 1.0.0',
			'storeRelease.versionRequired' => 'Por favor ingresa una cadena de versión',
			'storeRelease.whatsNew' => 'Novedades',
			'storeRelease.whatsNewHint' => 'Describe las novedades de esta versión',
			'storeRelease.whatsNewRequired' => 'Por favor ingresa las notas de la versión',
			'storeRelease.changeApp' => 'Cambiar app',
			'storeRelease.reconfigure' => 'Reconfigurar',
			'storeRelease.howToGetCredentials' => 'Cómo obtener credenciales',
			'storeRelease.credentialsHelp' => 'Ve a App Store Connect > Usuarios y acceso > Integraciones > API de App Store Connect para generar una clave API.',
			'storeRelease.waitingForReview' => 'Esperando revisión',
			'storeRelease.inReview' => 'En revisión',
			'storeRelease.pendingRelease' => 'Pendiente de lanzamiento',
			'storeRelease.readyForDistribution' => 'Listo para distribución',
			'storeRelease.developerRejected' => 'Rechazado por el desarrollador',
			'storeRelease.rejected' => 'Rechazado',
			'storeRelease.prepareForSubmission' => 'Preparar para envío',
			'storeRelease.submitted' => 'Enviado',
			'storeRelease.stepBuild' => 'Compilación',
			'storeRelease.stepDetails' => 'Detalles',
			'storeRelease.stepReview' => 'Revisión',
			'storeRelease.selectBuildTitle' => 'Seleccionar compilación',
			'storeRelease.selectBuildHint' => 'Elige una compilación para enviar a revisión en App Store',
			'storeRelease.releaseDetailsTitle' => 'Detalles del lanzamiento',
			'storeRelease.releaseDetailsHint' => 'Configurar versión y notas de lanzamiento',
			'storeRelease.reviewTitle' => 'Revisar y enviar',
			'storeRelease.reviewHint' => 'Confirma todos los detalles antes de enviar',
			'storeRelease.next' => 'Siguiente',
			'storeRelease.back' => 'Atrás',
			'storeRelease.confirmSubmit' => 'Enviar para revisión',
			'storeRelease.submittingReview' => 'Enviando...',
			'storeRelease.selectedBuildLabel' => 'Compilación seleccionada',
			'storeRelease.screenshotsTitle' => 'Capturas de pantalla',
			'storeRelease.noScreenshots' => 'No hay capturas disponibles',
			'storeRelease.screenshotsHint' => 'Gestiona las capturas en App Store Connect',
			'storeRelease.screenshotCount' => ({required Object count}) => '${count} capturas',
			'storeRelease.appDescription' => 'Descripción',
			'storeRelease.keywordsLabel' => 'Palabras clave',
			'storeRelease.noVersionInfo' => 'No se encontró información de versión existente',
			'storeRelease.existingInfo' => 'Información actual del App Store',
			'storeRelease.summarySection' => 'Resumen del envío',
			'storeRelease.underReview' => 'En revisión',
			'storeRelease.underReviewDescription' => 'Tu app está siendo revisada por Apple. No se pueden hacer cambios hasta que se complete la revisión.',
			'storeRelease.waitingForReviewDescription' => 'Tu app ha sido enviada y está esperando a que Apple inicie la revisión.',
			'storeRelease.pendingReleaseTitle' => 'Aprobada',
			'storeRelease.pendingReleaseDescription' => '¡Tu app ha sido aprobada! Está pendiente de lanzamiento en el App Store.',
			'storeRelease.submittedBuild' => 'Compilación enviada',
			'storeRelease.submittedOn' => 'Enviado',
			'storeRelease.estimatedWait' => 'Las revisiones suelen tardar entre 24 y 48 horas',
			'storeRelease.viewInAsc' => 'Ver en App Store Connect',
			_ => null,
		};
	}
}
