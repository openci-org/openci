// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ios_signing_credentials.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IosSigningCredentials {

 String get issuerId; String get keyId; String get ascPrivateKeyPath; String get certificatePrivateKeyPath;
/// Create a copy of IosSigningCredentials
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IosSigningCredentialsCopyWith<IosSigningCredentials> get copyWith => _$IosSigningCredentialsCopyWithImpl<IosSigningCredentials>(this as IosSigningCredentials, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IosSigningCredentials&&(identical(other.issuerId, issuerId) || other.issuerId == issuerId)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.ascPrivateKeyPath, ascPrivateKeyPath) || other.ascPrivateKeyPath == ascPrivateKeyPath)&&(identical(other.certificatePrivateKeyPath, certificatePrivateKeyPath) || other.certificatePrivateKeyPath == certificatePrivateKeyPath));
}


@override
int get hashCode => Object.hash(runtimeType,issuerId,keyId,ascPrivateKeyPath,certificatePrivateKeyPath);



}

/// @nodoc
abstract mixin class $IosSigningCredentialsCopyWith<$Res>  {
  factory $IosSigningCredentialsCopyWith(IosSigningCredentials value, $Res Function(IosSigningCredentials) _then) = _$IosSigningCredentialsCopyWithImpl;
@useResult
$Res call({
 String issuerId, String keyId, String ascPrivateKeyPath, String certificatePrivateKeyPath
});




}
/// @nodoc
class _$IosSigningCredentialsCopyWithImpl<$Res>
    implements $IosSigningCredentialsCopyWith<$Res> {
  _$IosSigningCredentialsCopyWithImpl(this._self, this._then);

  final IosSigningCredentials _self;
  final $Res Function(IosSigningCredentials) _then;

/// Create a copy of IosSigningCredentials
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issuerId = null,Object? keyId = null,Object? ascPrivateKeyPath = null,Object? certificatePrivateKeyPath = null,}) {
  return _then(_self.copyWith(
issuerId: null == issuerId ? _self.issuerId : issuerId // ignore: cast_nullable_to_non_nullable
as String,keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,ascPrivateKeyPath: null == ascPrivateKeyPath ? _self.ascPrivateKeyPath : ascPrivateKeyPath // ignore: cast_nullable_to_non_nullable
as String,certificatePrivateKeyPath: null == certificatePrivateKeyPath ? _self.certificatePrivateKeyPath : certificatePrivateKeyPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IosSigningCredentials].
extension IosSigningCredentialsPatterns on IosSigningCredentials {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IosSigningCredentials value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IosSigningCredentials() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IosSigningCredentials value)  $default,){
final _that = this;
switch (_that) {
case _IosSigningCredentials():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IosSigningCredentials value)?  $default,){
final _that = this;
switch (_that) {
case _IosSigningCredentials() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String issuerId,  String keyId,  String ascPrivateKeyPath,  String certificatePrivateKeyPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IosSigningCredentials() when $default != null:
return $default(_that.issuerId,_that.keyId,_that.ascPrivateKeyPath,_that.certificatePrivateKeyPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String issuerId,  String keyId,  String ascPrivateKeyPath,  String certificatePrivateKeyPath)  $default,) {final _that = this;
switch (_that) {
case _IosSigningCredentials():
return $default(_that.issuerId,_that.keyId,_that.ascPrivateKeyPath,_that.certificatePrivateKeyPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String issuerId,  String keyId,  String ascPrivateKeyPath,  String certificatePrivateKeyPath)?  $default,) {final _that = this;
switch (_that) {
case _IosSigningCredentials() when $default != null:
return $default(_that.issuerId,_that.keyId,_that.ascPrivateKeyPath,_that.certificatePrivateKeyPath);case _:
  return null;

}
}

}

/// @nodoc


class _IosSigningCredentials implements IosSigningCredentials {
  const _IosSigningCredentials({required this.issuerId, required this.keyId, required this.ascPrivateKeyPath, required this.certificatePrivateKeyPath});


@override final  String issuerId;
@override final  String keyId;
@override final  String ascPrivateKeyPath;
@override final  String certificatePrivateKeyPath;

/// Create a copy of IosSigningCredentials
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IosSigningCredentialsCopyWith<_IosSigningCredentials> get copyWith => __$IosSigningCredentialsCopyWithImpl<_IosSigningCredentials>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IosSigningCredentials&&(identical(other.issuerId, issuerId) || other.issuerId == issuerId)&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.ascPrivateKeyPath, ascPrivateKeyPath) || other.ascPrivateKeyPath == ascPrivateKeyPath)&&(identical(other.certificatePrivateKeyPath, certificatePrivateKeyPath) || other.certificatePrivateKeyPath == certificatePrivateKeyPath));
}


@override
int get hashCode => Object.hash(runtimeType,issuerId,keyId,ascPrivateKeyPath,certificatePrivateKeyPath);



}

/// @nodoc
abstract mixin class _$IosSigningCredentialsCopyWith<$Res> implements $IosSigningCredentialsCopyWith<$Res> {
  factory _$IosSigningCredentialsCopyWith(_IosSigningCredentials value, $Res Function(_IosSigningCredentials) _then) = __$IosSigningCredentialsCopyWithImpl;
@override @useResult
$Res call({
 String issuerId, String keyId, String ascPrivateKeyPath, String certificatePrivateKeyPath
});




}
/// @nodoc
class __$IosSigningCredentialsCopyWithImpl<$Res>
    implements _$IosSigningCredentialsCopyWith<$Res> {
  __$IosSigningCredentialsCopyWithImpl(this._self, this._then);

  final _IosSigningCredentials _self;
  final $Res Function(_IosSigningCredentials) _then;

/// Create a copy of IosSigningCredentials
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issuerId = null,Object? keyId = null,Object? ascPrivateKeyPath = null,Object? certificatePrivateKeyPath = null,}) {
  return _then(_IosSigningCredentials(
issuerId: null == issuerId ? _self.issuerId : issuerId // ignore: cast_nullable_to_non_nullable
as String,keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,ascPrivateKeyPath: null == ascPrivateKeyPath ? _self.ascPrivateKeyPath : ascPrivateKeyPath // ignore: cast_nullable_to_non_nullable
as String,certificatePrivateKeyPath: null == certificatePrivateKeyPath ? _self.certificatePrivateKeyPath : certificatePrivateKeyPath // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
