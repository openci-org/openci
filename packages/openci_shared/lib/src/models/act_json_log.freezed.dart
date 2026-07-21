// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'act_json_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActJsonLog {

 String? get job;@JsonKey(name: 'jobID') String? get jobId; String? get step; String? get msg; String? get level;@DateTimeConverter() DateTime? get time; String? get stepResult; String? get jobResult; bool? get dryrun;@JsonKey(name: 'raw_output') bool? get rawOutput; String? get stage;@JsonKey(name: 'stepID') List<String>? get stepId; Map<String, Object?>? get matrix;@NanosecondsDurationConverter() Duration? get executionTime;
/// Create a copy of ActJsonLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActJsonLogCopyWith<ActJsonLog> get copyWith => _$ActJsonLogCopyWithImpl<ActJsonLog>(this as ActJsonLog, _$identity);

  /// Serializes this ActJsonLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActJsonLog&&(identical(other.job, job) || other.job == job)&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.step, step) || other.step == step)&&(identical(other.msg, msg) || other.msg == msg)&&(identical(other.level, level) || other.level == level)&&(identical(other.time, time) || other.time == time)&&(identical(other.stepResult, stepResult) || other.stepResult == stepResult)&&(identical(other.jobResult, jobResult) || other.jobResult == jobResult)&&(identical(other.dryrun, dryrun) || other.dryrun == dryrun)&&(identical(other.rawOutput, rawOutput) || other.rawOutput == rawOutput)&&(identical(other.stage, stage) || other.stage == stage)&&const DeepCollectionEquality().equals(other.stepId, stepId)&&const DeepCollectionEquality().equals(other.matrix, matrix)&&(identical(other.executionTime, executionTime) || other.executionTime == executionTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,job,jobId,step,msg,level,time,stepResult,jobResult,dryrun,rawOutput,stage,const DeepCollectionEquality().hash(stepId),const DeepCollectionEquality().hash(matrix),executionTime);

@override
String toString() {
  return 'ActJsonLog(job: $job, jobId: $jobId, step: $step, msg: $msg, level: $level, time: $time, stepResult: $stepResult, jobResult: $jobResult, dryrun: $dryrun, rawOutput: $rawOutput, stage: $stage, stepId: $stepId, matrix: $matrix, executionTime: $executionTime)';
}


}

