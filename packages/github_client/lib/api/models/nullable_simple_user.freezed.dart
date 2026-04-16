// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nullable_simple_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NullableSimpleUser {

 String get login; int get id;@JsonKey(name: 'node_id') String get nodeId;@JsonKey(name: 'avatar_url') String get avatarUrl;@JsonKey(name: 'gravatar_id') String? get gravatarId; String get url;@JsonKey(name: 'html_url') String get htmlUrl;@JsonKey(name: 'followers_url') String get followersUrl;@JsonKey(name: 'following_url') String get followingUrl;@JsonKey(name: 'gists_url') String get gistsUrl;@JsonKey(name: 'starred_url') String get starredUrl;@JsonKey(name: 'subscriptions_url') String get subscriptionsUrl;@JsonKey(name: 'organizations_url') String get organizationsUrl;@JsonKey(name: 'repos_url') String get reposUrl;@JsonKey(name: 'events_url') String get eventsUrl;@JsonKey(name: 'received_events_url') String get receivedEventsUrl; String get type;@JsonKey(name: 'site_admin') bool get siteAdmin; String? get name;@JsonKey(name: 'Email') String? get email;@JsonKey(name: 'starred_at') String? get starredAt;@JsonKey(name: 'user_view_type') String? get userViewType;
/// Create a copy of NullableSimpleUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NullableSimpleUserCopyWith<NullableSimpleUser> get copyWith => _$NullableSimpleUserCopyWithImpl<NullableSimpleUser>(this as NullableSimpleUser, _$identity);

  /// Serializes this NullableSimpleUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NullableSimpleUser&&(identical(other.login, login) || other.login == login)&&(identical(other.id, id) || other.id == id)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.gravatarId, gravatarId) || other.gravatarId == gravatarId)&&(identical(other.url, url) || other.url == url)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.followersUrl, followersUrl) || other.followersUrl == followersUrl)&&(identical(other.followingUrl, followingUrl) || other.followingUrl == followingUrl)&&(identical(other.gistsUrl, gistsUrl) || other.gistsUrl == gistsUrl)&&(identical(other.starredUrl, starredUrl) || other.starredUrl == starredUrl)&&(identical(other.subscriptionsUrl, subscriptionsUrl) || other.subscriptionsUrl == subscriptionsUrl)&&(identical(other.organizationsUrl, organizationsUrl) || other.organizationsUrl == organizationsUrl)&&(identical(other.reposUrl, reposUrl) || other.reposUrl == reposUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.receivedEventsUrl, receivedEventsUrl) || other.receivedEventsUrl == receivedEventsUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.siteAdmin, siteAdmin) || other.siteAdmin == siteAdmin)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.starredAt, starredAt) || other.starredAt == starredAt)&&(identical(other.userViewType, userViewType) || other.userViewType == userViewType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,login,id,nodeId,avatarUrl,gravatarId,url,htmlUrl,followersUrl,followingUrl,gistsUrl,starredUrl,subscriptionsUrl,organizationsUrl,reposUrl,eventsUrl,receivedEventsUrl,type,siteAdmin,name,email,starredAt,userViewType]);

@override
String toString() {
  return 'NullableSimpleUser(login: $login, id: $id, nodeId: $nodeId, avatarUrl: $avatarUrl, gravatarId: $gravatarId, url: $url, htmlUrl: $htmlUrl, followersUrl: $followersUrl, followingUrl: $followingUrl, gistsUrl: $gistsUrl, starredUrl: $starredUrl, subscriptionsUrl: $subscriptionsUrl, organizationsUrl: $organizationsUrl, reposUrl: $reposUrl, eventsUrl: $eventsUrl, receivedEventsUrl: $receivedEventsUrl, type: $type, siteAdmin: $siteAdmin, name: $name, email: $email, starredAt: $starredAt, userViewType: $userViewType)';
}


}

