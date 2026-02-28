// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_list_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkflowListItem {

 String get id; String get name; String get orgId; String get yamlDefinition; String get triggerSummary; String get repository; String get branch; String get filePath; String? get commitSha; String? get lastBuildStatus; DateTime? get lastBuildAt;@DateTimeConverter() DateTime get createdAt;@DateTimeConverter() DateTime get updatedAt;
/// Create a copy of WorkflowListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowListItemCopyWith<WorkflowListItem> get copyWith => _$WorkflowListItemCopyWithImpl<WorkflowListItem>(this as WorkflowListItem, _$identity);

  /// Serializes this WorkflowListItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.yamlDefinition, yamlDefinition) || other.yamlDefinition == yamlDefinition)&&(identical(other.triggerSummary, triggerSummary) || other.triggerSummary == triggerSummary)&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.lastBuildStatus, lastBuildStatus) || other.lastBuildStatus == lastBuildStatus)&&(identical(other.lastBuildAt, lastBuildAt) || other.lastBuildAt == lastBuildAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,orgId,yamlDefinition,triggerSummary,repository,branch,filePath,commitSha,lastBuildStatus,lastBuildAt,createdAt,updatedAt);

@override
String toString() {
  return 'WorkflowListItem(id: $id, name: $name, orgId: $orgId, yamlDefinition: $yamlDefinition, triggerSummary: $triggerSummary, repository: $repository, branch: $branch, filePath: $filePath, commitSha: $commitSha, lastBuildStatus: $lastBuildStatus, lastBuildAt: $lastBuildAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $WorkflowListItemCopyWith<$Res>  {
  factory $WorkflowListItemCopyWith(WorkflowListItem value, $Res Function(WorkflowListItem) _then) = _$WorkflowListItemCopyWithImpl;
@useResult
$Res call({
 String id, String name, String orgId, String yamlDefinition, String triggerSummary, String repository, String branch, String filePath, String? commitSha, String? lastBuildStatus, DateTime? lastBuildAt,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$WorkflowListItemCopyWithImpl<$Res>
    implements $WorkflowListItemCopyWith<$Res> {
  _$WorkflowListItemCopyWithImpl(this._self, this._then);

  final WorkflowListItem _self;
  final $Res Function(WorkflowListItem) _then;

/// Create a copy of WorkflowListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? orgId = null,Object? yamlDefinition = null,Object? triggerSummary = null,Object? repository = null,Object? branch = null,Object? filePath = null,Object? commitSha = freezed,Object? lastBuildStatus = freezed,Object? lastBuildAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,yamlDefinition: null == yamlDefinition ? _self.yamlDefinition : yamlDefinition // ignore: cast_nullable_to_non_nullable
as String,triggerSummary: null == triggerSummary ? _self.triggerSummary : triggerSummary // ignore: cast_nullable_to_non_nullable
as String,repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,lastBuildStatus: freezed == lastBuildStatus ? _self.lastBuildStatus : lastBuildStatus // ignore: cast_nullable_to_non_nullable
as String?,lastBuildAt: freezed == lastBuildAt ? _self.lastBuildAt : lastBuildAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowListItem].
extension WorkflowListItemPatterns on WorkflowListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowListItem value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowListItem value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String orgId,  String yamlDefinition,  String triggerSummary,  String repository,  String branch,  String filePath,  String? commitSha,  String? lastBuildStatus,  DateTime? lastBuildAt, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowListItem() when $default != null:
return $default(_that.id,_that.name,_that.orgId,_that.yamlDefinition,_that.triggerSummary,_that.repository,_that.branch,_that.filePath,_that.commitSha,_that.lastBuildStatus,_that.lastBuildAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String orgId,  String yamlDefinition,  String triggerSummary,  String repository,  String branch,  String filePath,  String? commitSha,  String? lastBuildStatus,  DateTime? lastBuildAt, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _WorkflowListItem():
return $default(_that.id,_that.name,_that.orgId,_that.yamlDefinition,_that.triggerSummary,_that.repository,_that.branch,_that.filePath,_that.commitSha,_that.lastBuildStatus,_that.lastBuildAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String orgId,  String yamlDefinition,  String triggerSummary,  String repository,  String branch,  String filePath,  String? commitSha,  String? lastBuildStatus,  DateTime? lastBuildAt, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowListItem() when $default != null:
return $default(_that.id,_that.name,_that.orgId,_that.yamlDefinition,_that.triggerSummary,_that.repository,_that.branch,_that.filePath,_that.commitSha,_that.lastBuildStatus,_that.lastBuildAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowListItem implements WorkflowListItem {
  const _WorkflowListItem({required this.id, required this.name, required this.orgId, required this.yamlDefinition, required this.triggerSummary, required this.repository, this.branch = 'main', this.filePath = '.openci/workflow.yaml', this.commitSha, this.lastBuildStatus, this.lastBuildAt, @DateTimeConverter() required this.createdAt, @DateTimeConverter() required this.updatedAt});
  factory _WorkflowListItem.fromJson(Map<String, dynamic> json) => _$WorkflowListItemFromJson(json);

@override final  String id;
@override final  String name;
@override final  String orgId;
@override final  String yamlDefinition;
@override final  String triggerSummary;
@override final  String repository;
@override@JsonKey() final  String branch;
@override@JsonKey() final  String filePath;
@override final  String? commitSha;
@override final  String? lastBuildStatus;
@override final  DateTime? lastBuildAt;
@override@DateTimeConverter() final  DateTime createdAt;
@override@DateTimeConverter() final  DateTime updatedAt;

/// Create a copy of WorkflowListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowListItemCopyWith<_WorkflowListItem> get copyWith => __$WorkflowListItemCopyWithImpl<_WorkflowListItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowListItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.orgId, orgId) || other.orgId == orgId)&&(identical(other.yamlDefinition, yamlDefinition) || other.yamlDefinition == yamlDefinition)&&(identical(other.triggerSummary, triggerSummary) || other.triggerSummary == triggerSummary)&&(identical(other.repository, repository) || other.repository == repository)&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.lastBuildStatus, lastBuildStatus) || other.lastBuildStatus == lastBuildStatus)&&(identical(other.lastBuildAt, lastBuildAt) || other.lastBuildAt == lastBuildAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,orgId,yamlDefinition,triggerSummary,repository,branch,filePath,commitSha,lastBuildStatus,lastBuildAt,createdAt,updatedAt);

@override
String toString() {
  return 'WorkflowListItem(id: $id, name: $name, orgId: $orgId, yamlDefinition: $yamlDefinition, triggerSummary: $triggerSummary, repository: $repository, branch: $branch, filePath: $filePath, commitSha: $commitSha, lastBuildStatus: $lastBuildStatus, lastBuildAt: $lastBuildAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$WorkflowListItemCopyWith<$Res> implements $WorkflowListItemCopyWith<$Res> {
  factory _$WorkflowListItemCopyWith(_WorkflowListItem value, $Res Function(_WorkflowListItem) _then) = __$WorkflowListItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String orgId, String yamlDefinition, String triggerSummary, String repository, String branch, String filePath, String? commitSha, String? lastBuildStatus, DateTime? lastBuildAt,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$WorkflowListItemCopyWithImpl<$Res>
    implements _$WorkflowListItemCopyWith<$Res> {
  __$WorkflowListItemCopyWithImpl(this._self, this._then);

  final _WorkflowListItem _self;
  final $Res Function(_WorkflowListItem) _then;

/// Create a copy of WorkflowListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? orgId = null,Object? yamlDefinition = null,Object? triggerSummary = null,Object? repository = null,Object? branch = null,Object? filePath = null,Object? commitSha = freezed,Object? lastBuildStatus = freezed,Object? lastBuildAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_WorkflowListItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,orgId: null == orgId ? _self.orgId : orgId // ignore: cast_nullable_to_non_nullable
as String,yamlDefinition: null == yamlDefinition ? _self.yamlDefinition : yamlDefinition // ignore: cast_nullable_to_non_nullable
as String,triggerSummary: null == triggerSummary ? _self.triggerSummary : triggerSummary // ignore: cast_nullable_to_non_nullable
as String,repository: null == repository ? _self.repository : repository // ignore: cast_nullable_to_non_nullable
as String,branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,commitSha: freezed == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String?,lastBuildStatus: freezed == lastBuildStatus ? _self.lastBuildStatus : lastBuildStatus // ignore: cast_nullable_to_non_nullable
as String?,lastBuildAt: freezed == lastBuildAt ? _self.lastBuildAt : lastBuildAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
