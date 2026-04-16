// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'code_security2.freezed.dart';
part 'code_security2.g.dart';

@Freezed()
abstract class CodeSecurity2 with _$CodeSecurity2 {
  const factory CodeSecurity2({@JsonKey(name: 'Status') Status2? status}) =
      _CodeSecurity2;

  factory CodeSecurity2.fromJson(Map<String, Object?> json) =>
      _$CodeSecurity2FromJson(json);
}
