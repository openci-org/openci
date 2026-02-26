import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailVerificationPage extends HookConsumerWidget {
  final String email;

  const EmailVerificationPage({super.key, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeController = useTextEditingController();
    final isResending = useState(false);

    Future<void> verifyOtp() async {
      final code = codeController.text.trim();
      if (code.isEmpty) return;

      try {
        await Supabase.instance.client.auth.verifyOTP(
          email: email,
          token: code,
          type: OtpType.email,
        );
        ref.invalidate(authProvider);
        if (!context.mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      } on AuthException catch (e) {
        if (!context.mounted) return;
        context.showSnackBarMessage(e.message);
      } catch (e) {
        if (!context.mounted) return;
        context.showSnackBarMessage('Verification failed: $e');
      }
    }

    Future<void> resendCode() async {
      isResending.value = true;
      try {
        await Supabase.instance.client.auth.signInWithOtp(email: email);
        if (!context.mounted) return;
        context.showSnackBarMessage('Verification code sent!');
      } catch (e) {
        if (!context.mounted) return;
        context.showSnackBarMessage('Failed to resend: $e');
      } finally {
        isResending.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 32),
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  'We sent a verification code to',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '00000000',
                    counterText: '',
                  ),
                  onChanged: (value) async {
                    if (value.length == 8) {
                      await verifyOtp();
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: verifyOtp,
                    child: const Text('Verify'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: isResending.value ? null : resendCode,
                  icon: isResending.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Resend code'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
