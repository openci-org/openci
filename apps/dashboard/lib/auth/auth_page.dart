import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/auth/self_hosted_setup_form.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_firebase_auth.dart';
import 'package:dashboard/connections/connection_firebase_config.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/firebase/plist_parser.dart';
import 'package:dashboard/utilities/openci_server_url_provider.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class AuthPage extends HookConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isAgreed = useState(true);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final tapGestureRecognizer = useMemoized(() => TapGestureRecognizer());
    final isLoading = useState(false);
    final obscurePassword = useState(true);

    final authT = t.auth;
    final colorScheme = Theme.of(context).colorScheme;

    final customServerUrl = ref.watch(customServerUrlProvider);
    final hasCustomUrl = customServerUrl != null && customServerUrl.isNotEmpty;
    final localDevelopment = ref.watch(localDevelopmentConnectionProvider);

    // Check if a self-hosted Firebase config is active
    final configReloadKey = useState(0);
    final configFuture = useMemoized(
      () => loadSelfHostedConfig(),
      [configReloadKey.value],
    );
    final configSnapshot = useFuture(configFuture);

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'OpenCI',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            authT.signInSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),

                          // ── Connection indicator ──
                          if (localDevelopment != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Local Auth Emulator · demo-openci',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: colorScheme.primary),
                            ),
                          ] else if (configSnapshot.data != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 13,
                                    color: Colors.green.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      configSnapshot.data!.projectId,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // ── Form card ──
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── Email field ──
                                  TextFormField(
                                    controller: emailController,
                                    autofillHints: const [AutofillHints.email],
                                    decoration: InputDecoration(
                                      labelText: authT.email,
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        size: 18,
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return authT.enterEmail;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  // ── Password field ──
                                  TextFormField(
                                    controller: passwordController,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: authT.password,
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        size: 18,
                                        color: colorScheme.outline,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          obscurePassword.value
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.4),
                                        ),
                                        onPressed: () {
                                          obscurePassword.value =
                                              !obscurePassword.value;
                                        },
                                      ),
                                    ),
                                    obscureText: obscurePassword.value,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return authT.enterPassword;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Terms checkbox ──
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isAgreed.value,
                                        onChanged: (value) {
                                          isAgreed.value = value!;
                                        },
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text.rich(
                                          TextSpan(
                                            text: authT.agreePrefix,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                            children: [
                                              TextSpan(
                                                text: authT.termsOfService,
                                                style: TextStyle(
                                                  color: colorScheme.primary,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: colorScheme
                                                      .primary
                                                      .withValues(alpha: 0.4),
                                                ),
                                                recognizer: tapGestureRecognizer
                                                  ..onTap = () {
                                                    launchUrl(
                                                      Uri.parse(
                                                        'https://openci.org/terms-of-service',
                                                      ),
                                                    );
                                                  },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Primary action: Login ──
                                  FilledButton(
                                    onPressed:
                                        (isAgreed.value && !isLoading.value)
                                        ? () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              isLoading.value = true;
                                              try {
                                                final auth = await ref.read(
                                                  firebaseAuthProvider.future,
                                                );
                                                await auth
                                                    .signInWithEmailAndPassword(
                                                      email:
                                                          emailController.text,
                                                      password:
                                                          passwordController
                                                              .text,
                                                    );
                                                TextInput.finishAutofillContext();
                                              } catch (e) {
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                debugPrint(e.toString());
                                                context.showSnackBarMessage(
                                                  t.common.error(
                                                    error: e.toString(),
                                                  ),
                                                );
                                              } finally {
                                                isLoading.value = false;
                                              }
                                            }
                                          }
                                        : null,
                                    child: Text(authT.login),
                                  ),
                                  const SizedBox(height: 10),

                                  // ── Secondary action: Create Account ──
                                  OutlinedButton(
                                    onPressed:
                                        (isAgreed.value && !isLoading.value)
                                        ? () async {
                                            if (formKey.currentState!
                                                .validate()) {
                                              isLoading.value = true;
                                              try {
                                                final auth = await ref.read(
                                                  firebaseAuthProvider.future,
                                                );
                                                final credential = await auth
                                                    .createUserWithEmailAndPassword(
                                                      email:
                                                          emailController.text,
                                                      password:
                                                          passwordController
                                                              .text,
                                                    );
                                                TextInput.finishAutofillContext();
                                                final userId =
                                                    credential.user!.uid;
                                                final teamId = userId;
                                                final apiService = await ref
                                                    .read(
                                                      openciApiServiceProvider
                                                          .future,
                                                    );
                                                final response =
                                                    await apiService.createTeam(
                                                      {
                                                        'id': teamId,
                                                        'name': teamId,
                                                      },
                                                    );

                                                if (response.statusCode !=
                                                    200) {
                                                  throw StateError(
                                                    'Failed to initialize team on the server: ${response.bodyString}',
                                                  );
                                                }
                                                await ref
                                                    .read(
                                                      selectedTeamIdProvider
                                                          .notifier,
                                                    )
                                                    .saveSelectedTeamId(teamId);
                                              } catch (e) {
                                                if (!context.mounted) {
                                                  return;
                                                }
                                                debugPrint(e.toString());
                                                context.showSnackBarMessage(
                                                  t.common.error(
                                                    error: e.toString(),
                                                  ),
                                                );
                                              } finally {
                                                if (context.mounted) {
                                                  isLoading.value = false;
                                                }
                                              }
                                            }
                                          }
                                        : null,
                                    child: Text(authT.createAccount),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Tertiary actions ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 16,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Advanced Options',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    foregroundColor: colorScheme.onSurface,
                                    side: BorderSide(
                                      color: colorScheme.outlineVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.dns_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    authT.useYourFirebase,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  onPressed: () async {
                                    final action = await showSelfHostedSetup(
                                      context,
                                    );
                                    if (!context.mounted) return;
                                    if (action ==
                                        SelfHostedSetupAction.manual) {
                                      await showModalBottomSheet<void>(
                                        isScrollControlled: true,
                                        context: context,
                                        builder: (_) =>
                                            const FirebaseFormSheet(),
                                      );
                                    }
                                    if (!context.mounted) return;
                                    configReloadKey.value++;
                                  },
                                ),
                                if (configSnapshot.data != null ||
                                    hasCustomUrl) ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      foregroundColor: colorScheme.error,
                                      side: BorderSide(
                                        color: colorScheme.error.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.cloud_off_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      authT.resetFirebase,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    onPressed: () async {
                                      await clearSelfHostedConfig();
                                      await ref
                                          .read(
                                            customServerUrlProvider.notifier,
                                          )
                                          .clearUrl();
                                      ref.invalidate(selfHostedConfigProvider);
                                      configReloadKey.value++;
                                      if (!context.mounted) return;
                                      context.showSnackBarMessage(
                                        authT.resetSuccess,
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading.value) ...[
            const ModalBarrier(
              dismissible: false,
              color: Colors.black54,
            ),
            const Center(child: CircularProgressIndicator.adaptive()),
          ],
        ],
      ),
    );
  }
}

