import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore_provider.dart';
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
                        decoration: InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
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
                              text: 'I agree to the ',
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
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
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } finally {
                                    isLoading.value = false;
                                  }
                                }
                              }
                            : null,
                        child: Text('Log in'),
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
                                    await authNotifier
                                        .getFirebaseAuth()
                                        .createUserWithEmailAndPassword(
                                          email: emailController.text,
                                          password: passwordController.text,
                                        );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } finally {
                                    isLoading.value = false;
                                  }
                                }
                              }
                            : null,
                        child: Text(
                          'Create new account',
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
                          'Use your Firebase',
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
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () async {
                          for (final app in Firebase.apps) {
                            if (app.name == '[DEFAULT]') continue;
                            await app.delete();
                          }

                          ref.invalidate(authProvider);
                          ref.invalidate(firestoreProvider);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Firebase reset successfully. Please restart the app.",
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text(
                          'Reset Firebase',
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
                'Use your Firebase',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: apiKeyController,
              decoration: InputDecoration(labelText: 'API Key'),
            ),
            TextField(
              controller: appIdController,
              decoration: InputDecoration(labelText: 'App ID'),
            ),
            TextField(
              controller: messagingSenderIdController,
              decoration: InputDecoration(labelText: 'Messaging Sender ID'),
            ),
            TextField(
              controller: projectIdController,
              decoration: InputDecoration(labelText: 'Project ID'),
            ),
            TextField(
              controller: storageBucketController,
              decoration: InputDecoration(labelText: 'Storage Bucket'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } finally {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: Text('Pick Firebase config'),
            ),
          ],
        ),
      ),
    );
  }
}
