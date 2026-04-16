// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'secret_scanning2.freezed.dart';
part 'secret_scanning2.g.dart';

@Freezed()
abstract class SecretScanning2 with _$SecretScanning2 {
  const factory SecretScanning2({@JsonKey(name: 'Status') Status2? status}) =
      _SecretScanning2;

  factory SecretScanning2.fromJson(Map<String, Object?> json) =>
      _$SecretScanning2FromJson(json);
}
