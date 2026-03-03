import 'package:dashboard/auth/auth_provider.dart';
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

    final mutationState = ref.watch(authMutation);

    ref.listen(authMutation, (prev, next) {
      if (next case MutationError(:final error, :final stackTrace)) {
        debugPrint('Auth error: $error');
        debugPrint('$stackTrace');
        if (!context.mounted) return;
        final message = switch (error) {
          FirebaseAuthException(code: final code, message: final msg) =>
            switch (code) {
              'email-already-in-use' => 'This email is already registered.',
              'wrong-password' ||
              'invalid-credential' => 'Invalid email or password.',
              'user-not-found' => 'No account found with this email.',
              'weak-password' =>
                'Password is too weak. Use at least 6 characters.',
              'too-many-requests' =>
                'Too many attempts. Please try again later.',
              _ => msg ?? 'Authentication failed.',
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
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
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
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
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
                            return 'Please enter your password';
                          }
                          if (isSignUp.value && value.length < 6) {
                            return 'Password must be at least 6 characters';
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
                          isSignUp.value ? 'Sign up' : 'Sign in',
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
                              ? 'Already have an account? Sign in'
                              : "Don't have an account? Sign up",
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
