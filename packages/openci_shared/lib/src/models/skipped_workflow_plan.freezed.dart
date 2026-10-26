// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'skipped_workflow_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SkippedWorkflowPlan {

 String get owner; String get repo; String get workflowName; String get workflowFileName; String get teamId; String get commitSha; String get installationId; String get reason;
/// Create a copy of SkippedWorkflowPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkippedWorkflowPlanCopyWith<SkippedWorkflowPlan> get copyWith => _$SkippedWorkflowPlanCopyWithImpl<SkippedWorkflowPlan>(this as SkippedWorkflowPlan, _$identity);

  /// Serializes this SkippedWorkflowPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkippedWorkflowPlan&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,owner,repo,workflowName,workflowFileName,teamId,commitSha,installationId,reason);

@override
String toString() {
  return 'SkippedWorkflowPlan(owner: $owner, repo: $repo, workflowName: $workflowName, workflowFileName: $workflowFileName, teamId: $teamId, commitSha: $commitSha, installationId: $installationId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $SkippedWorkflowPlanCopyWith<$Res>  {
  factory $SkippedWorkflowPlanCopyWith(SkippedWorkflowPlan value, $Res Function(SkippedWorkflowPlan) _then) = _$SkippedWorkflowPlanCopyWithImpl;
@useResult
$Res call({
 String owner, String repo, String workflowName, String workflowFileName, String teamId, String commitSha, String installationId, String reason
});




}
/// @nodoc
class _$SkippedWorkflowPlanCopyWithImpl<$Res>
    implements $SkippedWorkflowPlanCopyWith<$Res> {
  _$SkippedWorkflowPlanCopyWithImpl(this._self, this._then);

  final SkippedWorkflowPlan _self;
  final $Res Function(SkippedWorkflowPlan) _then;

/// Create a copy of SkippedWorkflowPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? repo = null,Object? workflowName = null,Object? workflowFileName = null,Object? teamId = null,Object? commitSha = null,Object? installationId = null,Object? reason = null,}) {
  return _then(_self.copyWith(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,workflowFileName: null == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SkippedWorkflowPlan].
extension SkippedWorkflowPlanPatterns on SkippedWorkflowPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SkippedWorkflowPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SkippedWorkflowPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SkippedWorkflowPlan value)  $default,){
final _that = this;
switch (_that) {
case _SkippedWorkflowPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SkippedWorkflowPlan value)?  $default,){
final _that = this;
switch (_that) {
case _SkippedWorkflowPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String owner,  String repo,  String workflowName,  String workflowFileName,  String teamId,  String commitSha,  String installationId,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SkippedWorkflowPlan() when $default != null:
return $default(_that.owner,_that.repo,_that.workflowName,_that.workflowFileName,_that.teamId,_that.commitSha,_that.installationId,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String owner,  String repo,  String workflowName,  String workflowFileName,  String teamId,  String commitSha,  String installationId,  String reason)  $default,) {final _that = this;
switch (_that) {
case _SkippedWorkflowPlan():
return $default(_that.owner,_that.repo,_that.workflowName,_that.workflowFileName,_that.teamId,_that.commitSha,_that.installationId,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String owner,  String repo,  String workflowName,  String workflowFileName,  String teamId,  String commitSha,  String installationId,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _SkippedWorkflowPlan() when $default != null:
return $default(_that.owner,_that.repo,_that.workflowName,_that.workflowFileName,_that.teamId,_that.commitSha,_that.installationId,_that.reason);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(disallowUnrecognizedKeys: true)
class _SkippedWorkflowPlan implements SkippedWorkflowPlan {
  const _SkippedWorkflowPlan({required this.owner, required this.repo, required this.workflowName, required this.workflowFileName, required this.teamId, required this.commitSha, required this.installationId, required this.reason});
  factory _SkippedWorkflowPlan.fromJson(Map<String, dynamic> json) => _$SkippedWorkflowPlanFromJson(json);

@override final  String owner;
@override final  String repo;
@override final  String workflowName;
@override final  String workflowFileName;
@override final  String teamId;
@override final  String commitSha;
@override final  String installationId;
@override final  String reason;

/// Create a copy of SkippedWorkflowPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SkippedWorkflowPlanCopyWith<_SkippedWorkflowPlan> get copyWith => __$SkippedWorkflowPlanCopyWithImpl<_SkippedWorkflowPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkippedWorkflowPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SkippedWorkflowPlan&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,owner,repo,workflowName,workflowFileName,teamId,commitSha,installationId,reason);

@override
String toString() {
  return 'SkippedWorkflowPlan(owner: $owner, repo: $repo, workflowName: $workflowName, workflowFileName: $workflowFileName, teamId: $teamId, commitSha: $commitSha, installationId: $installationId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$SkippedWorkflowPlanCopyWith<$Res> implements $SkippedWorkflowPlanCopyWith<$Res> {
  factory _$SkippedWorkflowPlanCopyWith(_SkippedWorkflowPlan value, $Res Function(_SkippedWorkflowPlan) _then) = __$SkippedWorkflowPlanCopyWithImpl;
@override @useResult
$Res call({
 String owner, String repo, String workflowName, String workflowFileName, String teamId, String commitSha, String installationId, String reason
});




}
/// @nodoc
class __$SkippedWorkflowPlanCopyWithImpl<$Res>
    implements _$SkippedWorkflowPlanCopyWith<$Res> {
  __$SkippedWorkflowPlanCopyWithImpl(this._self, this._then);

  final _SkippedWorkflowPlan _self;
  final $Res Function(_SkippedWorkflowPlan) _then;

/// Create a copy of SkippedWorkflowPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? repo = null,Object? workflowName = null,Object? workflowFileName = null,Object? teamId = null,Object? commitSha = null,Object? installationId = null,Object? reason = null,}) {
  return _then(_SkippedWorkflowPlan(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,workflowFileName: null == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as String,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
