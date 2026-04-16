// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'commit.freezed.dart';
part 'commit.g.dart';

@Freezed()
abstract class Commit with _$Commit {
  const factory Commit({required String sha, required String url}) = _Commit;

  factory Commit.fromJson(Map<String, Object?> json) => _$CommitFromJson(json);
}
