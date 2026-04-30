import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/firebase/plist_parser.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/function_error_message.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

void _processInvitations() {
  unawaited(_processInvitationsAsync());
}

Future<void> _processInvitationsAsync() async {
  try {
    await firebaseFunctions.httpsCallable('acceptInvitations').call<void>();
  } on FirebaseFunctionsException catch (e, s) {
    final errorMessage = await FunctionErrorMessage.capture(
      e,
      stackTrace: s,
    );
    debugPrint('acceptInvitations failed: ${errorMessage.message}');
  } catch (e) {
    debugPrint('acceptInvitations failed: $e');
  }
}

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

    // Check if a self-hosted Firebase config is active
    final configReloadKey = useState(0);
    final configFuture = useMemoized(
      () => loadSelfHostedConfig(),
      [configReloadKey.value],
    );
    final configSnapshot = useFuture(configFuture);

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
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
                          // ── Branded logo ──
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'CI',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.of(context).textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'OpenCI',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.of(context).textPrimary,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sign in to your account',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.of(context).textSecondary,
                                ),
                          ),

                          // ── Self-hosted config indicator ──
                          if (configSnapshot.data != null) ...[
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
                                  Text(
                                    configSnapshot.data!.projectId,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green.withValues(
                                        alpha: 0.8,
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
                              color: AppColors.of(context).surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.of(context).border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── Email field ──
                                TextFormField(
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    labelText: authT.email,
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      size: 18,
                                      color: AppColors.of(context).textTertiary,
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
                                  decoration: InputDecoration(
                                    labelText: authT.password,
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      size: 18,
                                      color: AppColors.of(context).textTertiary,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        obscurePassword.value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color: AppColors.of(
                                          context,
                                        ).textPrimary.withValues(alpha: 0.4),
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
                                                color: AppColors.of(context)
                                                    .textPrimary
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
                                              await FirebaseAuth.instance
                                                  .signInWithEmailAndPassword(
                                                    email: emailController.text,
                                                    password:
                                                        passwordController.text,
                                                  );
                                              ref.invalidate(authProvider);
                                              // Process pending invitations (fire-and-forget)
                                              _processInvitations();
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
                                              final credential = await FirebaseAuth
                                                  .instance
                                                  .createUserWithEmailAndPassword(
                                                    email: emailController.text,
                                                    password:
                                                        passwordController.text,
                                                  );
                                              final userId =
                                                  credential.user!.uid;
                                              final teamId = userId;
                                              await dataConnector
                                                  .createTeamForCurrentUser(
                                                    id: teamId,
                                                    name: teamId,
                                                  )
                                                  .execute();
                                              ref.invalidate(authProvider);
                                              _processInvitations();
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
                                    await showModalBottomSheet(
                                      isScrollControlled: true,
                                      context: context,
                                      builder: (context) {
                                        return const FirebaseFormSheet();
                                      },
                                    );
                                    configReloadKey.value++;
                                  },
                                ),
                                if (configSnapshot.data != null) ...[
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

  /// Tries to parse file content as JSON (google-services.json) and returns
  /// a [SelfHostedConfig] if successful.
  static SelfHostedConfig? _parseJson(String content) {
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;

      // Web-style firebase config JSON (has apiKey at top-level)
      if (map.containsKey('apiKey')) {
        return SelfHostedConfig.fromJson(map);
      }

      // Android google-services.json style
      final projectInfo = map['project_info'] as Map<String, dynamic>?;
      final clients = map['client'] as List<dynamic>?;
      if (projectInfo != null && clients != null && clients.isNotEmpty) {
        final client = clients[0] as Map<String, dynamic>;
        final clientInfo = client['client_info'] as Map<String, dynamic>? ?? {};
        final apiKeys = client['api_key'] as List<dynamic>? ?? [];
        final appId = clientInfo['mobilesdk_app_id'] as String? ?? '';
        final apiKey = apiKeys.isNotEmpty
            ? (apiKeys[0] as Map<String, dynamic>)['current_key'] as String? ??
                  ''
            : '';
        final projectId = projectInfo['project_id'] as String? ?? '';
        final storageBucket = projectInfo['storage_bucket'] as String? ?? '';
        final projectNumber = projectInfo['project_number'] as String? ?? '';

        if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) {
          return null;
        }

        return SelfHostedConfig(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: projectNumber,
          projectId: projectId,
          storageBucket: storageBucket,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKeyController = useTextEditingController();
    final appIdController = useTextEditingController();
    final messagingSenderIdController = useTextEditingController();
    final projectIdController = useTextEditingController();
    final storageBucketController = useTextEditingController();
    final dataConnectServiceIdController = useTextEditingController();
    final isSaving = useState(false);
    final formT = t.auth.firebaseForm;
    final colorScheme = Theme.of(context).colorScheme;
    final configReloadKey = useState(0);

    // Check if config is already saved
    final configFuture = useMemoized(
      () => loadSelfHostedConfig(),
      [configReloadKey.value],
    );
    final configSnapshot = useFuture(configFuture);
    final configsFuture = useMemoized(
      () => loadSelfHostedConfigs(),
      [configReloadKey.value],
    );
    final configsSnapshot = useFuture(configsFuture);

    void applyConfig(SelfHostedConfig config) {
      apiKeyController.text = config.apiKey;
      appIdController.text = config.appId;
      messagingSenderIdController.text = config.messagingSenderId;
      projectIdController.text = config.projectId;
      storageBucketController.text = config.storageBucket;
      dataConnectServiceIdController.text = dataConnectServiceIdForConfig(
        config,
      );
    }

    Future<void> pickConfigFile() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'plist'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      final content = utf8.decode(bytes);
      final fileName = file.name.toLowerCase();

      SelfHostedConfig? config;

      if (fileName.endsWith('.plist')) {
        config = parsePlist(content);
      } else if (fileName.endsWith('.json')) {
        config = _parseJson(content);
      }

      if (config != null) {
        applyConfig(config);
        if (context.mounted) {
          context.showSnackBarMessage(formT.fileLoaded);
        }
      } else {
        if (context.mounted) {
          context.showSnackBarMessage(formT.invalidFile);
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

            // Show indicator if config is already saved
            if (configSnapshot.data != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formT.configActive,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: ListView(
                children: [
                  if (configsSnapshot.data?.isNotEmpty == true) ...[
                    Text(
                      formT.savedProjects,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final config in configsSnapshot.data!)
                      Container(
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
                                    config.projectId,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (configSnapshot.data?.projectId ==
                                    config.projectId)
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
                              config.appId,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await activateSelfHostedConfig(
                                      config.projectId,
                                    );
                                    ref.invalidate(selfHostedConfigProvider);
                                    configReloadKey.value++;
                                    if (context.mounted) {
                                      context.showSnackBarMessage(
                                        formT.configSaved,
                                      );
                                    }
                                  },
                                  child: Text(formT.useProject),
                                ),
                                TextButton(
                                  onPressed: () {
                                    applyConfig(config);
                                  },
                                  child: Text(formT.editProject),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: t.common.delete,
                                  onPressed: () async {
                                    await deleteSelfHostedConfig(
                                      config.projectId,
                                    );
                                    ref.invalidate(selfHostedConfigProvider);
                                    configReloadKey.value++;
                                  },
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                  // ── Import from file button ──
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: pickConfigFile,
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
                    controller: apiKeyController,
                    decoration: InputDecoration(labelText: formT.apiKey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: appIdController,
                    decoration: InputDecoration(labelText: formT.appId),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: messagingSenderIdController,
                    decoration: InputDecoration(
                      labelText: formT.messagingSenderId,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: projectIdController,
                    decoration: InputDecoration(labelText: formT.projectId),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: storageBucketController,
                    decoration: InputDecoration(
                      labelText: formT.storageBucket,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dataConnectServiceIdController,
                    decoration: InputDecoration(
                      labelText: formT.dataConnectServiceId,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving.value
                    ? null
                    : () async {
                        if (apiKeyController.text.isEmpty ||
                            appIdController.text.isEmpty ||
                            projectIdController.text.isEmpty) {
                          context.showSnackBarMessage(
                            t.common.error(
                              error: 'API Key, App ID, Project ID are required',
                            ),
                          );
                          return;
                        }
                        isSaving.value = true;
                        try {
                          final config = SelfHostedConfig(
                            apiKey: apiKeyController.text,
                            appId: appIdController.text,
                            messagingSenderId: messagingSenderIdController.text,
                            projectId: projectIdController.text,
                            storageBucket: storageBucketController.text,
                            dataConnectServiceId:
                                dataConnectServiceIdController.text,
                          );
                          await saveSelfHostedConfig(config);
                          ref.invalidate(selfHostedConfigProvider);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          context.showSnackBarMessage(formT.configSaved);
                        } catch (e) {
                          if (!context.mounted) return;
                          context.showSnackBarMessage(
                            t.common.error(error: e.toString()),
                          );
                        } finally {
                          isSaving.value = false;
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
