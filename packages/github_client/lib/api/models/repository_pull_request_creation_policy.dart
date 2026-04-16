// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The policy controlling who can create pull requests: all or collaborators_only.
@JsonEnum()
enum RepositoryPullRequestCreationPolicy {
  @JsonValue('all')
  all('all'),
  @JsonValue('collaborators_only')
  collaboratorsOnly('collaborators_only'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const RepositoryPullRequestCreationPolicy(this.json);

  factory RepositoryPullRequestCreationPolicy.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<RepositoryPullRequestCreationPolicy> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
