// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'build_job_logs_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildJobLog {

 String get message; String get level;@DateTimeConverter() DateTime? get timestamp;
/// Create a copy of BuildJobLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildJobLogCopyWith<BuildJobLog> get copyWith => _$BuildJobLogCopyWithImpl<BuildJobLog>(this as BuildJobLog, _$identity);

  /// Serializes this BuildJobLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildJobLog&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level,timestamp);

@override
String toString() {
  return 'BuildJobLog(message: $message, level: $level, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $BuildJobLogCopyWith<$Res>  {
  factory $BuildJobLogCopyWith(BuildJobLog value, $Res Function(BuildJobLog) _then) = _$BuildJobLogCopyWithImpl;
@useResult
$Res call({
 String message, String level,@DateTimeConverter() DateTime? timestamp
});




}
/// @nodoc
class _$BuildJobLogCopyWithImpl<$Res>
    implements $BuildJobLogCopyWith<$Res> {
  _$BuildJobLogCopyWithImpl(this._self, this._then);

  final BuildJobLog _self;
  final $Res Function(BuildJobLog) _then;

/// Create a copy of BuildJobLog
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? level = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildJobLog].
extension BuildJobLogPatterns on BuildJobLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildJobLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildJobLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildJobLog value)  $default,){
final _that = this;
switch (_that) {
case _BuildJobLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildJobLog value)?  $default,){
final _that = this;
switch (_that) {
case _BuildJobLog() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  String level, @DateTimeConverter()  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildJobLog() when $default != null:
return $default(_that.message,_that.level,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  String level, @DateTimeConverter()  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _BuildJobLog():
return $default(_that.message,_that.level,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  String level, @DateTimeConverter()  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _BuildJobLog() when $default != null:
return $default(_that.message,_that.level,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildJobLog implements BuildJobLog {
  const _BuildJobLog({required this.message, required this.level, @DateTimeConverter() this.timestamp});
  factory _BuildJobLog.fromJson(Map<String, dynamic> json) => _$BuildJobLogFromJson(json);

@override final  String message;
@override final  String level;
@override@DateTimeConverter() final  DateTime? timestamp;

/// Create a copy of BuildJobLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildJobLogCopyWith<_BuildJobLog> get copyWith => __$BuildJobLogCopyWithImpl<_BuildJobLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildJobLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildJobLog&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level,timestamp);

@override
String toString() {
  return 'BuildJobLog(message: $message, level: $level, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$BuildJobLogCopyWith<$Res> implements $BuildJobLogCopyWith<$Res> {
  factory _$BuildJobLogCopyWith(_BuildJobLog value, $Res Function(_BuildJobLog) _then) = __$BuildJobLogCopyWithImpl;
@override @useResult
$Res call({
 String message, String level,@DateTimeConverter() DateTime? timestamp
});




}
/// @nodoc
class __$BuildJobLogCopyWithImpl<$Res>
    implements _$BuildJobLogCopyWith<$Res> {
  __$BuildJobLogCopyWithImpl(this._self, this._then);

  final _BuildJobLog _self;
  final $Res Function(_BuildJobLog) _then;

/// Create a copy of BuildJobLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? level = null,Object? timestamp = freezed,}) {
  return _then(_BuildJobLog(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
