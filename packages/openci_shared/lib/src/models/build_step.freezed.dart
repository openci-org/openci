// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'build_step.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildStep {

 String get id; String get runId; String get name; BuildJobStatus get status; int get durationMs; int get stepOrder;@DateTimeConverter() DateTime get createdAt;@DateTimeConverter() DateTime get updatedAt;
/// Create a copy of BuildStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildStepCopyWith<BuildStep> get copyWith => _$BuildStepCopyWithImpl<BuildStep>(this as BuildStep, _$identity);

  /// Serializes this BuildStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildStep&&(identical(other.id, id) || other.id == id)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.stepOrder, stepOrder) || other.stepOrder == stepOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runId,name,status,durationMs,stepOrder,createdAt,updatedAt);

@override
String toString() {
  return 'BuildStep(id: $id, runId: $runId, name: $name, status: $status, durationMs: $durationMs, stepOrder: $stepOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BuildStepCopyWith<$Res>  {
  factory $BuildStepCopyWith(BuildStep value, $Res Function(BuildStep) _then) = _$BuildStepCopyWithImpl;
@useResult
$Res call({
 String id, String runId, String name, BuildJobStatus status, int durationMs, int stepOrder,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$BuildStepCopyWithImpl<$Res>
    implements $BuildStepCopyWith<$Res> {
  _$BuildStepCopyWithImpl(this._self, this._then);

  final BuildStep _self;
  final $Res Function(BuildStep) _then;

/// Create a copy of BuildStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? runId = null,Object? name = null,Object? status = null,Object? durationMs = null,Object? stepOrder = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,stepOrder: null == stepOrder ? _self.stepOrder : stepOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildStep].
extension BuildStepPatterns on BuildStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildStep value)  $default,){
final _that = this;
switch (_that) {
case _BuildStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildStep value)?  $default,){
final _that = this;
switch (_that) {
case _BuildStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String runId,  String name,  BuildJobStatus status,  int durationMs,  int stepOrder, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildStep() when $default != null:
return $default(_that.id,_that.runId,_that.name,_that.status,_that.durationMs,_that.stepOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String runId,  String name,  BuildJobStatus status,  int durationMs,  int stepOrder, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BuildStep():
return $default(_that.id,_that.runId,_that.name,_that.status,_that.durationMs,_that.stepOrder,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String runId,  String name,  BuildJobStatus status,  int durationMs,  int stepOrder, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BuildStep() when $default != null:
return $default(_that.id,_that.runId,_that.name,_that.status,_that.durationMs,_that.stepOrder,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildStep implements BuildStep {
  const _BuildStep({required this.id, required this.runId, required this.name, required this.status, required this.durationMs, required this.stepOrder, @DateTimeConverter() required this.createdAt, @DateTimeConverter() required this.updatedAt});
  factory _BuildStep.fromJson(Map<String, dynamic> json) => _$BuildStepFromJson(json);

@override final  String id;
@override final  String runId;
@override final  String name;
@override final  BuildJobStatus status;
@override final  int durationMs;
@override final  int stepOrder;
@override@DateTimeConverter() final  DateTime createdAt;
@override@DateTimeConverter() final  DateTime updatedAt;

/// Create a copy of BuildStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildStepCopyWith<_BuildStep> get copyWith => __$BuildStepCopyWithImpl<_BuildStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildStep&&(identical(other.id, id) || other.id == id)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.name, name) || other.name == name)&&(identical(other.status, status) || other.status == status)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.stepOrder, stepOrder) || other.stepOrder == stepOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,runId,name,status,durationMs,stepOrder,createdAt,updatedAt);

@override
String toString() {
  return 'BuildStep(id: $id, runId: $runId, name: $name, status: $status, durationMs: $durationMs, stepOrder: $stepOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BuildStepCopyWith<$Res> implements $BuildStepCopyWith<$Res> {
  factory _$BuildStepCopyWith(_BuildStep value, $Res Function(_BuildStep) _then) = __$BuildStepCopyWithImpl;
@override @useResult
$Res call({
 String id, String runId, String name, BuildJobStatus status, int durationMs, int stepOrder,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$BuildStepCopyWithImpl<$Res>
    implements _$BuildStepCopyWith<$Res> {
  __$BuildStepCopyWithImpl(this._self, this._then);

  final _BuildStep _self;
  final $Res Function(_BuildStep) _then;

/// Create a copy of BuildStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? runId = null,Object? name = null,Object? status = null,Object? durationMs = null,Object? stepOrder = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_BuildStep(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,runId: null == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as BuildJobStatus,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,stepOrder: null == stepOrder ? _self.stepOrder : stepOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
