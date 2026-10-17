// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'firebase_auth_client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FirebaseSession {

 String get token; String get refreshToken; DateTime get expiresAt;
/// Create a copy of FirebaseSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FirebaseSessionCopyWith<FirebaseSession> get copyWith => _$FirebaseSessionCopyWithImpl<FirebaseSession>(this as FirebaseSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FirebaseSession&&(identical(other.token, token) || other.token == token)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,token,refreshToken,expiresAt);



}

/// @nodoc
abstract mixin class $FirebaseSessionCopyWith<$Res>  {
  factory $FirebaseSessionCopyWith(FirebaseSession value, $Res Function(FirebaseSession) _then) = _$FirebaseSessionCopyWithImpl;
@useResult
$Res call({
 String token, String refreshToken, DateTime expiresAt
});




}
/// @nodoc
class _$FirebaseSessionCopyWithImpl<$Res>
    implements $FirebaseSessionCopyWith<$Res> {
  _$FirebaseSessionCopyWithImpl(this._self, this._then);

  final FirebaseSession _self;
  final $Res Function(FirebaseSession) _then;

/// Create a copy of FirebaseSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? token = null,Object? refreshToken = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FirebaseSession].
extension FirebaseSessionPatterns on FirebaseSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FirebaseSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FirebaseSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FirebaseSession value)  $default,){
final _that = this;
switch (_that) {
case _FirebaseSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FirebaseSession value)?  $default,){
final _that = this;
switch (_that) {
case _FirebaseSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String token,  String refreshToken,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FirebaseSession() when $default != null:
return $default(_that.token,_that.refreshToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String token,  String refreshToken,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _FirebaseSession():
return $default(_that.token,_that.refreshToken,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String token,  String refreshToken,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _FirebaseSession() when $default != null:
return $default(_that.token,_that.refreshToken,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _FirebaseSession implements FirebaseSession {
  const _FirebaseSession({required this.token, required this.refreshToken, required this.expiresAt});


@override final  String token;
@override final  String refreshToken;
@override final  DateTime expiresAt;

/// Create a copy of FirebaseSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FirebaseSessionCopyWith<_FirebaseSession> get copyWith => __$FirebaseSessionCopyWithImpl<_FirebaseSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FirebaseSession&&(identical(other.token, token) || other.token == token)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,token,refreshToken,expiresAt);



}

/// @nodoc
abstract mixin class _$FirebaseSessionCopyWith<$Res> implements $FirebaseSessionCopyWith<$Res> {
  factory _$FirebaseSessionCopyWith(_FirebaseSession value, $Res Function(_FirebaseSession) _then) = __$FirebaseSessionCopyWithImpl;
@override @useResult
$Res call({
 String token, String refreshToken, DateTime expiresAt
});




}
/// @nodoc
class __$FirebaseSessionCopyWithImpl<$Res>
    implements _$FirebaseSessionCopyWith<$Res> {
  __$FirebaseSessionCopyWithImpl(this._self, this._then);

  final _FirebaseSession _self;
  final $Res Function(_FirebaseSession) _then;

/// Create a copy of FirebaseSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? token = null,Object? refreshToken = null,Object? expiresAt = null,}) {
  return _then(_FirebaseSession(
token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,refreshToken: null == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
