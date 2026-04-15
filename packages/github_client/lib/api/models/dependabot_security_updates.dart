// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'status2.dart';

part 'dependabot_security_updates.freezed.dart';
part 'dependabot_security_updates.g.dart';

@Freezed()
abstract class DependabotSecurityUpdates with _$DependabotSecurityUpdates {
  const factory DependabotSecurityUpdates({
    /// The enablement Status of Dependabot security updates for the repository.
    @JsonKey(name: 'Status')
    Status2? status,
  }) = _DependabotSecurityUpdates;
  
  factory DependabotSecurityUpdates.fromJson(Map<String, Object?> json) => _$DependabotSecurityUpdatesFromJson(json);
}
