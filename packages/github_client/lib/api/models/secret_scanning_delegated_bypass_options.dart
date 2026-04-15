// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'reviewers.dart';

part 'secret_scanning_delegated_bypass_options.freezed.dart';
part 'secret_scanning_delegated_bypass_options.g.dart';

@Freezed()
abstract class SecretScanningDelegatedBypassOptions with _$SecretScanningDelegatedBypassOptions {
  const factory SecretScanningDelegatedBypassOptions({
    /// The bypass reviewers for secret scanning delegated bypass.
    /// If you omit this field, the existing set of reviewers is unchanged.
    List<Reviewers>? reviewers,
  }) = _SecretScanningDelegatedBypassOptions;
  
  factory SecretScanningDelegatedBypassOptions.fromJson(Map<String, Object?> json) => _$SecretScanningDelegatedBypassOptionsFromJson(json);
}
