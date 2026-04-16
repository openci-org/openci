// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'owner13.freezed.dart';
part 'owner13.g.dart';

@Freezed()
abstract class Owner13 with _$Owner13 {
  const factory Owner13({
    @JsonKey(name: 'avatar_url')
    String? avatarUrl,
    @JsonKey(name: 'events_url')
    String? eventsUrl,
    @JsonKey(name: 'followers_url')
    String? followersUrl,
    @JsonKey(name: 'following_url')
    String? followingUrl,
    @JsonKey(name: 'gists_url')
    String? gistsUrl,
    @JsonKey(name: 'gravatar_id')
    String? gravatarId,
    @JsonKey(name: 'html_url')
    String? htmlUrl,
    int? id,
    String? login,
    @JsonKey(name: 'node_id')
    String? nodeId,
    @JsonKey(name: 'organizations_url')
    String? organizationsUrl,
    @JsonKey(name: 'received_events_url')
    String? receivedEventsUrl,
    @JsonKey(name: 'repos_url')
    String? reposUrl,
    @JsonKey(name: 'site_admin')
    bool? siteAdmin,
    @JsonKey(name: 'starred_url')
    String? starredUrl,
    @JsonKey(name: 'subscriptions_url')
    String? subscriptionsUrl,
    String? type,
    String? url,
  }) = _Owner13;
  
  factory Owner13.fromJson(Map<String, Object?> json) => _$Owner13FromJson(json);
}
