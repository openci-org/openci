import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/connect_github_button.dart';
import 'package:dashboard/team/github_app_installation_link.dart';
import 'package:flutter/material.dart';

class GitHubConnectionHelp extends StatelessWidget {
  const GitHubConnectionHelp({
    super.key,
    required this.installationUrl,
    this.enabled = true,
    this.onConnectingChanged,
  });

  final String? installationUrl;
  final bool enabled;
  final ValueChanged<bool>? onConnectingChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.t.team.gitHubConnectionMissingAccount),
      const SizedBox(height: 8),
      GitHubAppInstallationLink(
        installationUrl: installationUrl,
        enabled: enabled,
      ),
      const SizedBox(height: 8),
      ConnectGitHubButton(
        enabled: enabled,
        onConnectingChanged: onConnectingChanged,
      ),
    ],
  );
}
