// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'asc_authentication_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AscAuthenticationStatus {

 bool get authenticated; String? get providerName; int? get providerId; String? get publicProviderId;
/// Create a copy of AscAuthenticationStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AscAuthenticationStatusCopyWith<AscAuthenticationStatus> get copyWith => _$AscAuthenticationStatusCopyWithImpl<AscAuthenticationStatus>(this as AscAuthenticationStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AscAuthenticationStatus&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.publicProviderId, publicProviderId) || other.publicProviderId == publicProviderId));
}


@override
int get hashCode => Object.hash(runtimeType,authenticated,providerName,providerId,publicProviderId);

@override
String toString() {
  return 'AscAuthenticationStatus(authenticated: $authenticated, providerName: $providerName, providerId: $providerId, publicProviderId: $publicProviderId)';
}


}

/// @nodoc
abstract mixin class $AscAuthenticationStatusCopyWith<$Res>  {
  factory $AscAuthenticationStatusCopyWith(AscAuthenticationStatus value, $Res Function(AscAuthenticationStatus) _then) = _$AscAuthenticationStatusCopyWithImpl;
@useResult
$Res call({
 bool authenticated, String? providerName, int? providerId, String? publicProviderId
});




}
/// @nodoc
class _$AscAuthenticationStatusCopyWithImpl<$Res>
    implements $AscAuthenticationStatusCopyWith<$Res> {
  _$AscAuthenticationStatusCopyWithImpl(this._self, this._then);

  final AscAuthenticationStatus _self;
  final $Res Function(AscAuthenticationStatus) _then;

/// Create a copy of AscAuthenticationStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? authenticated = null,Object? providerName = freezed,Object? providerId = freezed,Object? publicProviderId = freezed,}) {
  return _then(_self.copyWith(
authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,providerName: freezed == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String?,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as int?,publicProviderId: freezed == publicProviderId ? _self.publicProviderId : publicProviderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AscAuthenticationStatus].
extension AscAuthenticationStatusPatterns on AscAuthenticationStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AscAuthenticationStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AscAuthenticationStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AscAuthenticationStatus value)  $default,){
final _that = this;
switch (_that) {
case _AscAuthenticationStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AscAuthenticationStatus value)?  $default,){
final _that = this;
switch (_that) {
case _AscAuthenticationStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool authenticated,  String? providerName,  int? providerId,  String? publicProviderId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AscAuthenticationStatus() when $default != null:
return $default(_that.authenticated,_that.providerName,_that.providerId,_that.publicProviderId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool authenticated,  String? providerName,  int? providerId,  String? publicProviderId)  $default,) {final _that = this;
switch (_that) {
case _AscAuthenticationStatus():
return $default(_that.authenticated,_that.providerName,_that.providerId,_that.publicProviderId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool authenticated,  String? providerName,  int? providerId,  String? publicProviderId)?  $default,) {final _that = this;
switch (_that) {
case _AscAuthenticationStatus() when $default != null:
return $default(_that.authenticated,_that.providerName,_that.providerId,_that.publicProviderId);case _:
  return null;

}
}

}

/// @nodoc


class _AscAuthenticationStatus implements AscAuthenticationStatus {
  const _AscAuthenticationStatus({required this.authenticated, this.providerName, this.providerId, this.publicProviderId});


@override final  bool authenticated;
@override final  String? providerName;
@override final  int? providerId;
@override final  String? publicProviderId;

/// Create a copy of AscAuthenticationStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AscAuthenticationStatusCopyWith<_AscAuthenticationStatus> get copyWith => __$AscAuthenticationStatusCopyWithImpl<_AscAuthenticationStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AscAuthenticationStatus&&(identical(other.authenticated, authenticated) || other.authenticated == authenticated)&&(identical(other.providerName, providerName) || other.providerName == providerName)&&(identical(other.providerId, providerId) || other.providerId == providerId)&&(identical(other.publicProviderId, publicProviderId) || other.publicProviderId == publicProviderId));
}


@override
int get hashCode => Object.hash(runtimeType,authenticated,providerName,providerId,publicProviderId);

@override
String toString() {
  return 'AscAuthenticationStatus(authenticated: $authenticated, providerName: $providerName, providerId: $providerId, publicProviderId: $publicProviderId)';
}


}

/// @nodoc
abstract mixin class _$AscAuthenticationStatusCopyWith<$Res> implements $AscAuthenticationStatusCopyWith<$Res> {
  factory _$AscAuthenticationStatusCopyWith(_AscAuthenticationStatus value, $Res Function(_AscAuthenticationStatus) _then) = __$AscAuthenticationStatusCopyWithImpl;
@override @useResult
$Res call({
 bool authenticated, String? providerName, int? providerId, String? publicProviderId
});




}
/// @nodoc
class __$AscAuthenticationStatusCopyWithImpl<$Res>
    implements _$AscAuthenticationStatusCopyWith<$Res> {
  __$AscAuthenticationStatusCopyWithImpl(this._self, this._then);

  final _AscAuthenticationStatus _self;
  final $Res Function(_AscAuthenticationStatus) _then;

/// Create a copy of AscAuthenticationStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? authenticated = null,Object? providerName = freezed,Object? providerId = freezed,Object? publicProviderId = freezed,}) {
  return _then(_AscAuthenticationStatus(
authenticated: null == authenticated ? _self.authenticated : authenticated // ignore: cast_nullable_to_non_nullable
as bool,providerName: freezed == providerName ? _self.providerName : providerName // ignore: cast_nullable_to_non_nullable
as String?,providerId: freezed == providerId ? _self.providerId : providerId // ignore: cast_nullable_to_non_nullable
as int?,publicProviderId: freezed == publicProviderId ? _self.publicProviderId : publicProviderId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
