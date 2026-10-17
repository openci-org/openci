// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_store_connect_keys.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppStoreConnectKeys {

 String get issuerId; String get keyId; String get privateKeyBase64;
/// Create a copy of AppStoreConnectKeys
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppStoreConnectKeysCopyWith<AppStoreConnectKeys> get copyWith => _$AppStoreConnectKeysCopyWithImpl<AppStoreConnectKeys>(this as AppStoreConnectKeys, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppStoreConnectKeys&&(identical(other.issuerId, issuerId) || other.issuerId == issuerId)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.privateKeyBase64, privateKeyBase64) || other.privateKeyBase64 == privateKeyBase64));
}


@override
int get hashCode => Object.hash(runtimeType,issuerId,keyId,privateKeyBase64);



}

/// @nodoc
abstract mixin class $AppStoreConnectKeysCopyWith<$Res>  {
  factory $AppStoreConnectKeysCopyWith(AppStoreConnectKeys value, $Res Function(AppStoreConnectKeys) _then) = _$AppStoreConnectKeysCopyWithImpl;
@useResult
$Res call({
 String issuerId, String keyId, String privateKeyBase64
});




}
/// @nodoc
class _$AppStoreConnectKeysCopyWithImpl<$Res>
    implements $AppStoreConnectKeysCopyWith<$Res> {
  _$AppStoreConnectKeysCopyWithImpl(this._self, this._then);

  final AppStoreConnectKeys _self;
  final $Res Function(AppStoreConnectKeys) _then;

/// Create a copy of AppStoreConnectKeys
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issuerId = null,Object? keyId = null,Object? privateKeyBase64 = null,}) {
  return _then(_self.copyWith(
issuerId: null == issuerId ? _self.issuerId : issuerId // ignore: cast_nullable_to_non_nullable
as String,keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,privateKeyBase64: null == privateKeyBase64 ? _self.privateKeyBase64 : privateKeyBase64 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppStoreConnectKeys].
extension AppStoreConnectKeysPatterns on AppStoreConnectKeys {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppStoreConnectKeys value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppStoreConnectKeys() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppStoreConnectKeys value)  $default,){
final _that = this;
switch (_that) {
case _AppStoreConnectKeys():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppStoreConnectKeys value)?  $default,){
final _that = this;
switch (_that) {
case _AppStoreConnectKeys() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String issuerId,  String keyId,  String privateKeyBase64)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppStoreConnectKeys() when $default != null:
return $default(_that.issuerId,_that.keyId,_that.privateKeyBase64);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String issuerId,  String keyId,  String privateKeyBase64)  $default,) {final _that = this;
switch (_that) {
case _AppStoreConnectKeys():
return $default(_that.issuerId,_that.keyId,_that.privateKeyBase64);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String issuerId,  String keyId,  String privateKeyBase64)?  $default,) {final _that = this;
switch (_that) {
case _AppStoreConnectKeys() when $default != null:
return $default(_that.issuerId,_that.keyId,_that.privateKeyBase64);case _:
  return null;

}
}

}

/// @nodoc


class _AppStoreConnectKeys implements AppStoreConnectKeys {
  const _AppStoreConnectKeys({required this.issuerId, required this.keyId, required this.privateKeyBase64});


@override final  String issuerId;
@override final  String keyId;
@override final  String privateKeyBase64;

/// Create a copy of AppStoreConnectKeys
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppStoreConnectKeysCopyWith<_AppStoreConnectKeys> get copyWith => __$AppStoreConnectKeysCopyWithImpl<_AppStoreConnectKeys>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppStoreConnectKeys&&(identical(other.issuerId, issuerId) || other.issuerId == issuerId)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.privateKeyBase64, privateKeyBase64) || other.privateKeyBase64 == privateKeyBase64));
}


@override
int get hashCode => Object.hash(runtimeType,issuerId,keyId,privateKeyBase64);



}

/// @nodoc
abstract mixin class _$AppStoreConnectKeysCopyWith<$Res> implements $AppStoreConnectKeysCopyWith<$Res> {
  factory _$AppStoreConnectKeysCopyWith(_AppStoreConnectKeys value, $Res Function(_AppStoreConnectKeys) _then) = __$AppStoreConnectKeysCopyWithImpl;
@override @useResult
$Res call({
 String issuerId, String keyId, String privateKeyBase64
});




}
/// @nodoc
class __$AppStoreConnectKeysCopyWithImpl<$Res>
    implements _$AppStoreConnectKeysCopyWith<$Res> {
  __$AppStoreConnectKeysCopyWithImpl(this._self, this._then);

  final _AppStoreConnectKeys _self;
  final $Res Function(_AppStoreConnectKeys) _then;

/// Create a copy of AppStoreConnectKeys
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issuerId = null,Object? keyId = null,Object? privateKeyBase64 = null,}) {
  return _then(_AppStoreConnectKeys(
issuerId: null == issuerId ? _self.issuerId : issuerId // ignore: cast_nullable_to_non_nullable
as String,keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,privateKeyBase64: null == privateKeyBase64 ? _self.privateKeyBase64 : privateKeyBase64 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
