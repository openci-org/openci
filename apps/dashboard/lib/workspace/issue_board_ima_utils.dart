import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'issue_board_ima_app_shell.dart';
import 'issue_board_ima_models.dart';

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

List<Object?> asList(Object? value) {
  return value is List ? value : const [];
}

String asString(Object? value, [String fallback = '']) {
  return value is String && value.isNotEmpty ? value : fallback;
}

String? emptyToNull(String value) {
  return value.isEmpty ? null : value;
}

String normalizeIssueKeyPrefix(String value) {
  final normalized = value.trim().toUpperCase().replaceAll(
    RegExp(r'[^A-Z0-9]'),
    '',
  );
  return normalized.isEmpty ? 'IMA' : normalized;
}

int asInt(Object? value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

double asDouble(Object? value, [double fallback = 0]) {
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

List<String> asStringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<String>()
      .where((label) => label.trim().isNotEmpty)
      .toList();
}

String pullRequestLinkId(String repository, int number) {
  return '${repository}_$number'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

int issueProgressWeight(Issue issue) {
  if (issue.githubStateReason == 'not_planned') {
    return 0;
  }
  return issue.statusId == closedStatusId
      ? issue.resolution?.actualWeight ?? 0
      : issue.weightEstimate?.value ?? 0;
}


DateTime? asDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

Priority priorityFromString(String value) {
  return Priority.values.firstWhere(
    (priority) => priority.name == value,
    orElse: () => Priority.medium,
  );
}

double rankBetween(double? previousRank, double? nextRank) {
  if (previousRank != null && nextRank != null) {
    return (previousRank + nextRank) / 2;
  }
  if (previousRank != null) {
    return previousRank + 1000;
  }
  if (nextRank != null) {
    return nextRank - 1000;
  }
  return DateTime.now().millisecondsSinceEpoch.toDouble();
}

String friendlyError(Object error) {
  if (error is FirebaseFunctionsException) {
    return error.message ?? error.code;
  }
  if (error is FirebaseException) {
    return error.message ?? error.code;
  }
  if (error is Error) {
    return error.toString();
  }
  return '$error';
}

bool isGitHubAppNotInstalledError(Object error) {
  if (error is! FirebaseFunctionsException) {
    return false;
  }
  final message = error.message ?? '';
  return error.code == 'failed-precondition' &&
      message.contains('GitHub App') &&
      message.contains('not installed');
}

DateTime dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

String formatDate(DateTime date) {
  return '${date.month}月${date.day}日';
}

String dailyHistoryDateLabel(DateTime date) {
  final today = dateOnly(DateTime.now());
  final targetDate = dateOnly(date);
  final daysAgo = today.difference(targetDate).inDays;

  if (daysAgo == 0) {
    return '今日';
  }
  if (daysAgo == 1) {
    return '昨日';
  }
  return formatDate(targetDate);
}

String dueDateLabel(DateTime date) {
  final status = dueDateStatus(date);

  return switch (status) {
    DueDateStatus.overdue => '期限切れ',
    DueDateStatus.today => '今日',
    DueDateStatus.soon => formatDate(date),
    DueDateStatus.later => formatDate(date),
  };
}

DueDateStatus dueDateStatus(DateTime date) {
  final today = dateOnly(DateTime.now());
  final dueDate = dateOnly(date);
  final daysUntilDue = dueDate.difference(today).inDays;

  if (daysUntilDue < 0) {
    return DueDateStatus.overdue;
  }

  if (daysUntilDue == 0) {
    return DueDateStatus.today;
  }

  if (daysUntilDue <= 3) {
    return DueDateStatus.soon;
  }

  return DueDateStatus.later;
}

enum DueDateStatus { overdue, today, soon, later }

enum Priority { high, medium, low }
