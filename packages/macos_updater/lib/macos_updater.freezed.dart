// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'macos_updater.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MacosUpdaterCheckResult implements DiagnosticableTreeMixin {

 MacosUpdaterCheckResultType get type; String get message; String? get version; String? get displayVersion;
/// Create a copy of MacosUpdaterCheckResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MacosUpdaterCheckResultCopyWith<MacosUpdaterCheckResult> get copyWith => _$MacosUpdaterCheckResultCopyWithImpl<MacosUpdaterCheckResult>(this as MacosUpdaterCheckResult, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MacosUpdaterCheckResult'))
    ..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('version', version))..add(DiagnosticsProperty('displayVersion', displayVersion));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MacosUpdaterCheckResult&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.version, version) || other.version == version)&&(identical(other.displayVersion, displayVersion) || other.displayVersion == displayVersion));
}


@override
int get hashCode => Object.hash(runtimeType,type,message,version,displayVersion);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MacosUpdaterCheckResult(type: $type, message: $message, version: $version, displayVersion: $displayVersion)';
}


}

/// @nodoc
abstract mixin class $MacosUpdaterCheckResultCopyWith<$Res>  {
  factory $MacosUpdaterCheckResultCopyWith(MacosUpdaterCheckResult value, $Res Function(MacosUpdaterCheckResult) _then) = _$MacosUpdaterCheckResultCopyWithImpl;
@useResult
$Res call({
 MacosUpdaterCheckResultType type, String message, String? version, String? displayVersion
});




}
/// @nodoc
class _$MacosUpdaterCheckResultCopyWithImpl<$Res>
    implements $MacosUpdaterCheckResultCopyWith<$Res> {
  _$MacosUpdaterCheckResultCopyWithImpl(this._self, this._then);

  final MacosUpdaterCheckResult _self;
  final $Res Function(MacosUpdaterCheckResult) _then;

/// Create a copy of MacosUpdaterCheckResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? message = null,Object? version = freezed,Object? displayVersion = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MacosUpdaterCheckResultType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,displayVersion: freezed == displayVersion ? _self.displayVersion : displayVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MacosUpdaterCheckResult].
extension MacosUpdaterCheckResultPatterns on MacosUpdaterCheckResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MacosUpdaterCheckResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MacosUpdaterCheckResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MacosUpdaterCheckResult value)  $default,){
final _that = this;
switch (_that) {
case _MacosUpdaterCheckResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MacosUpdaterCheckResult value)?  $default,){
final _that = this;
switch (_that) {
case _MacosUpdaterCheckResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MacosUpdaterCheckResultType type,  String message,  String? version,  String? displayVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MacosUpdaterCheckResult() when $default != null:
return $default(_that.type,_that.message,_that.version,_that.displayVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MacosUpdaterCheckResultType type,  String message,  String? version,  String? displayVersion)  $default,) {final _that = this;
switch (_that) {
case _MacosUpdaterCheckResult():
return $default(_that.type,_that.message,_that.version,_that.displayVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MacosUpdaterCheckResultType type,  String message,  String? version,  String? displayVersion)?  $default,) {final _that = this;
switch (_that) {
case _MacosUpdaterCheckResult() when $default != null:
return $default(_that.type,_that.message,_that.version,_that.displayVersion);case _:
  return null;

}
}

}

/// @nodoc


class _MacosUpdaterCheckResult with DiagnosticableTreeMixin implements MacosUpdaterCheckResult {
  const _MacosUpdaterCheckResult({required this.type, required this.message, this.version, this.displayVersion});


@override final  MacosUpdaterCheckResultType type;
@override final  String message;
@override final  String? version;
@override final  String? displayVersion;

/// Create a copy of MacosUpdaterCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MacosUpdaterCheckResultCopyWith<_MacosUpdaterCheckResult> get copyWith => __$MacosUpdaterCheckResultCopyWithImpl<_MacosUpdaterCheckResult>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'MacosUpdaterCheckResult'))
    ..add(DiagnosticsProperty('type', type))..add(DiagnosticsProperty('message', message))..add(DiagnosticsProperty('version', version))..add(DiagnosticsProperty('displayVersion', displayVersion));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MacosUpdaterCheckResult&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.version, version) || other.version == version)&&(identical(other.displayVersion, displayVersion) || other.displayVersion == displayVersion));
}


@override
int get hashCode => Object.hash(runtimeType,type,message,version,displayVersion);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'MacosUpdaterCheckResult(type: $type, message: $message, version: $version, displayVersion: $displayVersion)';
}


}

/// @nodoc
abstract mixin class _$MacosUpdaterCheckResultCopyWith<$Res> implements $MacosUpdaterCheckResultCopyWith<$Res> {
  factory _$MacosUpdaterCheckResultCopyWith(_MacosUpdaterCheckResult value, $Res Function(_MacosUpdaterCheckResult) _then) = __$MacosUpdaterCheckResultCopyWithImpl;
@override @useResult
$Res call({
 MacosUpdaterCheckResultType type, String message, String? version, String? displayVersion
});




}
/// @nodoc
class __$MacosUpdaterCheckResultCopyWithImpl<$Res>
    implements _$MacosUpdaterCheckResultCopyWith<$Res> {
  __$MacosUpdaterCheckResultCopyWithImpl(this._self, this._then);

  final _MacosUpdaterCheckResult _self;
  final $Res Function(_MacosUpdaterCheckResult) _then;

/// Create a copy of MacosUpdaterCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? message = null,Object? version = freezed,Object? displayVersion = freezed,}) {
  return _then(_MacosUpdaterCheckResult(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as MacosUpdaterCheckResultType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,displayVersion: freezed == displayVersion ? _self.displayVersion : displayVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
