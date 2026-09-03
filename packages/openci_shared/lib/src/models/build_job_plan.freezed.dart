// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'build_job_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildJobPlan {

 String get owner; String get repo; String get workflowName; String get workflowFileName; String get teamId; String get commitSha; String get branch; String get runsOn; String get githubBaseUrl; String get installationId; String? get workflowId; String? get commitMessage; int? get pullRequestNumber; String? get tagName; String? get jobKey; String? get workflowJobKey; Map<String, Object?>? get matrix; String? get matrixLabel; String? get workflowRunId; List<String>? get needs;
/// Create a copy of BuildJobPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildJobPlanCopyWith<BuildJobPlan> get copyWith => _$BuildJobPlanCopyWithImpl<BuildJobPlan>(this as BuildJobPlan, _$identity);

  /// Serializes this BuildJobPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildJobPlan&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.runsOn, runsOn) || other.runsOn == runsOn)&&(identical(other.githubBaseUrl, githubBaseUrl) || other.githubBaseUrl == githubBaseUrl)&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.jobKey, jobKey) || other.jobKey == jobKey)&&(identical(other.workflowJobKey, workflowJobKey) || other.workflowJobKey == workflowJobKey)&&const DeepCollectionEquality().equals(other.matrix, matrix)&&(identical(other.matrixLabel, matrixLabel) || other.matrixLabel == matrixLabel)&&(identical(other.workflowRunId, workflowRunId) || other.workflowRunId == workflowRunId)&&const DeepCollectionEquality().equals(other.needs, needs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,owner,repo,workflowName,workflowFileName,teamId,commitSha,branch,runsOn,githubBaseUrl,installationId,workflowId,commitMessage,pullRequestNumber,tagName,jobKey,workflowJobKey,const DeepCollectionEquality().hash(matrix),matrixLabel,workflowRunId,const DeepCollectionEquality().hash(needs)]);

@override
String toString() {
  return 'BuildJobPlan(owner: $owner, repo: $repo, workflowName: $workflowName, workflowFileName: $workflowFileName, teamId: $teamId, commitSha: $commitSha, branch: $branch, runsOn: $runsOn, githubBaseUrl: $githubBaseUrl, installationId: $installationId, workflowId: $workflowId, commitMessage: $commitMessage, pullRequestNumber: $pullRequestNumber, tagName: $tagName, jobKey: $jobKey, workflowJobKey: $workflowJobKey, matrix: $matrix, matrixLabel: $matrixLabel, workflowRunId: $workflowRunId, needs: $needs)';
}


}

