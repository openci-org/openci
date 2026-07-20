// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cicd_commit_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CicdCommitGroup {

 String get branch; String get commitSha; String get commitMessage; BuildJobStatus get status; DateTime get createdAt; List<CicdWorkflowGroup> get workflows;
/// Create a copy of CicdCommitGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CicdCommitGroupCopyWith<CicdCommitGroup> get copyWith => _$CicdCommitGroupCopyWithImpl<CicdCommitGroup>(this as CicdCommitGroup, _$identity);

  /// Serializes this CicdCommitGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CicdCommitGroup&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.workflows, workflows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,branch,commitSha,commitMessage,status,createdAt,const DeepCollectionEquality().hash(workflows));

@override
String toString() {
  return 'CicdCommitGroup(branch: $branch, commitSha: $commitSha, commitMessage: $commitMessage, status: $status, createdAt: $createdAt, workflows: $workflows)';
}


}

/// @nodoc
abstract mixin class $CicdCommitGroupCopyWith<$Res>  {
  factory $CicdCommitGroupCopyWith(CicdCommitGroup value, $Res Function(CicdCommitGroup) _then) = _$CicdCommitGroupCopyWithImpl;
@useResult
$Res call({
 String branch, String commitSha, String commitMessage, BuildJobStatus status, DateTime createdAt, List<CicdWorkflowGroup> workflows
});




}
/// @nodoc
class _$CicdCommitGroupCopyWithImpl<$Res>
    implements $CicdCommitGroupCopyWith<$Res> {
  _$CicdCommitGroupCopyWithImpl(this._self, this._then);

  final CicdCommitGroup _self;
  final $Res Function(CicdCommitGroup) _then;

/// Create a copy of CicdCommitGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? branch = null,Object? commitSha = null,Object? commitMessage = null,Object? status = null,Object? createdAt = null,Object? workflows = null,}) {
  return _then(_self.copyWith(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,commitMessage: null == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,workflows: null == workflows ? _self.workflows : workflows // ignore: cast_nullable_to_non_nullable
as List<CicdWorkflowGroup>,
  ));
}

}


/// Adds pattern-matching-related methods to [CicdCommitGroup].
extension CicdCommitGroupPatterns on CicdCommitGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CicdCommitGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CicdCommitGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CicdCommitGroup value)  $default,){
final _that = this;
switch (_that) {
case _CicdCommitGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CicdCommitGroup value)?  $default,){
final _that = this;
switch (_that) {
case _CicdCommitGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String branch,  String commitSha,  String commitMessage,  BuildJobStatus status,  DateTime createdAt,  List<CicdWorkflowGroup> workflows)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CicdCommitGroup() when $default != null:
return $default(_that.branch,_that.commitSha,_that.commitMessage,_that.status,_that.createdAt,_that.workflows);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String branch,  String commitSha,  String commitMessage,  BuildJobStatus status,  DateTime createdAt,  List<CicdWorkflowGroup> workflows)  $default,) {final _that = this;
switch (_that) {
case _CicdCommitGroup():
return $default(_that.branch,_that.commitSha,_that.commitMessage,_that.status,_that.createdAt,_that.workflows);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String branch,  String commitSha,  String commitMessage,  BuildJobStatus status,  DateTime createdAt,  List<CicdWorkflowGroup> workflows)?  $default,) {final _that = this;
switch (_that) {
case _CicdCommitGroup() when $default != null:
return $default(_that.branch,_that.commitSha,_that.commitMessage,_that.status,_that.createdAt,_that.workflows);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CicdCommitGroup implements CicdCommitGroup {
  const _CicdCommitGroup({required this.branch, required this.commitSha, required this.commitMessage, required this.status, required this.createdAt, required final  List<CicdWorkflowGroup> workflows}): _workflows = workflows;
  factory _CicdCommitGroup.fromJson(Map<String, dynamic> json) => _$CicdCommitGroupFromJson(json);

@override final  String branch;
@override final  String commitSha;
@override final  String commitMessage;
@override final  BuildJobStatus status;
@override final  DateTime createdAt;
 final  List<CicdWorkflowGroup> _workflows;
@override List<CicdWorkflowGroup> get workflows {
  if (_workflows is EqualUnmodifiableListView) return _workflows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_workflows);
}


/// Create a copy of CicdCommitGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CicdCommitGroupCopyWith<_CicdCommitGroup> get copyWith => __$CicdCommitGroupCopyWithImpl<_CicdCommitGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CicdCommitGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CicdCommitGroup&&(identical(other.branch, branch) || other.branch == branch)&&(identical(other.commitSha, commitSha) || other.commitSha == commitSha)&&(identical(other.commitMessage, commitMessage) || other.commitMessage == commitMessage)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._workflows, _workflows));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,branch,commitSha,commitMessage,status,createdAt,const DeepCollectionEquality().hash(_workflows));

@override
String toString() {
  return 'CicdCommitGroup(branch: $branch, commitSha: $commitSha, commitMessage: $commitMessage, status: $status, createdAt: $createdAt, workflows: $workflows)';
}


}

/// @nodoc
abstract mixin class _$CicdCommitGroupCopyWith<$Res> implements $CicdCommitGroupCopyWith<$Res> {
  factory _$CicdCommitGroupCopyWith(_CicdCommitGroup value, $Res Function(_CicdCommitGroup) _then) = __$CicdCommitGroupCopyWithImpl;
@override @useResult
$Res call({
 String branch, String commitSha, String commitMessage, BuildJobStatus status, DateTime createdAt, List<CicdWorkflowGroup> workflows
});




}
/// @nodoc
class __$CicdCommitGroupCopyWithImpl<$Res>
    implements _$CicdCommitGroupCopyWith<$Res> {
  __$CicdCommitGroupCopyWithImpl(this._self, this._then);

  final _CicdCommitGroup _self;
  final $Res Function(_CicdCommitGroup) _then;

/// Create a copy of CicdCommitGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? branch = null,Object? commitSha = null,Object? commitMessage = null,Object? status = null,Object? createdAt = null,Object? workflows = null,}) {
  return _then(_CicdCommitGroup(
branch: null == branch ? _self.branch : branch // ignore: cast_nullable_to_non_nullable
as String,commitSha: null == commitSha ? _self.commitSha : commitSha // ignore: cast_nullable_to_non_nullable
as String,commitMessage: null == commitMessage ? _self.commitMessage : commitMessage // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,workflows: null == workflows ? _self._workflows : workflows // ignore: cast_nullable_to_non_nullable
as List<CicdWorkflowGroup>,
  ));
}


}


