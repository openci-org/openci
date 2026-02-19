// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'environment_variable_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EnvironmentVariable {

 String get id; String get key; String get value; String get teamId; bool get autoIncrement;@DateTimeConverter() DateTime get createdAt;@DateTimeConverter() DateTime get updatedAt;
/// Create a copy of EnvironmentVariable
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnvironmentVariableCopyWith<EnvironmentVariable> get copyWith => _$EnvironmentVariableCopyWithImpl<EnvironmentVariable>(this as EnvironmentVariable, _$identity);

  /// Serializes this EnvironmentVariable to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EnvironmentVariable&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.autoIncrement, autoIncrement) || other.autoIncrement == autoIncrement)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,value,teamId,autoIncrement,createdAt,updatedAt);

@override
String toString() {
  return 'EnvironmentVariable(id: $id, key: $key, value: $value, teamId: $teamId, autoIncrement: $autoIncrement, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $EnvironmentVariableCopyWith<$Res>  {
  factory $EnvironmentVariableCopyWith(EnvironmentVariable value, $Res Function(EnvironmentVariable) _then) = _$EnvironmentVariableCopyWithImpl;
@useResult
$Res call({
 String id, String key, String value, String teamId, bool autoIncrement,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class _$EnvironmentVariableCopyWithImpl<$Res>
    implements $EnvironmentVariableCopyWith<$Res> {
  _$EnvironmentVariableCopyWithImpl(this._self, this._then);

  final EnvironmentVariable _self;
  final $Res Function(EnvironmentVariable) _then;

/// Create a copy of EnvironmentVariable
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? key = null,Object? value = null,Object? teamId = null,Object? autoIncrement = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,autoIncrement: null == autoIncrement ? _self.autoIncrement : autoIncrement // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [EnvironmentVariable].
extension EnvironmentVariablePatterns on EnvironmentVariable {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EnvironmentVariable value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EnvironmentVariable() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EnvironmentVariable value)  $default,){
final _that = this;
switch (_that) {
case _EnvironmentVariable():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EnvironmentVariable value)?  $default,){
final _that = this;
switch (_that) {
case _EnvironmentVariable() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String key,  String value,  String teamId,  bool autoIncrement, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EnvironmentVariable() when $default != null:
return $default(_that.id,_that.key,_that.value,_that.teamId,_that.autoIncrement,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String key,  String value,  String teamId,  bool autoIncrement, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _EnvironmentVariable():
return $default(_that.id,_that.key,_that.value,_that.teamId,_that.autoIncrement,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String key,  String value,  String teamId,  bool autoIncrement, @DateTimeConverter()  DateTime createdAt, @DateTimeConverter()  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _EnvironmentVariable() when $default != null:
return $default(_that.id,_that.key,_that.value,_that.teamId,_that.autoIncrement,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EnvironmentVariable implements EnvironmentVariable {
  const _EnvironmentVariable({required this.id, required this.key, required this.value, required this.teamId, this.autoIncrement = false, @DateTimeConverter() required this.createdAt, @DateTimeConverter() required this.updatedAt});
  factory _EnvironmentVariable.fromJson(Map<String, dynamic> json) => _$EnvironmentVariableFromJson(json);

@override final  String id;
@override final  String key;
@override final  String value;
@override final  String teamId;
@override@JsonKey() final  bool autoIncrement;
@override@DateTimeConverter() final  DateTime createdAt;
@override@DateTimeConverter() final  DateTime updatedAt;

/// Create a copy of EnvironmentVariable
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnvironmentVariableCopyWith<_EnvironmentVariable> get copyWith => __$EnvironmentVariableCopyWithImpl<_EnvironmentVariable>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EnvironmentVariableToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EnvironmentVariable&&(identical(other.id, id) || other.id == id)&&(identical(other.key, key) || other.key == key)&&(identical(other.value, value) || other.value == value)&&(identical(other.teamId, teamId) || other.teamId == teamId)&&(identical(other.autoIncrement, autoIncrement) || other.autoIncrement == autoIncrement)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,key,value,teamId,autoIncrement,createdAt,updatedAt);

@override
String toString() {
  return 'EnvironmentVariable(id: $id, key: $key, value: $value, teamId: $teamId, autoIncrement: $autoIncrement, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$EnvironmentVariableCopyWith<$Res> implements $EnvironmentVariableCopyWith<$Res> {
  factory _$EnvironmentVariableCopyWith(_EnvironmentVariable value, $Res Function(_EnvironmentVariable) _then) = __$EnvironmentVariableCopyWithImpl;
@override @useResult
$Res call({
 String id, String key, String value, String teamId, bool autoIncrement,@DateTimeConverter() DateTime createdAt,@DateTimeConverter() DateTime updatedAt
});




}
/// @nodoc
class __$EnvironmentVariableCopyWithImpl<$Res>
    implements _$EnvironmentVariableCopyWith<$Res> {
  __$EnvironmentVariableCopyWithImpl(this._self, this._then);

  final _EnvironmentVariable _self;
  final $Res Function(_EnvironmentVariable) _then;

/// Create a copy of EnvironmentVariable
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? key = null,Object? value = null,Object? teamId = null,Object? autoIncrement = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_EnvironmentVariable(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,teamId: null == teamId ? _self.teamId : teamId // ignore: cast_nullable_to_non_nullable
as String,autoIncrement: null == autoIncrement ? _self.autoIncrement : autoIncrement // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
