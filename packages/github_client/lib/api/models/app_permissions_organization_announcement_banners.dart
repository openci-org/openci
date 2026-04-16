// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

/// The level of permission to grant the access token to view and manage announcement banners for an organization.
@JsonEnum()
enum AppPermissionsOrganizationAnnouncementBanners {
  @JsonValue('read')
  read('read'),
  @JsonValue('write')
  write('write'),
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const AppPermissionsOrganizationAnnouncementBanners(this.json);

  factory AppPermissionsOrganizationAnnouncementBanners.fromJson(String json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => $unknown,
      );

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();
  /// Returns all defined enum values excluding the $unknown value.
  static List<AppPermissionsOrganizationAnnouncementBanners> get $valuesDefined => values.where((value) => value != $unknown).toList();
}
