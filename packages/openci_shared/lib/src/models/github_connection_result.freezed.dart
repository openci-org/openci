// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_connection_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GitHubConnectionSessionResult {

 bool get success; GitHubConnectionSession get session;
/// Create a copy of GitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubConnectionSessionResultCopyWith<GitHubConnectionSessionResult> get copyWith => _$GitHubConnectionSessionResultCopyWithImpl<GitHubConnectionSessionResult>(this as GitHubConnectionSessionResult, _$identity);

  /// Serializes this GitHubConnectionSessionResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubConnectionSessionResult&&(identical(other.success, success) || other.success == success)&&(identical(other.session, session) || other.session == session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,session);

@override
String toString() {
  return 'GitHubConnectionSessionResult(success: $success, session: $session)';
}


}

/// @nodoc
abstract mixin class $GitHubConnectionSessionResultCopyWith<$Res>  {
  factory $GitHubConnectionSessionResultCopyWith(GitHubConnectionSessionResult value, $Res Function(GitHubConnectionSessionResult) _then) = _$GitHubConnectionSessionResultCopyWithImpl;
@useResult
$Res call({
 bool success, GitHubConnectionSession session
});


$GitHubConnectionSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$GitHubConnectionSessionResultCopyWithImpl<$Res>
    implements $GitHubConnectionSessionResultCopyWith<$Res> {
  _$GitHubConnectionSessionResultCopyWithImpl(this._self, this._then);

  final GitHubConnectionSessionResult _self;
  final $Res Function(GitHubConnectionSessionResult) _then;

/// Create a copy of GitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? session = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as GitHubConnectionSession,
  ));
}
/// Create a copy of GitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GitHubConnectionSessionCopyWith<$Res> get session {

  return $GitHubConnectionSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [GitHubConnectionSessionResult].
extension GitHubConnectionSessionResultPatterns on GitHubConnectionSessionResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubConnectionSessionResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubConnectionSessionResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubConnectionSessionResult value)  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionSessionResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubConnectionSessionResult value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionSessionResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  GitHubConnectionSession session)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubConnectionSessionResult() when $default != null:
return $default(_that.success,_that.session);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  GitHubConnectionSession session)  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionSessionResult():
return $default(_that.success,_that.session);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  GitHubConnectionSession session)?  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionSessionResult() when $default != null:
return $default(_that.success,_that.session);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _GitHubConnectionSessionResult implements GitHubConnectionSessionResult {
  const _GitHubConnectionSessionResult({required this.success, required this.session});
  factory _GitHubConnectionSessionResult.fromJson(Map<String, dynamic> json) => _$GitHubConnectionSessionResultFromJson(json);

@override final  bool success;
@override final  GitHubConnectionSession session;

/// Create a copy of GitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubConnectionSessionResultCopyWith<_GitHubConnectionSessionResult> get copyWith => __$GitHubConnectionSessionResultCopyWithImpl<_GitHubConnectionSessionResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubConnectionSessionResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubConnectionSessionResult&&(identical(other.success, success) || other.success == success)&&(identical(other.session, session) || other.session == session));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,session);

@override
String toString() {
  return 'GitHubConnectionSessionResult(success: $success, session: $session)';
}


}

/// @nodoc
abstract mixin class _$GitHubConnectionSessionResultCopyWith<$Res> implements $GitHubConnectionSessionResultCopyWith<$Res> {
  factory _$GitHubConnectionSessionResultCopyWith(_GitHubConnectionSessionResult value, $Res Function(_GitHubConnectionSessionResult) _then) = __$GitHubConnectionSessionResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, GitHubConnectionSession session
});


@override $GitHubConnectionSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$GitHubConnectionSessionResultCopyWithImpl<$Res>
    implements _$GitHubConnectionSessionResultCopyWith<$Res> {
  __$GitHubConnectionSessionResultCopyWithImpl(this._self, this._then);

  final _GitHubConnectionSessionResult _self;
  final $Res Function(_GitHubConnectionSessionResult) _then;

/// Create a copy of GitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? session = null,}) {
  return _then(_GitHubConnectionSessionResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as GitHubConnectionSession,
  ));
}

/// Create a copy of GitHubConnectionSessionResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GitHubConnectionSessionCopyWith<$Res> get session {

  return $GitHubConnectionSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// @nodoc
