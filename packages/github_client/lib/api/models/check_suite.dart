// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_suite.freezed.dart';
part 'check_suite.g.dart';

@Freezed()
abstract class CheckSuite with _$CheckSuite {
  const factory CheckSuite({
    required int id,
  }) = _CheckSuite;
  
  factory CheckSuite.fromJson(Map<String, Object?> json) => _$CheckSuiteFromJson(json);
}
