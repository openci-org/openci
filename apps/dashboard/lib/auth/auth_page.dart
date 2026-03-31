import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final authNotifier = ref.watch(authProvider.notifier);
    final firestore = ref.watch(firestoreProvider);
    final authT = t.auth;

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
                        Text(
                          'OpenCI',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        SizedBox(height: 16),
                        Text('Firebase: ${firestore.app.name}'),
                        SizedBox(height: 40),
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(labelText: authT.email),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return authT.enterEmail;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: authT.password,
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return authT.enterPassword;
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 40),
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
                            Text.rich(
                              TextSpan(
                                text: authT.agreePrefix,
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: [
                                  TextSpan(
                                    text: authT.termsOfService,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      decoration: TextDecoration.underline,
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
                          ],
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(200, 20),
                          ),
                          onPressed: (isAgreed.value && !isLoading.value)
                              ? () async {
                                  if (formKey.currentState!.validate()) {
                                    isLoading.value = true;
                                    try {
                                      await authNotifier
                                          .getFirebaseAuth()
                                          .signInWithEmailAndPassword(
                                            email: emailController.text,
                                            password: passwordController.text,
                                          );
                                      ref.invalidate(authProvider);
                                      ref.invalidate(firestoreProvider);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      debugPrint(e.toString());
                                      context.showSnackBarMessage(
                                        t.common.error(error: e.toString()),
                                      );
                                    } finally {
                                      isLoading.value = false;
                                    }
                                  }
                                }
                              : null,
                          child: Text(authT.login),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(200, 20),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          onPressed: (isAgreed.value && !isLoading.value)
                              ? () async {
                                  if (formKey.currentState!.validate()) {
                                    isLoading.value = true;
                                    try {
                                      final credential = await authNotifier
                                          .getFirebaseAuth()
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
                                      ref.invalidate(firestoreProvider);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      debugPrint(e.toString());
                                      context.showSnackBarMessage(
                                        t.common.error(error: e.toString()),
                                      );
                                    } finally {
                                      if (context.mounted) {
                                        isLoading.value = false;
                                      }
                                    }
                                  }
                                }
                              : null,
                          child: Text(
                            authT.createAccount,
                            style: TextStyle(
                              color: Theme.of(context).secondaryHeaderColor,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(200, 20),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.tertiary,
                          ),
                          onPressed: () async {
                            await showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              builder: (context) {
                                return FirebaseFormSheet();
                              },
                            );
                          },
                          child: Text(
                            authT.useYourFirebase,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 8,
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            fixedSize: Size(200, 20),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: () async {
                            for (final app in Firebase.apps) {
                              if (app.name == '[DEFAULT]') continue;
                              await app.delete();
                            }

                            ref.invalidate(authProvider);
                            ref.invalidate(firestoreProvider);
                            if (!context.mounted) return;
                            context.showSnackBarMessage(authT.resetSuccess);
                          },
                          child: Text(
                            authT.resetFirebase,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
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
    final nameController = useTextEditingController();
    final apiKeyController = useTextEditingController();
    final appIdController = useTextEditingController();
    final messagingSenderIdController = useTextEditingController();
    final projectIdController = useTextEditingController();
    final storageBucketController = useTextEditingController();
    final formT = t.auth.firebaseForm;

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height * 0.8,
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
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: formT.name),
            ),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(labelText: formT.apiKey),
            ),
            TextField(
              controller: appIdController,
              decoration: InputDecoration(labelText: formT.appId),
            ),
            TextField(
              controller: messagingSenderIdController,
              decoration: InputDecoration(
                labelText: formT.messagingSenderId,
              ),
            ),
            TextField(
              controller: projectIdController,
              decoration: InputDecoration(labelText: formT.projectId),
            ),
            TextField(
              controller: storageBucketController,
              decoration: InputDecoration(
                labelText: formT.storageBucket,
              ),
            ),
            SizedBox(
              height: 16,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (Firebase.apps.any(
                    (app) => app.name == nameController.text,
                  )) {
                    await Firebase.app(nameController.text).delete();
                  }

                  await Firebase.initializeApp(
                    name: nameController.text,
                    options: FirebaseOptions(
                      apiKey: apiKeyController.text,
                      appId: appIdController.text,
                      messagingSenderId: messagingSenderIdController.text,
                      projectId: projectIdController.text,
                      storageBucket: storageBucketController.text,
                    ),
                  );
                  ref.invalidate(authProvider);
                  ref.invalidate(firestoreProvider);
                } catch (e) {
                  if (!context.mounted) return;
                  debugPrint(e.toString());
                  context.showSnackBarMessage(
                    t.common.error(error: e.toString()),
                  );
                } finally {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text(formT.pickConfig),
            ),
          ],
        ),
      ),
    );
  }
}
