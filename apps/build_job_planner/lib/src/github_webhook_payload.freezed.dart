// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'github_webhook_payload.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GitHubWebhookPayload {

 int get installationId; String get eventType; String get owner; String get repo; String get commitSha; String get branch; String get triggerBranch; String get triggerType; int? get pullRequestNumber; String? get commitMessage; bool get isDeleted;
/// Create a copy of GitHubWebhookPayload
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GitHubWebhookPayloadCopyWith<GitHubWebhookPayload> get copyWith => _$GitHubWebhookPayloadCopyWithImpl<GitHubWebhookPayload>(this as GitHubWebhookPayload, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GitHubWebhookPayload&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.triggerBranch, triggerBranch) || other.triggerBranch == triggerBranch)&&(identical(other.triggerType, triggerType) || other.triggerType == triggerType)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,installationId,eventType,owner,repo,commitSha,branch,triggerBranch,triggerType,pullRequestNumber,commitMessage,isDeleted);

@override
String toString() {
  return 'GitHubWebhookPayload(installationId: $installationId, eventType: $eventType, owner: $owner, repo: $repo, commitSha: $commitSha, branch: $branch, triggerBranch: $triggerBranch, triggerType: $triggerType, pullRequestNumber: $pullRequestNumber, commitMessage: $commitMessage, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $GitHubWebhookPayloadCopyWith<$Res>  {
  factory $GitHubWebhookPayloadCopyWith(GitHubWebhookPayload value, $Res Function(GitHubWebhookPayload) _then) = _$GitHubWebhookPayloadCopyWithImpl;
@useResult
$Res call({
 int installationId, String eventType, String owner, String repo, String commitSha, String branch, String triggerBranch, String triggerType, int? pullRequestNumber, String? commitMessage, bool isDeleted
});




}
/// @nodoc
class _$GitHubWebhookPayloadCopyWithImpl<$Res>
    implements $GitHubWebhookPayloadCopyWith<$Res> {
  _$GitHubWebhookPayloadCopyWithImpl(this._self, this._then);

  final GitHubWebhookPayload _self;
  final $Res Function(GitHubWebhookPayload) _then;

/// Create a copy of GitHubWebhookPayload
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? installationId = null,Object? eventType = null,Object? owner = null,Object? repo = null,Object? commitSha = null,Object? branch = null,Object? triggerBranch = null,Object? triggerType = null,Object? pullRequestNumber = freezed,Object? commitMessage = freezed,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as int,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,triggerBranch: null == triggerBranch ? _self.triggerBranch : triggerBranch // ignore: cast_nullable_to_non_nullable
as String,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as String,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GitHubWebhookPayload].
extension GitHubWebhookPayloadPatterns on GitHubWebhookPayload {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GitHubWebhookPayload value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GitHubWebhookPayload() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GitHubWebhookPayload value)  $default,){
final _that = this;
switch (_that) {
case _GitHubWebhookPayload():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GitHubWebhookPayload value)?  $default,){
final _that = this;
switch (_that) {
case _GitHubWebhookPayload() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int installationId,  String eventType,  String owner,  String repo,  String commitSha,  String branch,  String triggerBranch,  String triggerType,  int? pullRequestNumber,  String? commitMessage,  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GitHubWebhookPayload() when $default != null:
return $default(_that.installationId,_that.eventType,_that.owner,_that.repo,_that.commitSha,_that.branch,_that.triggerBranch,_that.triggerType,_that.pullRequestNumber,_that.commitMessage,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int installationId,  String eventType,  String owner,  String repo,  String commitSha,  String branch,  String triggerBranch,  String triggerType,  int? pullRequestNumber,  String? commitMessage,  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _GitHubWebhookPayload():
return $default(_that.installationId,_that.eventType,_that.owner,_that.repo,_that.commitSha,_that.branch,_that.triggerBranch,_that.triggerType,_that.pullRequestNumber,_that.commitMessage,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int installationId,  String eventType,  String owner,  String repo,  String commitSha,  String branch,  String triggerBranch,  String triggerType,  int? pullRequestNumber,  String? commitMessage,  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _GitHubWebhookPayload() when $default != null:
return $default(_that.installationId,_that.eventType,_that.owner,_that.repo,_that.commitSha,_that.branch,_that.triggerBranch,_that.triggerType,_that.pullRequestNumber,_that.commitMessage,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc


class _GitHubWebhookPayload implements GitHubWebhookPayload {
  const _GitHubWebhookPayload({required this.installationId, required this.eventType, required this.owner, required this.repo, required this.commitSha, required this.branch, required this.triggerBranch, required this.triggerType, this.pullRequestNumber, this.commitMessage, this.isDeleted = false});


@override final  int installationId;
@override final  String eventType;
@override final  String owner;
@override final  String repo;
@override final  String commitSha;
@override final  String branch;
@override final  String triggerBranch;
@override final  String triggerType;
@override final  int? pullRequestNumber;
@override final  String? commitMessage;
@override@JsonKey() final  bool isDeleted;

/// Create a copy of GitHubWebhookPayload
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GitHubWebhookPayloadCopyWith<_GitHubWebhookPayload> get copyWith => __$GitHubWebhookPayloadCopyWithImpl<_GitHubWebhookPayload>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GitHubWebhookPayload&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.triggerBranch, triggerBranch) || other.triggerBranch == triggerBranch)&&(identical(other.triggerType, triggerType) || other.triggerType == triggerType)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}


@override
int get hashCode => Object.hash(runtimeType,installationId,eventType,owner,repo,commitSha,branch,triggerBranch,triggerType,pullRequestNumber,commitMessage,isDeleted);

@override
String toString() {
  return 'GitHubWebhookPayload(installationId: $installationId, eventType: $eventType, owner: $owner, repo: $repo, commitSha: $commitSha, branch: $branch, triggerBranch: $triggerBranch, triggerType: $triggerType, pullRequestNumber: $pullRequestNumber, commitMessage: $commitMessage, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$GitHubWebhookPayloadCopyWith<$Res> implements $GitHubWebhookPayloadCopyWith<$Res> {
  factory _$GitHubWebhookPayloadCopyWith(_GitHubWebhookPayload value, $Res Function(_GitHubWebhookPayload) _then) = __$GitHubWebhookPayloadCopyWithImpl;
@override @useResult
$Res call({
 int installationId, String eventType, String owner, String repo, String commitSha, String branch, String triggerBranch, String triggerType, int? pullRequestNumber, String? commitMessage, bool isDeleted
});




}
/// @nodoc
class __$GitHubWebhookPayloadCopyWithImpl<$Res>
    implements _$GitHubWebhookPayloadCopyWith<$Res> {
  __$GitHubWebhookPayloadCopyWithImpl(this._self, this._then);

  final _GitHubWebhookPayload _self;
  final $Res Function(_GitHubWebhookPayload) _then;

/// Create a copy of GitHubWebhookPayload
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? installationId = null,Object? eventType = null,Object? owner = null,Object? repo = null,Object? commitSha = null,Object? branch = null,Object? triggerBranch = null,Object? triggerType = null,Object? pullRequestNumber = freezed,Object? commitMessage = freezed,Object? isDeleted = null,}) {
  return _then(_GitHubWebhookPayload(
installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as int,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,triggerBranch: null == triggerBranch ? _self.triggerBranch : triggerBranch // ignore: cast_nullable_to_non_nullable
as String,triggerType: null == triggerType ? _self.triggerType : triggerType // ignore: cast_nullable_to_non_nullable
as String,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