/// @nodoc
abstract mixin class $ActJsonLogCopyWith<$Res>  {
  factory $ActJsonLogCopyWith(ActJsonLog value, $Res Function(ActJsonLog) _then) = _$ActJsonLogCopyWithImpl;
@useResult
$Res call({
 String? job,@JsonKey(name: 'jobID') String? jobId, String? step, String? msg, String? level,@DateTimeConverter() DateTime? time, String? stepResult, String? jobResult, bool? dryrun,@JsonKey(name: 'raw_output') bool? rawOutput, String? stage,@JsonKey(name: 'stepID') List<String>? stepId, Map<String, Object?>? matrix,@NanosecondsDurationConverter() Duration? executionTime
});




}
/// @nodoc
class _$ActJsonLogCopyWithImpl<$Res>
    implements $ActJsonLogCopyWith<$Res> {
  _$ActJsonLogCopyWithImpl(this._self, this._then);

  final ActJsonLog _self;
  final $Res Function(ActJsonLog) _then;

/// Create a copy of ActJsonLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? job = freezed,Object? jobId = freezed,Object? step = freezed,Object? msg = freezed,Object? level = freezed,Object? time = freezed,Object? stepResult = freezed,Object? jobResult = freezed,Object? dryrun = freezed,Object? rawOutput = freezed,Object? stage = freezed,Object? stepId = freezed,Object? matrix = freezed,Object? executionTime = freezed,}) {
  return _then(_self.copyWith(
job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,jobId: freezed == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String?,step: freezed == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as String?,msg: freezed == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime?,stepResult: freezed == stepResult ? _self.stepResult : stepResult // ignore: cast_nullable_to_non_nullable
as String?,jobResult: freezed == jobResult ? _self.jobResult : jobResult // ignore: cast_nullable_to_non_nullable
as String?,dryrun: freezed == dryrun ? _self.dryrun : dryrun // ignore: cast_nullable_to_non_nullable
as bool?,rawOutput: freezed == rawOutput ? _self.rawOutput : rawOutput // ignore: cast_nullable_to_non_nullable
as bool?,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,stepId: freezed == stepId ? _self.stepId : stepId // ignore: cast_nullable_to_non_nullable
as List<String>?,matrix: freezed == matrix ? _self.matrix : matrix // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,executionTime: freezed == executionTime ? _self.executionTime : executionTime // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}

}


/// Adds pattern-matching-related methods to [ActJsonLog].
extension ActJsonLogPatterns on ActJsonLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActJsonLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActJsonLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActJsonLog value)  $default,){
final _that = this;
switch (_that) {
case _ActJsonLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActJsonLog value)?  $default,){
final _that = this;
switch (_that) {
case _ActJsonLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? job, @JsonKey(name: 'jobID')  String? jobId,  String? step,  String? msg,  String? level, @DateTimeConverter()  DateTime? time,  String? stepResult,  String? jobResult,  bool? dryrun, @JsonKey(name: 'raw_output')  bool? rawOutput,  String? stage, @JsonKey(name: 'stepID')  List<String>? stepId,  Map<String, Object?>? matrix, @NanosecondsDurationConverter()  Duration? executionTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActJsonLog() when $default != null:
return $default(_that.job,_that.jobId,_that.step,_that.msg,_that.level,_that.time,_that.stepResult,_that.jobResult,_that.dryrun,_that.rawOutput,_that.stage,_that.stepId,_that.matrix,_that.executionTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? job, @JsonKey(name: 'jobID')  String? jobId,  String? step,  String? msg,  String? level, @DateTimeConverter()  DateTime? time,  String? stepResult,  String? jobResult,  bool? dryrun, @JsonKey(name: 'raw_output')  bool? rawOutput,  String? stage, @JsonKey(name: 'stepID')  List<String>? stepId,  Map<String, Object?>? matrix, @NanosecondsDurationConverter()  Duration? executionTime)  $default,) {final _that = this;
switch (_that) {
case _ActJsonLog():
return $default(_that.job,_that.jobId,_that.step,_that.msg,_that.level,_that.time,_that.stepResult,_that.jobResult,_that.dryrun,_that.rawOutput,_that.stage,_that.stepId,_that.matrix,_that.executionTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? job, @JsonKey(name: 'jobID')  String? jobId,  String? step,  String? msg,  String? level, @DateTimeConverter()  DateTime? time,  String? stepResult,  String? jobResult,  bool? dryrun, @JsonKey(name: 'raw_output')  bool? rawOutput,  String? stage, @JsonKey(name: 'stepID')  List<String>? stepId,  Map<String, Object?>? matrix, @NanosecondsDurationConverter()  Duration? executionTime)?  $default,) {final _that = this;
switch (_that) {
case _ActJsonLog() when $default != null:
return $default(_that.job,_that.jobId,_that.step,_that.msg,_that.level,_that.time,_that.stepResult,_that.jobResult,_that.dryrun,_that.rawOutput,_that.stage,_that.stepId,_that.matrix,_that.executionTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActJsonLog implements ActJsonLog {
  const _ActJsonLog({this.job, @JsonKey(name: 'jobID') this.jobId, this.step, this.msg, this.level, @DateTimeConverter() this.time, this.stepResult, this.jobResult, this.dryrun, @JsonKey(name: 'raw_output') this.rawOutput, this.stage, @JsonKey(name: 'stepID') final  List<String>? stepId, final  Map<String, Object?>? matrix, @NanosecondsDurationConverter() this.executionTime}): _stepId = stepId,_matrix = matrix;
  factory _ActJsonLog.fromJson(Map<String, dynamic> json) => _$ActJsonLogFromJson(json);

@override final  String? job;
@override@JsonKey(name: 'jobID') final  String? jobId;
@override final  String? step;
@override final  String? msg;
@override final  String? level;
@override@DateTimeConverter() final  DateTime? time;
@override final  String? stepResult;
@override final  String? jobResult;
@override final  bool? dryrun;
@override@JsonKey(name: 'raw_output') final  bool? rawOutput;
@override final  String? stage;
 final  List<String>? _stepId;
@override@JsonKey(name: 'stepID') List<String>? get stepId {
  final value = _stepId;
  if (value == null) return null;
  if (_stepId is EqualUnmodifiableListView) return _stepId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  Map<String, Object?>? _matrix;
@override Map<String, Object?>? get matrix {
  final value = _matrix;
  if (value == null) return null;
  if (_matrix is EqualUnmodifiableMapView) return _matrix;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@NanosecondsDurationConverter() final  Duration? executionTime;

/// Create a copy of ActJsonLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActJsonLogCopyWith<_ActJsonLog> get copyWith => __$ActJsonLogCopyWithImpl<_ActJsonLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActJsonLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActJsonLog&&(identical(other.job, job) || other.job == job)&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.step, step) || other.step == step)&&(identical(other.msg, msg) || other.msg == msg)&&(identical(other.level, level) || other.level == level)&&(identical(other.time, time) || other.time == time)&&(identical(other.stepResult, stepResult) || other.stepResult == stepResult)&&(identical(other.jobResult, jobResult) || other.jobResult == jobResult)&&(identical(other.dryrun, dryrun) || other.dryrun == dryrun)&&(identical(other.rawOutput, rawOutput) || other.rawOutput == rawOutput)&&(identical(other.stage, stage) || other.stage == stage)&&const DeepCollectionEquality().equals(other._stepId, _stepId)&&const DeepCollectionEquality().equals(other._matrix, _matrix)&&(identical(other.executionTime, executionTime) || other.executionTime == executionTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,job,jobId,step,msg,level,time,stepResult,jobResult,dryrun,rawOutput,stage,const DeepCollectionEquality().hash(_stepId),const DeepCollectionEquality().hash(_matrix),executionTime);

@override
String toString() {
  return 'ActJsonLog(job: $job, jobId: $jobId, step: $step, msg: $msg, level: $level, time: $time, stepResult: $stepResult, jobResult: $jobResult, dryrun: $dryrun, rawOutput: $rawOutput, stage: $stage, stepId: $stepId, matrix: $matrix, executionTime: $executionTime)';
}


}

/// @nodoc
abstract mixin class _$ActJsonLogCopyWith<$Res> implements $ActJsonLogCopyWith<$Res> {
  factory _$ActJsonLogCopyWith(_ActJsonLog value, $Res Function(_ActJsonLog) _then) = __$ActJsonLogCopyWithImpl;
@override @useResult
$Res call({
 String? job,@JsonKey(name: 'jobID') String? jobId, String? step, String? msg, String? level,@DateTimeConverter() DateTime? time, String? stepResult, String? jobResult, bool? dryrun,@JsonKey(name: 'raw_output') bool? rawOutput, String? stage,@JsonKey(name: 'stepID') List<String>? stepId, Map<String, Object?>? matrix,@NanosecondsDurationConverter() Duration? executionTime
});




}
/// @nodoc
class __$ActJsonLogCopyWithImpl<$Res>
    implements _$ActJsonLogCopyWith<$Res> {
  __$ActJsonLogCopyWithImpl(this._self, this._then);

  final _ActJsonLog _self;
  final $Res Function(_ActJsonLog) _then;

/// Create a copy of ActJsonLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? job = freezed,Object? jobId = freezed,Object? step = freezed,Object? msg = freezed,Object? level = freezed,Object? time = freezed,Object? stepResult = freezed,Object? jobResult = freezed,Object? dryrun = freezed,Object? rawOutput = freezed,Object? stage = freezed,Object? stepId = freezed,Object? matrix = freezed,Object? executionTime = freezed,}) {
  return _then(_ActJsonLog(
job: freezed == job ? _self.job : job // ignore: cast_nullable_to_non_nullable
as String?,jobId: freezed == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String?,step: freezed == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as String?,msg: freezed == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String?,time: freezed == time ? _self.time : time // ignore: cast_nullable_to_non_nullable
as DateTime?,stepResult: freezed == stepResult ? _self.stepResult : stepResult // ignore: cast_nullable_to_non_nullable
as String?,jobResult: freezed == jobResult ? _self.jobResult : jobResult // ignore: cast_nullable_to_non_nullable
as String?,dryrun: freezed == dryrun ? _self.dryrun : dryrun // ignore: cast_nullable_to_non_nullable
as bool?,rawOutput: freezed == rawOutput ? _self.rawOutput : rawOutput // ignore: cast_nullable_to_non_nullable
as bool?,stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,stepId: freezed == stepId ? _self._stepId : stepId // ignore: cast_nullable_to_non_nullable
as List<String>?,matrix: freezed == matrix ? _self._matrix : matrix // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>?,executionTime: freezed == executionTime ? _self.executionTime : executionTime // ignore: cast_nullable_to_non_nullable
as Duration?,
  ));
}


}

// dart format on
