// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'loki_labels.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LokiLabels {

 String get stream; String get type; String? get command; String? get runId; String? get buildJobId; String? get stepId;
/// Create a copy of LokiLabels
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LokiLabelsCopyWith<LokiLabels> get copyWith => _$LokiLabelsCopyWithImpl<LokiLabels>(this as LokiLabels, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LokiLabels&&(identical(other.stream, stream) || other.stream == stream)&&(identical(other.type, type) || other.type == type)&&(identical(other.command, command) || other.command == command)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.buildJobId, buildJobId) || other.buildJobId == buildJobId)&&(identical(other.stepId, stepId) || other.stepId == stepId));
}


@override
int get hashCode => Object.hash(runtimeType,stream,type,command,runId,buildJobId,stepId);

@override
String toString() {
  return 'LokiLabels(stream: $stream, type: $type, command: $command, runId: $runId, buildJobId: $buildJobId, stepId: $stepId)';
}


}

/// @nodoc
abstract mixin class $LokiLabelsCopyWith<$Res>  {
  factory $LokiLabelsCopyWith(LokiLabels value, $Res Function(LokiLabels) _then) = _$LokiLabelsCopyWithImpl;
@useResult
$Res call({
 String stream, String type, String? command, String? runId, String? buildJobId, String? stepId
});




}
/// @nodoc
class _$LokiLabelsCopyWithImpl<$Res>
    implements $LokiLabelsCopyWith<$Res> {
  _$LokiLabelsCopyWithImpl(this._self, this._then);

  final LokiLabels _self;
  final $Res Function(LokiLabels) _then;

/// Create a copy of LokiLabels
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stream = null,Object? type = null,Object? command = freezed,Object? runId = freezed,Object? buildJobId = freezed,Object? stepId = freezed,}) {
  return _then(_self.copyWith(
stream: null == stream ? _self.stream : stream // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,buildJobId: freezed == buildJobId ? _self.buildJobId : buildJobId // ignore: cast_nullable_to_non_nullable
as String?,stepId: freezed == stepId ? _self.stepId : stepId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LokiLabels].
extension LokiLabelsPatterns on LokiLabels {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LokiLabels value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LokiLabels() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LokiLabels value)  $default,){
final _that = this;
switch (_that) {
case _LokiLabels():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LokiLabels value)?  $default,){
final _that = this;
switch (_that) {
case _LokiLabels() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stream,  String type,  String? command,  String? runId,  String? buildJobId,  String? stepId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LokiLabels() when $default != null:
return $default(_that.stream,_that.type,_that.command,_that.runId,_that.buildJobId,_that.stepId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stream,  String type,  String? command,  String? runId,  String? buildJobId,  String? stepId)  $default,) {final _that = this;
switch (_that) {
case _LokiLabels():
return $default(_that.stream,_that.type,_that.command,_that.runId,_that.buildJobId,_that.stepId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stream,  String type,  String? command,  String? runId,  String? buildJobId,  String? stepId)?  $default,) {final _that = this;
switch (_that) {
case _LokiLabels() when $default != null:
return $default(_that.stream,_that.type,_that.command,_that.runId,_that.buildJobId,_that.stepId);case _:
  return null;

}
}

}

/// @nodoc


class _LokiLabels extends LokiLabels {
  const _LokiLabels({required this.stream, this.type = 'step_log', this.command, this.runId, this.buildJobId, this.stepId}): super._();
  

@override final  String stream;
@override@JsonKey() final  String type;
@override final  String? command;
@override final  String? runId;
@override final  String? buildJobId;
@override final  String? stepId;

/// Create a copy of LokiLabels
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LokiLabelsCopyWith<_LokiLabels> get copyWith => __$LokiLabelsCopyWithImpl<_LokiLabels>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LokiLabels&&(identical(other.stream, stream) || other.stream == stream)&&(identical(other.type, type) || other.type == type)&&(identical(other.command, command) || other.command == command)&&(identical(other.runId, runId) || other.runId == runId)&&(identical(other.buildJobId, buildJobId) || other.buildJobId == buildJobId)&&(identical(other.stepId, stepId) || other.stepId == stepId));
}


@override
int get hashCode => Object.hash(runtimeType,stream,type,command,runId,buildJobId,stepId);

@override
String toString() {
  return 'LokiLabels(stream: $stream, type: $type, command: $command, runId: $runId, buildJobId: $buildJobId, stepId: $stepId)';
}


}

/// @nodoc
abstract mixin class _$LokiLabelsCopyWith<$Res> implements $LokiLabelsCopyWith<$Res> {
  factory _$LokiLabelsCopyWith(_LokiLabels value, $Res Function(_LokiLabels) _then) = __$LokiLabelsCopyWithImpl;
@override @useResult
$Res call({
 String stream, String type, String? command, String? runId, String? buildJobId, String? stepId
});




}
/// @nodoc
class __$LokiLabelsCopyWithImpl<$Res>
    implements _$LokiLabelsCopyWith<$Res> {
  __$LokiLabelsCopyWithImpl(this._self, this._then);

  final _LokiLabels _self;
  final $Res Function(_LokiLabels) _then;

/// Create a copy of LokiLabels
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stream = null,Object? type = null,Object? command = freezed,Object? runId = freezed,Object? buildJobId = freezed,Object? stepId = freezed,}) {
  return _then(_LokiLabels(
stream: null == stream ? _self.stream : stream // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,command: freezed == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as String?,runId: freezed == runId ? _self.runId : runId // ignore: cast_nullable_to_non_nullable
as String?,buildJobId: freezed == buildJobId ? _self.buildJobId : buildJobId // ignore: cast_nullable_to_non_nullable
as String?,stepId: freezed == stepId ? _self.stepId : stepId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
