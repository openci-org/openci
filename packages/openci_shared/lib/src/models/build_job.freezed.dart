// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'build_job.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildJob {

 String get id; BuildJobStatus get status; String get owner; String get repo; String get workflowName; String? get teamId; String? get workflowId; String? get workflowFileName; String? get commitSha; String? get commitMessage; int? get pullRequestNumber; int? get runCount; String? get latestRunId; String? get tagName; String? get branch; String? get jobKey; String? get workflowJobKey; Map<String, Object?>? get matrix; String? get matrixLabel; String? get workflowRunId; List<String>? get needs; String? get runsOn; String? get failureSummary; String? get failureSummaryModel; String? get failureSummaryStatus; int? get failureSummaryDurationMs; List<String>? get provisionedUdids; String? get ipaUrl; bool? get hasIpa; String? get bundleId; String? get ipaVersion; String? get appName; String? get githubBaseUrl; String? get vmName; String? get workerHost;@DateTimeConverter() DateTime get createdAt;@DateTimeConverter() DateTime get updatedAt;@DateTimeConverter() DateTime? get completedAt;
/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildJobCopyWith<BuildJob> get copyWith => _$BuildJobCopyWithImpl<BuildJob>(this as BuildJob, _$identity);

  /// Serializes this BuildJob to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.runCount, runCount) || other.runCount == runCount)&&(identical(other.latestRunId, latestRunId) || other.latestRunId == latestRunId)&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.jobKey, jobKey) || other.jobKey == jobKey)&&(identical(other.workflowJobKey, workflowJobKey) || other.workflowJobKey == workflowJobKey)&&const DeepCollectionEquality().equals(other.matrix, matrix)&&(identical(other.matrixLabel, matrixLabel) || other.matrixLabel == matrixLabel)&&(identical(other.workflowRunId, workflowRunId) || other.workflowRunId == workflowRunId)&&const DeepCollectionEquality().equals(other.needs, needs)&&(identical(other.runsOn, runsOn) || other.runsOn == runsOn)&&(identical(other.failureSummary, failureSummary) || other.failureSummary == failureSummary)&&(identical(other.failureSummaryModel, failureSummaryModel) || other.failureSummaryModel == failureSummaryModel)&&(identical(other.failureSummaryStatus, failureSummaryStatus) || other.failureSummaryStatus == failureSummaryStatus)&&(identical(other.failureSummaryDurationMs, failureSummaryDurationMs) || other.failureSummaryDurationMs == failureSummaryDurationMs)&&const DeepCollectionEquality().equals(other.provisionedUdids, provisionedUdids)&&(identical(other.ipaUrl, ipaUrl) || other.ipaUrl == ipaUrl)&&(identical(other.hasIpa, hasIpa) || other.hasIpa == hasIpa)&&(identical(other.bundleId, bundleId) || other.bundleId == bundleId)&&(identical(other.ipaVersion, ipaVersion) || other.ipaVersion == ipaVersion)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.githubBaseUrl, githubBaseUrl) || other.githubBaseUrl == githubBaseUrl)&&(identical(other.vmName, vmName) || other.vmName == vmName)&&(identical(other.workerHost, workerHost) || other.workerHost == workerHost)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,owner,repo,workflowName,teamId,workflowId,workflowFileName,commitSha,commitMessage,pullRequestNumber,runCount,latestRunId,tagName,branch,jobKey,workflowJobKey,const DeepCollectionEquality().hash(matrix),matrixLabel,workflowRunId,const DeepCollectionEquality().hash(needs),runsOn,failureSummary,failureSummaryModel,failureSummaryStatus,failureSummaryDurationMs,const DeepCollectionEquality().hash(provisionedUdids),ipaUrl,hasIpa,bundleId,ipaVersion,appName,githubBaseUrl,vmName,workerHost,createdAt,updatedAt,completedAt]);

