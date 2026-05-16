import 'dart:async';

import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const reviewStatusId = 'review';
const closedStatusId = 'done';
const boardHorizontalPadding = 16.0;
const boardBottomPadding = 18.0;
const boardColumnWidth = 280.0;
const boardColumnGap = 12.0;
const compactBoardBreakpoint = 640.0;
const compactColumnCollapsedLimit = 0;
const mobileDragStartDelay = Duration(milliseconds: 420);
const defaultDailyWeightTarget = 20;
const validIssueWeights = [0, 1, 2, 4, 8, 16, 32];
const openCiRepositoryUrl = 'https://github.com/openci-org/openci';

enum BoardViewMode { standard, overview }

enum BoardSidePanel { runs, workers, workflows, variables, storeRelease }

enum CompactBoardDestination {
  issueBoard,
  runs,
  workers,
  workflows,
  variables,
  storeRelease,
}

const boardNavigationDestinations = [
  CompactBoardDestination.issueBoard,
  CompactBoardDestination.runs,
  CompactBoardDestination.workers,
  CompactBoardDestination.workflows,
  CompactBoardDestination.variables,
  CompactBoardDestination.storeRelease,
];

extension CompactBoardDestinationLabel on CompactBoardDestination {
  String get label => switch (this) {
    CompactBoardDestination.issueBoard => 'ワークスペース',
    CompactBoardDestination.runs => 'CI/CDログ',
    CompactBoardDestination.workers => 'ワーカー',
    CompactBoardDestination.workflows => 'CI/CD設定',
    CompactBoardDestination.variables => '変数',
    CompactBoardDestination.storeRelease => 'ストアリリース',
  };

  IconData get icon => switch (this) {
    CompactBoardDestination.issueBoard => Icons.view_kanban_outlined,
    CompactBoardDestination.runs => Icons.history_rounded,
    CompactBoardDestination.workers => Icons.dns_outlined,
    CompactBoardDestination.workflows => Icons.schema_rounded,
    CompactBoardDestination.variables => Icons.key_rounded,
    CompactBoardDestination.storeRelease => Icons.rocket_launch_outlined,
  };

  IconData get selectedIcon => switch (this) {
    CompactBoardDestination.issueBoard => Icons.view_kanban_rounded,
    CompactBoardDestination.runs => Icons.history_rounded,
    CompactBoardDestination.workers => Icons.dns_rounded,
    CompactBoardDestination.workflows => Icons.schema_rounded,
    CompactBoardDestination.variables => Icons.key_rounded,
    CompactBoardDestination.storeRelease => Icons.rocket_launch_rounded,
  };
}

String? normalizedOptionalUrl(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? validateOptionalHttpUrl(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  final isHttpUrl =
      uri != null &&
      uri.hasScheme &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'https' || uri.scheme == 'http');
  return isHttpUrl ? null : 'URL形式で入力してください';
}

void showFloatingSnackBar(BuildContext context, String message) {
  showResponsiveSnackBar(
    context,
    content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
    duration: const Duration(milliseconds: 1400),
  );
}

void showOverlaySnackBar(BuildContext context, String message) {
  showResponsiveSnackBar(
    context,
    content: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
    duration: const Duration(milliseconds: 1400),
  );
}

Future<void> copyTextToClipboard(
  BuildContext context, {
  required String text,
  required String successMessage,
}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return;
  }

  await Clipboard.setData(ClipboardData(text: trimmed));
  if (!context.mounted) {
    return;
  }

  showFloatingSnackBar(context, successMessage);
}

Future<void> launchUrlExternal(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return;
  }
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