/// @nodoc
abstract mixin class $BuildJobPlanCopyWith<$Res>  {
  factory $BuildJobPlanCopyWith(BuildJobPlan value, $Res Function(BuildJobPlan) _then) = _$BuildJobPlanCopyWithImpl;
@useResult
$Res call({
 String owner, String repo, String workflowName, String workflowFileName, String teamId, String commitSha, String branch, String runsOn, String githubBaseUrl, String installationId, String? workflowId, String? commitMessage, int? pullRequestNumber, String? tagName, String? jobKey, String? workflowJobKey, Map<String, Object?>? matrix, String? matrixLabel, String? workflowRunId, List<String>? needs
});




}
/// @nodoc
class _$BuildJobPlanCopyWithImpl<$Res>
    implements $BuildJobPlanCopyWith<$Res> {
  _$BuildJobPlanCopyWithImpl(this._self, this._then);

  final BuildJobPlan _self;
  final $Res Function(BuildJobPlan) _then;

/// Create a copy of BuildJobPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? repo = null,Object? workflowName = null,Object? workflowFileName = null,Object? teamId = null,Object? commitSha = null,Object? branch = null,Object? runsOn = null,Object? githubBaseUrl = null,Object? installationId = null,Object? workflowId = freezed,Object? commitMessage = freezed,Object? pullRequestNumber = freezed,Object? tagName = freezed,Object? jobKey = freezed,Object? workflowJobKey = freezed,Object? matrix = freezed,Object? matrixLabel = freezed,Object? workflowRunId = freezed,Object? needs = freezed,}) {
  return _then(_self.copyWith(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,workflowFileName: null == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,runsOn: null == runsOn ? _self.runsOn : runsOn // ignore: cast_nullable_to_non_nullable
as String,githubBaseUrl: null == githubBaseUrl ? _self.githubBaseUrl : githubBaseUrl // ignore: cast_nullable_to_non_nullable
as String,installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as String,workflowId: freezed == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as String?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,tagName: freezed == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String?,jobKey: freezed == jobKey ? _self.jobKey : jobKey // ignore: cast_nullable_to_non_nullable
as String?,workflowJobKey: freezed == workflowJobKey ? _self.workflowJobKey : workflowJobKey // ignore: cast_nullable_to_non_nullable
as String?,matrix: freezed == matrix ? _self.matrix : matrix // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,matrixLabel: freezed == matrixLabel ? _self.matrixLabel : matrixLabel // ignore: cast_nullable_to_non_nullable
as String?,workflowRunId: freezed == workflowRunId ? _self.workflowRunId : workflowRunId // ignore: cast_nullable_to_non_nullable
as String?,needs: freezed == needs ? _self.needs : needs // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildJobPlan].
extension BuildJobPlanPatterns on BuildJobPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildJobPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildJobPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildJobPlan value)  $default,){
final _that = this;
switch (_that) {
case _BuildJobPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildJobPlan value)?  $default,){
final _that = this;
switch (_that) {
case _BuildJobPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String owner,  String repo,  String workflowName,  String workflowFileName,  String teamId,  String commitSha,  String branch,  String runsOn,  String githubBaseUrl,  String installationId,  String? workflowId,  String? commitMessage,  int? pullRequestNumber,  String? tagName,  String? jobKey,  String? workflowJobKey,  Map<String, Object?>? matrix,  String? matrixLabel,  String? workflowRunId,  List<String>? needs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildJobPlan() when $default != null:
return $default(_that.owner,_that.repo,_that.workflowName,_that.workflowFileName,_that.teamId,_that.commitSha,_that.branch,_that.runsOn,_that.githubBaseUrl,_that.installationId,_that.workflowId,_that.commitMessage,_that.pullRequestNumber,_that.tagName,_that.jobKey,_that.workflowJobKey,_that.matrix,_that.matrixLabel,_that.workflowRunId,_that.needs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String owner,  String repo,  String workflowName,  String workflowFileName,  String teamId,  String commitSha,  String branch,  String runsOn,  String githubBaseUrl,  String installationId,  String? workflowId,  String? commitMessage,  int? pullRequestNumber,  String? tagName,  String? jobKey,  String? workflowJobKey,  Map<String, Object?>? matrix,  String? matrixLabel,  String? workflowRunId,  List<String>? needs)  $default,) {final _that = this;
switch (_that) {
case _BuildJobPlan():
return $default(_that.owner,_that.repo,_that.workflowName,_that.workflowFileName,_that.teamId,_that.commitSha,_that.branch,_that.runsOn,_that.githubBaseUrl,_that.installationId,_that.workflowId,_that.commitMessage,_that.pullRequestNumber,_that.tagName,_that.jobKey,_that.workflowJobKey,_that.matrix,_that.matrixLabel,_that.workflowRunId,_that.needs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String owner,  String repo,  String workflowName,  String workflowFileName,  String teamId,  String commitSha,  String branch,  String runsOn,  String githubBaseUrl,  String installationId,  String? workflowId,  String? commitMessage,  int? pullRequestNumber,  String? tagName,  String? jobKey,  String? workflowJobKey,  Map<String, Object?>? matrix,  String? matrixLabel,  String? workflowRunId,  List<String>? needs)?  $default,) {final _that = this;
switch (_that) {
case _BuildJobPlan() when $default != null:
return $default(_that.owner,_that.repo,_that.workflowName,_that.workflowFileName,_that.teamId,_that.commitSha,_that.branch,_that.runsOn,_that.githubBaseUrl,_that.installationId,_that.workflowId,_that.commitMessage,_that.pullRequestNumber,_that.tagName,_that.jobKey,_that.workflowJobKey,_that.matrix,_that.matrixLabel,_that.workflowRunId,_that.needs);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(disallowUnrecognizedKeys: true, includeIfNull: false)
class _BuildJobPlan implements BuildJobPlan {
  const _BuildJobPlan({required this.owner, required this.repo, required this.workflowName, required this.workflowFileName, required this.teamId, required this.commitSha, required this.branch, required this.runsOn, required this.githubBaseUrl, required this.installationId, this.workflowId, this.commitMessage, this.pullRequestNumber, this.tagName, this.jobKey, this.workflowJobKey, final  Map<String, Object?>? matrix, this.matrixLabel, this.workflowRunId, final  List<String>? needs}): _matrix = matrix,_needs = needs;
  factory _BuildJobPlan.fromJson(Map<String, dynamic> json) => _$BuildJobPlanFromJson(json);

@override final  String owner;
@override final  String repo;
@override final  String workflowName;
@override final  String workflowFileName;
@override final  String teamId;
@override final  String commitSha;
@override final  String branch;
@override final  String runsOn;
@override final  String githubBaseUrl;
@override final  String installationId;
@override final  String? workflowId;
@override final  String? commitMessage;
@override final  int? pullRequestNumber;
@override final  String? tagName;
@override final  String? jobKey;
@override final  String? workflowJobKey;
 final  Map<String, Object?>? _matrix;
@override Map<String, Object?>? get matrix {
  final value = _matrix;
  if (value == null) return null;
  if (_matrix is EqualUnmodifiableMapView) return _matrix;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? matrixLabel;
@override final  String? workflowRunId;
 final  List<String>? _needs;
@override List<String>? get needs {
  final value = _needs;
  if (value == null) return null;
  if (_needs is EqualUnmodifiableListView) return _needs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of BuildJobPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildJobPlanCopyWith<_BuildJobPlan> get copyWith => __$BuildJobPlanCopyWithImpl<_BuildJobPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildJobPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildJobPlan&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.runsOn, runsOn) || other.runsOn == runsOn)&&(identical(other.githubBaseUrl, githubBaseUrl) || other.githubBaseUrl == githubBaseUrl)&&(identical(other.installationId, installationId) || other.installationId == installationId)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.jobKey, jobKey) || other.jobKey == jobKey)&&(identical(other.workflowJobKey, workflowJobKey) || other.workflowJobKey == workflowJobKey)&&const DeepCollectionEquality().equals(other._matrix, _matrix)&&(identical(other.matrixLabel, matrixLabel) || other.matrixLabel == matrixLabel)&&(identical(other.workflowRunId, workflowRunId) || other.workflowRunId == workflowRunId)&&const DeepCollectionEquality().equals(other._needs, _needs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,owner,repo,workflowName,workflowFileName,teamId,commitSha,branch,runsOn,githubBaseUrl,installationId,workflowId,commitMessage,pullRequestNumber,tagName,jobKey,workflowJobKey,const DeepCollectionEquality().hash(_matrix),matrixLabel,workflowRunId,const DeepCollectionEquality().hash(_needs)]);

@override
String toString() {
  return 'BuildJobPlan(owner: $owner, repo: $repo, workflowName: $workflowName, workflowFileName: $workflowFileName, teamId: $teamId, commitSha: $commitSha, branch: $branch, runsOn: $runsOn, githubBaseUrl: $githubBaseUrl, installationId: $installationId, workflowId: $workflowId, commitMessage: $commitMessage, pullRequestNumber: $pullRequestNumber, tagName: $tagName, jobKey: $jobKey, workflowJobKey: $workflowJobKey, matrix: $matrix, matrixLabel: $matrixLabel, workflowRunId: $workflowRunId, needs: $needs)';
}


}

/// @nodoc
abstract mixin class _$BuildJobPlanCopyWith<$Res> implements $BuildJobPlanCopyWith<$Res> {
  factory _$BuildJobPlanCopyWith(_BuildJobPlan value, $Res Function(_BuildJobPlan) _then) = __$BuildJobPlanCopyWithImpl;
@override @useResult
$Res call({
 String owner, String repo, String workflowName, String workflowFileName, String teamId, String commitSha, String branch, String runsOn, String githubBaseUrl, String installationId, String? workflowId, String? commitMessage, int? pullRequestNumber, String? tagName, String? jobKey, String? workflowJobKey, Map<String, Object?>? matrix, String? matrixLabel, String? workflowRunId, List<String>? needs
});




}
/// @nodoc
class __$BuildJobPlanCopyWithImpl<$Res>
    implements _$BuildJobPlanCopyWith<$Res> {
  __$BuildJobPlanCopyWithImpl(this._self, this._then);

  final _BuildJobPlan _self;
  final $Res Function(_BuildJobPlan) _then;

/// Create a copy of BuildJobPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? repo = null,Object? workflowName = null,Object? workflowFileName = null,Object? teamId = null,Object? commitSha = null,Object? branch = null,Object? runsOn = null,Object? githubBaseUrl = null,Object? installationId = null,Object? workflowId = freezed,Object? commitMessage = freezed,Object? pullRequestNumber = freezed,Object? tagName = freezed,Object? jobKey = freezed,Object? workflowJobKey = freezed,Object? matrix = freezed,Object? matrixLabel = freezed,Object? workflowRunId = freezed,Object? needs = freezed,}) {
  return _then(_BuildJobPlan(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,workflowFileName: null == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,runsOn: null == runsOn ? _self.runsOn : runsOn // ignore: cast_nullable_to_non_nullable
as String,githubBaseUrl: null == githubBaseUrl ? _self.githubBaseUrl : githubBaseUrl // ignore: cast_nullable_to_non_nullable
as String,installationId: null == installationId ? _self.installationId : installationId // ignore: cast_nullable_to_non_nullable
as String,workflowId: freezed == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as String?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,tagName: freezed == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String?,jobKey: freezed == jobKey ? _self.jobKey : jobKey // ignore: cast_nullable_to_non_nullable
as String?,workflowJobKey: freezed == workflowJobKey ? _self.workflowJobKey : workflowJobKey // ignore: cast_nullable_to_non_nullable
as String?,matrix: freezed == matrix ? _self._matrix : matrix // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,matrixLabel: freezed == matrixLabel ? _self.matrixLabel : matrixLabel // ignore: cast_nullable_to_non_nullable
as String?,workflowRunId: freezed == workflowRunId ? _self.workflowRunId : workflowRunId // ignore: cast_nullable_to_non_nullable
as String?,needs: freezed == needs ? _self._needs : needs // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
