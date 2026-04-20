import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

void _processInvitations() {
  FirebaseFunctions.instance
      .httpsCallableFromUrl(
        dartFunctionUrl('process-invitations-on-sign-up'),
      )
      .call<void>()
      .then((_) {})
      .catchError((Object e) {
        debugPrint('processInvitationsOnSignUp failed: $e');
      });
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

    final firestore = FirebaseFirestore.instance;
    final authT = t.auth;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── Branded header ──
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'CI',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onPrimary,
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
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to your account',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 36),

                        // ── Form fields ──
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: authT.email,
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
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
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: authT.password,
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          obscureText: true,
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 8.0,
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
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: authT.agreePrefix,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                  children: [
                                    TextSpan(
                                      text: authT.termsOfService,
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: colorScheme.primary
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
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: (isAgreed.value && !isLoading.value)
                                ? () async {
                                    if (formKey.currentState!.validate()) {
                                      isLoading.value = true;
                                      try {
                                        await FirebaseAuth.instance
                                            .signInWithEmailAndPassword(
                                              email: emailController.text,
                                              password: passwordController.text,
                                            );
                                        ref.invalidate(authProvider);
                                        // Process pending invitations (fire-and-forget)
                                        _processInvitations();
                                      } catch (e) {
                                        if (!context.mounted) return;
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
                        ),
                        const SizedBox(height: 10),

                        // ── Secondary action: Create Account ──
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: (isAgreed.value && !isLoading.value)
                                ? () async {
                                    if (formKey.currentState!.validate()) {
                                      isLoading.value = true;
                                      try {
                                        final credential = await FirebaseAuth
                                            .instance
                                            .createUserWithEmailAndPassword(
                                              email: emailController.text,
                                              password: passwordController.text,
                                            );
                                        final userId = credential.user!.uid;
                                        final db = firestore;
                                        final teamsRef = db
                                            .collection(teamsCollection)
                                            .doc();
                                        final teamId = teamsRef.id;
                                        final batch = db.batch();
                                        batch.set(teamsRef, {
                                          'id': teamId,
                                          'name': teamId,
                                          'members': [userId],
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                        final userRef = db
                                            .collection(usersCollection)
                                            .doc(userId);
                                        batch.set(userRef, {
                                          'id': userId,
                                          'selectedTeamId': teamId,
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                        await batch.commit();
                                        ref.invalidate(authProvider);
                                        // Process pending invitations (fire-and-forget)
                                        _processInvitations();
                                      } catch (e) {
                                        if (!context.mounted) return;
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
                        ),

                        const SizedBox(height: 32),

                        // ── Tertiary actions ──
                        Divider(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Advanced',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () async {
                              await showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                builder: (context) {
                                  return FirebaseFormSheet();
                                },
                              );
                            },
                            child: Text(authT.useYourFirebase),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                            ),
                            onPressed: () async {
                              await clearSelfHostedConfig();
                              if (!context.mounted) return;
                              context.showSnackBarMessage(authT.resetSuccess);
                            },
                            child: Text(authT.resetFirebase),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading.value) ...[
            const ModalBarrier(dismissible: false, color: Colors.black26),
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
    final apiKeyController = useTextEditingController();
    final appIdController = useTextEditingController();
    final messagingSenderIdController = useTextEditingController();
    final projectIdController = useTextEditingController();
    final storageBucketController = useTextEditingController();
    final cloudRunHashController = useTextEditingController();
    final cloudRunRegionCodeController = useTextEditingController(text: 'an');
    final isSaving = useState(false);
    final formT = t.auth.firebaseForm;
    final colorScheme = Theme.of(context).colorScheme;

    // Check if config is already saved
    final configFuture = useMemoized(() => loadSelfHostedConfig());
    final configSnapshot = useFuture(configFuture);

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
                    controller: cloudRunHashController,
                    decoration: InputDecoration(
                      labelText: formT.cloudRunHash,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cloudRunRegionCodeController,
                    decoration: InputDecoration(
                      labelText: formT.cloudRunRegionCode,
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
                            cloudRunHash: cloudRunHashController.text,
                            cloudRunRegionCode:
                                cloudRunRegionCodeController.text.isNotEmpty
                                ? cloudRunRegionCodeController.text
                                : 'an',
                          );
                          await saveSelfHostedConfig(config);
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