mixin _$GitHubConnectionSession {

 String get teamId; int get githubUserId; DateTime get expiresAt;
/// Create a copy of GitHubConnectionSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubConnectionSessionCopyWith<GitHubConnectionSession> get copyWith => _$GitHubConnectionSessionCopyWithImpl<GitHubConnectionSession>(this as GitHubConnectionSession, _$identity);

  /// Serializes this GitHubConnectionSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubConnectionSession&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.githubUserId, githubUserId) || other.githubUserId == githubUserId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,githubUserId,expiresAt);

@override
String toString() {
  return 'GitHubConnectionSession(teamId: $teamId, githubUserId: $githubUserId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $GitHubConnectionSessionCopyWith<$Res>  {
  factory $GitHubConnectionSessionCopyWith(GitHubConnectionSession value, $Res Function(GitHubConnectionSession) _then) = _$GitHubConnectionSessionCopyWithImpl;
@useResult
$Res call({
 String teamId, int githubUserId, DateTime expiresAt
});




}
/// @nodoc
class _$GitHubConnectionSessionCopyWithImpl<$Res>
    implements $GitHubConnectionSessionCopyWith<$Res> {
  _$GitHubConnectionSessionCopyWithImpl(this._self, this._then);

  final GitHubConnectionSession _self;
  final $Res Function(GitHubConnectionSession) _then;

/// Create a copy of GitHubConnectionSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? teamId = null,Object? githubUserId = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,githubUserId: null == githubUserId ? _self.githubUserId : githubUserId // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubConnectionSession].
extension GitHubConnectionSessionPatterns on GitHubConnectionSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubConnectionSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubConnectionSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubConnectionSession value)  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubConnectionSession value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String teamId,  int githubUserId,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubConnectionSession() when $default != null:
return $default(_that.teamId,_that.githubUserId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String teamId,  int githubUserId,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionSession():
return $default(_that.teamId,_that.githubUserId,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String teamId,  int githubUserId,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionSession() when $default != null:
return $default(_that.teamId,_that.githubUserId,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubConnectionSession implements GitHubConnectionSession {
  const _GitHubConnectionSession({required this.teamId, required this.githubUserId, required this.expiresAt});
  factory _GitHubConnectionSession.fromJson(Map<String, dynamic> json) => _$GitHubConnectionSessionFromJson(json);

@override final  String teamId;
@override final  int githubUserId;
@override final  DateTime expiresAt;

/// Create a copy of GitHubConnectionSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubConnectionSessionCopyWith<_GitHubConnectionSession> get copyWith => __$GitHubConnectionSessionCopyWithImpl<_GitHubConnectionSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubConnectionSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubConnectionSession&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.githubUserId, githubUserId) || other.githubUserId == githubUserId)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,teamId,githubUserId,expiresAt);

@override
String toString() {
  return 'GitHubConnectionSession(teamId: $teamId, githubUserId: $githubUserId, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$GitHubConnectionSessionCopyWith<$Res> implements $GitHubConnectionSessionCopyWith<$Res> {
  factory _$GitHubConnectionSessionCopyWith(_GitHubConnectionSession value, $Res Function(_GitHubConnectionSession) _then) = __$GitHubConnectionSessionCopyWithImpl;
@override @useResult
$Res call({
 String teamId, int githubUserId, DateTime expiresAt
});




}
/// @nodoc
class __$GitHubConnectionSessionCopyWithImpl<$Res>
    implements _$GitHubConnectionSessionCopyWith<$Res> {
  __$GitHubConnectionSessionCopyWithImpl(this._self, this._then);

  final _GitHubConnectionSession _self;
  final $Res Function(_GitHubConnectionSession) _then;

/// Create a copy of GitHubConnectionSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? teamId = null,Object? githubUserId = null,Object? expiresAt = null,}) {
  return _then(_GitHubConnectionSession(
teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,githubUserId: null == githubUserId ? _self.githubUserId : githubUserId // ignore: cast_nullable_to_non_nullable
as int,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$GitHubConnectionCandidatesResult {

 bool get success; List<GitHubConnectionCandidate> get candidates; String? get installationUrl;
/// Create a copy of GitHubConnectionCandidatesResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubConnectionCandidatesResultCopyWith<GitHubConnectionCandidatesResult> get copyWith => _$GitHubConnectionCandidatesResultCopyWithImpl<GitHubConnectionCandidatesResult>(this as GitHubConnectionCandidatesResult, _$identity);

  /// Serializes this GitHubConnectionCandidatesResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubConnectionCandidatesResult&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other.candidates, candidates)&&(identical(other.installationUrl, installationUrl) || other.installationUrl == installationUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(candidates),installationUrl);

@override
String toString() {
  return 'GitHubConnectionCandidatesResult(success: $success, candidates: $candidates, installationUrl: $installationUrl)';
}


}

/// @nodoc
abstract mixin class $GitHubConnectionCandidatesResultCopyWith<$Res>  {
  factory $GitHubConnectionCandidatesResultCopyWith(GitHubConnectionCandidatesResult value, $Res Function(GitHubConnectionCandidatesResult) _then) = _$GitHubConnectionCandidatesResultCopyWithImpl;
@useResult
$Res call({
 bool success, List<GitHubConnectionCandidate> candidates, String? installationUrl
});




}
/// @nodoc
class _$GitHubConnectionCandidatesResultCopyWithImpl<$Res>
    implements $GitHubConnectionCandidatesResultCopyWith<$Res> {
  _$GitHubConnectionCandidatesResultCopyWithImpl(this._self, this._then);

  final GitHubConnectionCandidatesResult _self;
  final $Res Function(GitHubConnectionCandidatesResult) _then;

/// Create a copy of GitHubConnectionCandidatesResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? candidates = null,Object? installationUrl = freezed,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<GitHubConnectionCandidate>,installationUrl: freezed == installationUrl ? _self.installationUrl : installationUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubConnectionCandidatesResult].
extension GitHubConnectionCandidatesResultPatterns on GitHubConnectionCandidatesResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubConnectionCandidatesResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubConnectionCandidatesResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubConnectionCandidatesResult value)  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionCandidatesResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubConnectionCandidatesResult value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionCandidatesResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success,  List<GitHubConnectionCandidate> candidates,  String? installationUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubConnectionCandidatesResult() when $default != null:
return $default(_that.success,_that.candidates,_that.installationUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success,  List<GitHubConnectionCandidate> candidates,  String? installationUrl)  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionCandidatesResult():
return $default(_that.success,_that.candidates,_that.installationUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success,  List<GitHubConnectionCandidate> candidates,  String? installationUrl)?  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionCandidatesResult() when $default != null:
return $default(_that.success,_that.candidates,_that.installationUrl);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class _GitHubConnectionCandidatesResult implements GitHubConnectionCandidatesResult {
  const _GitHubConnectionCandidatesResult({required this.success, required final  List<GitHubConnectionCandidate> candidates, this.installationUrl}): _candidates = candidates;
  factory _GitHubConnectionCandidatesResult.fromJson(Map<String, dynamic> json) => _$GitHubConnectionCandidatesResultFromJson(json);

@override final  bool success;
 final  List<GitHubConnectionCandidate> _candidates;
@override List<GitHubConnectionCandidate> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}

@override final  String? installationUrl;

/// Create a copy of GitHubConnectionCandidatesResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubConnectionCandidatesResultCopyWith<_GitHubConnectionCandidatesResult> get copyWith => __$GitHubConnectionCandidatesResultCopyWithImpl<_GitHubConnectionCandidatesResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubConnectionCandidatesResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubConnectionCandidatesResult&&(identical(other.success, success) || other.success == success)&&const DeepCollectionEquality().equals(other._candidates, _candidates)&&(identical(other.installationUrl, installationUrl) || other.installationUrl == installationUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,const DeepCollectionEquality().hash(_candidates),installationUrl);

@override
String toString() {
  return 'GitHubConnectionCandidatesResult(success: $success, candidates: $candidates, installationUrl: $installationUrl)';
}


}

/// @nodoc
abstract mixin class _$GitHubConnectionCandidatesResultCopyWith<$Res> implements $GitHubConnectionCandidatesResultCopyWith<$Res> {
  factory _$GitHubConnectionCandidatesResultCopyWith(_GitHubConnectionCandidatesResult value, $Res Function(_GitHubConnectionCandidatesResult) _then) = __$GitHubConnectionCandidatesResultCopyWithImpl;
@override @useResult
$Res call({
 bool success, List<GitHubConnectionCandidate> candidates, String? installationUrl
});




}
/// @nodoc
class __$GitHubConnectionCandidatesResultCopyWithImpl<$Res>
    implements _$GitHubConnectionCandidatesResultCopyWith<$Res> {
  __$GitHubConnectionCandidatesResultCopyWithImpl(this._self, this._then);

  final _GitHubConnectionCandidatesResult _self;
  final $Res Function(_GitHubConnectionCandidatesResult) _then;

/// Create a copy of GitHubConnectionCandidatesResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? candidates = null,Object? installationUrl = freezed,}) {
  return _then(_GitHubConnectionCandidatesResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<GitHubConnectionCandidate>,installationUrl: freezed == installationUrl ? _self.installationUrl : installationUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$GitHubConnectionCandidate {

 int get installationId; String get accountLogin; String get accountType;
/// Create a copy of GitHubConnectionCandidate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubConnectionCandidateCopyWith<GitHubConnectionCandidate> get copyWith => _$GitHubConnectionCandidateCopyWithImpl<GitHubConnectionCandidate>(this as GitHubConnectionCandidate, _$identity);

  /// Serializes this GitHubConnectionCandidate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubConnectionCandidate&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.accountLogin, accountLogin) || other.accountLogin == accountLogin)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,installationId,accountLogin,accountType);

@override
String toString() {
  return 'GitHubConnectionCandidate(installationId: $installationId, accountLogin: $accountLogin, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class $GitHubConnectionCandidateCopyWith<$Res>  {
  factory $GitHubConnectionCandidateCopyWith(GitHubConnectionCandidate value, $Res Function(GitHubConnectionCandidate) _then) = _$GitHubConnectionCandidateCopyWithImpl;
@useResult
$Res call({
 int installationId, String accountLogin, String accountType
});




}
/// @nodoc
class _$GitHubConnectionCandidateCopyWithImpl<$Res>
    implements $GitHubConnectionCandidateCopyWith<$Res> {
  _$GitHubConnectionCandidateCopyWithImpl(this._self, this._then);

  final GitHubConnectionCandidate _self;
  final $Res Function(GitHubConnectionCandidate) _then;

/// Create a copy of GitHubConnectionCandidate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? installationId = null,Object? accountLogin = null,Object? accountType = null,}) {
  return _then(_self.copyWith(
installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as int,accountLogin: null == accountLogin ? _self.accountLogin : accountLogin // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubConnectionCandidate].
extension GitHubConnectionCandidatePatterns on GitHubConnectionCandidate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubConnectionCandidate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubConnectionCandidate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubConnectionCandidate value)  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionCandidate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubConnectionCandidate value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionCandidate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int installationId,  String accountLogin,  String accountType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubConnectionCandidate() when $default != null:
return $default(_that.installationId,_that.accountLogin,_that.accountType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int installationId,  String accountLogin,  String accountType)  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionCandidate():
return $default(_that.installationId,_that.accountLogin,_that.accountType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int installationId,  String accountLogin,  String accountType)?  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionCandidate() when $default != null:
return $default(_that.installationId,_that.accountLogin,_that.accountType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubConnectionCandidate implements GitHubConnectionCandidate {
  const _GitHubConnectionCandidate({required this.installationId, required this.accountLogin, required this.accountType});
  factory _GitHubConnectionCandidate.fromJson(Map<String, dynamic> json) => _$GitHubConnectionCandidateFromJson(json);

@override final  int installationId;
@override final  String accountLogin;
@override final  String accountType;

/// Create a copy of GitHubConnectionCandidate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubConnectionCandidateCopyWith<_GitHubConnectionCandidate> get copyWith => __$GitHubConnectionCandidateCopyWithImpl<_GitHubConnectionCandidate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubConnectionCandidateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubConnectionCandidate&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.accountLogin, accountLogin) || other.accountLogin == accountLogin)&&(identical(other.accountType, accountType) || other.accountType == accountType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,installationId,accountLogin,accountType);

@override
String toString() {
  return 'GitHubConnectionCandidate(installationId: $installationId, accountLogin: $accountLogin, accountType: $accountType)';
}


}

/// @nodoc
abstract mixin class _$GitHubConnectionCandidateCopyWith<$Res> implements $GitHubConnectionCandidateCopyWith<$Res> {
  factory _$GitHubConnectionCandidateCopyWith(_GitHubConnectionCandidate value, $Res Function(_GitHubConnectionCandidate) _then) = __$GitHubConnectionCandidateCopyWithImpl;
@override @useResult
$Res call({
 int installationId, String accountLogin, String accountType
});




}
/// @nodoc
class __$GitHubConnectionCandidateCopyWithImpl<$Res>
    implements _$GitHubConnectionCandidateCopyWith<$Res> {
  __$GitHubConnectionCandidateCopyWithImpl(this._self, this._then);

  final _GitHubConnectionCandidate _self;
  final $Res Function(_GitHubConnectionCandidate) _then;

/// Create a copy of GitHubConnectionCandidate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? installationId = null,Object? accountLogin = null,Object? accountType = null,}) {
  return _then(_GitHubConnectionCandidate(
installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as int,accountLogin: null == accountLogin ? _self.accountLogin : accountLogin // ignore: cast_nullable_to_non_nullable
as String,accountType: null == accountType ? _self.accountType : accountType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$GitHubConnectionConfirmationResult {

 bool get success;
/// Create a copy of GitHubConnectionConfirmationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubConnectionConfirmationResultCopyWith<GitHubConnectionConfirmationResult> get copyWith => _$GitHubConnectionConfirmationResultCopyWithImpl<GitHubConnectionConfirmationResult>(this as GitHubConnectionConfirmationResult, _$identity);

  /// Serializes this GitHubConnectionConfirmationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubConnectionConfirmationResult&&(identical(other.success, success) || other.success == success));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success);

@override
String toString() {
  return 'GitHubConnectionConfirmationResult(success: $success)';
}


}

/// @nodoc
abstract mixin class $GitHubConnectionConfirmationResultCopyWith<$Res>  {
  factory $GitHubConnectionConfirmationResultCopyWith(GitHubConnectionConfirmationResult value, $Res Function(GitHubConnectionConfirmationResult) _then) = _$GitHubConnectionConfirmationResultCopyWithImpl;
@useResult
$Res call({
 bool success
});




}
/// @nodoc
class _$GitHubConnectionConfirmationResultCopyWithImpl<$Res>
    implements $GitHubConnectionConfirmationResultCopyWith<$Res> {
  _$GitHubConnectionConfirmationResultCopyWithImpl(this._self, this._then);

  final GitHubConnectionConfirmationResult _self;
  final $Res Function(GitHubConnectionConfirmationResult) _then;

/// Create a copy of GitHubConnectionConfirmationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubConnectionConfirmationResult].
extension GitHubConnectionConfirmationResultPatterns on GitHubConnectionConfirmationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubConnectionConfirmationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubConnectionConfirmationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubConnectionConfirmationResult value)  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionConfirmationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubConnectionConfirmationResult value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubConnectionConfirmationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool success)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubConnectionConfirmationResult() when $default != null:
return $default(_that.success);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool success)  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionConfirmationResult():
return $default(_that.success);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool success)?  $default,) {final _that = this;
switch (_that) {
case _GitHubConnectionConfirmationResult() when $default != null:
return $default(_that.success);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GitHubConnectionConfirmationResult implements GitHubConnectionConfirmationResult {
  const _GitHubConnectionConfirmationResult({required this.success});
  factory _GitHubConnectionConfirmationResult.fromJson(Map<String, dynamic> json) => _$GitHubConnectionConfirmationResultFromJson(json);

@override final  bool success;

/// Create a copy of GitHubConnectionConfirmationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubConnectionConfirmationResultCopyWith<_GitHubConnectionConfirmationResult> get copyWith => __$GitHubConnectionConfirmationResultCopyWithImpl<_GitHubConnectionConfirmationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GitHubConnectionConfirmationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubConnectionConfirmationResult&&(identical(other.success, success) || other.success == success));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success);

@override
String toString() {
  return 'GitHubConnectionConfirmationResult(success: $success)';
}


}

/// @nodoc
abstract mixin class _$GitHubConnectionConfirmationResultCopyWith<$Res> implements $GitHubConnectionConfirmationResultCopyWith<$Res> {
  factory _$GitHubConnectionConfirmationResultCopyWith(_GitHubConnectionConfirmationResult value, $Res Function(_GitHubConnectionConfirmationResult) _then) = __$GitHubConnectionConfirmationResultCopyWithImpl;
@override @useResult
$Res call({
 bool success
});




}
/// @nodoc
class __$GitHubConnectionConfirmationResultCopyWithImpl<$Res>
    implements _$GitHubConnectionConfirmationResultCopyWith<$Res> {
  __$GitHubConnectionConfirmationResultCopyWithImpl(this._self, this._then);

  final _GitHubConnectionConfirmationResult _self;
  final $Res Function(_GitHubConnectionConfirmationResult) _then;

/// Create a copy of GitHubConnectionConfirmationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,}) {
  return _then(_GitHubConnectionConfirmationResult(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
