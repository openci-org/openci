// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_editor_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkflowEditorState {

 String get workflowId; String get orgId; String get dbName; String get yamlRaw; YamlWorkflow get parsedWorkflow; String? get parseError; String get repository; String get branch; String get filePath; String? get commitSha;
/// Create a copy of WorkflowEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowEditorStateCopyWith<WorkflowEditorState> get copyWith => _$WorkflowEditorStateCopyWithImpl<WorkflowEditorState>(this as WorkflowEditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowEditorState&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.dbName, dbName) || other.dbName == dbName)&&(identical(other.yamlRaw, yamlRaw) || other.yamlRaw == yamlRaw)&&(identical(other.parsedWorkflow, parsedWorkflow) || other.parsedWorkflow == parsedWorkflow)&&(identical(other.parseError, parseError) || other.parseError == parseError)&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha));
}


@override
int get hashCode => Object.hash(runtimeType,workflowId,orgId,dbName,yamlRaw,parsedWorkflow,parseError,repository,branch,filePath,commitSha);

@override
String toString() {
  return 'WorkflowEditorState(workflowId: $workflowId, orgId: $orgId, dbName: $dbName, yamlRaw: $yamlRaw, parsedWorkflow: $parsedWorkflow, parseError: $parseError, repository: $repository, branch: $branch, filePath: $filePath, commitSha: $commitSha)';
}


}

