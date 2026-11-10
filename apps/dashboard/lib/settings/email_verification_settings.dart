import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EmailVerificationSettings extends ConsumerWidget {
  const EmailVerificationSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(firebaseAuthProvider);
    final auth = authState.isLoading || authState.hasError
        ? null
        : authState.asData?.value;
    if (auth == null) return const SizedBox.shrink();
    return _AccountEmail(key: ObjectKey(auth), auth: auth);
  }
}

class _AccountEmail extends HookWidget {
  const _AccountEmail({super.key, required this.auth});
  final FirebaseAuth auth;

  @override
  Widget build(BuildContext context) {
    final changes = useMemoized(auth.userChanges, [auth]);
    final user = useStream(changes, initialData: auth.currentUser).data;
    if (user == null || user.email == null || user.isAnonymous) {
      return const SizedBox.shrink();
    }
    return _VerificationActions(
      key: ValueKey((user.uid, user.email)),
      auth: auth,
      user: user,
    );
  }
}

enum _VerificationMessage { sent, unverified, rateLimited, failed }

class _VerificationActions extends HookWidget {
  const _VerificationActions({
    super.key,
    required this.auth,
    required this.user,
  });
  final FirebaseAuth auth;
  final User user;

  @override
  Widget build(BuildContext context) {
    final busy = useState(false);
    final message = useState<_VerificationMessage?>(null);
    bool isCurrent() =>
        context.mounted &&
        auth.currentUser?.uid == user.uid &&
        auth.currentUser?.email == user.email;

    Future<void> verify({required bool sendEmail}) async {
      if (busy.value || !isCurrent()) return;
      busy.value = true;
      message.value = null;
      try {
        await user.reload();
        if (!isCurrent()) return;
        final current = auth.currentUser!;
        if (current.emailVerified) return;
        if (sendEmail) {
          await current.sendEmailVerification();
          if (isCurrent()) message.value = _VerificationMessage.sent;
        } else {
          message.value = _VerificationMessage.unverified;
        }
      } on FirebaseAuthException catch (error) {
        if (isCurrent()) {
          message.value = error.code == 'too-many-requests'
              ? _VerificationMessage.rateLimited
              : _VerificationMessage.failed;
        }
      } catch (_) {
        if (isCurrent()) message.value = _VerificationMessage.failed;
      } finally {
        if (context.mounted) busy.value = false;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.settings.emailVerification,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(user.email!),
          const SizedBox(height: 8),
          if (user.emailVerified)
            Text(context.t.settings.emailVerified)
          else ...[
            Text(context.t.settings.emailVerificationRequired),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: busy.value ? null : () => verify(sendEmail: true),
                  child: Text(context.t.settings.sendVerificationEmail),
                ),
                TextButton(
                  onPressed: busy.value ? null : () => verify(sendEmail: false),
                  child: Text(context.t.settings.refreshEmailVerification),
                ),
              ],
            ),
            if (message.value case final status?)
              Text(switch (status) {
                _VerificationMessage.sent =>
                  context.t.settings.verificationEmailSent,
                _VerificationMessage.unverified =>
                  context.t.settings.emailStillUnverified,
                _VerificationMessage.rateLimited =>
                  context.t.settings.emailVerificationRateLimited,
                _VerificationMessage.failed =>
                  context.t.settings.emailVerificationFailed,
              }),
          ],
        ],
      ),
    );
  }
}