/// @nodoc
mixin _$CicdWorkflowGroup {

 String get fileName; BuildJobStatus get status; Duration get duration; List<List<CicdJobGroup>> get stages;
/// Create a copy of CicdWorkflowGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CicdWorkflowGroupCopyWith<CicdWorkflowGroup> get copyWith => _$CicdWorkflowGroupCopyWithImpl<CicdWorkflowGroup>(this as CicdWorkflowGroup, _$identity);

  /// Serializes this CicdWorkflowGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CicdWorkflowGroup&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other.stages, stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,status,duration,const DeepCollectionEquality().hash(stages));

@override
String toString() {
  return 'CicdWorkflowGroup(fileName: $fileName, status: $status, duration: $duration, stages: $stages)';
}


}

/// @nodoc
abstract mixin class $CicdWorkflowGroupCopyWith<$Res>  {
  factory $CicdWorkflowGroupCopyWith(CicdWorkflowGroup value, $Res Function(CicdWorkflowGroup) _then) = _$CicdWorkflowGroupCopyWithImpl;
@useResult
$Res call({
 String fileName, BuildJobStatus status, Duration duration, List<List<CicdJobGroup>> stages
});




}
/// @nodoc
class _$CicdWorkflowGroupCopyWithImpl<$Res>
    implements $CicdWorkflowGroupCopyWith<$Res> {
  _$CicdWorkflowGroupCopyWithImpl(this._self, this._then);

  final CicdWorkflowGroup _self;
  final $Res Function(CicdWorkflowGroup) _then;

/// Create a copy of CicdWorkflowGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? status = null,Object? duration = null,Object? stages = null,}) {
  return _then(_self.copyWith(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as List<List<CicdJobGroup>>,
  ));
}

}


