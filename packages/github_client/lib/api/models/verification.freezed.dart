// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Verification {

 bool? get verified; String? get reason; String? get signature; String? get payload;@JsonKey(name: 'verified_at') String? get verifiedAt;
/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationCopyWith<Verification> get copyWith => _$VerificationCopyWithImpl<Verification>(this as Verification, _$identity);

  /// Serializes this Verification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Verification&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verified,reason,signature,payload,verifiedAt);

@override
String toString() {
  return 'Verification(verified: $verified, reason: $reason, signature: $signature, payload: $payload, verifiedAt: $verifiedAt)';
}


}

/// @nodoc
abstract mixin class $VerificationCopyWith<$Res>  {
  factory $VerificationCopyWith(Verification value, $Res Function(Verification) _then) = _$VerificationCopyWithImpl;
@useResult
$Res call({
 bool? verified, String? reason, String? signature, String? payload,@JsonKey(name: 'verified_at') String? verifiedAt
});




}
/// @nodoc
class _$VerificationCopyWithImpl<$Res>
    implements $VerificationCopyWith<$Res> {
  _$VerificationCopyWithImpl(this._self, this._then);

  final Verification _self;
  final $Res Function(Verification) _then;

/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verified = freezed,Object? reason = freezed,Object? signature = freezed,Object? payload = freezed,Object? verifiedAt = freezed,}) {
  return _then(_self.copyWith(
verified: freezed == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,signature: freezed == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Verification].
extension VerificationPatterns on Verification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Verification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Verification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Verification value)  $default,){
final _that = this;
switch (_that) {
case _Verification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Verification value)?  $default,){
final _that = this;
switch (_that) {
case _Verification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? verified,  String? reason,  String? signature,  String? payload, @JsonKey(name: 'verified_at')  String? verifiedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Verification() when $default != null:
return $default(_that.verified,_that.reason,_that.signature,_that.payload,_that.verifiedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? verified,  String? reason,  String? signature,  String? payload, @JsonKey(name: 'verified_at')  String? verifiedAt)  $default,) {final _that = this;
switch (_that) {
case _Verification():
return $default(_that.verified,_that.reason,_that.signature,_that.payload,_that.verifiedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? verified,  String? reason,  String? signature,  String? payload, @JsonKey(name: 'verified_at')  String? verifiedAt)?  $default,) {final _that = this;
switch (_that) {
case _Verification() when $default != null:
return $default(_that.verified,_that.reason,_that.signature,_that.payload,_that.verifiedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Verification implements Verification {
  const _Verification({this.verified, this.reason, this.signature, this.payload, @JsonKey(name: 'verified_at') this.verifiedAt});
  factory _Verification.fromJson(Map<String, dynamic> json) => _$VerificationFromJson(json);

@override final  bool? verified;
@override final  String? reason;
@override final  String? signature;
@override final  String? payload;
@override@JsonKey(name: 'verified_at') final  String? verifiedAt;

/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationCopyWith<_Verification> get copyWith => __$VerificationCopyWithImpl<_Verification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Verification&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,verified,reason,signature,payload,verifiedAt);

@override
String toString() {
  return 'Verification(verified: $verified, reason: $reason, signature: $signature, payload: $payload, verifiedAt: $verifiedAt)';
}


}

/// @nodoc
abstract mixin class _$VerificationCopyWith<$Res> implements $VerificationCopyWith<$Res> {
  factory _$VerificationCopyWith(_Verification value, $Res Function(_Verification) _then) = __$VerificationCopyWithImpl;
@override @useResult
$Res call({
 bool? verified, String? reason, String? signature, String? payload,@JsonKey(name: 'verified_at') String? verifiedAt
});




}
/// @nodoc
class __$VerificationCopyWithImpl<$Res>
    implements _$VerificationCopyWith<$Res> {
  __$VerificationCopyWithImpl(this._self, this._then);

  final _Verification _self;
  final $Res Function(_Verification) _then;

/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verified = freezed,Object? reason = freezed,Object? signature = freezed,Object? payload = freezed,Object? verifiedAt = freezed,}) {
  return _then(_Verification(
verified: freezed == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,signature: freezed == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
