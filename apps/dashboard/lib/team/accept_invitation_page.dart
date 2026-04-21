import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AcceptInvitationPage extends HookConsumerWidget {
  const AcceptInvitationPage({
    super.key,
    required this.token,
  });

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = useState(true);
    final result = useState<_InviteResult?>(null);
    final error = useState<String?>(null);

    useEffect(() {
      Future<void> acceptInvitation() async {
        try {
          final response = await FirebaseFunctions.instance
              .httpsCallableFromUrl(
                dartFunctionUrl('accept-invitation'),
              )
              .call({'token': token});

          final data = response.data as Map<String, dynamic>;
          final status = data['status'] as String;
          final teamName = data['teamName'] as String? ?? '';

          result.value = _InviteResult(status: status, teamName: teamName);
        } on FirebaseFunctionsException catch (e) {
          error.value = e.message ?? e.code;
        } catch (e) {
          error.value = e.toString();
        } finally {
          isProcessing.value = false;
        }
      }

      acceptInvitation();
      return null;
    }, [token]);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _buildContent(
              context,
              isProcessing.value,
              result.value,
              error.value,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isProcessing,
    _InviteResult? result,
    String? error,
  ) {
    if (isProcessing) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: 24),
          Text(
            t.team.processingInvitation,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      );
    }

    if (error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 24),
          Text(
            t.team.invitationFailed,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: Text(t.team.goToDashboard),
          ),
        ],
      );
    }

    if (result != null) {
      final isAlreadyMember = result.status == 'already_member';
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            isAlreadyMember
                ? t.team.alreadyMemberTitle
                : t.team.invitationAccepted,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            isAlreadyMember
                ? t.team.alreadyMemberMessage(teamName: result.teamName)
                : t.team.joinedTeamMessage(teamName: result.teamName),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: Text(t.team.goToDashboard),
          ),
        ],
      );
    }

    return const SizedBox();
  }
}

class _InviteResult {
  final String status;
  final String teamName;

  _InviteResult({required this.status, required this.teamName});
}
