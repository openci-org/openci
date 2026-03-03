import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/dataconnect_generated/generated.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/experimental/mutation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final authMutation = Mutation<void>();

class AuthPage extends HookConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isSignUp = useState(false);
    final isAgreed = useState(true);
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final tapGestureRecognizer = useMemoized(() => TapGestureRecognizer());
    final isPasswordVisible = useState(false);
    final t = context.t;

    final mutationState = ref.watch(authMutation);

    ref.listen(authMutation, (prev, next) {
      if (next case MutationError(:final error, :final stackTrace)) {
        debugPrint('Auth error: $error');
        debugPrint('$stackTrace');
        if (!context.mounted) return;
        final message = switch (error) {
          FirebaseAuthException(code: final code, message: final msg) =>
            switch (code) {
              'email-already-in-use' => t.auth.emailAlreadyInUse,
              'wrong-password' ||
              'invalid-credential' => t.auth.invalidCredential,
              'user-not-found' => t.auth.userNotFound,
              'weak-password' => t.auth.weakPassword,
              'too-many-requests' => t.auth.tooManyRequests,
              _ => msg ?? t.auth.authFailed,
            },
          _ => 'Error: $error',
        };
        context.showSnackBarMessage(message);
      }
    });

    void submit() {
      if (!formKey.currentState!.validate()) return;

      authMutation.run(ref, (tsx) async {
        if (isSignUp.value) {
          final credential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
                email: emailController.text.trim(),
                password: passwordController.text,
              );
          await DashboardConnector.instance
              .createUserWithDefaultTeam(
                uid: credential.user!.uid,
              )
              .execute();
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
        }
        ref.invalidate(authProvider);
      });
    }

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
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: t.auth.email,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return t.auth.pleaseEnterEmail;
                          }
                          if (!value.contains('@')) {
                            return t.auth.pleaseEnterValidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: t.auth.password,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible.value
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              isPasswordVisible.value =
                                  !isPasswordVisible.value;
                            },
                          ),
                        ),
                        obscureText: !isPasswordVisible.value,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => submit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t.auth.pleaseEnterPassword;
                          }
                          if (isSignUp.value && value.length < 6) {
                            return t.auth.passwordTooShort;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (isSignUp.value)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
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
                                  text: t.auth.agreePrefix,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: t.auth.termsOfService,
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
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(200, 20),
                        ),
                        onPressed:
                            (!mutationState.isPending &&
                                (!isSignUp.value || isAgreed.value))
                            ? submit
                            : null,
                        child: Text(
                          isSignUp.value ? t.auth.signUp : t.auth.signIn,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          isSignUp.value = !isSignUp.value;
                          formKey.currentState?.reset();
                        },
                        child: Text(
                          isSignUp.value
                              ? t.auth.switchToSignIn
                              : t.auth.switchToSignUp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (mutationState.isPending) ...[
            const ModalBarrier(dismissible: false, color: Colors.black26),
            const Center(child: CircularProgressIndicator.adaptive()),
          ],
        ],
      ),
    );
  }
}
