// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_connection_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubConnectionContext {

 String get profileId; String get apiUrl; String get userId; String get teamId;
/// Create a copy of GitHubConnectionContext
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubConnectionContextCopyWith<GitHubConnectionContext> get copyWith => _$GitHubConnectionContextCopyWithImpl<GitHubConnectionContext>(this as GitHubConnectionContext, _$identity);

  /// Serializes this GitHubConnectionContext to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubConnectionContext&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.teamId, teamId) || other.teamId == teamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,profileId,apiUrl,userId,teamId);

@override
String toString() {
  return 'GitHubConnectionContext(profileId: $profileId, apiUrl: $apiUrl, userId: $userId, teamId: $teamId)';
}


}

/// @nodoc
abstract mixin class $GitHubConnectionContextCopyWith<$Res>  {
  factory $GitHubConnectionContextCopyWith(GitHubConnectionContext value, $Res Function(GitHubConnectionContext) _then) = _$GitHubConnectionContextCopyWithImpl;
@useResult
$Res call({
 String profileId, String apiUrl, String userId, String teamId
});




}
/// @nodoc
class _$GitHubConnectionContextCopyWithImpl<$Res>
    implements $GitHubConnectionContextCopyWith<$Res> {
  _$GitHubConnectionContextCopyWithImpl(this._self, this._then);

  final GitHubConnectionContext _self;
  final $Res Function(GitHubConnectionContext) _then;

/// Create a copy of GitHubConnectionContext
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? profileId = null,Object? apiUrl = null,Object? userId = null,Object? teamId = null,}) {
  return _then(_self.copyWith(
profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,apiUrl: null == apiUrl ? _self.apiUrl : apiUrl // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubConnectionContext].
extension GitHubConnectionContextPatterns on GitHubConnectionContext {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubConnectionContext value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubConnectionContext() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubConnectionContext value)  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionContext():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubConnectionContext value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionContext() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String profileId,  String apiUrl,  String userId,  String teamId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubConnectionContext() when $default != null:
return $default(_that.profileId,_that.apiUrl,_that.userId,_that.teamId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String profileId,  String apiUrl,  String userId,  String teamId)  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionContext():
return $default(_that.profileId,_that.apiUrl,_that.userId,_that.teamId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String profileId,  String apiUrl,  String userId,  String teamId)?  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionContext() when $default != null:
return $default(_that.profileId,_that.apiUrl,_that.userId,_that.teamId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubConnectionContext implements GitHubConnectionContext {
  const _GitHubConnectionContext({required this.profileId, required this.apiUrl, required this.userId, required this.teamId});
  factory _GitHubConnectionContext.fromJson(Map<String, dynamic> json) => _$GitHubConnectionContextFromJson(json);

@override final  String profileId;
@override final  String apiUrl;
@override final  String userId;
@override final  String teamId;

/// Create a copy of GitHubConnectionContext
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubConnectionContextCopyWith<_GitHubConnectionContext> get copyWith => __$GitHubConnectionContextCopyWithImpl<_GitHubConnectionContext>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubConnectionContextToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubConnectionContext&&(identical(other.profileId, profileId) || other.profileId == profileId)&&(identical(other.apiUrl, apiUrl) || other.apiUrl == apiUrl)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.teamId, teamId) || other.teamId == teamId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,profileId,apiUrl,userId,teamId);

@override
String toString() {
  return 'GitHubConnectionContext(profileId: $profileId, apiUrl: $apiUrl, userId: $userId, teamId: $teamId)';
}


}

/// @nodoc
abstract mixin class _$GitHubConnectionContextCopyWith<$Res> implements $GitHubConnectionContextCopyWith<$Res> {
  factory _$GitHubConnectionContextCopyWith(_GitHubConnectionContext value, $Res Function(_GitHubConnectionContext) _then) = __$GitHubConnectionContextCopyWithImpl;
@override @useResult
$Res call({
 String profileId, String apiUrl, String userId, String teamId
});




}
/// @nodoc
class __$GitHubConnectionContextCopyWithImpl<$Res>
    implements _$GitHubConnectionContextCopyWith<$Res> {
  __$GitHubConnectionContextCopyWithImpl(this._self, this._then);

  final _GitHubConnectionContext _self;
  final $Res Function(_GitHubConnectionContext) _then;

/// Create a copy of GitHubConnectionContext
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? profileId = null,Object? apiUrl = null,Object? userId = null,Object? teamId = null,}) {
  return _then(_GitHubConnectionContext(
profileId: null == profileId ? _self.profileId : profileId // ignore: cast_nullable_to_non_nullable
as String,apiUrl: null == apiUrl ? _self.apiUrl : apiUrl // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