class FirebaseFormSheet extends HookConsumerWidget {
  const FirebaseFormSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final apiKeyController = useTextEditingController();
    final appIdController = useTextEditingController();
    final messagingSenderIdController = useTextEditingController();
    final projectIdController = useTextEditingController();
    final storageBucketController = useTextEditingController();
    final customServerUrlController = useTextEditingController();
    final importedConfig = useState<SelfHostedConfig?>(null);
    final isSaving = useState(false);
    final switchingProfileId = useState<String?>(null);
    final isBusy = isSaving.value || switchingProfileId.value != null;
    final formT = t.auth.firebaseForm;
    final colorScheme = Theme.of(context).colorScheme;
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
    final appIdPlatform = platform == 'macos' ? 'ios' : platform;
    final store = ref.watch(connectionStoreProvider);
    final profiles = useMemoized(() => store.load().profiles, [store]);
    final activeProfile = ref.watch(activeConnectionProfileProvider(store));
    final localDevelopment = ref.watch(localDevelopmentConnectionProvider);

    Future<void> selectProfile(ConnectionProfile profile) async {
      if (isSaving.value || switchingProfileId.value != null) return;
      final selection = ref.read(
        activeConnectionProfileProvider(store).notifier,
      );
      final router = GoRouter.of(context);
      final messenger = ScaffoldMessenger.of(context);
      switchingProfileId.value = profile.id;
      try {
        // Initialize authentication before changing the saved selection, so a
        // configuration error leaves the current connection available.
        final authProvider = connectionFirebaseAuthProvider(
          profile.id,
          firebaseConfigForCurrentPlatform(profile),
        );
        if (ref.read(authProvider).hasError) ref.invalidate(authProvider);
        final auth = await ref.read(authProvider.future);
        final user = await auth.authStateChanges().first;
        if (!context.mounted) return;
        await selection.select(profile.id);

        // Root may remove this sheet while the active authentication changes.
        if (context.mounted) Navigator.pop(context);
        router.go(user == null ? '/auth' : '/');
      } catch (error) {
        if (messenger.mounted) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              responsiveSnackBar(
                messenger.context,
                content: Text(t.common.error(error: error.toString())),
              ),
            );
        }
      } finally {
        if (context.mounted) switchingProfileId.value = null;
      }
    }

    void applyConfig(SelfHostedConfig config) {
      importedConfig.value = config;
      apiKeyController.text = config.apiKey;
      appIdController.text = config.appId;
      messagingSenderIdController.text = config.messagingSenderId;
      projectIdController.text = config.projectId;
      storageBucketController.text = config.storageBucket;
    }

    Future<void> pickConfigFile() async {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'plist'],
        withData: true,
      );
      if (!context.mounted || result == null || result.files.isEmpty) return;

      final file = result.files.first;
      List<int>? bytes = file.bytes;

      if (!kIsWeb && bytes == null && file.path != null) {
        try {
          final f = File(file.path!);
          if (f.existsSync()) {
            bytes = f.readAsBytesSync();
          }
        } catch (e) {
          debugPrint('Error reading file: $e');
        }
      }

      if (bytes == null) {
        if (context.mounted) {
          context.showSnackBarMessage(formT.invalidFile);
        }
        return;
      }

      final fileName = file.name.toLowerCase();

      try {
        String content;
        if (isBinaryPlist(bytes)) {
          throw const FormatException(
            'バイナリ形式の plist はサポートしていません。XML形式に変換した GoogleService-Info.plist を選択してください。',
          );
        } else if (isUtf16Le(bytes)) {
          content = decodeUtf16(bytes, isLittleEndian: true);
        } else if (isUtf16Be(bytes)) {
          content = decodeUtf16(bytes, isLittleEndian: false);
        } else {
          content = utf8.decode(bytes);
        }

        SelfHostedConfig config;
        if (fileName.endsWith('.plist')) {
          config = parsePlist(content);
        } else if (fileName.endsWith('.json')) {
          config = parseJsonConfig(content);
        } else {
          throw const FormatException(
            '未対応のファイル形式です。JSON (google-services.json) または plist (GoogleService-Info.plist) を選択してください。',
          );
        }

        applyConfig(config);
        if (context.mounted) {
          context.showSnackBarMessage(formT.fileLoaded);
        }
      } catch (e) {
        if (context.mounted) {
          context.showSnackBarMessage(
            'ファイルの読み込みに失敗しました: ${e.toString().replaceAll('FormatException: ', '')}',
          );
        }
      }
    }

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                formT.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  if (profiles.isNotEmpty) ...[
                    Text(
                      formT.savedProjects,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final profile in profiles)
                      Container(
                        key: ValueKey(profile.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    profile.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (activeProfile.value?.id == profile.id)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      formT.active,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.apiUrl,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  isBusy ||
                                      activeProfile.isLoading ||
                                      activeProfile.hasError ||
                                      localDevelopment != null ||
                                      activeProfile.value?.id == profile.id
                                  ? null
                                  : () => selectProfile(profile),
                              child: switchingProfileId.value == profile.id
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(formT.useProject),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  // ── Import from file button ──
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isBusy ? null : pickConfigFile,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.upload_file_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formT.importFile,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formT.importFileHint,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: colorScheme.primary.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: formT.profileName,
                      hintText: formT.profileNameHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customServerUrlController,
                    decoration: InputDecoration(
                      labelText: formT.apiUrl,
                      hintText: formT.apiUrlHint,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: apiKeyController,
                    decoration: InputDecoration(labelText: formT.apiKey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: appIdController,
                    decoration: InputDecoration(
                      labelText: formT.appId,
                      hintText: '1:123456789:$appIdPlatform:abcdef',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: projectIdController,
                    decoration: InputDecoration(labelText: formT.projectId),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isBusy
                    ? null
                    : () async {
                        if (isSaving.value ||
                            switchingProfileId.value != null) {
                          return;
                        }
                        final name = nameController.text.trim();
                        final apiUrl = customServerUrlController.text.trim();
                        final apiKey = apiKeyController.text.trim();
                        final appId = appIdController.text.trim();
                        final projectId = projectIdController.text.trim();
                        if (name.isEmpty ||
                            apiUrl.isEmpty ||
                            apiKey.isEmpty ||
                            appId.isEmpty ||
                            projectId.isEmpty) {
                          context.showSnackBarMessage(
                            formT.requiredProfileFields,
                          );
                          return;
                        }

                        final uri = Uri.tryParse(apiUrl);
                        if (uri == null ||
                            !['http', 'https'].contains(uri.scheme) ||
                            uri.host.isEmpty ||
                            RegExp(r'\s').hasMatch(apiUrl) ||
                            uri.userInfo.isNotEmpty ||
                            uri.hasQuery ||
                            uri.hasFragment ||
                            uri.port < 1 ||
                            uri.port > 65535) {
                          context.showSnackBarMessage(formT.invalidApiUrl);
                          return;
                        }

                        if (!RegExp(
                          '^1:[0-9]+:$appIdPlatform:[a-zA-Z0-9]+\$',
                        ).hasMatch(appId)) {
                          context.showSnackBarMessage(formT.invalidAppId);
                          return;
                        }

                        isSaving.value = true;
                        try {
                          final imported = importedConfig.value;
                          final config = SelfHostedConfig(
                            apiKey: apiKey,
                            appId: appId,
                            messagingSenderId:
                                messagingSenderIdController.text.trim().isEmpty
                                ? appId.split(':')[1]
                                : messagingSenderIdController.text.trim(),
                            projectId: projectId,
                            storageBucket: storageBucketController.text.trim(),
                            authDomain: imported?.authDomain,
                            iosBundleId: imported?.iosBundleId,
                            iosClientId: imported?.iosClientId,
                            androidClientId: imported?.androidClientId,
                            databaseURL: imported?.databaseURL,
                            measurementId: imported?.measurementId,
                          );
                          final profile = ConnectionProfile(
                            id: const Uuid().v4(),
                            name: name,
                            apiUrl: apiUrl,
                            firebase: {platform: config},
                          );
                          final store = ref.read(connectionStoreProvider);
                          final snapshot = store.load();
                          await store.save(
                            snapshot.copyWith(
                              profiles: [...snapshot.profiles, profile],
                            ),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          context.showSnackBarMessage(formT.profileSaved);
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage(
                            t.common.error(error: e.toString()),
                          );
                        } finally {
                          if (context.mounted) isSaving.value = false;
                        }
                      },
                child: Text(formT.pickConfig),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