@override
String toString() {
  return 'BuildJob(id: $id, status: $status, owner: $owner, repo: $repo, workflowName: $workflowName, teamId: $teamId, workflowId: $workflowId, workflowFileName: $workflowFileName, commitSha: $commitSha, commitMessage: $commitMessage, pullRequestNumber: $pullRequestNumber, runCount: $runCount, latestRunId: $latestRunId, tagName: $tagName, branch: $branch, jobKey: $jobKey, workflowJobKey: $workflowJobKey, matrix: $matrix, matrixLabel: $matrixLabel, workflowRunId: $workflowRunId, needs: $needs, runsOn: $runsOn, failureSummary: $failureSummary, failureSummaryModel: $failureSummaryModel, failureSummaryStatus: $failureSummaryStatus, failureSummaryDurationMs: $failureSummaryDurationMs, provisionedUdids: $provisionedUdids, ipaUrl: $ipaUrl, hasIpa: $hasIpa, bundleId: $bundleId, ipaVersion: $ipaVersion, appName: $appName, githubBaseUrl: $githubBaseUrl, vmName: $vmName, workerHost: $workerHost, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $BuildJobCopyWith<$Res>  {
  factory $BuildJobCopyWith(BuildJob value, $Res Function(BuildJob) _then) = _$BuildJobCopyWithImpl;
@useResult
$Res call({
 String id, BuildJobStatus status, String owner, String repo, String workflowName, String? teamId, String? workflowId, String? workflowFileName, String? commitSha, String? commitMessage, int? pullRequestNumber, int? runCount, String? latestRunId, String? tagName, String? branch, String? jobKey, String? workflowJobKey, Map<String, Object?>? matrix, String? matrixLabel, String? workflowRunId, List<String>? needs, String? runsOn, String? failureSummary, String? failureSummaryModel, String? failureSummaryStatus, int? failureSummaryDurationMs, List<String>? provisionedUdids, String? ipaUrl, bool? hasIpa, String? bundleId, String? ipaVersion, String? appName, String? githubBaseUrl, String? vmName, String? workerHost,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt,@DateTimeConverter() DateTime? completedAt
});




}
/// @nodoc
class _$BuildJobCopyWithImpl<$Res>
    implements $BuildJobCopyWith<$Res> {
  _$BuildJobCopyWithImpl(this._self, this._then);

  final BuildJob _self;
  final $Res Function(BuildJob) _then;

/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? owner = null,Object? repo = null,Object? workflowName = null,Object? teamId = freezed,Object? workflowId = freezed,Object? workflowFileName = freezed,Object? commitSha = freezed,Object? commitMessage = freezed,Object? pullRequestNumber = freezed,Object? runCount = freezed,Object? latestRunId = freezed,Object? tagName = freezed,Object? branch = freezed,Object? jobKey = freezed,Object? workflowJobKey = freezed,Object? matrix = freezed,Object? matrixLabel = freezed,Object? workflowRunId = freezed,Object? needs = freezed,Object? runsOn = freezed,Object? failureSummary = freezed,Object? failureSummaryModel = freezed,Object? failureSummaryStatus = freezed,Object? failureSummaryDurationMs = freezed,Object? provisionedUdids = freezed,Object? ipaUrl = freezed,Object? hasIpa = freezed,Object? bundleId = freezed,Object? ipaVersion = freezed,Object? appName = freezed,Object? githubBaseUrl = freezed,Object? vmName = freezed,Object? workerHost = freezed,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,workflowId: freezed == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as String?,workflowFileName: freezed == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String?,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,runCount: freezed == runCount ? _self.runCount : runCount // ignore: cast_nullable_to_non_nullable
as int?,latestRunId: freezed == latestRunId ? _self.latestRunId : latestRunId // ignore: cast_nullable_to_non_nullable
as String?,tagName: freezed == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String?,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String?,jobKey: freezed == jobKey ? _self.jobKey : jobKey // ignore: cast_nullable_to_non_nullable
as String?,workflowJobKey: freezed == workflowJobKey ? _self.workflowJobKey : workflowJobKey // ignore: cast_nullable_to_non_nullable
as String?,matrix: freezed == matrix ? _self.matrix : matrix // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,matrixLabel: freezed == matrixLabel ? _self.matrixLabel : matrixLabel // ignore: cast_nullable_to_non_nullable
as String?,workflowRunId: freezed == workflowRunId ? _self.workflowRunId : workflowRunId // ignore: cast_nullable_to_non_nullable
as String?,needs: freezed == needs ? _self.needs : needs // ignore: cast_nullable_to_non_nullable
as List<String>?,runsOn: freezed == runsOn ? _self.runsOn : runsOn // ignore: cast_nullable_to_non_nullable
as String?,failureSummary: freezed == failureSummary ? _self.failureSummary : failureSummary // ignore: cast_nullable_to_non_nullable
as String?,failureSummaryModel: freezed == failureSummaryModel ? _self.failureSummaryModel : failureSummaryModel // ignore: cast_nullable_to_non_nullable
as String?,failureSummaryStatus: freezed == failureSummaryStatus ? _self.failureSummaryStatus : failureSummaryStatus // ignore: cast_nullable_to_non_nullable
as String?,failureSummaryDurationMs: freezed == failureSummaryDurationMs ? _self.failureSummaryDurationMs : failureSummaryDurationMs // ignore: cast_nullable_to_non_nullable
as int?,provisionedUdids: freezed == provisionedUdids ? _self.provisionedUdids : provisionedUdids // ignore: cast_nullable_to_non_nullable
as List<String>?,ipaUrl: freezed == ipaUrl ? _self.ipaUrl : ipaUrl // ignore: cast_nullable_to_non_nullable
as String?,hasIpa: freezed == hasIpa ? _self.hasIpa : hasIpa // ignore: cast_nullable_to_non_nullable
as bool?,bundleId: freezed == bundleId ? _self.bundleId : bundleId // ignore: cast_nullable_to_non_nullable
as String?,ipaVersion: freezed == ipaVersion ? _self.ipaVersion : ipaVersion // ignore: cast_nullable_to_non_nullable
as String?,appName: freezed == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String?,githubBaseUrl: freezed == githubBaseUrl ? _self.githubBaseUrl : githubBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,vmName: freezed == vmName ? _self.vmName : vmName // ignore: cast_nullable_to_non_nullable
as String?,workerHost: freezed == workerHost ? _self.workerHost : workerHost // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildJob].
extension BuildJobPatterns on BuildJob {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildJob value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildJob value)  $default,){
final _that = this;
switch (_that) {
case _BuildJob():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildJob value)?  $default,){
final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  BuildJobStatus status,  String owner,  String repo,  String workflowName,  String? teamId,  String? workflowId,  String? workflowFileName,  String? commitSha,  String? commitMessage,  int? pullRequestNumber,  int? runCount,  String? latestRunId,  String? tagName,  String? branch,  String? jobKey,  String? workflowJobKey,  Map<String, Object?>? matrix,  String? matrixLabel,  String? workflowRunId,  List<String>? needs,  String? runsOn,  String? failureSummary,  String? failureSummaryModel,  String? failureSummaryStatus,  int? failureSummaryDurationMs,  List<String>? provisionedUdids,  String? ipaUrl,  bool? hasIpa,  String? bundleId,  String? ipaVersion,  String? appName,  String? githubBaseUrl,  String? vmName,  String? workerHost, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt, @DateTimeConverter()  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
return $default(_that.id,_that.status,_that.owner,_that.repo,_that.workflowName,_that.teamId,_that.workflowId,_that.workflowFileName,_that.commitSha,_that.commitMessage,_that.pullRequestNumber,_that.runCount,_that.latestRunId,_that.tagName,_that.branch,_that.jobKey,_that.workflowJobKey,_that.matrix,_that.matrixLabel,_that.workflowRunId,_that.needs,_that.runsOn,_that.failureSummary,_that.failureSummaryModel,_that.failureSummaryStatus,_that.failureSummaryDurationMs,_that.provisionedUdids,_that.ipaUrl,_that.hasIpa,_that.bundleId,_that.ipaVersion,_that.appName,_that.githubBaseUrl,_that.vmName,_that.workerHost,_that.createdAt,_that.updatedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  BuildJobStatus status,  String owner,  String repo,  String workflowName,  String? teamId,  String? workflowId,  String? workflowFileName,  String? commitSha,  String? commitMessage,  int? pullRequestNumber,  int? runCount,  String? latestRunId,  String? tagName,  String? branch,  String? jobKey,  String? workflowJobKey,  Map<String, Object?>? matrix,  String? matrixLabel,  String? workflowRunId,  List<String>? needs,  String? runsOn,  String? failureSummary,  String? failureSummaryModel,  String? failureSummaryStatus,  int? failureSummaryDurationMs,  List<String>? provisionedUdids,  String? ipaUrl,  bool? hasIpa,  String? bundleId,  String? ipaVersion,  String? appName,  String? githubBaseUrl,  String? vmName,  String? workerHost, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt, @DateTimeConverter()  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _BuildJob():
return $default(_that.id,_that.status,_that.owner,_that.repo,_that.workflowName,_that.teamId,_that.workflowId,_that.workflowFileName,_that.commitSha,_that.commitMessage,_that.pullRequestNumber,_that.runCount,_that.latestRunId,_that.tagName,_that.branch,_that.jobKey,_that.workflowJobKey,_that.matrix,_that.matrixLabel,_that.workflowRunId,_that.needs,_that.runsOn,_that.failureSummary,_that.failureSummaryModel,_that.failureSummaryStatus,_that.failureSummaryDurationMs,_that.provisionedUdids,_that.ipaUrl,_that.hasIpa,_that.bundleId,_that.ipaVersion,_that.appName,_that.githubBaseUrl,_that.vmName,_that.workerHost,_that.createdAt,_that.updatedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  BuildJobStatus status,  String owner,  String repo,  String workflowName,  String? teamId,  String? workflowId,  String? workflowFileName,  String? commitSha,  String? commitMessage,  int? pullRequestNumber,  int? runCount,  String? latestRunId,  String? tagName,  String? branch,  String? jobKey,  String? workflowJobKey,  Map<String, Object?>? matrix,  String? matrixLabel,  String? workflowRunId,  List<String>? needs,  String? runsOn,  String? failureSummary,  String? failureSummaryModel,  String? failureSummaryStatus,  int? failureSummaryDurationMs,  List<String>? provisionedUdids,  String? ipaUrl,  bool? hasIpa,  String? bundleId,  String? ipaVersion,  String? appName,  String? githubBaseUrl,  String? vmName,  String? workerHost, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt, @DateTimeConverter()  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _BuildJob() when $default != null:
return $default(_that.id,_that.status,_that.owner,_that.repo,_that.workflowName,_that.teamId,_that.workflowId,_that.workflowFileName,_that.commitSha,_that.commitMessage,_that.pullRequestNumber,_that.runCount,_that.latestRunId,_that.tagName,_that.branch,_that.jobKey,_that.workflowJobKey,_that.matrix,_that.matrixLabel,_that.workflowRunId,_that.needs,_that.runsOn,_that.failureSummary,_that.failureSummaryModel,_that.failureSummaryStatus,_that.failureSummaryDurationMs,_that.provisionedUdids,_that.ipaUrl,_that.hasIpa,_that.bundleId,_that.ipaVersion,_that.appName,_that.githubBaseUrl,_that.vmName,_that.workerHost,_that.createdAt,_that.updatedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildJob extends BuildJob {
  const _BuildJob({required this.id, required this.status, required this.owner, required this.repo, required this.workflowName, this.teamId, this.workflowId, this.workflowFileName, this.commitSha, this.commitMessage, this.pullRequestNumber, this.runCount, this.latestRunId, this.tagName, this.branch, this.jobKey, this.workflowJobKey, final  Map<String, Object?>? matrix, this.matrixLabel, this.workflowRunId, final  List<String>? needs, this.runsOn, this.failureSummary, this.failureSummaryModel, this.failureSummaryStatus, this.failureSummaryDurationMs, final  List<String>? provisionedUdids, this.ipaUrl, this.hasIpa, this.bundleId, this.ipaVersion, this.appName, this.githubBaseUrl, this.vmName, this.workerHost, @DateTimeConverter() required this.createdAt, @DateTimeConverter() required this.updatedAt, @DateTimeConverter() this.completedAt}): _matrix = matrix,_needs = needs,_provisionedUdids = provisionedUdids,super._();
  factory _BuildJob.fromJson(Map<String, dynamic> json) => _$BuildJobFromJson(json);

@override final  String id;
@override final  BuildJobStatus status;
@override final  String owner;
@override final  String repo;
@override final  String workflowName;
@override final  String? teamId;
@override final  String? workflowId;
@override final  String? workflowFileName;
@override final  String? commitSha;
@override final  String? commitMessage;
@override final  int? pullRequestNumber;
@override final  int? runCount;
@override final  String? latestRunId;
@override final  String? tagName;
@override final  String? branch;
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

@override final  String? runsOn;
@override final  String? failureSummary;
@override final  String? failureSummaryModel;
@override final  String? failureSummaryStatus;
@override final  int? failureSummaryDurationMs;
 final  List<String>? _provisionedUdids;
@override List<String>? get provisionedUdids {
  final value = _provisionedUdids;
  if (value == null) return null;
  if (_provisionedUdids is EqualUnmodifiableListView) return _provisionedUdids;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? ipaUrl;
@override final  bool? hasIpa;
@override final  String? bundleId;
@override final  String? ipaVersion;
@override final  String? appName;
@override final  String? githubBaseUrl;
@override final  String? vmName;
@override final  String? workerHost;
@override@DateTimeConverter() final  DateTime createdAt;
@override@DateTimeConverter() final  DateTime updatedAt;
@override@DateTimeConverter() final  DateTime? completedAt;

/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildJobCopyWith<_BuildJob> get copyWith => __$BuildJobCopyWithImpl<_BuildJob>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildJobToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildJob&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.repo, repo) || other.repo == repo)&&(identical(other.workflowName, workflowName) || other.workflowName == workflowName)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.workflowFileName, workflowFileName) || other.workflowFileName == workflowFileName)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.pullRequestNumber, pullRequestNumber) || other.pullRequestNumber == pullRequestNumber)&&(identical(other.runCount, runCount) || other.runCount == runCount)&&(identical(other.latestRunId, latestRunId) || other.latestRunId == latestRunId)&&(identical(other.tagName, tagName) || other.tagName == tagName)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.jobKey, jobKey) || other.jobKey == jobKey)&&(identical(other.workflowJobKey, workflowJobKey) || other.workflowJobKey == workflowJobKey)&&const DeepCollectionEquality().equals(other._matrix, _matrix)&&(identical(other.matrixLabel, matrixLabel) || other.matrixLabel == matrixLabel)&&(identical(other.workflowRunId, workflowRunId) || other.workflowRunId == workflowRunId)&&const DeepCollectionEquality().equals(other._needs, _needs)&&(identical(other.runsOn, runsOn) || other.runsOn == runsOn)&&(identical(other.failureSummary, failureSummary) || other.failureSummary == failureSummary)&&(identical(other.failureSummaryModel, failureSummaryModel) || other.failureSummaryModel == failureSummaryModel)&&(identical(other.failureSummaryStatus, failureSummaryStatus) || other.failureSummaryStatus == failureSummaryStatus)&&(identical(other.failureSummaryDurationMs, failureSummaryDurationMs) || other.failureSummaryDurationMs == failureSummaryDurationMs)&&const DeepCollectionEquality().equals(other._provisionedUdids, _provisionedUdids)&&(identical(other.ipaUrl, ipaUrl) || other.ipaUrl == ipaUrl)&&(identical(other.hasIpa, hasIpa) || other.hasIpa == hasIpa)&&(identical(other.bundleId, bundleId) || other.bundleId == bundleId)&&(identical(other.ipaVersion, ipaVersion) || other.ipaVersion == ipaVersion)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.githubBaseUrl, githubBaseUrl) || other.githubBaseUrl == githubBaseUrl)&&(identical(other.vmName, vmName) || other.vmName == vmName)&&(identical(other.workerHost, workerHost) || other.workerHost == workerHost)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,status,owner,repo,workflowName,teamId,workflowId,workflowFileName,commitSha,commitMessage,pullRequestNumber,runCount,latestRunId,tagName,branch,jobKey,workflowJobKey,const DeepCollectionEquality().hash(_matrix),matrixLabel,workflowRunId,const DeepCollectionEquality().hash(_needs),runsOn,failureSummary,failureSummaryModel,failureSummaryStatus,failureSummaryDurationMs,const DeepCollectionEquality().hash(_provisionedUdids),ipaUrl,hasIpa,bundleId,ipaVersion,appName,githubBaseUrl,vmName,workerHost,createdAt,updatedAt,completedAt]);