/// @nodoc
abstract mixin class $NullableSimpleUserCopyWith<$Res>  {
  factory $NullableSimpleUserCopyWith(NullableSimpleUser value, $Res Function(NullableSimpleUser) _then) = _$NullableSimpleUserCopyWithImpl;
@useResult
$Res call({
 String login, int id,@JsonKey(name: 'node_id') String nodeId,@JsonKey(name: 'avatar_url') String avatarUrl,@JsonKey(name: 'gravatar_id') String? gravatarId, String url,@JsonKey(name: 'html_url') String htmlUrl,@JsonKey(name: 'followers_url') String followersUrl,@JsonKey(name: 'following_url') String followingUrl,@JsonKey(name: 'gists_url') String gistsUrl,@JsonKey(name: 'starred_url') String starredUrl,@JsonKey(name: 'subscriptions_url') String subscriptionsUrl,@JsonKey(name: 'organizations_url') String organizationsUrl,@JsonKey(name: 'repos_url') String reposUrl,@JsonKey(name: 'events_url') String eventsUrl,@JsonKey(name: 'received_events_url') String receivedEventsUrl, String type,@JsonKey(name: 'site_admin') bool siteAdmin, String? name,@JsonKey(name: 'Email') String? email,@JsonKey(name: 'starred_at') String? starredAt,@JsonKey(name: 'user_view_type') String? userViewType
});




}
/// @nodoc
class _$NullableSimpleUserCopyWithImpl<$Res>
    implements $NullableSimpleUserCopyWith<$Res> {
  _$NullableSimpleUserCopyWithImpl(this._self, this._then);

  final NullableSimpleUser _self;
  final $Res Function(NullableSimpleUser) _then;

/// Create a copy of NullableSimpleUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? login = null,Object? id = null,Object? nodeId = null,Object? avatarUrl = null,Object? gravatarId = freezed,Object? url = null,Object? htmlUrl = null,Object? followersUrl = null,Object? followingUrl = null,Object? gistsUrl = null,Object? starredUrl = null,Object? subscriptionsUrl = null,Object? organizationsUrl = null,Object? reposUrl = null,Object? eventsUrl = null,Object? receivedEventsUrl = null,Object? type = null,Object? siteAdmin = null,Object? name = freezed,Object? email = freezed,Object? starredAt = freezed,Object? userViewType = freezed,}) {
  return _then(_self.copyWith(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,gravatarId: freezed == gravatarId ? _self.gravatarId : gravatarId // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,followersUrl: null == followersUrl ? _self.followersUrl : followersUrl // ignore: cast_nullable_to_non_nullable
as String,followingUrl: null == followingUrl ? _self.followingUrl : followingUrl // ignore: cast_nullable_to_non_nullable
as String,gistsUrl: null == gistsUrl ? _self.gistsUrl : gistsUrl // ignore: cast_nullable_to_non_nullable
as String,starredUrl: null == starredUrl ? _self.starredUrl : starredUrl // ignore: cast_nullable_to_non_nullable
as String,subscriptionsUrl: null == subscriptionsUrl ? _self.subscriptionsUrl : subscriptionsUrl // ignore: cast_nullable_to_non_nullable
as String,organizationsUrl: null == organizationsUrl ? _self.organizationsUrl : organizationsUrl // ignore: cast_nullable_to_non_nullable
as String,reposUrl: null == reposUrl ? _self.reposUrl : reposUrl // ignore: cast_nullable_to_non_nullable
as String,eventsUrl: null == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String,receivedEventsUrl: null == receivedEventsUrl ? _self.receivedEventsUrl : receivedEventsUrl // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,siteAdmin: null == siteAdmin ? _self.siteAdmin : siteAdmin // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,starredAt: freezed == starredAt ? _self.starredAt : starredAt // ignore: cast_nullable_to_non_nullable
as String?,userViewType: freezed == userViewType ? _self.userViewType : userViewType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NullableSimpleUser].
extension NullableSimpleUserPatterns on NullableSimpleUser {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NullableSimpleUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NullableSimpleUser() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NullableSimpleUser value)  $default,){
final _that = this;
switch (_that) {
case _NullableSimpleUser():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NullableSimpleUser value)?  $default,){
final _that = this;
switch (_that) {
case _NullableSimpleUser() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String login,  int id, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'avatar_url')  String avatarUrl, @JsonKey(name: 'gravatar_id')  String? gravatarId,  String url, @JsonKey(name: 'html_url')  String htmlUrl, @JsonKey(name: 'followers_url')  String followersUrl, @JsonKey(name: 'following_url')  String followingUrl, @JsonKey(name: 'gists_url')  String gistsUrl, @JsonKey(name: 'starred_url')  String starredUrl, @JsonKey(name: 'subscriptions_url')  String subscriptionsUrl, @JsonKey(name: 'organizations_url')  String organizationsUrl, @JsonKey(name: 'repos_url')  String reposUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'received_events_url')  String receivedEventsUrl,  String type, @JsonKey(name: 'site_admin')  bool siteAdmin,  String? name, @JsonKey(name: 'Email')  String? email, @JsonKey(name: 'starred_at')  String? starredAt, @JsonKey(name: 'user_view_type')  String? userViewType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NullableSimpleUser() when $default != null:
return $default(_that.login,_that.id,_that.nodeId,_that.avatarUrl,_that.gravatarId,_that.url,_that.htmlUrl,_that.followersUrl,_that.followingUrl,_that.gistsUrl,_that.starredUrl,_that.subscriptionsUrl,_that.organizationsUrl,_that.reposUrl,_that.eventsUrl,_that.receivedEventsUrl,_that.type,_that.siteAdmin,_that.name,_that.email,_that.starredAt,_that.userViewType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String login,  int id, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'avatar_url')  String avatarUrl, @JsonKey(name: 'gravatar_id')  String? gravatarId,  String url, @JsonKey(name: 'html_url')  String htmlUrl, @JsonKey(name: 'followers_url')  String followersUrl, @JsonKey(name: 'following_url')  String followingUrl, @JsonKey(name: 'gists_url')  String gistsUrl, @JsonKey(name: 'starred_url')  String starredUrl, @JsonKey(name: 'subscriptions_url')  String subscriptionsUrl, @JsonKey(name: 'organizations_url')  String organizationsUrl, @JsonKey(name: 'repos_url')  String reposUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'received_events_url')  String receivedEventsUrl,  String type, @JsonKey(name: 'site_admin')  bool siteAdmin,  String? name, @JsonKey(name: 'Email')  String? email, @JsonKey(name: 'starred_at')  String? starredAt, @JsonKey(name: 'user_view_type')  String? userViewType)  $default,) {final _that = this;
switch (_that) {
case _NullableSimpleUser():
return $default(_that.login,_that.id,_that.nodeId,_that.avatarUrl,_that.gravatarId,_that.url,_that.htmlUrl,_that.followersUrl,_that.followingUrl,_that.gistsUrl,_that.starredUrl,_that.subscriptionsUrl,_that.organizationsUrl,_that.reposUrl,_that.eventsUrl,_that.receivedEventsUrl,_that.type,_that.siteAdmin,_that.name,_that.email,_that.starredAt,_that.userViewType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String login,  int id, @JsonKey(name: 'node_id')  String nodeId, @JsonKey(name: 'avatar_url')  String avatarUrl, @JsonKey(name: 'gravatar_id')  String? gravatarId,  String url, @JsonKey(name: 'html_url')  String htmlUrl, @JsonKey(name: 'followers_url')  String followersUrl, @JsonKey(name: 'following_url')  String followingUrl, @JsonKey(name: 'gists_url')  String gistsUrl, @JsonKey(name: 'starred_url')  String starredUrl, @JsonKey(name: 'subscriptions_url')  String subscriptionsUrl, @JsonKey(name: 'organizations_url')  String organizationsUrl, @JsonKey(name: 'repos_url')  String reposUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'received_events_url')  String receivedEventsUrl,  String type, @JsonKey(name: 'site_admin')  bool siteAdmin,  String? name, @JsonKey(name: 'Email')  String? email, @JsonKey(name: 'starred_at')  String? starredAt, @JsonKey(name: 'user_view_type')  String? userViewType)?  $default,) {final _that = this;
switch (_that) {
case _NullableSimpleUser() when $default != null:
return $default(_that.login,_that.id,_that.nodeId,_that.avatarUrl,_that.gravatarId,_that.url,_that.htmlUrl,_that.followersUrl,_that.followingUrl,_that.gistsUrl,_that.starredUrl,_that.subscriptionsUrl,_that.organizationsUrl,_that.reposUrl,_that.eventsUrl,_that.receivedEventsUrl,_that.type,_that.siteAdmin,_that.name,_that.email,_that.starredAt,_that.userViewType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NullableSimpleUser implements NullableSimpleUser {
  const _NullableSimpleUser({required this.login, required this.id, @JsonKey(name: 'node_id') required this.nodeId, @JsonKey(name: 'avatar_url') required this.avatarUrl, @JsonKey(name: 'gravatar_id') required this.gravatarId, required this.url, @JsonKey(name: 'html_url') required this.htmlUrl, @JsonKey(name: 'followers_url') required this.followersUrl, @JsonKey(name: 'following_url') required this.followingUrl, @JsonKey(name: 'gists_url') required this.gistsUrl, @JsonKey(name: 'starred_url') required this.starredUrl, @JsonKey(name: 'subscriptions_url') required this.subscriptionsUrl, @JsonKey(name: 'organizations_url') required this.organizationsUrl, @JsonKey(name: 'repos_url') required this.reposUrl, @JsonKey(name: 'events_url') required this.eventsUrl, @JsonKey(name: 'received_events_url') required this.receivedEventsUrl, required this.type, @JsonKey(name: 'site_admin') required this.siteAdmin, this.name, @JsonKey(name: 'Email') this.email, @JsonKey(name: 'starred_at') this.starredAt, @JsonKey(name: 'user_view_type') this.userViewType});
  factory _NullableSimpleUser.fromJson(Map<String, dynamic> json) => _$NullableSimpleUserFromJson(json);

@override final  String login;
@override final  int id;
@override@JsonKey(name: 'node_id') final  String nodeId;
@override@JsonKey(name: 'avatar_url') final  String avatarUrl;
@override@JsonKey(name: 'gravatar_id') final  String? gravatarId;
@override final  String url;
@override@JsonKey(name: 'html_url') final  String htmlUrl;
@override@JsonKey(name: 'followers_url') final  String followersUrl;
@override@JsonKey(name: 'following_url') final  String followingUrl;
@override@JsonKey(name: 'gists_url') final  String gistsUrl;
@override@JsonKey(name: 'starred_url') final  String starredUrl;
@override@JsonKey(name: 'subscriptions_url') final  String subscriptionsUrl;
@override@JsonKey(name: 'organizations_url') final  String organizationsUrl;
@override@JsonKey(name: 'repos_url') final  String reposUrl;
@override@JsonKey(name: 'events_url') final  String eventsUrl;
@override@JsonKey(name: 'received_events_url') final  String receivedEventsUrl;
@override final  String type;
@override@JsonKey(name: 'site_admin') final  bool siteAdmin;
@override final  String? name;
@override@JsonKey(name: 'Email') final  String? email;
@override@JsonKey(name: 'starred_at') final  String? starredAt;
@override@JsonKey(name: 'user_view_type') final  String? userViewType;

/// Create a copy of NullableSimpleUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NullableSimpleUserCopyWith<_NullableSimpleUser> get copyWith => __$NullableSimpleUserCopyWithImpl<_NullableSimpleUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NullableSimpleUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NullableSimpleUser&&(identical(other.login, login) || other.login == login)&&(identical(other.id, id) || other.id == id)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.gravatarId, gravatarId) || other.gravatarId == gravatarId)&&(identical(other.url, url) || other.url == url)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.followersUrl, followersUrl) || other.followersUrl == followersUrl)&&(identical(other.followingUrl, followingUrl) || other.followingUrl == followingUrl)&&(identical(other.gistsUrl, gistsUrl) || other.gistsUrl == gistsUrl)&&(identical(other.starredUrl, starredUrl) || other.starredUrl == starredUrl)&&(identical(other.subscriptionsUrl, subscriptionsUrl) || other.subscriptionsUrl == subscriptionsUrl)&&(identical(other.organizationsUrl, organizationsUrl) || other.organizationsUrl == organizationsUrl)&&(identical(other.reposUrl, reposUrl) || other.reposUrl == reposUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.receivedEventsUrl, receivedEventsUrl) || other.receivedEventsUrl == receivedEventsUrl)&&(identical(other.type, type) || other.type == type)&&(identical(other.siteAdmin, siteAdmin) || other.siteAdmin == siteAdmin)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.starredAt, starredAt) || other.starredAt == starredAt)&&(identical(other.userViewType, userViewType) || other.userViewType == userViewType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,login,id,nodeId,avatarUrl,gravatarId,url,htmlUrl,followersUrl,followingUrl,gistsUrl,starredUrl,subscriptionsUrl,organizationsUrl,reposUrl,eventsUrl,receivedEventsUrl,type,siteAdmin,name,email,starredAt,userViewType]);

@override
String toString() {
  return 'NullableSimpleUser(login: $login, id: $id, nodeId: $nodeId, avatarUrl: $avatarUrl, gravatarId: $gravatarId, url: $url, htmlUrl: $htmlUrl, followersUrl: $followersUrl, followingUrl: $followingUrl, gistsUrl: $gistsUrl, starredUrl: $starredUrl, subscriptionsUrl: $subscriptionsUrl, organizationsUrl: $organizationsUrl, reposUrl: $reposUrl, eventsUrl: $eventsUrl, receivedEventsUrl: $receivedEventsUrl, type: $type, siteAdmin: $siteAdmin, name: $name, email: $email, starredAt: $starredAt, userViewType: $userViewType)';
}


}

/// @nodoc
abstract mixin class _$NullableSimpleUserCopyWith<$Res> implements $NullableSimpleUserCopyWith<$Res> {
  factory _$NullableSimpleUserCopyWith(_NullableSimpleUser value, $Res Function(_NullableSimpleUser) _then) = __$NullableSimpleUserCopyWithImpl;
@override @useResult
$Res call({
 String login, int id,@JsonKey(name: 'node_id') String nodeId,@JsonKey(name: 'avatar_url') String avatarUrl,@JsonKey(name: 'gravatar_id') String? gravatarId, String url,@JsonKey(name: 'html_url') String htmlUrl,@JsonKey(name: 'followers_url') String followersUrl,@JsonKey(name: 'following_url') String followingUrl,@JsonKey(name: 'gists_url') String gistsUrl,@JsonKey(name: 'starred_url') String starredUrl,@JsonKey(name: 'subscriptions_url') String subscriptionsUrl,@JsonKey(name: 'organizations_url') String organizationsUrl,@JsonKey(name: 'repos_url') String reposUrl,@JsonKey(name: 'events_url') String eventsUrl,@JsonKey(name: 'received_events_url') String receivedEventsUrl, String type,@JsonKey(name: 'site_admin') bool siteAdmin, String? name,@JsonKey(name: 'Email') String? email,@JsonKey(name: 'starred_at') String? starredAt,@JsonKey(name: 'user_view_type') String? userViewType
});




}
/// @nodoc
class __$NullableSimpleUserCopyWithImpl<$Res>
    implements _$NullableSimpleUserCopyWith<$Res> {
  __$NullableSimpleUserCopyWithImpl(this._self, this._then);

  final _NullableSimpleUser _self;
  final $Res Function(_NullableSimpleUser) _then;

/// Create a copy of NullableSimpleUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? login = null,Object? id = null,Object? nodeId = null,Object? avatarUrl = null,Object? gravatarId = freezed,Object? url = null,Object? htmlUrl = null,Object? followersUrl = null,Object? followingUrl = null,Object? gistsUrl = null,Object? starredUrl = null,Object? subscriptionsUrl = null,Object? organizationsUrl = null,Object? reposUrl = null,Object? eventsUrl = null,Object? receivedEventsUrl = null,Object? type = null,Object? siteAdmin = null,Object? name = freezed,Object? email = freezed,Object? starredAt = freezed,Object? userViewType = freezed,}) {
  return _then(_NullableSimpleUser(
login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,gravatarId: freezed == gravatarId ? _self.gravatarId : gravatarId // ignore: cast_nullable_to_non_nullable
as String?,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,followersUrl: null == followersUrl ? _self.followersUrl : followersUrl // ignore: cast_nullable_to_non_nullable
as String,followingUrl: null == followingUrl ? _self.followingUrl : followingUrl // ignore: cast_nullable_to_non_nullable
as String,gistsUrl: null == gistsUrl ? _self.gistsUrl : gistsUrl // ignore: cast_nullable_to_non_nullable
as String,starredUrl: null == starredUrl ? _self.starredUrl : starredUrl // ignore: cast_nullable_to_non_nullable
as String,subscriptionsUrl: null == subscriptionsUrl ? _self.subscriptionsUrl : subscriptionsUrl // ignore: cast_nullable_to_non_nullable
as String,organizationsUrl: null == organizationsUrl ? _self.organizationsUrl : organizationsUrl // ignore: cast_nullable_to_non_nullable
as String,reposUrl: null == reposUrl ? _self.reposUrl : reposUrl // ignore: cast_nullable_to_non_nullable
as String,eventsUrl: null == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String,receivedEventsUrl: null == receivedEventsUrl ? _self.receivedEventsUrl : receivedEventsUrl // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,siteAdmin: null == siteAdmin ? _self.siteAdmin : siteAdmin // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,starredAt: freezed == starredAt ? _self.starredAt : starredAt // ignore: cast_nullable_to_non_nullable
as String?,userViewType: freezed == userViewType ? _self.userViewType : userViewType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
