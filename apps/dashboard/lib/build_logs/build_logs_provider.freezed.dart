// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'build_logs_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BuildLog {

 String get message; String get level;@DateTimeConverter() DateTime? get timestamp;
/// Create a copy of BuildLog
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildLogCopyWith<BuildLog> get copyWith => _$BuildLogCopyWithImpl<BuildLog>(this as BuildLog, _$identity);

  /// Serializes this BuildLog to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildLog&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level,timestamp);

@override
String toString() {
  return 'BuildLog(message: $message, level: $level, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $BuildLogCopyWith<$Res>  {
  factory $BuildLogCopyWith(BuildLog value, $Res Function(BuildLog) _then) = _$BuildLogCopyWithImpl;
@useResult
$Res call({
 String message, String level,@DateTimeConverter() DateTime? timestamp
});




}
/// @nodoc
class _$BuildLogCopyWithImpl<$Res>
    implements $BuildLogCopyWith<$Res> {
  _$BuildLogCopyWithImpl(this._self, this._then);

  final BuildLog _self;
  final $Res Function(BuildLog) _then;

/// Create a copy of BuildLog
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


/// Adds pattern-matching-related methods to [BuildLog].
extension BuildLogPatterns on BuildLog {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildLog value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildLog() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildLog value)  $default,){
final _that = this;
switch (_that) {
case _BuildLog():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildLog value)?  $default,){
final _that = this;
switch (_that) {
case _BuildLog() when $default != null:
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
case _BuildLog() when $default != null:
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
case _BuildLog():
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
case _BuildLog() when $default != null:
return $default(_that.message,_that.level,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BuildLog implements BuildLog {
  const _BuildLog({required this.message, required this.level, @DateTimeConverter() this.timestamp});
  factory _BuildLog.fromJson(Map<String, dynamic> json) => _$BuildLogFromJson(json);

@override final  String message;
@override final  String level;
@override@DateTimeConverter() final  DateTime? timestamp;

/// Create a copy of BuildLog
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildLogCopyWith<_BuildLog> get copyWith => __$BuildLogCopyWithImpl<_BuildLog>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuildLogToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildLog&&(identical(other.message, message) || other.message == message)&&(identical(other.level, level) || other.level == level)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,level,timestamp);

@override
String toString() {
  return 'BuildLog(message: $message, level: $level, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$BuildLogCopyWith<$Res> implements $BuildLogCopyWith<$Res> {
  factory _$BuildLogCopyWith(_BuildLog value, $Res Function(_BuildLog) _then) = __$BuildLogCopyWithImpl;
@override @useResult
$Res call({
 String message, String level,@DateTimeConverter() DateTime? timestamp
});




}
/// @nodoc
class __$BuildLogCopyWithImpl<$Res>
    implements _$BuildLogCopyWith<$Res> {
  __$BuildLogCopyWithImpl(this._self, this._then);

  final _BuildLog _self;
  final $Res Function(_BuildLog) _then;

/// Create a copy of BuildLog
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? level = null,Object? timestamp = freezed,}) {
  return _then(_BuildLog(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