@override
String toString() {
  return 'BuildJob(id: $id, status: $status, owner: $owner, repo: $repo, workflowName: $workflowName, teamId: $teamId, workflowId: $workflowId, workflowFileName: $workflowFileName, commitSha: $commitSha, commitMessage: $commitMessage, pullRequestNumber: $pullRequestNumber, runCount: $runCount, latestRunId: $latestRunId, tagName: $tagName, branch: $branch, jobKey: $jobKey, workflowJobKey: $workflowJobKey, matrix: $matrix, matrixLabel: $matrixLabel, workflowRunId: $workflowRunId, needs: $needs, runsOn: $runsOn, failureSummary: $failureSummary, failureSummaryModel: $failureSummaryModel, failureSummaryStatus: $failureSummaryStatus, failureSummaryDurationMs: $failureSummaryDurationMs, provisionedUdids: $provisionedUdids, ipaUrl: $ipaUrl, hasIpa: $hasIpa, bundleId: $bundleId, ipaVersion: $ipaVersion, appName: $appName, githubBaseUrl: $githubBaseUrl, vmName: $vmName, workerHost: $workerHost, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$BuildJobCopyWith<$Res> implements $BuildJobCopyWith<$Res> {
  factory _$BuildJobCopyWith(_BuildJob value, $Res Function(_BuildJob) _then) = __$BuildJobCopyWithImpl;
@override @useResult
$Res call({
 String id, BuildJobStatus status, String owner, String repo, String workflowName, String? teamId, String? workflowId, String? workflowFileName, String? commitSha, String? commitMessage, int? pullRequestNumber, int? runCount, String? latestRunId, String? tagName, String? branch, String? jobKey, String? workflowJobKey, Map<String, Object?>? matrix, String? matrixLabel, String? workflowRunId, List<String>? needs, String? runsOn, String? failureSummary, String? failureSummaryModel, String? failureSummaryStatus, int? failureSummaryDurationMs, List<String>? provisionedUdids, String? ipaUrl, bool? hasIpa, String? bundleId, String? ipaVersion, String? appName, String? githubBaseUrl, String? vmName, String? workerHost,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt,@DateTimeConverter() DateTime? completedAt
});




}
/// @nodoc
class __$BuildJobCopyWithImpl<$Res>
    implements _$BuildJobCopyWith<$Res> {
  __$BuildJobCopyWithImpl(this._self, this._then);

  final _BuildJob _self;
  final $Res Function(_BuildJob) _then;

/// Create a copy of BuildJob
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? owner = null,Object? repo = null,Object? workflowName = null,Object? teamId = freezed,Object? workflowId = freezed,Object? workflowFileName = freezed,Object? commitSha = freezed,Object? commitMessage = freezed,Object? pullRequestNumber = freezed,Object? runCount = freezed,Object? latestRunId = freezed,Object? tagName = freezed,Object? branch = freezed,Object? jobKey = freezed,Object? workflowJobKey = freezed,Object? matrix = freezed,Object? matrixLabel = freezed,Object? workflowRunId = freezed,Object? needs = freezed,Object? runsOn = freezed,Object? failureSummary = freezed,Object? failureSummaryModel = freezed,Object? failureSummaryStatus = freezed,Object? failureSummaryDurationMs = freezed,Object? provisionedUdids = freezed,Object? ipaUrl = freezed,Object? hasIpa = freezed,Object? bundleId = freezed,Object? ipaVersion = freezed,Object? appName = freezed,Object? githubBaseUrl = freezed,Object? vmName = freezed,Object? workerHost = freezed,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,}) {
  return _then(_BuildJob(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as String,repo: null == repo ? _self.repo : repo // ignore: cast_nullable_to_non_nullable
as String,workflowName: null == workflowName ? _self.workflowName : workflowName // ignore: cast_nullable_to_non_nullable
as String,teamId: freezed == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String?,workflowId: freezed == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as String?,workflowFileName: freezed == workflowFileName ? _self.workflowFileName : workflowFileName // ignore: cast_nullable_to_non_nullable
as String?,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,commitMessage: freezed == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String?,pullRequestNumber: freezed == pullRequestNumber ? _self.pullRequestNumber : pullRequestNumber // ignore: cast_nullable_to_non_nullable
as int?,runCount: freezed == runCount ? _self.runCount : runCount // ignore: cast_nullable_to_non_nullable
as int?,latestRunId: freezed == latestRunId ? _self.latestRunId : latestRunId // ignore: cast_nullable_to_non_nullable
as String?,tagName: freezed == tagName ? _self.tagName : tagName // ignore: cast_nullable_to_non_nullable
as String?,branch: freezed == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String?,jobKey: freezed == jobKey ? _self.jobKey : jobKey // ignore: cast_nullable_to_non_nullable
as String?,workflowJobKey: freezed == workflowJobKey ? _self.workflowJobKey : workflowJobKey // ignore: cast_nullable_to_non_nullable
as String?,matrix: freezed == matrix ? _self._matrix : matrix // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,matrixLabel: freezed == matrixLabel ? _self.matrixLabel : matrixLabel // ignore: cast_nullable_to_non_nullable
as String?,workflowRunId: freezed == workflowRunId ? _self.workflowRunId : workflowRunId // ignore: cast_nullable_to_non_nullable
as String?,needs: freezed == needs ? _self._needs : needs // ignore: cast_nullable_to_non_nullable
as List<String>?,runsOn: freezed == runsOn ? _self.runsOn : runsOn // ignore: cast_nullable_to_non_nullable
as String?,failureSummary: freezed == failureSummary ? _self.failureSummary : failureSummary // ignore: cast_nullable_to_non_nullable
as String?,failureSummaryModel: freezed == failureSummaryModel ? _self.failureSummaryModel : failureSummaryModel // ignore: cast_nullable_to_non_nullable
as String?,failureSummaryStatus: freezed == failureSummaryStatus ? _self.failureSummaryStatus : failureSummaryStatus // ignore: cast_nullable_to_non_nullable
as String?,failureSummaryDurationMs: freezed == failureSummaryDurationMs ? _self.failureSummaryDurationMs : failureSummaryDurationMs // ignore: cast_nullable_to_non_nullable
as int?,provisionedUdids: freezed == provisionedUdids ? _self._provisionedUdids : provisionedUdids // ignore: cast_nullable_to_non_nullable
as List<String>?,ipaUrl: freezed == ipaUrl ? _self.ipaUrl : ipaUrl // ignore: cast_nullable_to_non_nullable
as String?,hasIpa: freezed == hasIpa ? _self.hasIpa : hasIpa // ignore: cast_nullable_to_non_nullable
as bool?,bundleId: freezed == bundleId ? _self.bundleId : bundleId // ignore: cast_nullable_to_non_nullable
as String?,ipaVersion: freezed == ipaVersion ? _self.ipaVersion : ipaVersion // ignore: cast_nullable_to_non_nullable
as String?,appName: freezed == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String?,githubBaseUrl: freezed == githubBaseUrl ? _self.githubBaseUrl : githubBaseUrl // ignore: cast_nullable_to_non_nullable
as String?,vmName: freezed == vmName ? _self.vmName : vmName // ignore: cast_nullable_to_non_nullable
as String?,workerHost: freezed == workerHost ? _self.workerHost : workerHost // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
