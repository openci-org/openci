import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectGitHubButton extends HookConsumerWidget {
  const ConnectGitHubButton({super.key, this.enabled = true});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnecting = useState(false);
    final currentTeam = ref.watch(selectedTeamProvider).value;
    final canConnect = enabled && currentTeam != null && !isConnecting.value;

    return OutlinedButton.icon(
      onPressed: canConnect ? () => _connectGitHub(ref, isConnecting) : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const FaIcon(FontAwesomeIcons.github, size: 20),
      label: Text(t.team.connectGitHub),
    );
  }

  Future<void> _connectGitHub(
    WidgetRef ref,
    ValueNotifier<bool> isConnecting,
  ) async {
    final context = ref.context;
    final teamId = ref.read(selectedTeamProvider).value?.id;
    if (teamId == null || isConnecting.value) return;

    isConnecting.value = true;
    try {
      final uri = await _requestAuthorizationUri(ref, teamId);
      if (!context.mounted || uri == null) return;
      await _openAuthorizationUri(uri);
    } catch (_) {
      if (context.mounted) {
        context.showSnackBarMessage(t.team.gitHubConnectionFailed);
      }
    } finally {
      if (context.mounted) isConnecting.value = false;
    }
  }

  Future<Uri?> _requestAuthorizationUri(WidgetRef ref, String teamId) async {
    final context = ref.context;
    final api = await ref.read(openciApiServiceProvider.future);
    if (!context.mounted) return null;

    final response = await api.startGitHubConnection(teamId);
    if (!response.isSuccessful || response.body?['success'] != true) {
      throw StateError('Invalid GitHub connection response');
    }
    return _parseAuthorizationUri(response.body?['authorizationUrl']);
  }

  Uri _parseAuthorizationUri(Object? authorizationUrl) {
    final uri = authorizationUrl is String
        ? Uri.tryParse(authorizationUrl)
        : null;
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw StateError('Invalid GitHub authorization URL');
    }
    return uri;
  }

  Future<void> _openAuthorizationUri(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      // Use the current tab after awaiting the API to avoid popup blocking.
      webOnlyWindowName: '_self',
    );
    if (!launched) {
      throw StateError('Could not open GitHub authorization');
    }
  }
}
