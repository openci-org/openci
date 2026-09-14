// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'step_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StepEvent {

 BuildStep get step;
/// Create a copy of StepEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StepEventCopyWith<StepEvent> get copyWith => _$StepEventCopyWithImpl<StepEvent>(this as StepEvent, _$identity);

  /// Serializes this StepEvent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StepEvent&&(identical(other.step, step) || other.step == step));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,step);

@override
String toString() {
  return 'StepEvent(step: $step)';
}


}

/// @nodoc
abstract mixin class $StepEventCopyWith<$Res>  {
  factory $StepEventCopyWith(StepEvent value, $Res Function(StepEvent) _then) = _$StepEventCopyWithImpl;
@useResult
$Res call({
 BuildStep step
});


$BuildStepCopyWith<$Res> get step;

}
/// @nodoc
class _$StepEventCopyWithImpl<$Res>
    implements $StepEventCopyWith<$Res> {
  _$StepEventCopyWithImpl(this._self, this._then);

  final StepEvent _self;
  final $Res Function(StepEvent) _then;

/// Create a copy of StepEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,}) {
  return _then(_self.copyWith(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as BuildStep,
  ));
}
/// Create a copy of StepEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildStepCopyWith<$Res> get step {
  
  return $BuildStepCopyWith<$Res>(_self.step, (value) {
    return _then(_self.copyWith(step: value));
  });
}
}


/// Adds pattern-matching-related methods to [StepEvent].
extension StepEventPatterns on StepEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StepEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StepEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StepEvent value)  $default,){
final _that = this;
switch (_that) {
case _StepEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StepEvent value)?  $default,){
final _that = this;
switch (_that) {
case _StepEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BuildStep step)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StepEvent() when $default != null:
return $default(_that.step);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BuildStep step)  $default,) {final _that = this;
switch (_that) {
case _StepEvent():
return $default(_that.step);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BuildStep step)?  $default,) {final _that = this;
switch (_that) {
case _StepEvent() when $default != null:
return $default(_that.step);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _StepEvent implements StepEvent {
  const _StepEvent({required this.step});
  factory _StepEvent.fromJson(Map<String, dynamic> json) => _$StepEventFromJson(json);

@override final  BuildStep step;

/// Create a copy of StepEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StepEventCopyWith<_StepEvent> get copyWith => __$StepEventCopyWithImpl<_StepEvent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StepEventToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StepEvent&&(identical(other.step, step) || other.step == step));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,step);

@override
String toString() {
  return 'StepEvent(step: $step)';
}


}

/// @nodoc
abstract mixin class _$StepEventCopyWith<$Res> implements $StepEventCopyWith<$Res> {
  factory _$StepEventCopyWith(_StepEvent value, $Res Function(_StepEvent) _then) = __$StepEventCopyWithImpl;
@override @useResult
$Res call({
 BuildStep step
});


@override $BuildStepCopyWith<$Res> get step;

}
/// @nodoc
class __$StepEventCopyWithImpl<$Res>
    implements _$StepEventCopyWith<$Res> {
  __$StepEventCopyWithImpl(this._self, this._then);

  final _StepEvent _self;
  final $Res Function(_StepEvent) _then;

/// Create a copy of StepEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,}) {
  return _then(_StepEvent(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as BuildStep,
  ));
}

/// Create a copy of StepEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BuildStepCopyWith<$Res> get step {
  
  return $BuildStepCopyWith<$Res>(_self.step, (value) {
    return _then(_self.copyWith(step: value));
  });
}
}

// dart format on
