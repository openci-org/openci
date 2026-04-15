// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'actions2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Actions2 {

/// The text to be displayed on a button in the web UI. The maximum size is 20 characters.
@JsonKey(name: 'Label') String get label;/// A short explanation of what this action would do. The maximum size is 40 characters.
 String get description;/// A reference for the action on the integrator's system. The maximum size is 20 characters.
 String get identifier;
/// Create a copy of Actions2
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Actions2CopyWith<Actions2> get copyWith => _$Actions2CopyWithImpl<Actions2>(this as Actions2, _$identity);

  /// Serializes this Actions2 to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Actions2&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.identifier, identifier) || other.identifier == identifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,description,identifier);

@override
String toString() {
  return 'Actions2(label: $label, description: $description, identifier: $identifier)';
}


}

/// @nodoc
abstract mixin class $Actions2CopyWith<$Res>  {
  factory $Actions2CopyWith(Actions2 value, $Res Function(Actions2) _then) = _$Actions2CopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'Label') String label, String description, String identifier
});




}
/// @nodoc
class _$Actions2CopyWithImpl<$Res>
    implements $Actions2CopyWith<$Res> {
  _$Actions2CopyWithImpl(this._self, this._then);

  final Actions2 _self;
  final $Res Function(Actions2) _then;

/// Create a copy of Actions2
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? description = null,Object? identifier = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Actions2].
extension Actions2Patterns on Actions2 {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Actions2 value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Actions2() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Actions2 value)  $default,){
final _that = this;
switch (_that) {
case _Actions2():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Actions2 value)?  $default,){
final _that = this;
switch (_that) {
case _Actions2() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'Label')  String label,  String description,  String identifier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Actions2() when $default != null:
return $default(_that.label,_that.description,_that.identifier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'Label')  String label,  String description,  String identifier)  $default,) {final _that = this;
switch (_that) {
case _Actions2():
return $default(_that.label,_that.description,_that.identifier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'Label')  String label,  String description,  String identifier)?  $default,) {final _that = this;
switch (_that) {
case _Actions2() when $default != null:
return $default(_that.label,_that.description,_that.identifier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Actions2 implements Actions2 {
  const _Actions2({@JsonKey(name: 'Label') required this.label, required this.description, required this.identifier});
  factory _Actions2.fromJson(Map<String, dynamic> json) => _$Actions2FromJson(json);

/// The text to be displayed on a button in the web UI. The maximum size is 20 characters.
@override@JsonKey(name: 'Label') final  String label;
/// A short explanation of what this action would do. The maximum size is 40 characters.
@override final  String description;
/// A reference for the action on the integrator's system. The maximum size is 20 characters.
@override final  String identifier;

/// Create a copy of Actions2
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$Actions2CopyWith<_Actions2> get copyWith => __$Actions2CopyWithImpl<_Actions2>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Actions2ToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Actions2&&(identical(other.label, label) || other.label == label)&&(identical(other.description, description) || other.description == description)&&(identical(other.identifier, identifier) || other.identifier == identifier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,description,identifier);

@override
String toString() {
  return 'Actions2(label: $label, description: $description, identifier: $identifier)';
}


}

/// @nodoc
abstract mixin class _$Actions2CopyWith<$Res> implements $Actions2CopyWith<$Res> {
  factory _$Actions2CopyWith(_Actions2 value, $Res Function(_Actions2) _then) = __$Actions2CopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'Label') String label, String description, String identifier
});




}
/// @nodoc
class __$Actions2CopyWithImpl<$Res>
    implements _$Actions2CopyWith<$Res> {
  __$Actions2CopyWithImpl(this._self, this._then);

  final _Actions2 _self;
  final $Res Function(_Actions2) _then;

/// Create a copy of Actions2
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? description = null,Object? identifier = null,}) {
  return _then(_Actions2(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
