// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asc_api_key.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AscApiKey {

 String get keyId; String get issuerId; File get privateKeyFile;
/// Create a copy of AscApiKey
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AscApiKeyCopyWith<AscApiKey> get copyWith => _$AscApiKeyCopyWithImpl<AscApiKey>(this as AscApiKey, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AscApiKey&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.issuerId, issuerId) || other.issuerId == issuerId)&&(identical(other.privateKeyFile, privateKeyFile) || other.privateKeyFile == privateKeyFile));
}


@override
int get hashCode => Object.hash(runtimeType,keyId,issuerId,privateKeyFile);



}

/// @nodoc
abstract mixin class $AscApiKeyCopyWith<$Res>  {
  factory $AscApiKeyCopyWith(AscApiKey value, $Res Function(AscApiKey) _then) = _$AscApiKeyCopyWithImpl;
@useResult
$Res call({
 String keyId, String issuerId, File privateKeyFile
});




}
/// @nodoc
class _$AscApiKeyCopyWithImpl<$Res>
    implements $AscApiKeyCopyWith<$Res> {
  _$AscApiKeyCopyWithImpl(this._self, this._then);

  final AscApiKey _self;
  final $Res Function(AscApiKey) _then;

/// Create a copy of AscApiKey
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyId = null,Object? issuerId = null,Object? privateKeyFile = null,}) {
  return _then(_self.copyWith(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,issuerId: null == issuerId ? _self.issuerId : issuerId // ignore: cast_nullable_to_non_nullable
as String,privateKeyFile: null == privateKeyFile ? _self.privateKeyFile : privateKeyFile // ignore: cast_nullable_to_non_nullable
as File,
  ));
}

}


/// Adds pattern-matching-related methods to [AscApiKey].
extension AscApiKeyPatterns on AscApiKey {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AscApiKey value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AscApiKey() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AscApiKey value)  $default,){
final _that = this;
switch (_that) {
case _AscApiKey():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AscApiKey value)?  $default,){
final _that = this;
switch (_that) {
case _AscApiKey() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String keyId,  String issuerId,  File privateKeyFile)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AscApiKey() when $default != null:
return $default(_that.keyId,_that.issuerId,_that.privateKeyFile);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String keyId,  String issuerId,  File privateKeyFile)  $default,) {final _that = this;
switch (_that) {
case _AscApiKey():
return $default(_that.keyId,_that.issuerId,_that.privateKeyFile);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String keyId,  String issuerId,  File privateKeyFile)?  $default,) {final _that = this;
switch (_that) {
case _AscApiKey() when $default != null:
return $default(_that.keyId,_that.issuerId,_that.privateKeyFile);case _:
  return null;

}
}

}

/// @nodoc


class _AscApiKey implements AscApiKey {
  const _AscApiKey({required this.keyId, required this.issuerId, required this.privateKeyFile});


@override final  String keyId;
@override final  String issuerId;
@override final  File privateKeyFile;

/// Create a copy of AscApiKey
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AscApiKeyCopyWith<_AscApiKey> get copyWith => __$AscApiKeyCopyWithImpl<_AscApiKey>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AscApiKey&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.issuerId, issuerId) || other.issuerId == issuerId)&&(identical(other.privateKeyFile, privateKeyFile) || other.privateKeyFile == privateKeyFile));
}


@override
int get hashCode => Object.hash(runtimeType,keyId,issuerId,privateKeyFile);



}

/// @nodoc
abstract mixin class _$AscApiKeyCopyWith<$Res> implements $AscApiKeyCopyWith<$Res> {
  factory _$AscApiKeyCopyWith(_AscApiKey value, $Res Function(_AscApiKey) _then) = __$AscApiKeyCopyWithImpl;
@override @useResult
$Res call({
 String keyId, String issuerId, File privateKeyFile
});




}
/// @nodoc
class __$AscApiKeyCopyWithImpl<$Res>
    implements _$AscApiKeyCopyWith<$Res> {
  __$AscApiKeyCopyWithImpl(this._self, this._then);

  final _AscApiKey _self;
  final $Res Function(_AscApiKey) _then;

/// Create a copy of AscApiKey
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyId = null,Object? issuerId = null,Object? privateKeyFile = null,}) {
  return _then(_AscApiKey(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,issuerId: null == issuerId ? _self.issuerId : issuerId // ignore: cast_nullable_to_non_nullable
as String,privateKeyFile: null == privateKeyFile ? _self.privateKeyFile : privateKeyFile // ignore: cast_nullable_to_non_nullable
as File,
  ));
}


}

// dart format on