/// @nodoc
abstract mixin class $WorkflowEditorStateCopyWith<$Res>  {
  factory $WorkflowEditorStateCopyWith(WorkflowEditorState value, $Res Function(WorkflowEditorState) _then) = _$WorkflowEditorStateCopyWithImpl;
@useResult
$Res call({
 String workflowId, String orgId, String dbName, String yamlRaw, YamlWorkflow parsedWorkflow, String? parseError, String repository, String branch, String filePath, String? commitSha
});


$YamlWorkflowCopyWith<$Res> get parsedWorkflow;

}
/// @nodoc
class _$WorkflowEditorStateCopyWithImpl<$Res>
    implements $WorkflowEditorStateCopyWith<$Res> {
  _$WorkflowEditorStateCopyWithImpl(this._self, this._then);

  final WorkflowEditorState _self;
  final $Res Function(WorkflowEditorState) _then;

/// Create a copy of WorkflowEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workflowId = null,Object? orgId = null,Object? dbName = null,Object? yamlRaw = null,Object? parsedWorkflow = null,Object? parseError = freezed,Object? repository = null,Object? branch = null,Object? filePath = null,Object? commitSha = freezed,}) {
  return _then(_self.copyWith(
workflowId: null == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,dbName: null == dbName ? _self.dbName : dbName // ignore: cast_nullable_to_non_nullable
as String,yamlRaw: null == yamlRaw ? _self.yamlRaw : yamlRaw // ignore: cast_nullable_to_non_nullable
as String,parsedWorkflow: null == parsedWorkflow ? _self.parsedWorkflow : parsedWorkflow // ignore: cast_nullable_to_non_nullable
as YamlWorkflow,parseError: freezed == parseError ? _self.parseError : parseError // ignore: cast_nullable_to_non_nullable
as String?,repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WorkflowEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlWorkflowCopyWith<$Res> get parsedWorkflow {
  
  return $YamlWorkflowCopyWith<$Res>(_self.parsedWorkflow, (value) {
    return _then(_self.copyWith(parsedWorkflow: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkflowEditorState].
extension WorkflowEditorStatePatterns on WorkflowEditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowEditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowEditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowEditorState value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowEditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowEditorState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowEditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String workflowId,  String orgId,  String dbName,  String yamlRaw,  YamlWorkflow parsedWorkflow,  String? parseError,  String repository,  String branch,  String filePath,  String? commitSha)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowEditorState() when $default != null:
return $default(_that.workflowId,_that.orgId,_that.dbName,_that.yamlRaw,_that.parsedWorkflow,_that.parseError,_that.repository,_that.branch,_that.filePath,_that.commitSha);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String workflowId,  String orgId,  String dbName,  String yamlRaw,  YamlWorkflow parsedWorkflow,  String? parseError,  String repository,  String branch,  String filePath,  String? commitSha)  $default,) {final _that = this;
switch (_that) {
case _WorkflowEditorState():
return $default(_that.workflowId,_that.orgId,_that.dbName,_that.yamlRaw,_that.parsedWorkflow,_that.parseError,_that.repository,_that.branch,_that.filePath,_that.commitSha);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String workflowId,  String orgId,  String dbName,  String yamlRaw,  YamlWorkflow parsedWorkflow,  String? parseError,  String repository,  String branch,  String filePath,  String? commitSha)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowEditorState() when $default != null:
return $default(_that.workflowId,_that.orgId,_that.dbName,_that.yamlRaw,_that.parsedWorkflow,_that.parseError,_that.repository,_that.branch,_that.filePath,_that.commitSha);case _:
  return null;

}
}

}

/// @nodoc


class _WorkflowEditorState implements WorkflowEditorState {
  const _WorkflowEditorState({required this.workflowId, required this.orgId, required this.dbName, required this.yamlRaw, required this.parsedWorkflow, this.parseError, required this.repository, required this.branch, required this.filePath, this.commitSha});
  

@override final  String workflowId;
@override final  String orgId;
@override final  String dbName;
@override final  String yamlRaw;
@override final  YamlWorkflow parsedWorkflow;
@override final  String? parseError;
@override final  String repository;
@override final  String branch;
@override final  String filePath;
@override final  String? commitSha;

/// Create a copy of WorkflowEditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowEditorStateCopyWith<_WorkflowEditorState> get copyWith => __$WorkflowEditorStateCopyWithImpl<_WorkflowEditorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowEditorState&&(identical(other.workflowId, workflowId) || other.workflowId == workflowId)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.dbName, dbName) || other.dbName == dbName)&&(identical(other.yamlRaw, yamlRaw) || other.yamlRaw == yamlRaw)&&(identical(other.parsedWorkflow, parsedWorkflow) || other.parsedWorkflow == parsedWorkflow)&&(identical(other.parseError, parseError) || other.parseError == parseError)&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha));
}


@override
int get hashCode => Object.hash(runtimeType,workflowId,orgId,dbName,yamlRaw,parsedWorkflow,parseError,repository,branch,filePath,commitSha);

@override
String toString() {
  return 'WorkflowEditorState(workflowId: $workflowId, orgId: $orgId, dbName: $dbName, yamlRaw: $yamlRaw, parsedWorkflow: $parsedWorkflow, parseError: $parseError, repository: $repository, branch: $branch, filePath: $filePath, commitSha: $commitSha)';
}


}

/// @nodoc
abstract mixin class _$WorkflowEditorStateCopyWith<$Res> implements $WorkflowEditorStateCopyWith<$Res> {
  factory _$WorkflowEditorStateCopyWith(_WorkflowEditorState value, $Res Function(_WorkflowEditorState) _then) = __$WorkflowEditorStateCopyWithImpl;
@override @useResult
$Res call({
 String workflowId, String orgId, String dbName, String yamlRaw, YamlWorkflow parsedWorkflow, String? parseError, String repository, String branch, String filePath, String? commitSha
});


@override $YamlWorkflowCopyWith<$Res> get parsedWorkflow;

}
/// @nodoc
class __$WorkflowEditorStateCopyWithImpl<$Res>
    implements _$WorkflowEditorStateCopyWith<$Res> {
  __$WorkflowEditorStateCopyWithImpl(this._self, this._then);

  final _WorkflowEditorState _self;
  final $Res Function(_WorkflowEditorState) _then;

/// Create a copy of WorkflowEditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workflowId = null,Object? orgId = null,Object? dbName = null,Object? yamlRaw = null,Object? parsedWorkflow = null,Object? parseError = freezed,Object? repository = null,Object? branch = null,Object? filePath = null,Object? commitSha = freezed,}) {
  return _then(_WorkflowEditorState(
workflowId: null == workflowId ? _self.workflowId : workflowId // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,dbName: null == dbName ? _self.dbName : dbName // ignore: cast_nullable_to_non_nullable
as String,yamlRaw: null == yamlRaw ? _self.yamlRaw : yamlRaw // ignore: cast_nullable_to_non_nullable
as String,parsedWorkflow: null == parsedWorkflow ? _self.parsedWorkflow : parsedWorkflow // ignore: cast_nullable_to_non_nullable
as YamlWorkflow,parseError: freezed == parseError ? _self.parseError : parseError // ignore: cast_nullable_to_non_nullable
as String?,repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WorkflowEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$YamlWorkflowCopyWith<$Res> get parsedWorkflow {
  
  return $YamlWorkflowCopyWith<$Res>(_self.parsedWorkflow, (value) {
    return _then(_self.copyWith(parsedWorkflow: value));
  });
}
}

// dart format on