/// Adds pattern-matching-related methods to [CicdWorkflowGroup].
extension CicdWorkflowGroupPatterns on CicdWorkflowGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CicdWorkflowGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CicdWorkflowGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CicdWorkflowGroup value)  $default,){
final _that = this;
switch (_that) {
case _CicdWorkflowGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CicdWorkflowGroup value)?  $default,){
final _that = this;
switch (_that) {
case _CicdWorkflowGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  BuildJobStatus status,  Duration duration,  List<List<CicdJobGroup>> stages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CicdWorkflowGroup() when $default != null:
return $default(_that.fileName,_that.status,_that.duration,_that.stages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  BuildJobStatus status,  Duration duration,  List<List<CicdJobGroup>> stages)  $default,) {final _that = this;
switch (_that) {
case _CicdWorkflowGroup():
return $default(_that.fileName,_that.status,_that.duration,_that.stages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  BuildJobStatus status,  Duration duration,  List<List<CicdJobGroup>> stages)?  $default,) {final _that = this;
switch (_that) {
case _CicdWorkflowGroup() when $default != null:
return $default(_that.fileName,_that.status,_that.duration,_that.stages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CicdWorkflowGroup implements CicdWorkflowGroup {
  const _CicdWorkflowGroup({required this.fileName, required this.status, required this.duration, required final  List<List<CicdJobGroup>> stages}): _stages = stages;
  factory _CicdWorkflowGroup.fromJson(Map<String, dynamic> json) => _$CicdWorkflowGroupFromJson(json);

@override final  String fileName;
@override final  BuildJobStatus status;
@override final  Duration duration;
 final  List<List<CicdJobGroup>> _stages;
@override List<List<CicdJobGroup>> get stages {
  if (_stages is EqualUnmodifiableListView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stages);
}


/// Create a copy of CicdWorkflowGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CicdWorkflowGroupCopyWith<_CicdWorkflowGroup> get copyWith => __$CicdWorkflowGroupCopyWithImpl<_CicdWorkflowGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CicdWorkflowGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CicdWorkflowGroup&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.status, status) || other.status == status)&&(identical(other.duration, duration) || other.duration == duration)&&const DeepCollectionEquality().equals(other._stages, _stages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fileName,status,duration,const DeepCollectionEquality().hash(_stages));

@override
String toString() {
  return 'CicdWorkflowGroup(fileName: $fileName, status: $status, duration: $duration, stages: $stages)';
}


}

/// @nodoc
abstract mixin class _$CicdWorkflowGroupCopyWith<$Res> implements $CicdWorkflowGroupCopyWith<$Res> {
  factory _$CicdWorkflowGroupCopyWith(_CicdWorkflowGroup value, $Res Function(_CicdWorkflowGroup) _then) = __$CicdWorkflowGroupCopyWithImpl;
@override @useResult
$Res call({
 String fileName, BuildJobStatus status, Duration duration, List<List<CicdJobGroup>> stages
});




}
/// @nodoc
class __$CicdWorkflowGroupCopyWithImpl<$Res>
    implements _$CicdWorkflowGroupCopyWith<$Res> {
  __$CicdWorkflowGroupCopyWithImpl(this._self, this._then);

  final _CicdWorkflowGroup _self;
  final $Res Function(_CicdWorkflowGroup) _then;

/// Create a copy of CicdWorkflowGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? status = null,Object? duration = null,Object? stages = null,}) {
  return _then(_CicdWorkflowGroup(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as List<List<CicdJobGroup>>,
  ));
}


}


/// @nodoc
mixin _$CicdJobGroup {

 String get id; String get label; BuildJobStatus get status;
/// Create a copy of CicdJobGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CicdJobGroupCopyWith<CicdJobGroup> get copyWith => _$CicdJobGroupCopyWithImpl<CicdJobGroup>(this as CicdJobGroup, _$identity);

  /// Serializes this CicdJobGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CicdJobGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,status);

@override
String toString() {
  return 'CicdJobGroup(id: $id, label: $label, status: $status)';
}


}

/// @nodoc
abstract mixin class $CicdJobGroupCopyWith<$Res>  {
  factory $CicdJobGroupCopyWith(CicdJobGroup value, $Res Function(CicdJobGroup) _then) = _$CicdJobGroupCopyWithImpl;
@useResult
$Res call({
 String id, String label, BuildJobStatus status
});




}
/// @nodoc
class _$CicdJobGroupCopyWithImpl<$Res>
    implements $CicdJobGroupCopyWith<$Res> {
  _$CicdJobGroupCopyWithImpl(this._self, this._then);

  final CicdJobGroup _self;
  final $Res Function(CicdJobGroup) _then;

/// Create a copy of CicdJobGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [CicdJobGroup].
extension CicdJobGroupPatterns on CicdJobGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CicdJobGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CicdJobGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CicdJobGroup value)  $default,){
final _that = this;
switch (_that) {
case _CicdJobGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CicdJobGroup value)?  $default,){
final _that = this;
switch (_that) {
case _CicdJobGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String label,  BuildJobStatus status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CicdJobGroup() when $default != null:
return $default(_that.id,_that.label,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String label,  BuildJobStatus status)  $default,) {final _that = this;
switch (_that) {
case _CicdJobGroup():
return $default(_that.id,_that.label,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String label,  BuildJobStatus status)?  $default,) {final _that = this;
switch (_that) {
case _CicdJobGroup() when $default != null:
return $default(_that.id,_that.label,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CicdJobGroup implements CicdJobGroup {
  const _CicdJobGroup({required this.id, required this.label, required this.status});
  factory _CicdJobGroup.fromJson(Map<String, dynamic> json) => _$CicdJobGroupFromJson(json);

@override final  String id;
@override final  String label;
@override final  BuildJobStatus status;

/// Create a copy of CicdJobGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CicdJobGroupCopyWith<_CicdJobGroup> get copyWith => __$CicdJobGroupCopyWithImpl<_CicdJobGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CicdJobGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CicdJobGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,status);

@override
String toString() {
  return 'CicdJobGroup(id: $id, label: $label, status: $status)';
}


}

/// @nodoc
abstract mixin class _$CicdJobGroupCopyWith<$Res> implements $CicdJobGroupCopyWith<$Res> {
  factory _$CicdJobGroupCopyWith(_CicdJobGroup value, $Res Function(_CicdJobGroup) _then) = __$CicdJobGroupCopyWithImpl;
@override @useResult
$Res call({
 String id, String label, BuildJobStatus status
});




}
/// @nodoc
class __$CicdJobGroupCopyWithImpl<$Res>
    implements _$CicdJobGroupCopyWith<$Res> {
  __$CicdJobGroupCopyWithImpl(this._self, this._then);

  final _CicdJobGroup _self;
  final $Res Function(_CicdJobGroup) _then;

/// Create a copy of CicdJobGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? status = null,}) {
  return _then(_CicdJobGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,
  ));
}


}

// dart format on
