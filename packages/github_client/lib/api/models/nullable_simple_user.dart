// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nullable_simple_user.freezed.dart';
part 'nullable_simple_user.g.dart';

/// A GitHub user.
@Freezed()
abstract class NullableSimpleUser with _$NullableSimpleUser {
  const factory NullableSimpleUser({
    required String login,
    required int id,
    @JsonKey(name: 'node_id')
    required String nodeId,
    @JsonKey(name: 'avatar_url')
    required String avatarUrl,
    @JsonKey(name: 'gravatar_id')
    required String? gravatarId,
    required String url,
    @JsonKey(name: 'html_url')
    required String htmlUrl,
    @JsonKey(name: 'followers_url')
    required String followersUrl,
    @JsonKey(name: 'following_url')
    required String followingUrl,
    @JsonKey(name: 'gists_url')
    required String gistsUrl,
    @JsonKey(name: 'starred_url')
    required String starredUrl,
    @JsonKey(name: 'subscriptions_url')
    required String subscriptionsUrl,
    @JsonKey(name: 'organizations_url')
    required String organizationsUrl,
    @JsonKey(name: 'repos_url')
    required String reposUrl,
    @JsonKey(name: 'events_url')
    required String eventsUrl,
    @JsonKey(name: 'received_events_url')
    required String receivedEventsUrl,
    required String type,
    @JsonKey(name: 'site_admin')
    required bool siteAdmin,
    String? name,
    @JsonKey(name: 'Email')
    String? email,
    @JsonKey(name: 'starred_at')
    String? starredAt,
    @JsonKey(name: 'user_view_type')
    String? userViewType,
  }) = _NullableSimpleUser;
  
  factory NullableSimpleUser.fromJson(Map<String, Object?> json) => _$NullableSimpleUserFromJson(json);
}
