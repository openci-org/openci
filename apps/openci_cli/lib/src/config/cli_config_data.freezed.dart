// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cli_config_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CliConfigData {

 String? get language;
/// Create a copy of CliConfigData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CliConfigDataCopyWith<CliConfigData> get copyWith => _$CliConfigDataCopyWithImpl<CliConfigData>(this as CliConfigData, _$identity);

  /// Serializes this CliConfigData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CliConfigData&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language);

@override
String toString() {
  return 'CliConfigData(language: $language)';
}


}

/// @nodoc
abstract mixin class $CliConfigDataCopyWith<$Res>  {
  factory $CliConfigDataCopyWith(CliConfigData value, $Res Function(CliConfigData) _then) = _$CliConfigDataCopyWithImpl;
@useResult
$Res call({
 String? language
});




}
/// @nodoc
class _$CliConfigDataCopyWithImpl<$Res>
    implements $CliConfigDataCopyWith<$Res> {
  _$CliConfigDataCopyWithImpl(this._self, this._then);

  final CliConfigData _self;
  final $Res Function(CliConfigData) _then;

/// Create a copy of CliConfigData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = freezed,}) {
  return _then(_self.copyWith(
language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CliConfigData].
extension CliConfigDataPatterns on CliConfigData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CliConfigData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CliConfigData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CliConfigData value)  $default,){
final _that = this;
switch (_that) {
case _CliConfigData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CliConfigData value)?  $default,){
final _that = this;
switch (_that) {
case _CliConfigData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CliConfigData() when $default != null:
return $default(_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? language)  $default,) {final _that = this;
switch (_that) {
case _CliConfigData():
return $default(_that.language);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? language)?  $default,) {final _that = this;
switch (_that) {
case _CliConfigData() when $default != null:
return $default(_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CliConfigData implements CliConfigData {
  const _CliConfigData({this.language});
  factory _CliConfigData.fromJson(Map<String, dynamic> json) => _$CliConfigDataFromJson(json);

@override final  String? language;

/// Create a copy of CliConfigData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CliConfigDataCopyWith<_CliConfigData> get copyWith => __$CliConfigDataCopyWithImpl<_CliConfigData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CliConfigDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CliConfigData&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,language);

@override
String toString() {
  return 'CliConfigData(language: $language)';
}


}

/// @nodoc
abstract mixin class _$CliConfigDataCopyWith<$Res> implements $CliConfigDataCopyWith<$Res> {
  factory _$CliConfigDataCopyWith(_CliConfigData value, $Res Function(_CliConfigData) _then) = __$CliConfigDataCopyWithImpl;
@override @useResult
$Res call({
 String? language
});




}
/// @nodoc
class __$CliConfigDataCopyWithImpl<$Res>
    implements _$CliConfigDataCopyWith<$Res> {
  __$CliConfigDataCopyWithImpl(this._self, this._then);

  final _CliConfigData _self;
  final $Res Function(_CliConfigData) _then;

/// Create a copy of CliConfigData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = freezed,}) {
  return _then(_CliConfigData(
language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
