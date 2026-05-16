import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'issue_board_ima_models.dart';
import 'issue_board_ima_overview.dart';

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
  return issue.resolution?.actualWeight ?? issue.weightEstimate?.value ?? 0;
}

DailyProgressPrediction buildDailyProgressPrediction({
  required int targetWeight,
  required DailyPaceBucket todayBucket,
  required List<DailyPaceBucket> historicalBuckets,
  required DateTime now,
}) {
  if (targetWeight <= 0) {
    return const DailyProgressPrediction(
      finishProbability: 0,
      paceLabel: '未設定',
      advice: '目標を設定してください',
      color: Color(0xFF64748B),
      requiredAfternoonWeight: 0,
      historicalAfternoonMedian: 0,
      sampleCount: 0,
      usesFallback: true,
    );
  }

  final remainingWeight = positive(targetWeight - todayBucket.totalWeight);
  final requiredAfternoonWeight = now.hour < 12
      ? positive(targetWeight - todayBucket.morningWeight)
      : remainingWeight;
  final historicalAfternoonMedian = median(
    historicalBuckets.map((bucket) => bucket.afternoonWeight).toList(),
  );

  if (todayBucket.totalWeight >= targetWeight) {
    final overWeight = todayBucket.totalWeight - targetWeight;
    return DailyProgressPrediction(
      finishProbability: 100,
      paceLabel: '達成',
      advice: overWeight > 0 ? '達成 · +W$overWeight' : '達成',
      color: const Color(0xFF15803D),
      requiredAfternoonWeight: 0,
      historicalAfternoonMedian: historicalAfternoonMedian,
      sampleCount: historicalBuckets.length,
      usesFallback: false,
    );
  }

  final comparableBuckets = historicalBuckets
      .where(
        (bucket) =>
            bucket.totalWeight > 0 &&
            bucket.weightAtCurrentTime <= todayBucket.weightAtCurrentTime,
      )
      .toList();
  final futureWeights = historicalBuckets
      .where((bucket) => bucket.totalWeight > 0)
      .map(
        (bucket) => positive(bucket.totalWeight - bucket.weightAtCurrentTime),
      )
      .toList();

  final int finishProbability;
  final int sampleCount;
  final bool usesFallback;
  if (comparableBuckets.length >= 3) {
    final achievedDays = comparableBuckets
        .where((bucket) => bucket.totalWeight >= targetWeight)
        .length;
    finishProbability = (achievedDays / comparableBuckets.length * 100).round();
    sampleCount = comparableBuckets.length;
    usesFallback = false;
  } else {
    final projectedWeight = todayBucket.totalWeight + median(futureWeights);
    finishProbability = (projectedWeight / targetWeight * 100)
        .round()
        .clamp(0, 95)
        .toInt();
    sampleCount = futureWeights.length;
    usesFallback = true;
  }

  final isMorning = now.hour < 12;
  if (finishProbability >= 75) {
    return DailyProgressPrediction(
      finishProbability: finishProbability,
      paceLabel: '順調',
      advice: '順調 · このペースなら達成見込み',
      color: const Color(0xFF15803D),
      requiredAfternoonWeight: requiredAfternoonWeight,
      historicalAfternoonMedian: historicalAfternoonMedian,
      sampleCount: sampleCount,
      usesFallback: usesFallback,
    );
  }

  if (finishProbability >= 45) {
    final advice = isMorning
        ? '午前遅め · 午後にW$requiredAfternoonWeight必要'
        : 'ペース遅め · 残りW$remainingWeight';
    return DailyProgressPrediction(
      finishProbability: finishProbability,
      paceLabel: '遅め',
      advice: advice,
      color: const Color(0xFFA16207),
      requiredAfternoonWeight: requiredAfternoonWeight,
      historicalAfternoonMedian: historicalAfternoonMedian,
      sampleCount: sampleCount,
      usesFallback: usesFallback,
    );
  }

  final advice = isMorning
      ? '達成厳しめ · 午後にW$requiredAfternoonWeight必要'
      : '達成厳しめ · いつもより速いペースが必要';
  return DailyProgressPrediction(
    finishProbability: finishProbability,
    paceLabel: '厳しめ',
    advice: advice,
    color: const Color(0xFFDC2626),
    requiredAfternoonWeight: requiredAfternoonWeight,
    historicalAfternoonMedian: historicalAfternoonMedian,
    sampleCount: sampleCount,
    usesFallback: usesFallback,
  );
}

int positive(num value) {
  return value > 0 ? value.round() : 0;
}

double median(List<int> values) {
  if (values.isEmpty) {
    return 0;
  }
  values.sort();
  final middle = values.length ~/ 2;
  if (values.length.isOdd) {
    return values[middle].toDouble();
  }
  return (values[middle - 1] + values[middle]) / 2;
}

bool isAtOrBeforeTimeOfDay(DateTime value, DateTime cutoff) {
  if (value.hour != cutoff.hour) {
    return value.hour < cutoff.hour;
  }
  if (value.minute != cutoff.minute) {
    return value.minute <= cutoff.minute;
  }
  return value.second <= cutoff.second;
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
