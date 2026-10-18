import 'package:dashboard/app_strings.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubAppInstallationLink extends StatelessWidget {
  const GitHubAppInstallationLink({super.key, required this.installationUrl});

  final String? installationUrl;

  @override
  Widget build(BuildContext context) {
    final uri = _parseInstallationUri();
    if (uri == null) {
      return Text(
        t.team.gitHubAppInstallationUrlUnavailable,
        textAlign: TextAlign.center,
      );
    }
    return TextButton.icon(
      onPressed: () => _openInstallationUri(context, uri),
      icon: const Icon(Icons.open_in_new),
      label: Text(t.team.gitHubAppInstallation),
    );
  }

  Uri? _parseInstallationUri() {
    final uri = Uri.tryParse(installationUrl?.trim() ?? '');
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  Future<void> _openInstallationUri(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        // Keep this page open so the user can retry after checking the App.
        webOnlyWindowName: '_blank',
      );
      if (!launched) throw StateError('Could not open GitHub App installation');
    } catch (_) {
      if (context.mounted) {
        context.showSnackBarMessage(t.team.gitHubAppInstallationOpenFailed);
      }
    }
  }
}
