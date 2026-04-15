// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner13.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Owner13 _$Owner13FromJson(Map<String, dynamic> json) => _Owner13(
  avatarUrl: json['avatar_url'] as String?,
  eventsUrl: json['events_url'] as String?,
  followersUrl: json['followers_url'] as String?,
  followingUrl: json['following_url'] as String?,
  gistsUrl: json['gists_url'] as String?,
  gravatarId: json['gravatar_id'] as String?,
  htmlUrl: json['html_url'] as String?,
  id: (json['id'] as num?)?.toInt(),
  login: json['login'] as String?,
  nodeId: json['node_id'] as String?,
  organizationsUrl: json['organizations_url'] as String?,
  receivedEventsUrl: json['received_events_url'] as String?,
  reposUrl: json['repos_url'] as String?,
  siteAdmin: json['site_admin'] as bool?,
  starredUrl: json['starred_url'] as String?,
  subscriptionsUrl: json['subscriptions_url'] as String?,
  type: json['type'] as String?,
  url: json['url'] as String?,
);

Map<String, dynamic> _$Owner13ToJson(_Owner13 instance) => <String, dynamic>{
  'avatar_url': instance.avatarUrl,
  'events_url': instance.eventsUrl,
  'followers_url': instance.followersUrl,
  'following_url': instance.followingUrl,
  'gists_url': instance.gistsUrl,
  'gravatar_id': instance.gravatarId,
  'html_url': instance.htmlUrl,
  'id': instance.id,
  'login': instance.login,
  'node_id': instance.nodeId,
  'organizations_url': instance.organizationsUrl,
  'received_events_url': instance.receivedEventsUrl,
  'repos_url': instance.reposUrl,
  'site_admin': instance.siteAdmin,
  'starred_url': instance.starredUrl,
  'subscriptions_url': instance.subscriptionsUrl,
  'type': instance.type,
  'url': instance.url,
};
