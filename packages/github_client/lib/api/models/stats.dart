// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats.freezed.dart';
part 'stats.g.dart';

@Freezed()
abstract class Stats with _$Stats {
  const factory Stats({
    int? additions,
    int? deletions,
    int? total,
  }) = _Stats;
  
  factory Stats.fromJson(Map<String, Object?> json) => _$StatsFromJson(json);
}
